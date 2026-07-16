#!/usr/bin/env python3
"""Narrow installer for the generated Quickshell SDDM theme snapshot.

The real destination is fixed. A /tmp destination is accepted only with
--test-mode so the complete copy/compare/backup/rollback flow can be tested
without touching system files.
"""
from __future__ import annotations

import argparse
import configparser
import hashlib
import os
import shutil
import stat
import sys
import tempfile
from pathlib import Path

REAL_DEST = Path("/usr/share/sddm/themes/quickshell-custom")
REAL_BACKUP = Path("/usr/share/sddm/themes/.quickshell-custom.backup")
MANIFEST = ".quickshell-installed.sha256"
ACTIVE_CONFIG = Path("/etc/sddm.conf.d/quickshell-theme.conf")
ACTIVE_CONFIG_BACKUP = Path("/etc/sddm.conf.d/.quickshell-theme.conf.backup")
ACTIVE_CONFIG_TEXT = "[Theme]\nCurrent=quickshell-custom\n"
ALLOWED = (
    "Main.qml",
    "metadata.desktop",
    "theme.conf",
    "theme.conf.user",
    "assets/background.png",
    "snapshot/generated.sha256",
)
MAX_SIZE = {
    "Main.qml": 2 * 1024 * 1024,
    "metadata.desktop": 64 * 1024,
    "theme.conf": 256 * 1024,
    "theme.conf.user": 256 * 1024,
    "assets/background.png": 64 * 1024 * 1024,
    "snapshot/generated.sha256": 256,
}


def die(message: str, code: int = 2) -> "NoReturn":
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(code)


def regular_file(path: Path, relative: str) -> bytes:
    try:
        info = path.lstat()
    except FileNotFoundError:
        die(f"required file missing: {relative}")
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        die(f"must be a regular non-symlink file: {relative}")
    if info.st_size > MAX_SIZE[relative]:
        die(f"file is too large: {relative}")
    return path.read_bytes()


def snapshot_digest(files: list[tuple[str, bytes]]) -> str:
    digest = hashlib.sha256()
    for relative_name, content in sorted(files):
        name = relative_name.encode("utf-8")
        digest.update(len(name).to_bytes(8, "big"))
        digest.update(name)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest()


def validate_source(source: Path) -> tuple[dict[str, bytes], str]:
    if not source.is_dir() or source.is_symlink():
        die(f"source must be a real directory: {source}")

    files = {relative: regular_file(source / relative, relative) for relative in ALLOWED}

    if not files["assets/background.png"].startswith(b"\x89PNG\r\n\x1a\n"):
        die("assets/background.png is not a valid PNG header")

    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    try:
        parser.read_string(files["theme.conf.user"].decode("utf-8"))
    except (UnicodeDecodeError, configparser.Error) as exc:
        die(f"invalid theme.conf.user: {exc}")
    if parser.get("General", "Background", fallback="") != "assets/background.png":
        die("theme.conf.user Background must be assets/background.png")

    recorded = files["snapshot/generated.sha256"].decode("ascii", errors="strict").strip()
    if len(recorded) != 64 or any(c not in "0123456789abcdef" for c in recorded):
        die("snapshot/generated.sha256 is malformed")
    expected = snapshot_digest([
        ("theme.conf.user", files["theme.conf.user"]),
        ("assets/background.png", files["assets/background.png"]),
    ])
    if recorded != expected:
        die("generated snapshot hash does not match theme.conf.user/background.png")

    full_digest = snapshot_digest(list(files.items()))
    return files, full_digest


def destination_digest(destination: Path) -> str | None:
    manifest = destination / MANIFEST
    if not manifest.is_file() or manifest.is_symlink():
        return None
    value = manifest.read_text(encoding="ascii", errors="ignore").strip()
    return value if len(value) == 64 else None


def ensure_destination(args: argparse.Namespace) -> tuple[Path, Path]:
    if args.test_mode:
        destination = Path(args.destination).expanduser().resolve() if args.destination else Path("/tmp/quickshell-sddm-installer-test/theme")
        try:
            destination.relative_to(Path("/tmp"))
        except ValueError:
            die("test destination must be under /tmp")
        backup = destination.parent / (destination.name + ".backup")
        return destination, backup
    if args.destination:
        die("--destination is only allowed with --test-mode")
    if os.geteuid() != 0 and not args.dry_run and args.action != "status":
        die("real installation requires root (run through pkexec)")
    return REAL_DEST, REAL_BACKUP


def write_tree(destination: Path, files: dict[str, bytes], digest: str, real_install: bool) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temp = Path(tempfile.mkdtemp(prefix=f".{destination.name}.new-", dir=destination.parent))
    try:
        for relative, content in files.items():
            target = temp / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content)
        (temp / MANIFEST).write_text(digest + "\n", encoding="ascii")
        for directory in [temp, temp / "assets", temp / "snapshot"]:
            directory.chmod(0o755)
        for relative in (*ALLOWED, MANIFEST):
            (temp / relative).chmod(0o644)
        if real_install:
            for root, dirs, names in os.walk(temp):
                os.chown(root, 0, 0)
                for name in dirs + names:
                    os.chown(Path(root) / name, 0, 0)
        os.replace(temp, destination)
    finally:
        if temp.exists():
            shutil.rmtree(temp)


