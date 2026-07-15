//=============================================================================
// FILE
//=============================================================================
//
// themes/HorizonTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Horizon — Jono Alderson's warm, coral-and-pink dark theme. Sits
// between Dracula's saturation and Rosé Pine's softness: warm and
// colorful without being neon. Plain data file, full theme property
// contract (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   HorizonTheme { id: horizonThemeInst }
//   "HorizonTheme": horizonThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical theme names):
//   background #1c1e26 (bg)        foreground #e0e0e0 (fg)
//   accent     #e95678 (pink/      urgent     #e95379 (red, near-
//              coral, the          identical to accent in the official
//              signature color)    palette — nudged a touch redder here
//   muted      #6c6f93 (comment    so accent vs urgent stay visually
//              purple-grey)        distinct on the bar)
//   surface    #16161c (bg1, the   hover      #232530 (hand-picked step
//   palette's own darker           between bg and surface)
//   variant)
//
// BORDER: coral → gold (#e95678 → #fab795) — Horizon's pink paired
// with its warm peach accent, the theme's two warmest tones together.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical palette; urgent nudged
//             slightly redder than spec to stay distinct from accent
//             (see notes). colorHover hand-picked.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#1c1e26"
    property color colorForeground: "#e0e0e0"
    property color colorAccent: "#e95678"
    property color colorUrgent: "#e95379"
    property color colorMuted: "#6c6f93"
    property color colorSurface: "#16161c"
    property color colorHover: "#232530"

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
    property color barBorderColor: "#e95678"
    property color barBorderColor2: "#fab795"
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
