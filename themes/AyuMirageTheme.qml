//=============================================================================
// FILE
//=============================================================================
//
// themes/AyuMirageTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Ayu Mirage — the middle-brightness sibling of AyuDarkTheme.qml.
// Same mustard-gold accent family, but on a softer slate-navy
// background instead of near-black — easier on the eyes in a lit room.
// Plain data file, full theme property contract (see
// themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   AyuMirageTheme { id: ayuMirageThemeInst }
//   "AyuMirageTheme": ayuMirageThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical ayu-mirage names):
//   background #1f2430 (bg)        foreground #cbccc6 (fg)
//   accent     #ffcc66 (accent —   urgent     #ff6666 (error red)
//              brighter/warmer     muted      #5c6773 (comment)
//              gold than Dark's    surface    #171b24 (hand-darkened
//              #e6b450, per spec)  step below bg)
//   hover      #232834 (hand-
//   picked step)
//
// BORDER: gold → orange (#ffcc66 → #ffa759, mirage's warning orange) —
// same warm-family logic as AyuDarkTheme, tuned to Mirage's slightly
// brighter accent values so the two Ayu variants stay recognizably
// related but distinct.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical ayu-mirage core palette;
//             colorSurface/colorHover hand-picked (see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#1f2430"
    property color colorForeground: "#cbccc6"
    property color colorAccent: "#ffcc66"
    property color colorUrgent: "#ff6666"
    property color colorMuted: "#5c6773"
    property color colorSurface: "#171b24"
    property color colorHover: "#232834"

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
    property color barBorderColor: "#ffcc66"
    property color barBorderColor2: "#ffa759"
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
