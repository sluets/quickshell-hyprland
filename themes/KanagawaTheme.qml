//=============================================================================
// FILE
//=============================================================================
//
// themes/KanagawaTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Kanagawa (wave variant) — rebelot's palette inspired by Hokusai's
// "The Great Wave off Kanagawa". Ink indigo, aged cream, gold. The
// artistic one. Plain data file, full theme property contract (see
// themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   KanagawaTheme { id: kanagawaThemeInst }
//   "KanagawaTheme": kanagawaThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical kanagawa.nvim names):
//   background #1f1f28 (sumiInk1)   foreground #dcd7ba (fujiWhite)
//   accent     #7e9cd8 (crystal-    urgent     #c34043 (autumnRed —
//              Blue)                chosen over samuraiRed #e82424,
//   muted      #727169 (fujiGray)   which is too neon for this palette)
//   surface    #16161d (sumiInk0)   hover      #2a2a37 (sumiInk4)
//
// BORDER: gold → blue (#c0a36e boatYellow2/gold → #7e9cd8), i.e. the
// gold foam highlights against the wave's blue — the palette's whole
// painting reference in one gradient.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical wave palette; urgent uses
//             autumnRed by taste (see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#1f1f28"
    property color colorForeground: "#dcd7ba"
    property color colorAccent: "#7e9cd8"
    property color colorUrgent: "#c34043"
    property color colorMuted: "#727169"
    property color colorSurface: "#16161d"
    property color colorHover: "#2a2a37"

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
    property color barBorderColor: "#c0a36e"
    property color barBorderColor2: "#7e9cd8"
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
