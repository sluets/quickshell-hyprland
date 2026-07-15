# hyprland.lua integration reference

Everything the shell needs from the compositor config, in one place.
This machine's Hyprland config is **hyprland.lua** (Lua config, Hyprland
0.55+ — see HYPRLAND_INFO.md for the config-format background and the
GUI-managed-config caveat before hand-editing anything).

This file was originally a 2026-07-04 build-session handoff; everything
in it has since been confirmed working live, so it's been trimmed to
just the lines worth re-checking or re-pasting if the compositor config
is ever rebuilt.

## Global shortcut binds

The shell registers GlobalShortcuts under appid `shell` (all in
shell.qml). The Lua binds:

```lua
hl.bind(mainMod .. " + R", hl.dsp.global("shell:launcher"))
hl.bind(mainMod .. " + W", hl.dsp.global("shell:wallpapers"))
hl.bind(mainMod .. " + P", hl.dsp.global("shell:power"))
```

Note the Lua form: `global` is a FUNCTION under the `hl.dsp` table
returning a dispatcher closure, and its argument is one quoted
`"appid:name"` string. The QML side (GlobalShortcut) is
config-language-agnostic.

## awww-daemon autostart

The wallpaper picker applies wallpapers through `awww`; the daemon must
be running (it's a plain daemon, NOT a systemd unit — see
PROBLEMS_AND_FIXES 2026-07-05). Compositor autostart:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
end)
```

Bonus: awww-daemon restores the last-set wallpaper from its cache on
startup, so this also gets wallpaper-persists-across-reboot for free.

## Media-key binds (Volume OSD hardware triggers)

The changes flow through PipeWire, so the shell's Audio service and the
OSD react with no shell-side wiring:

```lua
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
```

## Testing without touching hyprland.lua

Every shortcut has an IPC equivalent (no `-c` flag on this machine —
shell.qml sits at the quickshell root, so there's no config name):

```sh
qs ipc call launcher toggle
qs ipc call wallpapers toggle
qs ipc call wallpapers set ~/Pictures/Wallpapers/foo.jpg
qs ipc call wallpapers get
qs ipc call wallpapers list
qs ipc call wallpapers random
qs ipc call power toggle
```
