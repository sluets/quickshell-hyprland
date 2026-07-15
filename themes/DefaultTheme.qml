//=============================================================================
// FILE
//=============================================================================
//
// themes/DefaultTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The actual color/font/size VALUES for the default theme. A neutral,
// light, Windows-default-style palette (light grey chrome, white
// elevated surfaces, near-black text, restrained blue accent) — no
// wild saturated colors, meant to look boring and safe rather than
// "stylized." Kept as the project's stable fallback while fancier
// themes (see HoneycombTheme.qml) get built alongside it.
//
// This is a plain data file. It should never contain layout logic,
// MouseAreas, signals, or anything behavioral — just values. It is NOT a
// singleton — core/Theme.qml creates one instance of this internally
// (`property var active: DefaultTheme {}`) and forwards its values.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick (for the `color` and `font` types)
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml (imports this module via `import qs.themes` and forwards
// its properties)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// core/Theme.qml's `active: DefaultTheme {}` line will fail to resolve,
// and the whole shell will fail to start (QML import error). If you're
// deleting this because you built a real replacement theme, update
// core/Theme.qml's `active` property to point at the new file FIRST,
// then delete this one.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// This file intentionally has very few values right now. As new widgets
// get built and need new theme properties (e.g. a specific icon size, a
// border-radius value, a second accent color for warnings vs errors),
// add them here AND to core/Theme.qml's forwarding list at the same time.
// Forgetting the core/Theme.qml half is the most likely mistake — a
// widget will reference `Theme.someNewProperty` and get `undefined`
// silently rather than a clear error, so if a new value "isn't working,"
// check both files.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-12  (Opus) Reworked to a neutral LIGHT palette — light grey
//             background (#F2F2F2), white elevated surfaces (#FFFFFF,
//             popups now clearly lift off the bar), near-black text
//             (#1A1A1A), restrained blue accent (#0078D4, Windows'
//             own default Fluent accent) instead of the old brighter
//             blue, muted grey (#8A8A8A) for de-emphasized state, and
//             a light blue hover tint (#E5F1FB). Explicitly no
//             gradient (barBorderColor2 stays transparent) — the
//             point of this rework was "boring on purpose," a plain
//             Windows-default-style look with nothing saturated or
//             stylized. Old dark palette (grey #64727D bg, black text,
//             brighter blue #5294e2 accent) is below if reverting.
// 2026-07-04  Added `barMargin` (8) and `barRadius` (10) — the bar now
//             floats inset from the screen edges with rounded corners.
//             Both zero out cleanly to restore the old square bar.
// 2026-07-01  Removed `tooltipDelay` — the tooltip it was for
//             (NowPlaying.qml) was removed same day. Not left as dead
//             config; add it back if a tooltip comes back.
// 2026-07-01  Added `tooltipDelay` (500ms). (Removed — see entry above.)
// 2026-07-01  Added `animationDuration` (180ms) and `animationEasing`
//             (Easing.OutCubic) — the shared timing for popup-menu
//             open animations (see widgets/TopBar/SystemMenu.qml, the
//             reference implementation; more popups planned). Centralizing
//             these means every future dropdown's "scroll down" reveal
//             speed changes with one edit here instead of per-widget.
// 2026-07-01  Added `colorSurface` (#4B5761), `colorHover` (#5D6B76),
//             and `radiusMedium` (6) for the new dropdown-menu pattern
//             (see widgets/TopBar/SystemMenu.qml — the first popup menu,
//             more planned for wifi/bluetooth/volume). `colorSurface` is
//             a shade darker than `colorBackground` so popups read as
//             "elevated" above the bar rather than blending into it.
// 2026-07-01  Added `colorMuted` (#40474E), for de-emphasized UI state
//             (currently: empty workspace indicators in
//             widgets/TopBar/Workspaces.qml). A dark slate between
//             colorBackground and colorForeground — reads as "present
//             but not active" rather than "important."
// 2026-07-01  No value changes. Only the header above was updated to
//             reflect that core/Theme.qml now reaches this file via
//             `import qs.themes` (module-style) instead of
//             `import "../themes"` (relative path).
// 2026-07-01  Initial theme. Grey background (#64727D), black foreground,
//             blue accent (#5294e2), red urgent (#f53c3c).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    // Neutral light palette, 2026-07-12 rework — "boring on purpose."
    // Light grey chrome (#F2F2F2, close to Windows 10/11's default
    // window background), WHITE elevated surfaces so popups clearly
    // lift off the bar the way Windows menus do, near-black (not pure
    // #000) text for readability without harshness, and a single
    // restrained blue accent (#0078D4 — Fluent/Windows' own default
    // accent blue) instead of anything saturated. No gradients, no
    // bright secondary colors — see barBorderColor2 below.
    property color colorBackground: "#F2F2F2"
    property color colorForeground: "#1A1A1A"
    property color colorAccent: "#0078D4"
    property color colorUrgent: "#C42B1C"
    property color colorMuted: "#8A8A8A"
    property color colorSurface: "#FFFFFF"
    property color colorHover: "#E5F1FB"

    // ---- Typography ----
    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property int fontSize: 14

    // ---- Sizing ----
    property int barHeight: 32
    property int radiusMedium: 6

    // ---- Bar framing ----
    // The bar now floats: barMargin is the gap between the bar and the
    // screen's top/left/right edges, barRadius rounds its corners.
    // Set barMargin to 0 and barRadius to 0 to get the old full-width
    // square bar back — both are pure theme choices, nothing in the
    // widgets depends on them being nonzero.
    property int barMargin: 8
    property int barRadius: 10

    // Border drawn around the bar, continued around any open popout
    // so bar + menu read as one outlined shape (widgets/TopBar/
    // TopBar.qml + BarPopout.qml, 2026-07-10). Width -1 = follow
    // UserPrefs.hyprBorderSize live, so the bar's border matches the
    // window borders the settings window's Hyprland page manages;
    // 0 = no border; >0 = fixed px, decoupled from Hyprland.
    // Color is a theme choice — Hyprland's own border color lives in
    // user/look.lua, which the shell never parses; set this to match
    // it by hand if you want them identical.
    property int barBorderWidth: -1
    property color barBorderColor: colorAccent
    // Second gradient stop. TRANSPARENT (the default) = no gradient,
    // solid barBorderColor. Deliberately left transparent here — a
    // gradient border would undercut the whole point of this theme
    // being the plain, neutral one. Set a color and the border becomes
    // a linear gradient across the bar — angle: 0 = left→right, 90 =
    // top→bottom, clockwise — that CONTINUES through any open popout
    // (matching Hyprland's own gradient window borders is a
    // tune-by-eye job: same two colors, then nudge the angle).
    property color barBorderColor2: "transparent"
    property real barBorderGradientAngle: 0
    // Fillet where the popout meets the bar: the bar's bottom border
    // curves down into the popout's sides instead of butting into
    // them. -1 = follow barRadius (matching corners), 0 = square
    // joint, >0 = explicit px.
    property int barBorderFilletRadius: -1

    // ---- Spacing scale ----
    // Use these instead of inventing new margin/padding numbers per widget.
    property int spacingSmall: 4
    property int spacingMedium: 8
    property int spacingLarge: 16

    // ---- Animation ----
    // Shared timing for popup-menu open/close animations. See
    // widgets/TopBar/SystemMenu.qml's DESIGN NOTES for how these are used.
    property int animationDuration: 180
    property int animationEasing: Easing.OutCubic
}
