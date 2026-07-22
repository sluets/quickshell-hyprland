#!/usr/bin/env bash
#=============================================================================
# simulate-zero-output.sh — Hyprland 0.55+ Lua-compatible zero-output test
#
# Disables every currently active physical output through `hyprctl eval`,
# waits for the requested duration, then restores the normal monitor config
# with `hyprctl reload`.
#
# WARNING: every screen will go black. The script continues running and
# restores the configured outputs automatically.
#
# Usage:
#   ./simulate-zero-output.sh [SECONDS]
#
# Emergency recovery from a TTY:
#   Ctrl+Alt+F3
#   log in
#   hyprctl reload
#
# GPT Rev 74:
#   Replaced the obsolete `hyprctl keyword monitor ...` calls with the
#   Hyprland 0.55+ Lua API:
#       hyprctl eval 'hl.monitor({ output = "...", disabled = true })'
#   Every disable command is checked. Output removal is then polled for up
#   to four seconds because Hyprland applies monitor changes asynchronously.
#   A real failure aborts and reloads the normal monitor configuration.
#=============================================================================

set -Eeuo pipefail

DURATION="${1:-30}"
RESTORE_NEEDED=false
declare -a MONITORS=()

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

restore_outputs() {
    local rc=$?

    if $RESTORE_NEEDED; then
        echo
        echo "Restoring monitor configuration with: hyprctl reload"

        if hyprctl reload; then
            echo "Monitor configuration restored."
        else
            echo "WARNING: hyprctl reload failed." >&2
            echo "Switch to a TTY with Ctrl+Alt+F3 and run: hyprctl reload" >&2
        fi
    fi

    exit "$rc"
}
trap restore_outputs EXIT INT TERM HUP

[[ "$DURATION" =~ ^[0-9]+([.][0-9]+)?$ ]] \
    || die "duration must be a non-negative number of seconds"

command -v hyprctl >/dev/null 2>&1 \
    || die "hyprctl was not found"

command -v python3 >/dev/null 2>&1 \
    || die "python3 was not found"

[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] \
    || die "HYPRLAND_INSTANCE_SIGNATURE is not set; run this inside Hyprland"

# Use Hyprland's active-monitor list and exclude synthetic/test outputs.
mapfile -t MONITORS < <(
    hyprctl -j monitors | python3 -c '
import json
import sys

try:
    monitors = json.load(sys.stdin)
except Exception as exc:
    print(f"failed to parse hyprctl monitor JSON: {exc}", file=sys.stderr)
    raise SystemExit(1)

for monitor in monitors:
    name = monitor.get("name", "")
    if not name or name in {"FALLBACK", "QSWATCHDOG"}:
        continue
    if monitor.get("disabled", False):
        continue
    print(name)
'
)

((${#MONITORS[@]} > 0)) \
    || die "no active physical outputs were found"

echo "Will disable for ${DURATION}s: ${MONITORS[*]}"
echo "Screens go BLACK in 5 seconds."
echo "The script restores your monitor config automatically."
echo "Emergency recovery from a TTY: hyprctl reload"
sleep 5

# From this point onward, any exit path must restore the monitor config.
RESTORE_NEEDED=true

for monitor in "${MONITORS[@]}"; do
    # JSON-encode the connector name so it is safe inside the Lua string.
    quoted_name=$(
        python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$monitor"
    )

    lua_code="hl.monitor({ output = ${quoted_name}, disabled = true })"

    echo "Disabling ${monitor}..."

    if ! output=$(hyprctl eval "$lua_code" 2>&1); then
        printf 'Failed to disable %s:\n%s\n' "$monitor" "$output" >&2
        exit 1
    fi

    printf '%s\n' "$output"

    # Hyprland eval should return "ok". Treat anything else as failure rather
    # than blindly entering the black-screen timer.
    if [[ "${output,,}" != *"ok"* ]]; then
        printf 'Unexpected response while disabling %s:\n%s\n' \
            "$monitor" "$output" >&2
        exit 1
    fi
done

# Output removal is asynchronous. Hyprland may briefly report one connector
# after both eval calls returned "ok", especially while a monitor or client is
# reacting to the layout change. Poll for a short settle window instead of
# treating the first snapshot as final.
ZERO_VERIFY_TIMEOUT=4
verify_deadline=$((SECONDS + ZERO_VERIFY_TIMEOUT))
remaining="-1"

while (( SECONDS <= verify_deadline )); do
    remaining=$(
        hyprctl -j monitors | python3 -c '
import json
import sys

monitors = json.load(sys.stdin)
count = 0
for monitor in monitors:
    name = monitor.get("name", "")
    if not name or name in {"FALLBACK", "QSWATCHDOG"}:
        continue
    if monitor.get("disabled", False):
        continue
    count += 1
print(count)
'
    )

    if [[ "$remaining" == "0" ]]; then
        break
    fi

    sleep 0.25
done

if [[ "$remaining" != "0" ]]; then
    echo "Hyprland did not settle at zero outputs within ${ZERO_VERIFY_TIMEOUT}s." >&2
    echo "Current monitor snapshot:" >&2
    hyprctl -j monitors >&2 || true
    die "Hyprland still reports ${remaining} active physical output(s); aborting"
fi

echo "All real outputs disabled at $(date +%H:%M:%S)."
echo "Sleeping ${DURATION}s..."
sleep "$DURATION"

echo "Zero-output interval complete."
# EXIT trap runs `hyprctl reload`.
