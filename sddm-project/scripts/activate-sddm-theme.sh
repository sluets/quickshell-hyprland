#!/usr/bin/env bash
set -euo pipefail

HELPER="/usr/local/libexec/quickshell-sddm-installer"
[[ -x "$HELPER" ]] || {
  echo "error: helper is not installed: $HELPER" >&2
  echo "run ./scripts/install-system-helper.sh first" >&2
  exit 1
}

# Prove the installed theme and intended config are valid before authentication.
"$HELPER" activate --dry-run
pkexec "$HELPER" activate

echo
echo "Activated for the next SDDM start. No restart or reboot was performed."
echo "Rollback from a TTY:"
echo "  sudo rm -f /etc/sddm.conf.d/quickshell-theme.conf"
echo "  sudo systemctl restart sddm"
