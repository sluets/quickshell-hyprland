//=============================================================================
// FILE
//=============================================================================
//
// themes/MonokaiTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Monokai (classic) — Wimer Hazenberg's original loud, saturated
// palette. Warm charcoal base, lime green + hot pink + orange + cyan
// all fighting for attention on purpose. Plain data file, full theme
// property contract (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   MonokaiTheme { id: monokaiThemeInst }
//   "MonokaiTheme": monokaiThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical classic Monokai syntax names):
//   background #272822 (bg)        foreground #f8f8f2 (fg)
//   accent     #a6e22e (green —    urgent     #f92672 (pink, normally
//              chosen over the      "keyword" — repurposed here since
//              equally iconic       it reads as more "alert" than the
//              #f92672 pink so      green does)
//              accent and urgent   muted      #75715e (comment)
//              don't both scream)  surface    #1e1f1c (hand-darkened
//   hover      #3e3d32 (selection  step below bg — no official darker
//              bg)                 swatch exists in the classic 8-color
//                                  spec)
//
// BORDER: orange → cyan (#fd971f → #66d9ef) — the two accent colors
// NOT already used for accent/urgent above, keeping all four classic
// Monokai accents represented somewhere in the theme.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical classic Monokai palette;
//             colorSurface hand-picked (see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#272822"
    property color colorForeground: "#f8f8f2"
    property color colorAccent: "#a6e22e"
    property color colorUrgent: "#f92672"
    property color colorMuted: "#75715e"
    property color colorSurface: "#1e1f1c"
    property color colorHover: "#3e3d32"

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
    property color barBorderColor: "#fd971f"
    property color barBorderColor2: "#66d9ef"
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
