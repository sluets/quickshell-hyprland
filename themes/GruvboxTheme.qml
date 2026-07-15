//=============================================================================
// FILE
//=============================================================================
//
// themes/GruvboxTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Gruvbox Dark (medium contrast) — the retro warm-paper palette by
// morhetz. Browns, olives, burnt orange. Plain data file, full theme
// property contract (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   GruvboxTheme { id: gruvboxThemeInst }
//   "GruvboxTheme": gruvboxThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical gruvbox-dark names):
//   background #282828 (bg0)         foreground #ebdbb2 (fg1)
//   accent     #fe8019 (orange,      urgent     #fb4934 (bright red)
//              bright)               muted      #928374 (gray)
//   surface    #1d2021 (bg0_hard —   hover      #3c3836 (bg1)
//   the "hard contrast" background doubles perfectly as the darker
//   popup surface)
//
// BORDER: burnt orange → warm yellow (#fabd2f), the two signature
// gruvbox brights. Near-black surface + saturated accents is why this
// palette is famous on OLED.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical gruvbox-dark-medium palette.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#282828"
    property color colorForeground: "#ebdbb2"
    property color colorAccent: "#fe8019"
    property color colorUrgent: "#fb4934"
    property color colorMuted: "#928374"
    property color colorSurface: "#1d2021"
    property color colorHover: "#3c3836"

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
    property color barBorderColor: "#fe8019"
    property color barBorderColor2: "#fabd2f"
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
