#!/usr/bin/env python3
"""Generate the user-owned SDDM appearance snapshot.

This script has no privileged behavior. It validates a small JSON contract,
writes theme.conf.user, and calculates a deterministic hash over the files
that a later installer helper will copy.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

HEX_COLOR = re.compile(r"^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$")
REQUIRED_COLORS = (
    "background", "foreground", "accent", "urgent",
    "muted", "surface", "hover", "border",
)


def fail(message: str) -> "NoReturn":
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(2)


def clean_text(value: object, name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{name} must be a non-empty string")
    if "\n" in value or "\r" in value:
        fail(f"{name} must be one line")
    return value.strip()


def integer(value: object, name: str, low: int, high: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        fail(f"{name} must be an integer")
    if not low <= value <= high:
        fail(f"{name} must be between {low} and {high}")
    return value


def load_contract(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"input file not found: {path}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path}: {exc}")
    if not isinstance(data, dict):
        fail("snapshot input must contain one JSON object")
    return data


def validate(data: dict, theme_dir: Path) -> dict[str, str | int | Path]:
    colors = data.get("colors")
    layout = data.get("layout")
    if not isinstance(colors, dict):
        fail("colors must be an object")
    if not isinstance(layout, dict):
        fail("layout must be an object")

    normalized: dict[str, str | int | Path] = {
        "Greeting": clean_text(data.get("greeting"), "greeting"),
        "ClockFormat": clean_text(data.get("clockFormat"), "clockFormat"),
        "DateFormat": clean_text(data.get("dateFormat"), "dateFormat"),
        "FontFamily": clean_text(data.get("fontFamily"), "fontFamily"),
        "Radius": integer(data.get("radius"), "radius", 0, 64),
        "ClockXOffset": integer(layout.get("clockXOffset"), "clockXOffset", -4096, 4096),
        "ClockYOffset": integer(layout.get("clockYOffset"), "clockYOffset", -4096, 4096),
        "LoginXOffset": integer(layout.get("loginXOffset"), "loginXOffset", -4096, 4096),
        "LoginYOffset": integer(layout.get("loginYOffset"), "loginYOffset", -4096, 4096),
        "ClockScalePercent": integer(layout.get("clockScalePercent"), "clockScalePercent", 50, 200),
        "LoginScalePercent": integer(layout.get("loginScalePercent"), "loginScalePercent", 50, 200),
        "LoginPanelWidth": integer(layout.get("loginPanelWidth"), "loginPanelWidth", 320, 720),
        "LoginPanelSpacing": integer(layout.get("loginPanelSpacing"), "loginPanelSpacing", 6, 30),
    }

    for key in REQUIRED_COLORS:
        value = clean_text(colors.get(key), f"colors.{key}")
        if not HEX_COLOR.fullmatch(value):
            fail(f"colors.{key} must be #RRGGBB or #RRGGBBAA")
        normalized["Color" + key.capitalize()] = value.upper()

    background_rel = Path(clean_text(data.get("background"), "background"))
    if background_rel.is_absolute() or ".." in background_rel.parts:
        fail("background must be a relative path inside the theme directory")
    background = (theme_dir / background_rel).resolve()
    try:
        background.relative_to(theme_dir.resolve())
    except ValueError:
        fail("background resolves outside the theme directory")
    if not background.is_file() or background.is_symlink():
        fail(f"background must be a regular non-symlink file: {background_rel}")
    if background.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
        fail("background must be PNG, JPEG, or WebP")
    normalized["Background"] = background_rel.as_posix()
    normalized["_background_path"] = background
    return normalized


def render_config(values: dict[str, str | int | Path]) -> bytes:
    keys = (
        "Background", "Greeting", "ClockFormat", "DateFormat",
        "ColorBackground", "ColorForeground", "ColorAccent", "ColorUrgent",
        "ColorMuted", "ColorSurface", "ColorHover", "ColorBorder",
        "FontFamily", "Radius", "ClockXOffset", "ClockYOffset",
        "LoginXOffset", "LoginYOffset", "ClockScalePercent", "LoginScalePercent",
        "LoginPanelWidth", "LoginPanelSpacing",
    )
    lines = [
        "[General]",
        "# Generated file. Edit snapshot/snapshot-input.json instead.",
    ]
    lines.extend(f"{key}={values[key]}" for key in keys)
    lines.append("")
    return "\n".join(lines).encode("utf-8")


def snapshot_digest(files: list[tuple[str, bytes]]) -> str:
    digest = hashlib.sha256()
    for relative_name, content in sorted(files):
        name = relative_name.encode("utf-8")
        digest.update(len(name).to_bytes(8, "big"))
        digest.update(name)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="snapshot/snapshot-input.json")
    parser.add_argument("--theme-dir", default=None)
    args = parser.parse_args()

    script = Path(__file__).resolve()
    theme_dir = Path(args.theme_dir).expanduser().resolve() if args.theme_dir else script.parent.parent
    input_path = Path(args.input).expanduser()
    if not input_path.is_absolute():
        input_path = theme_dir / input_path

    values = validate(load_contract(input_path), theme_dir)
    config_bytes = render_config(values)
    background_path = values["_background_path"]
    assert isinstance(background_path, Path)
    background_bytes = background_path.read_bytes()

    config_path = theme_dir / "theme.conf.user"
    hash_path = theme_dir / "snapshot" / "generated.sha256"
    config_path.write_bytes(config_bytes)
    digest = snapshot_digest([
        ("theme.conf.user", config_bytes),
        (str(values["Background"]), background_bytes),
    ])
    hash_path.write_text(digest + "\n", encoding="ascii")

    print(f"generated: {config_path}")
    print(f"snapshot:  {digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
