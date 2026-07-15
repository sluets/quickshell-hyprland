//=============================================================================
// FILE
//=============================================================================
//
// themes/MaterialOceanTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Material Ocean — the deep blue-black variant of the Material Theme
// family (distinct from Palenight's purple lean). Very popular for
// terminal/rice setups. Plain data file, full theme property contract
// (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   MaterialOceanTheme { id: materialOceanThemeInst }
//   "MaterialOceanTheme": materialOceanThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical Material Ocean names):
//   background #0f111a (bg)        foreground #8f93a2 (fg — Material's
//   accent     #84ffff (cyan,      own body text is a muted slate, not
//              the brightest,      pure white; keeps the "flatter"
//              most recognizable   Material feel rather than high
//              Ocean accent)       contrast)
//   urgent     #ff5370 (red)       muted      #464b5d (comment)
//   surface    #090b10 (hand-      hover      #1f2233 (hand-picked
//   darkened step below bg)        step between bg and surface)
//
// BORDER: cyan → indigo (#84ffff → #7086d6) — Ocean's signature bright
// cyan paired with its softer accent blue, staying in the cool half of
// the palette throughout (no warm accents in Material Ocean at all).
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical Material Ocean palette;
//             colorSurface/colorHover hand-picked (see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#0f111a"
    property color colorForeground: "#8f93a2"
    property color colorAccent: "#84ffff"
    property color colorUrgent: "#ff5370"
    property color colorMuted: "#464b5d"
    property color colorSurface: "#090b10"
    property color colorHover: "#1f2233"

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
    property color barBorderColor: "#84ffff"
    property color barBorderColor2: "#7086d6"
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
