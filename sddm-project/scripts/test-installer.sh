#!/usr/bin/env bash
set -euo pipefail
THEME_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$THEME_DIR/scripts/sddm-install-helper.py"
TEST_ROOT="/tmp/quickshell-sddm-installer-test"
DEST="$TEST_ROOT/theme"

rm -rf "$TEST_ROOT"
echo "== Generate current snapshot =="
"$THEME_DIR/scripts/generate-snapshot.py" --theme-dir "$THEME_DIR"

echo
echo "== Dry run =="
"$HELPER" install --source "$THEME_DIR" --test-mode --destination "$DEST" --dry-run

echo
echo "== First fake install =="
"$HELPER" install --source "$THEME_DIR" --test-mode --destination "$DEST"

echo
echo "== Identical fake install (must skip writes) =="
before="$(stat -c %Y "$DEST")"
sleep 1
"$HELPER" install --source "$THEME_DIR" --test-mode --destination "$DEST"
after="$(stat -c %Y "$DEST")"
[[ "$before" == "$after" ]] || { echo "error: unchanged destination was rewritten" >&2; exit 1; }

echo
echo "== Status =="
"$HELPER" status --test-mode --destination "$DEST"

echo
echo "PASS: dry-run, install, validation, and unchanged-snapshot skip all worked."
echo "Fake installed theme: $DEST"
