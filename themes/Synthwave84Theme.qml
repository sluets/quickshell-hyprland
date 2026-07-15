//=============================================================================
// FILE
//=============================================================================
//
// themes/Synthwave84Theme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Synthwave '84 — Robb Owen's neon retro-futurist VS Code theme. Deep
// purple-black base, glowing pink/cyan/yellow accents — the "outrun /
// vaporwave" aesthetic. Plain data file, full theme property contract
// (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   Synthwave84Theme { id: synthwave84ThemeInst }
//   "Synthwave84Theme": synthwave84ThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical theme names):
//   background #262335 (bg)        foreground #f8f8f2 (fg — shared
//   accent     #ff7edb (pink,      with Dracula/Monokai's near-white,
//              the signature       fitting for a theme built the same
//              neon magenta)       era)
//   urgent     #fe4450 (red)       muted      #848bbd (comment lavender)
//   surface    #1a1a2e (hand-      hover      #34294f (hand-picked
//   picked, deeper purple-black    lighter step, matches the palette's
//   step below bg)                 "selection" purple family)
//
// BORDER: cyan → pink (#36f9f6 → #ff7edb) — the theme's own "glow"
// pairing (function names / operators in cyan against pink keywords).
// This is the most saturated theme in the whole set; expect it to
// dominate the desktop over any wallpaper.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical Synthwave '84 palette;
//             colorSurface/colorHover hand-picked (see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#262335"
    property color colorForeground: "#f8f8f2"
    property color colorAccent: "#ff7edb"
    property color colorUrgent: "#fe4450"
    property color colorMuted: "#848bbd"
    property color colorSurface: "#1a1a2e"
    property color colorHover: "#34294f"

    // ---- Typography ----
    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property int fontSize: 14

    // ---- Sizing ----
    property int barHeight: 32
    property int radiusMedium: 6

    // ---- Bar framing ----
    property int barMargin: 8
    property int barRadius: 10
    property int barBorderWidth: -1
    property color barBorderColor: "#36f9f6"
    property color barBorderColor2: "#ff7edb"
    property real barBorderGradientAngle: 0
    property int barBorderFilletRadius: -1

    // ---- Spacing scale ----
    property int spacingSmall: 4
    property int spacingMedium: 8
    property int spacingLarge: 16

    // ---- Animation ----
    property int animationDuration: 180
    property int animationEasing: Easing.OutCubic
}
