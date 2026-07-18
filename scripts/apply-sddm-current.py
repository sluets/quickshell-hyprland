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
import tempfile
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
    parser.add_argument("--preview", action="store_true", help="build and launch an unprivileged temporary preview")
    parser.add_argument("--theme", action="store_true", help="update palette/font/radius")
    parser.add_argument("--wallpaper", action="store_true", help="update wallpaper")
    parser.add_argument("--layout", action="store_true", help="update clock/login layout")
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
    parser.add_argument("--clock-x-offset", required=True, type=int)
    parser.add_argument("--clock-y-offset", required=True, type=int)
    parser.add_argument("--login-x-offset", required=True, type=int)
    parser.add_argument("--login-y-offset", required=True, type=int)
    parser.add_argument("--clock-scale-percent", required=True, type=int)
    parser.add_argument("--login-scale-percent", required=True, type=int)
    parser.add_argument("--login-panel-width", required=True, type=int)
    parser.add_argument("--login-panel-spacing", required=True, type=int)
    parser.add_argument("--custom-login-text", required=True)
    args = parser.parse_args()

    if not args.theme and not args.wallpaper and not args.layout:
        fail("select Theme, Wallpaper, Layout, or a combination")

    home = Path.home()
    source_dir = home / ".config" / "sddm-project"
    source_contract = source_dir / "snapshot" / "snapshot-input.json"
    if not source_contract.is_file():
        fail(f"missing SDDM snapshot contract: {source_contract}")

    preview_temp: tempfile.TemporaryDirectory[str] | None = None
    if args.preview:
        preview_temp = tempfile.TemporaryDirectory(prefix="quickshell-sddm-preview-")
        sddm_dir = Path(preview_temp.name) / "theme"
        shutil.copytree(source_dir, sddm_dir)
    else:
        sddm_dir = source_dir

    contract_path = sddm_dir / "snapshot" / "snapshot-input.json"
    apply_script = sddm_dir / "scripts" / "apply-sddm-theme.sh"
    generator = sddm_dir / "scripts" / "generate-snapshot.py"
    if not apply_script.is_file():
        fail(f"missing SDDM apply script: {apply_script}")
    if args.preview and not generator.is_file():
        fail(f"missing SDDM snapshot generator: {generator}")

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

    if args.layout:
        contract["layout"] = {
            "clockXOffset": max(-4096, min(4096, args.clock_x_offset)),
            "clockYOffset": max(-4096, min(4096, args.clock_y_offset)),
            "loginXOffset": max(-4096, min(4096, args.login_x_offset)),
            "loginYOffset": max(-4096, min(4096, args.login_y_offset)),
            "clockScalePercent": max(50, min(200, args.clock_scale_percent)),
            "loginScalePercent": max(50, min(200, args.login_scale_percent)),
            "loginPanelWidth": max(320, min(720, args.login_panel_width)),
            "loginPanelSpacing": max(6, min(30, args.login_panel_spacing)),
        }
        custom_text = args.custom_login_text.strip()
        contract["greeting"] = custom_text if custom_text else "Welcome back"

    if args.wallpaper:
        source = current_wallpaper()
        write_png(source, sddm_dir / "assets" / "background.png")
        contract["background"] = "assets/background.png"
        print(f"wallpaper:          {source}")

    temp = contract_path.with_suffix(".json.tmp")
    temp.write_text(json.dumps(contract, indent=2) + "\n", encoding="utf-8")
    temp.replace(contract_path)

    print("snapshot contract:  updated")

    if args.preview:
        try:
            generated = subprocess.run(
                ["python3", str(generator), "--theme-dir", str(sddm_dir)],
                cwd=sddm_dir,
            )
            if generated.returncode != 0:
                return generated.returncode

            greeter = shutil.which("sddm-greeter-qt6") or shutil.which("sddm-greeter")
            if greeter is None:
                fail("no SDDM greeter executable was found")
            print(f"preview theme:      {sddm_dir}")
            print("result:             temporary preview only; no root files written")
            return subprocess.run(
                [greeter, "--test-mode", "--theme", str(sddm_dir)],
                cwd=sddm_dir,
            ).returncode
        finally:
            if preview_temp is not None:
                preview_temp.cleanup()

    completed = subprocess.run(["bash", str(apply_script)], cwd=sddm_dir)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
