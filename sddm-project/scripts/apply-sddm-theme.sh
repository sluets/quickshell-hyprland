#!/usr/bin/env bash
set -euo pipefail
THEME_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="/usr/local/libexec/quickshell-sddm-installer"

[[ -x "$HELPER" ]] || {
  echo "error: system helper is not installed" >&2
  echo "run: $THEME_DIR/scripts/install-system-helper.sh" >&2
  exit 1
}
"$THEME_DIR/scripts/generate-snapshot.py" --theme-dir "$THEME_DIR"
"$HELPER" install --source "$THEME_DIR" --dry-run
pkexec "$HELPER" install --source "$THEME_DIR"
