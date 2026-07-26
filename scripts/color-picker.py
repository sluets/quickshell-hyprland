#!/usr/bin/env python3
"""Hyprpicker bridge, color conversion, clipboard, and bounded history. // GPT"""

from __future__ import annotations

import colorsys
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

MAX_HISTORY = 16
HEX_RE = re.compile(r"#[0-9a-fA-F]{6}")
PICK_HEX_RE = re.compile(r"(?<![0-9a-fA-F])#?([0-9a-fA-F]{8}|[0-9a-fA-F]{6})(?![0-9a-fA-F])")
ANSI_RE = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")


def history_path() -> Path:
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    return data_home / "quickshell" / "color-history.json"


def atomic_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=".color-history.", dir=path.parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(value, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, path)
    except Exception:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise


def color_record(hex_value: str) -> dict[str, object]:
    value = hex_value.upper()
    r = int(value[1:3], 16)
    g = int(value[3:5], 16)
    b = int(value[5:7], 16)
    h, l, s = colorsys.rgb_to_hls(r / 255.0, g / 255.0, b / 255.0)
    hue = round((h * 360.0) % 360.0)
    saturation = round(s * 100.0)
    lightness = round(l * 100.0)
    return {
        "hex": value,
        "rgb": f"rgb({r}, {g}, {b})",
        "hsl": f"hsl({hue}, {saturation}%, {lightness}%)",
        "r": r,
        "g": g,
        "b": b,
        "h": hue,
        "s": saturation,
        "l": lightness,
    }


def load_history() -> list[dict[str, object]]:
    path = history_path()
    if not path.exists():
        return []
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    if not isinstance(raw, list):
        return []
    result: list[dict[str, object]] = []
    for item in raw:
        if isinstance(item, dict) and isinstance(item.get("hex"), str) and HEX_RE.fullmatch(item["hex"]):
            result.append(color_record(item["hex"]))
    return result[:MAX_HISTORY]


def store_color(record: dict[str, object]) -> list[dict[str, object]]:
    existing = [item for item in load_history() if item.get("hex") != record["hex"]]
    result = [record, *existing][:MAX_HISTORY]
    atomic_json(history_path(), result)
    return result


def pick() -> int:
    try:
        proc = subprocess.run(
            ["hyprpicker", "--format=hex", "--no-fancy"],
            text=True,
            capture_output=True,
            check=False,
        )
    except FileNotFoundError:
        print(json.dumps({"error": "hyprpicker is not installed"}))
        return 127

    # Hyprpicker exits nonzero when selection is cancelled. That is not an error dialog.
    if proc.returncode != 0:
        print(json.dumps({"cancelled": True}))
        return 0

    # Hyprpicker versions/package builds may emit the selected value on stdout
    # or stderr, with or without a leading '#', and occasionally with ANSI
    # decoration. Normalize all supported forms to canonical #RRGGBB.
    output = ANSI_RE.sub("", f"{proc.stdout}\n{proc.stderr}")
    match = PICK_HEX_RE.search(output)
    if not match:
        print(json.dumps({"error": "hyprpicker returned no valid color"}))
        return 1

    digits = match.group(1)
    if len(digits) == 8:
        digits = digits[:6]
    record = color_record("#" + digits)
    history = store_color(record)
    print(json.dumps({"color": record, "history": history}))
    return 0


def copy_text(text: str) -> int:
    try:
        subprocess.run(["wl-copy"], input=text, text=True, check=True)
    except FileNotFoundError:
        print("wl-copy is not installed", file=sys.stderr)
        return 127
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: color-picker.py pick|load|copy|clear [text]", file=sys.stderr)
        return 2

    action = sys.argv[1]
    if action == "pick":
        return pick()
    if action == "load":
        print(json.dumps(load_history()))
        return 0
    if action == "copy":
        return copy_text(sys.argv[2] if len(sys.argv) > 2 else "")
    if action == "clear":
        atomic_json(history_path(), [])
        print("[]")
        return 0

    print(f"unknown action: {action}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
