#!/bin/sh
set -eu

state_base=${XDG_STATE_HOME:-"$HOME/.local/state"}
qs_state="$state_base/quickshell"
profile_dir="$qs_state/ui-profiles/my-default"
prefs="$qs_state/user-prefs.json"
profile_prefs="$profile_dir/user-prefs.json"
wallpaper_file="$profile_dir/wallpaper.txt"

command=${1:-}

save_profile() {
    [ -f "$prefs" ] || { echo "Current settings file does not exist yet: $prefs" >&2; exit 2; }
    mkdir -p "$profile_dir"
    tmp="$profile_prefs.tmp.$$"
    cp -p "$prefs" "$tmp"
    mv -f "$tmp" "$profile_prefs"

    wall_tmp="$wallpaper_file.tmp.$$"
    : > "$wall_tmp"
    if command -v awww >/dev/null 2>&1; then
        awww query 2>/dev/null | sed -n 's/^.*image: //p' | head -n 1 > "$wall_tmp" || true
    fi
    mv -f "$wall_tmp" "$wallpaper_file"
    echo "Saved My Default settings and current wallpaper."
}

restore_profile() {
    [ -f "$profile_prefs" ] || { echo "My Default has not been saved yet." >&2; exit 3; }
    mkdir -p "$qs_state"
    tmp="$prefs.restore.$$"
    cp -p "$profile_prefs" "$tmp"
    mv -f "$tmp" "$prefs"

    restored_wallpaper=""
    if [ -f "$wallpaper_file" ]; then
        restored_wallpaper=$(sed -n '1p' "$wallpaper_file")
    fi
    if [ -n "$restored_wallpaper" ] && [ -f "$restored_wallpaper" ] && command -v awww >/dev/null 2>&1; then
        awww img "$restored_wallpaper" --transition-type fade --transition-duration 0.4 >/dev/null 2>&1 || true
        echo "Restored My Default settings and wallpaper."
    elif [ -n "$restored_wallpaper" ]; then
        echo "Restored My Default settings. Saved wallpaper is missing: $restored_wallpaper"
    else
        echo "Restored My Default settings. No wallpaper was stored."
    fi
}

status_profile() {
    if [ -f "$profile_prefs" ]; then
        stamp=$(date -r "$profile_prefs" '+%Y-%m-%d %I:%M %p' 2>/dev/null || true)
        wall=""
        [ -f "$wallpaper_file" ] && wall=$(sed -n '1p' "$wallpaper_file")
        printf 'saved\n%s\n%s\n' "$stamp" "$wall"
    else
        printf 'missing\n\n\n'
    fi
}

case "$command" in
    save) save_profile ;;
    restore) restore_profile ;;
    status) status_profile ;;
    *) echo "Usage: $0 {save|restore|status}" >&2; exit 64 ;;
esac
