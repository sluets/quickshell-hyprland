#!/usr/bin/env bash
set -euo pipefail
HELPER="/usr/local/libexec/quickshell-sddm-installer"
[[ -x "$HELPER" ]] || { echo "error: helper is not installed: $HELPER" >&2; exit 1; }
pkexec "$HELPER" rollback
