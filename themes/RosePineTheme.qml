//=============================================================================
// FILE
//=============================================================================
//
// themes/RosePineTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Rosé Pine (main variant) — the soft, dreamy, low-contrast palette.
// Mauve/rose/pine on deep plum. Plain data file, full theme property
// contract (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   RosePineTheme { id: rosePineThemeInst }
//   "RosePineTheme": rosePineThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical rosé pine names):
//   background #191724 (Base)      foreground #e0def4 (Text)
//   accent     #c4a7e7 (Iris)      urgent     #eb6f92 (Love)
//   muted      #6e6a86 (Muted —    hover      #26233a (Overlay)
//              literally)
//   surface    #131020 — Rosé Pine's own "Surface" (#1f1d2e) is LIGHTER
//   than Base, so like Nord this is a hand-darkened step below Base to
//   keep the darker-popup house rule.
//
// BORDER: rose → pine (#ebbcba → #31748f) — the theme's namesake pair.
// Low contrast is the point of this palette; if the bar text feels too
// soft, this isn't the theme's bug, it's its personality.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical palette except colorSurface
//             (hand-darkened, see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#191724"
    property color colorForeground: "#e0def4"
    property color colorAccent: "#c4a7e7"
    property color colorUrgent: "#eb6f92"
    property color colorMuted: "#6e6a86"
    property color colorSurface: "#131020"
    property color colorHover: "#26233a"

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
    property color barBorderColor: "#ebbcba"
    property color barBorderColor2: "#31748f"
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
