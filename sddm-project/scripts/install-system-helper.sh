#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$THEME_DIR/scripts/sddm-install-helper.py"
DEST_DIR="/usr/local/libexec"
DEST="$DEST_DIR/quickshell-sddm-installer"

command -v pkexec >/dev/null || {
  echo "error: pkexec is not installed" >&2
  exit 1
}

# Install the directory and helper in one authenticated operation. This also
# fixes fresh systems where /usr/local/libexec does not exist yet.
pkexec /bin/sh -c '
  set -eu
  /usr/bin/install -d -o root -g root -m 0755 "$1"
  /usr/bin/install -o root -g root -m 0755 "$2" "$3"
' sh "$DEST_DIR" "$SOURCE" "$DEST"

echo "Installed helper: $DEST"
