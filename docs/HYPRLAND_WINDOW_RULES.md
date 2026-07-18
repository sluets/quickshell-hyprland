# Hyprland Window Rules Used by Quickshell

<!-- GPT: updated 2026-07-18 -->

This file documents compositor-side rules that Quickshell depends on. These rules are not stored in the Quickshell repository unless the Hyprland configuration is backed up separately.

## Quickshell Settings window

Stable client metadata:

```text
class: org.quickshell
title: Quickshell Settings
initialClass: org.quickshell
initialTitle: Quickshell Settings
```

The window must be forced to float. Without that rule, Hyprland can tile it and ignore the QML preferred dimensions.

Use:

```lua
hl.window_rule({
    name = "quickshell-settings",
    match = {
        class = "org.quickshell",
        title = "Quickshell Settings",
    },

    float = true,
    center = true,
})
```

**Do not add a hardcoded `size` rule.** The preferred Settings width and height are now persisted in Quickshell under:

```text
Settings -> Appearance -> Settings Window
```

Defaults:

```text
1036 x 616
```

Supported ranges:

```text
width:  700–1800 px
height: 500–1200 px
```

When the saved preferred size changes, `shell.qml` recreates only the Settings window on the next reopen. Quickshell itself does not need to be restarted.

The implementation deliberately uses `implicitWidth` and `implicitHeight`; assigning `width` or `height` directly to Quickshell's `ProxyFloatingWindow` is deprecated and produces warnings.

Reload Hyprland after editing the compositor rule:

```bash
hyprctl reload
```

Verify:

1. Open Settings from an empty workspace.
2. Open it with several tiled clients present.
3. Change the saved default size, Apply, close Settings, and reopen it.
4. Confirm `hyprctl clients` reports the window as floating.

## Super+M exit binding

Use the native Lua dispatcher:

```lua
hl.bind(mainMod .. " + M", hl.dsp.exit())
```

Terminal equivalent:

```bash
hyprctl dispatch 'hl.dsp.exit()'
```

## Porting to another machine

1. Copy the Settings float/center rule into that machine's `rules.lua`.
2. Do not copy a fixed size line.
3. Copy the native `Super+M` binding.
4. Run `hyprctl reload`.
5. Choose an appropriate preferred Settings size in Appearance for that display.

A smaller saved size is useful on a 14-inch 1080p laptop; a larger size is more appropriate on a 2560x1440 desktop.
