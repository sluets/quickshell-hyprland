//=============================================================================
// FILE
//=============================================================================
//
// themes/PalenightTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Palenight — the Material Theme variant that swaps Material's blue-
// grey base for a deep indigo/purple one. Cool, muted, popular in the
// "Material-adjacent" crowd. Plain data file, full theme property
// contract (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   PalenightTheme { id: palenightThemeInst }
//   "PalenightTheme": palenightThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical theme names):
//   background #292d3e (bg)        foreground #a6accd (fg)
//   accent     #c792ea (purple,    urgent     #ff5370 (red)
//              the signature       muted      #676e95 (comment)
//              tone)                surface    #1f2233 (hand-darkened
//   hover      #343951 (hand-      step below bg — no official darker
//   picked lighter step)           swatch in the base spec)
//
// BORDER: purple → cyan (#c792ea → #89ddff) — Palenight's two most
// distinct accent hues, cool-on-cool rather than a warm/cool contrast.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical Palenight palette;
//             colorSurface/colorHover hand-picked (see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#292d3e"
    property color colorForeground: "#a6accd"
    property color colorAccent: "#c792ea"
    property color colorUrgent: "#ff5370"
    property color colorMuted: "#676e95"
    property color colorSurface: "#1f2233"
    property color colorHover: "#343951"

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
    property color barBorderColor: "#c792ea"
    property color barBorderColor2: "#89ddff"
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
