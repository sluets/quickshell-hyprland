#!/usr/bin/env bash
set -euo pipefail

HELPER="/usr/local/libexec/quickshell-sddm-installer"
[[ -x "$HELPER" ]] || {
  echo "error: helper is not installed: $HELPER" >&2
  exit 1
}

"$HELPER" deactivate --dry-run
pkexec "$HELPER" deactivate

echo "Quickshell SDDM override disabled. No restart was performed."
