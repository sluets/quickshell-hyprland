//=============================================================================
// FILE
//=============================================================================
//
// themes/OceanicNextTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Oceanic Next — voronianski's palette, a spiritual successor to the
// original Sublime "Oceanic" theme. Deep teal-navy base, more
// saturated than Nord but still cool-toned throughout. Plain data
// file, full theme property contract (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   OceanicNextTheme { id: oceanicNextThemeInst }
//   "OceanicNextTheme": oceanicNextThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical theme names):
//   background #1b2b34 (base00)    foreground #c0c5ce (base06/fg)
//   accent     #6699cc (blue)      urgent     #ec5f67 (red)
//   muted      #65737e (base04,    surface    #14232b (hand-darkened
//              comment)            step below base00 — the spec's
//   hover      #243c47 (base01,    darkest official swatch is base00
//              selection bg)       itself)
//
// BORDER: teal → blue (#5fb3b3 → #6699cc) — Oceanic Next's cyan paired
// with its primary accent blue, staying entirely in the palette's
// aquatic half.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical palette; colorSurface
//             hand-picked (see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#1b2b34"
    property color colorForeground: "#c0c5ce"
    property color colorAccent: "#6699cc"
    property color colorUrgent: "#ec5f67"
    property color colorMuted: "#65737e"
    property color colorSurface: "#14232b"
    property color colorHover: "#243c47"

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
    property color barBorderColor: "#5fb3b3"
    property color barBorderColor2: "#6699cc"
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