def install(source: Path, destination: Path, backup: Path, dry_run: bool, test_mode: bool) -> int:
    files, digest = validate_source(source)
    current = destination_digest(destination)
    print(f"source digest:      {digest}")
    print(f"installed digest:   {current or 'none'}")
    print(f"destination:        {destination}")
    if current == digest:
        print("result:             already up to date; no files written")
        return 0
    if dry_run:
        print("result:             changes validated; dry run only")
        return 0

    if backup.exists():
        shutil.rmtree(backup)
    if destination.exists():
        os.replace(destination, backup)
        print(f"backup:             {backup}")
    try:
        write_tree(destination, files, digest, real_install=not test_mode)
    except Exception:
        if destination.exists():
            shutil.rmtree(destination)
        if backup.exists():
            os.replace(backup, destination)
        raise
    print("result:             installed successfully")
    return 0


def rollback(destination: Path, backup: Path, dry_run: bool) -> int:
    if not backup.is_dir():
        die(f"no backup exists at {backup}")
    print(f"destination:        {destination}")
    print(f"backup:             {backup}")
    if dry_run:
        print("result:             rollback available; dry run only")
        return 0
    failed = destination.parent / (destination.name + ".failed")
    if failed.exists():
        shutil.rmtree(failed)
    if destination.exists():
        os.replace(destination, failed)
    os.replace(backup, destination)
    if failed.exists():
        shutil.rmtree(failed)
    print("result:             rollback completed")
    return 0


def validate_installed_theme() -> str:
    digest = destination_digest(REAL_DEST)
    if not REAL_DEST.is_dir() or digest is None:
        die(f"installed theme is missing or invalid: {REAL_DEST}")
    # Re-read every installed allowlisted file and verify the manifest instead
    # of trusting that the directory merely exists.
    files = {relative: regular_file(REAL_DEST / relative, relative) for relative in ALLOWED}
    actual = snapshot_digest(list(files.items()))
    if actual != digest:
        die("installed theme files do not match their manifest; re-apply the theme first")
    return digest


def activate(dry_run: bool) -> int:
    if os.geteuid() != 0 and not dry_run:
        die("activation requires root (run through pkexec)")
    digest = validate_installed_theme()
    current = ACTIVE_CONFIG.read_text(encoding="utf-8", errors="replace") if ACTIVE_CONFIG.is_file() else None
    print(f"installed digest:   {digest}")
    print(f"config:             {ACTIVE_CONFIG}")
    if current == ACTIVE_CONFIG_TEXT:
        print("result:             already active; no files written")
        return 0
    if dry_run:
        print("result:             activation validated; dry run only")
        return 0
    ACTIVE_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    if ACTIVE_CONFIG_BACKUP.exists():
        ACTIVE_CONFIG_BACKUP.unlink()
    if ACTIVE_CONFIG.exists():
        os.replace(ACTIVE_CONFIG, ACTIVE_CONFIG_BACKUP)
    tmp = ACTIVE_CONFIG.with_name(ACTIVE_CONFIG.name + ".new")
    tmp.write_text(ACTIVE_CONFIG_TEXT, encoding="utf-8")
    tmp.chmod(0o644)
    os.chown(tmp, 0, 0)
    os.replace(tmp, ACTIVE_CONFIG)
    print("result:             theme activated; SDDM was not restarted")
    return 0


def deactivate(dry_run: bool) -> int:
    if os.geteuid() != 0 and not dry_run:
        die("deactivation requires root (run through pkexec)")
    print(f"config:             {ACTIVE_CONFIG}")
    if not ACTIVE_CONFIG.exists() and not ACTIVE_CONFIG_BACKUP.exists():
        print("result:             already inactive; no files written")
        return 0
    if dry_run:
        print("result:             deactivation available; dry run only")
        return 0
    if ACTIVE_CONFIG.exists():
        ACTIVE_CONFIG.unlink()
    if ACTIVE_CONFIG_BACKUP.exists():
        os.replace(ACTIVE_CONFIG_BACKUP, ACTIVE_CONFIG)
        print("result:             previous config restored; SDDM was not restarted")
    else:
        print("result:             override removed; SDDM was not restarted")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("install", "status", "rollback", "activate", "deactivate"), nargs="?", default="install")
    parser.add_argument("--source", default=None)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--test-mode", action="store_true")
    parser.add_argument("--destination", default=None)
    args = parser.parse_args()

    if args.action == "activate":
        if args.test_mode or args.destination:
            die("activate does not support test destinations")
        return activate(args.dry_run)
    if args.action == "deactivate":
        if args.test_mode or args.destination:
            die("deactivate does not support test destinations")
        return deactivate(args.dry_run)

    destination, backup = ensure_destination(args)
    if args.action == "rollback":
        return rollback(destination, backup, args.dry_run)
    if args.action == "status":
        print(f"destination:        {destination}")
        print(f"installed digest:   {destination_digest(destination) or 'none'}")
        print(f"backup present:     {'yes' if backup.is_dir() else 'no'}")
        return 0
    if not args.source:
        die("install requires --source")
    return install(Path(args.source).expanduser().resolve(), destination, backup, args.dry_run, args.test_mode)


if __name__ == "__main__":
    raise SystemExit(main())
