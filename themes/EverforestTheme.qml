//=============================================================================
// FILE
//=============================================================================
//
// themes/EverforestTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Everforest (dark, medium contrast) — the warm green-on-green forest
// palette by sainnhe. Gruvbox's woodland cousin, very easy on the eyes.
// Plain data file, full theme property contract (see
// themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   EverforestTheme { id: everforestThemeInst }
//   "EverforestTheme": everforestThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical everforest-dark-medium names):
//   background #2d353b (bg0)       foreground #d3c6aa (fg)
//   accent     #a7c080 (green)     urgent     #e67e80 (red)
//   muted      #859289 (grey1)     surface    #232a2e (bg_dim — the
//   hover      #3d484d (bg2)       palette's own dimmed background,
//                                  fits the darker-popup rule as-is)
//
// BORDER: moss green → aqua (#83c092). Deliberately quiet — this
// palette's appeal is low visual noise.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical dark-medium palette.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#2d353b"
    property color colorForeground: "#d3c6aa"
    property color colorAccent: "#a7c080"
    property color colorUrgent: "#e67e80"
    property color colorMuted: "#859289"
    property color colorSurface: "#232a2e"
    property color colorHover: "#3d484d"

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
    property color barBorderColor: "#a7c080"
    property color barBorderColor2: "#83c092"
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
