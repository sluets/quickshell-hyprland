# Hyprland Window Rules Used by Quickshell

This file documents compositor-side rules that Quickshell depends on. These rules are **not** stored in the Quickshell configuration itself, so they must be copied to every machine's Hyprland Lua configuration.

## Quickshell Settings window

The Settings window reports stable client metadata:

```text
class: org.quickshell
title: Quickshell Settings
initialClass: org.quickshell
initialTitle: Quickshell Settings
```

Without an explicit rule, Hyprland may treat it differently depending on workspace state:

- with one tiled client present, it may appear floating;
- with multiple tiled clients present, it may join the tiling layout;
- on an otherwise empty workspace, it may expand to most of the usable area;
- QML `implicitWidth` and `implicitHeight` are only size requests and do not control a tiled window.

Add this rule to the machine's Hyprland `rules.lua`:

```lua
hl.window_rule({
    name = "quickshell-settings",
    match = {
        class = "org.quickshell",
        title = "Quickshell Settings",
    },

    float = true,
    center = true,
    size = "1440 820",
})
```

The approved `1440 x 820` size:

- fits inside a 1920 x 1080 laptop display;
- leaves the Settings footer buttons visible at 1.5x shell font scale;
- remains comfortable on the 2560 x 1440 desktop;
- respects monitor reserved areas such as the Quickshell top bar.

Reload Hyprland after editing:

```bash
hyprctl reload
```

Confirm the rule from an empty workspace, with one tiled window, and with multiple tiled windows. The Settings window should float, center, and use the same dimensions in every case.

## Super+M exit binding

The old shell-command fallback stopped working after a Hyprland Lua update:

```lua
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
```

On the tested system, `hyprshutdown` was not installed and the legacy CLI form `hyprctl dispatch exit` was rejected by the Lua dispatcher parser.

Use the native Lua dispatcher instead:

```lua
hl.bind(mainMod .. " + M", hl.dsp.exit())
```

Terminal equivalent for testing:

```bash
hyprctl dispatch 'hl.dsp.exit()'
```

## Porting to another machine

After cloning the Quickshell repository to another machine:

1. Copy the Settings rule into that machine's `rules.lua`.
2. Copy the native `Super+M` binding into its keybind file.
3. Run `hyprctl reload`.
4. Open Settings and verify with `hyprctl clients` that `floating: 1` is reported.

Do not assume compositor-side rules are backed up by the Quickshell Git repository unless the Hyprland configuration itself is also committed elsewhere.

---

Updated 2026-07-17 by GPT-5.6 Thinking.
