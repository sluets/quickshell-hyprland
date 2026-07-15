//=============================================================================
// FILE
//=============================================================================
//
// themes/NightfoxTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Nightfox — EdenEast's Neovim-favorite palette. Deep blue-black base,
// muted teal/blue/orange accents, built specifically around careful
// contrast ratios for long sessions. Plain data file, full theme
// property contract (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   NightfoxTheme { id: nightfoxThemeInst }
//   "NightfoxTheme": nightfoxThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical nightfox.nvim palette names):
//   background #192330 (bg0)       foreground #cdcecf (fg)
//   accent     #719cd6 (blue)      urgent     #c94f6d (red)
//   muted      #71839b (comment)   surface    #131a24 (bg0's own
//   hover      #223449 (bg2)       darker step, bg_dark region of the
//                                  spec's gradient)
//
// BORDER: teal → orange (#63cdcf → #dbc074) — Nightfox's two warmest-
// against-coolest accents, used for diagnostics/hints in the original
// spec, repurposed here as the bar's signature gradient.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical Nightfox palette.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#192330"
    property color colorForeground: "#cdcecf"
    property color colorAccent: "#719cd6"
    property color colorUrgent: "#c94f6d"
    property color colorMuted: "#71839b"
    property color colorSurface: "#131a24"
    property color colorHover: "#223449"

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
    property color barBorderColor: "#63cdcf"
    property color barBorderColor2: "#dbc074"
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
