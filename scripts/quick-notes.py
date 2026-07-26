#!/usr/bin/env python3
"""Atomic persistence and clipboard helper for the Quickshell scratchpad. // GPT"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path


def notes_path() -> Path:
    data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
    return data_home / "quickshell" / "quick-notes.txt"


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=".quick-notes.", dir=path.parent, text=True)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, path)
    except Exception:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: quick-notes.py load|write|copy|clear [text]", file=sys.stderr)
        return 2

    action = sys.argv[1]
    path = notes_path()

    if action == "load":
        if path.exists():
            sys.stdout.write(path.read_text(encoding="utf-8"))
        return 0

    if action == "write":
        text = sys.argv[2] if len(sys.argv) > 2 else ""
        atomic_write(path, text)
        return 0

    if action == "clear":
        atomic_write(path, "")
        return 0

    if action == "copy":
        text = sys.argv[2] if len(sys.argv) > 2 else ""
        try:
            subprocess.run(["wl-copy"], input=text, text=True, check=True)
        except FileNotFoundError:
            print("wl-copy is not installed", file=sys.stderr)
            return 127
        return 0

    print(f"unknown action: {action}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
