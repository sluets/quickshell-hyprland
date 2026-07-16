#!/usr/bin/env python3
"""Apply the current Quickshell appearance to the staged SDDM theme.

Runs as the desktop user. It updates the user-owned SDDM snapshot, then calls
sddm-project's already-tested apply script, which performs validation and uses
pkexec only when the installed snapshot actually differs.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


def fail(message: str) -> "NoReturn":
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(2)


def current_wallpaper() -> Path:
    try:
        proc = subprocess.run(
            ["awww", "query"], check=True, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
    except FileNotFoundError:
        fail("awww was not found")
    except subprocess.CalledProcessError as exc:
        fail((exc.stderr or "awww query failed").strip())

    for line in proc.stdout.splitlines():
        marker = "image: "
        at = line.find(marker)
        if at >= 0:
            path = Path(line[at + len(marker):].strip()).expanduser().resolve()
            if path.is_file() and not path.is_symlink():
                return path
            fail(f"current wallpaper is not a regular file: {path}")
    fail("awww did not report a current image wallpaper")


def write_png(source: Path, destination: Path) -> None:
    header = source.read_bytes()[:8]
    destination.parent.mkdir(parents=True, exist_ok=True)
    if header == b"\x89PNG\r\n\x1a\n":
        shutil.copyfile(source, destination)
        return

    converters = [
        (["magick", str(source), str(destination)], "ImageMagick (magick)"),
        (["convert", str(source), str(destination)], "ImageMagick (convert)"),
        (["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(source), str(destination)], "ffmpeg"),
    ]
    for command, _name in converters:
        if shutil.which(command[0]) is None:
            continue
        try:
            subprocess.run(command, check=True)
            return
        except subprocess.CalledProcessError:
            if destination.exists():
                destination.unlink()
    fail("wallpaper is not PNG and no working converter was found (install imagemagick or ffmpeg)")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--theme", action="store_true", help="update palette/font/radius")
    parser.add_argument("--wallpaper", action="store_true", help="update wallpaper")
    parser.add_argument("--background", required=True)
    parser.add_argument("--foreground", required=True)
    parser.add_argument("--accent", required=True)
    parser.add_argument("--urgent", required=True)
    parser.add_argument("--muted", required=True)
    parser.add_argument("--surface", required=True)
    parser.add_argument("--hover", required=True)
    parser.add_argument("--border", required=True)
    parser.add_argument("--font", required=True)
    parser.add_argument("--radius", required=True, type=int)
    args = parser.parse_args()

    if not args.theme and not args.wallpaper:
        fail("select Theme, Wallpaper, or both")

    home = Path.home()
    sddm_dir = home / ".config" / "sddm-project"
    contract_path = sddm_dir / "snapshot" / "snapshot-input.json"
    apply_script = sddm_dir / "scripts" / "apply-sddm-theme.sh"
    if not contract_path.is_file():
        fail(f"missing SDDM snapshot contract: {contract_path}")
    if not apply_script.is_file():
        fail(f"missing SDDM apply script: {apply_script}")

    try:
        contract = json.loads(contract_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read SDDM snapshot contract: {exc}")

    if args.theme:
        contract["colors"] = {
            "background": args.background,
            "foreground": args.foreground,
            "accent": args.accent,
            "urgent": args.urgent,
            "muted": args.muted,
            "surface": args.surface,
            "hover": args.hover,
            "border": args.border,
        }
        contract["fontFamily"] = args.font
        contract["radius"] = max(0, min(64, args.radius))

    if args.wallpaper:
        source = current_wallpaper()
        write_png(source, sddm_dir / "assets" / "background.png")
        contract["background"] = "assets/background.png"
        print(f"wallpaper:          {source}")

    temp = contract_path.with_suffix(".json.tmp")
    temp.write_text(json.dumps(contract, indent=2) + "\n", encoding="utf-8")
    temp.replace(contract_path)

    print("snapshot contract:  updated")
    completed = subprocess.run(["bash", str(apply_script)], cwd=sddm_dir)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
