//=============================================================================
// FILE
//=============================================================================
//
// themes/OneDarkTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// One Dark — the Atom editor palette that spread everywhere (VS Code,
// terminals, etc). Neutral grey base, balanced blue/green/orange/purple
// accents. Plain data file, full theme property contract (see
// themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   OneDarkTheme { id: oneDarkThemeInst }
//   "OneDarkTheme": oneDarkThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical Atom One Dark syntax names):
//   background #282c34 (mono-1     foreground #abb2bf (mono-4 grey)
//              bg)                 urgent     #e06c75 (red)
//   accent     #61afef (blue)      muted      #5c6370 (comment grey)
//   surface    #21252b (Atom's     hover      #2c313a (Atom's own
//   own gutter/sidebar bg — a      list-hover bg)
//   touch darker than the editor
//   bg, matches the house rule
//   without hand-picking)
//
// BORDER: blue → purple (#c678dd) — the two coolest accents in the
// palette, since orange/green are usually reserved for syntax roles
// (numbers, strings) that would clash if reused on the chrome.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical Atom One Dark palette.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#282c34"
    property color colorForeground: "#abb2bf"
    property color colorAccent: "#61afef"
    property color colorUrgent: "#e06c75"
    property color colorMuted: "#5c6370"
    property color colorSurface: "#21252b"
    property color colorHover: "#2c313a"

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
    property color barBorderColor: "#61afef"
    property color barBorderColor2: "#c678dd"
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
