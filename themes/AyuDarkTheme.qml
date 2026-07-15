//=============================================================================
// FILE
//=============================================================================
//
// themes/AyuDarkTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Ayu Dark — the "dark" (not "mirage") variant of dempfi's palette.
// Cool near-black base, warm mustard/orange accent — a deliberate
// warm-on-cool contrast, unlike most dark themes which stay monochrome
// in temperature. Plain data file, full theme property contract (see
// themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   AyuDarkTheme { id: ayuDarkThemeInst }
//   "AyuDarkTheme": ayuDarkThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical ayu-dark names):
//   background #0b0e14 (bg)        foreground #bfbdb6 (fg)
//   accent     #e6b450 (accent —   urgent     #f07178 (markup/error red)
//              the signature       muted      #565b66 (comment)
//              mustard-gold)       surface    #0d1017 (a touch darker
//   hover      #131721 (hand-      than bg, no official "surface" swatch
//   picked, one step up from       exists in the 3-file ayu spec)
//   bg toward surface)
//
// BORDER: gold → orange (#e6b450 → #ff8f40, ayu's "warning" orange) —
// stays entirely in the warm half of the palette so it reads as one
// deliberate accent family against the cool background, rather than
// borrowing ayu's cyan/blue syntax colors which are reserved for
// keywords elsewhere in the family.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical ayu-dark core palette;
//             colorSurface/colorHover hand-picked (no official spec
//             swatch — see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#0b0e14"
    property color colorForeground: "#bfbdb6"
    property color colorAccent: "#e6b450"
    property color colorUrgent: "#f07178"
    property color colorMuted: "#565b66"
    property color colorSurface: "#0d1017"
    property color colorHover: "#131721"

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
    property color barBorderColor: "#e6b450"
    property color barBorderColor2: "#ff8f40"
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
