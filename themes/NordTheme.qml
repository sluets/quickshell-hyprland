//=============================================================================
// FILE
//=============================================================================
//
// themes/NordTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Nord — the arctic, low-saturation blue-grey palette. Minimal and
// professional. Plain data file, full theme property contract (see
// themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   NordTheme { id: nordThemeInst }
//   "NordTheme": nordThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical nord0–nord15 names):
//   background #2e3440 (nord0)     foreground #d8dee9 (nord4, Snow Storm)
//   accent     #88c0d0 (nord8,     urgent     #bf616a (nord11, Aurora red)
//              Frost cyan)         muted      #4c566a (nord3)
//   hover      #3b4252 (nord1)
//   surface    #262b35 — nord0 is already the DARKEST official Nord
//   color, so this is a hand-darkened step below it (~10%) to preserve
//   the "popups elevated by darker" house rule. The one non-canonical
//   value in the file, on purpose.
//
// BORDER: frost gradient, #88c0d0 → #81a1c1 (nord8 → nord9). Subtle by
// design — Nord's whole identity is low saturation, so a loud border
// would fight the palette.
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
    property color colorBackground: "#2e3440"
    property color colorForeground: "#d8dee9"
    property color colorAccent: "#88c0d0"
    property color colorUrgent: "#bf616a"
    property color colorMuted: "#4c566a"
    property color colorSurface: "#262b35"
    property color colorHover: "#3b4252"

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
    property color barBorderColor: "#88c0d0"
    property color barBorderColor2: "#81a1c1"
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
