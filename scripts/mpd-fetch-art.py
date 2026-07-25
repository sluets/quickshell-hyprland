#!/usr/bin/env python3
"""Fetch album art for an MPD track and cache it to a local file.

Lookup order:
  1. readpicture  -> embedded artwork from the audio file
  2. albumart     -> cover image from the track's directory

Prints the absolute cached image path on stdout when art is found.
Prints nothing and exits 0 when no art is available.
Prints a short error on stderr and exits nonzero only for true helper failures.
"""

from __future__ import annotations

import hashlib
import os
import socket
import sys
from pathlib import Path


def shell_escape_mpd(value: str) -> str:
    return value.replace('\\', '\\\\').replace('"', '\\"')


class MpdClient:
    def __init__(self) -> None:
        self.sock: socket.socket | None = None
        self.stream = None

    def connect(self) -> None:
        runtime_dir = os.environ.get("XDG_RUNTIME_DIR", "")
        unix_path = os.path.join(runtime_dir, "mpd", "socket") if runtime_dir else ""
        errors = []
        if unix_path:
            try:
                sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                sock.connect(unix_path)
                self.sock = sock
                self.stream = sock.makefile("rb")
                greeting = self.stream.readline().decode("utf-8", "replace").strip()
                if not greeting.startswith("OK MPD"):
                    raise RuntimeError(f"unexpected MPD greeting: {greeting}")
                return
            except Exception as exc:  # noqa: BLE001
                errors.append(f"unix:{exc}")
                try:
                    sock.close()
                except Exception:  # noqa: BLE001
                    pass
        try:
            sock = socket.create_connection(("127.0.0.1", 6600), timeout=3)
            self.sock = sock
            self.stream = sock.makefile("rb")
            greeting = self.stream.readline().decode("utf-8", "replace").strip()
            if not greeting.startswith("OK MPD"):
                raise RuntimeError(f"unexpected MPD greeting: {greeting}")
            return
        except Exception as exc:  # noqa: BLE001
            errors.append(f"tcp:{exc}")

        raise RuntimeError("could not connect to MPD (" + "; ".join(errors) + ")")

    def close(self) -> None:
        try:
            if self.stream is not None:
                self.stream.close()
        finally:
            if self.sock is not None:
                self.sock.close()

    def command_binary(self, command: str) -> tuple[dict[str, str], bytes, str | None]:
        assert self.sock is not None and self.stream is not None
        self.sock.sendall((command + "\n").encode("utf-8"))
        headers: dict[str, str] = {}
        binary = b""

        while True:
            line = self.stream.readline()
            if not line:
                return headers, binary, "connection closed"
            if line == b"OK\n":
                return headers, binary, None
            if line.startswith(b"ACK"):
                return headers, binary, line.decode("utf-8", "replace").strip()
            if line.startswith(b"binary: "):
                try:
                    count = int(line.split(b":", 1)[1].strip())
                except Exception:  # noqa: BLE001
                    return headers, binary, "invalid binary header"
                binary = self.stream.read(count)
                trailing = self.stream.read(1)
                if trailing != b"\n":
                    return headers, binary, "invalid binary payload terminator"
                continue

            decoded = line.decode("utf-8", "replace").rstrip("\n")
            if ": " in decoded:
                key, value = decoded.split(": ", 1)
                headers[key.lower()] = value


def fetch_art(track_path: str) -> tuple[str | None, bytes | None]:
    escaped = shell_escape_mpd(track_path)
    client = MpdClient()
    client.connect()
    try:
        for method in ("readpicture", "albumart"):
            offset = 0
            data = bytearray()
            mime_type: str | None = None
            total_size: int | None = None

            while True:
                headers, chunk, error = client.command_binary(f'{method} "{escaped}" {offset}')
                if error is not None:
                    data.clear()
                    mime_type = None
                    break
                if mime_type is None:
                    mime_type = headers.get("type")
                if total_size is None and "size" in headers:
                    try:
                        total_size = int(headers["size"])
                    except Exception:  # noqa: BLE001
                        total_size = None
                if chunk:
                    data.extend(chunk)
                    offset += len(chunk)
                if not chunk:
                    break
                if total_size is not None and len(data) >= total_size:
                    break

            if data:
                return mime_type, bytes(data)

        return None, None
    finally:
        client.close()


def extension_for(mime_type: str | None, payload: bytes) -> str:
    by_mime = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/webp": ".webp",
        "image/gif": ".gif",
        "image/bmp": ".bmp",
    }
    if mime_type in by_mime:
        return by_mime[mime_type]
    if payload.startswith(b"\xff\xd8\xff"):
        return ".jpg"
    if payload.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png"
    if payload.startswith(b"RIFF") and payload[8:12] == b"WEBP":
        return ".webp"
    if payload.startswith(b"GIF87a") or payload.startswith(b"GIF89a"):
        return ".gif"
    if payload.startswith(b"BM"):
        return ".bmp"
    return ".img"


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: mpd-fetch-art.py <relative-track-file>", file=sys.stderr)
        return 2

    track_path = argv[1].strip()
    if not track_path:
        return 0

    try:
        mime_type, payload = fetch_art(track_path)
    except Exception as exc:  # noqa: BLE001
        print(str(exc), file=sys.stderr)
        return 1

    if not payload:
        return 0

    runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or f"/tmp/quickshell-{os.getuid()}"
    cache_dir = Path(runtime_dir) / "quickshell-music-art"
    cache_dir.mkdir(parents=True, exist_ok=True)

    digest = hashlib.sha1(track_path.encode("utf-8")).hexdigest()  # nosec B324
    ext = extension_for(mime_type, payload)
    target = cache_dir / f"{digest}{ext}"
    target.write_bytes(payload)
    print(str(target))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
