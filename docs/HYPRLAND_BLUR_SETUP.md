# Hyprland blur setup for Quickshell surfaces

**Status:** Live-tested on Hyprland 0.56 or newer with Lua configuration.

Quickshell background opacity and Hyprland blur are separate features. Quickshell draws translucent fills; Hyprland performs the blur behind layer surfaces and their popup children.

## Namespaces

- `qs-bar` — top-bar `PanelWindow`; attached module menus are `PopupWindow` children of this surface.
- `qs-notif` — detached notification surface.

Launcher, OSD, desktop clock, and unrelated overlays intentionally keep their existing namespaces and are not included by these rules.

## Recommended rules

Add these to the hand-owned Hyprland rules file, such as `hypr/user/rules.lua`. Quickshell and `ConfigManager` must not write this file automatically.

```lua
hl.layer_rule({
    name = "quickshell-bar-blur",
    match = { namespace = "^qs-bar$" },

    blur = true,
    blur_popups = true,
    ignore_alpha = 0.2,
})

hl.layer_rule({
    name = "quickshell-notification-blur",
    match = { namespace = "^qs-notif$" },

    blur = true,
    ignore_alpha = 0.2,
})
```

Reload after editing:

```bash
hyprctl reload
```

`blur_popups = true` is required for attached Volume, Connectivity, Bluetooth, Clock, Clipboard, Music, and System Menu popups. Without it, the bar can blur while attached menus remain merely translucent.

## Known attached-menu seam

With popup blur enabled, a thin line can appear where an attached popup overlaps the lower edge of the bar. The attached design intentionally uses a small overlap so its fillets and border connect cleanly. Hyprland composites the bar layer and popup as separate surfaces, and the blur boundary can expose that overlap.

This is not the former broad dark band from duplicate translucent QML paint; that issue is fixed. Alpha-threshold changes and a popup visible mask did not remove the thin compositor seam reliably, and the visible-mask experiment clipped the fillets.

Current options are:

- Keep `blur_popups = true` and accept the subtle attached seam.
- Remove `blur_popups = true` to blur only the bar while attached menus remain translucent.
- Select **Settings → Appearance → Menus → Detached**, which removes the connected overlap entirely.

Treat further work here as compositor/surface investigation, not a generic opacity adjustment.
