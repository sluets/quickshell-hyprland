//=============================================================================
// FILE
//=============================================================================
//
// themes/HoneycombTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Greyscale theme built from the hexagon-grid wallpaper (light grey
// canvas, honeycomb of grey hexes fading from near-white to dark in
// the corner). Every color here is a value SAMPLED from that image
// (PIL quantization, 2026-07-05) — not eyeballed — except colorUrgent,
// which stays red on purpose (see DESIGN NOTES).
//
// The bar takes the DARK end of the wallpaper's gradient and the text
// takes the wallpaper's canvas color: the image is so light that a
// light bar would disappear into it, floating corners and all.
//
// This is a plain data file. It should never contain layout logic,
// MouseAreas, signals, or anything behavioral — just values. It is NOT
// a singleton — core/Theme.qml creates one instance of the active
// theme internally and forwards its values.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick (for the `color` and `font` types)
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — but ONLY while its `active:` line points here.
// Activate with:  property var active: HoneycombTheme {}
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Nothing, unless core/Theme.qml's `active:` currently points here —
// in which case the shell fails to start (QML import error). Point
// `active:` back at DefaultTheme {} first, then delete.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// SAMPLED PALETTE (share of image):
//   #ECECEC canvas 55%  ·  #E7E7E7 / #D9D9D9 / #CBCBCB / #B5B5B5 /
//   #A8A8A8 / #9A9A9A / #888888 / #6C6C6C hex fills  ·  #5E5E5E
//   darkest corner hexes  ·  near-white gaps between hexes
//
// ROLE MAPPING: background = darkest hex (#5E5E5E), foreground = the
// wallpaper's canvas (#ECECEC — the text is literally the color of
// the paper the hexes sit on), surface = one step darker than the bar
// (keeps DefaultTheme's "popups read as elevated by being darker"
// relationship), hover = #6C6C6C (the next sampled step up), muted =
// #9A9A9A (mid-gradient, "present but not active").
//
// ACCENT IS PURE WHITE — the one risky monochrome choice. The image
// has no accent hue to borrow, so active states (workspace indicator,
// volume fill, picker selection border, shuffle checkbox, OSD icon)
// are #FFFFFF, matching the white seams between hexagons. On the
// #5E5E5E bar that pops clearly, but accent-colored things sitting
// directly on colorForeground-adjacent greys lose distinction. If
// living with it proves annoying, swapping ONLY colorAccent to a hue
// (e.g. the old #5294e2) keeps the rest of the monochrome look — one
// line, try it before abandoning the theme.
//
// URGENT STAYS RED (#E05252) — the deliberate departure from strict
// monochrome. Urgent is SEMANTIC (critical notification borders,
// error states), and a grey "critical" carries no meaning at a
// glance. Slightly desaturated from DefaultTheme's #f53c3c so it
// shouts a little less against an otherwise colorless desktop.
//
// GEOMETRY UNCHANGED: sizing/spacing/animation values are copied from
// DefaultTheme verbatim — this theme is a palette statement, not a
// layout opinion. (Theme files must define the FULL property
// contract; a missing property forwards as silent `undefined`, per
// DefaultTheme's own header warning.)
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Created from the hexagon wallpaper. First non-default
//             theme; first real exercise of the "new theme = new file
//             + one line in core/Theme.qml" claim in
//             docs/ARCHITECTURE.md.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors (sampled — see DESIGN NOTES) ----
    property color colorBackground: "#5E5E5E"
    property color colorForeground: "#ECECEC"
    property color colorAccent: "#FFFFFF"
    property color colorUrgent: "#E05252"
    property color colorMuted: "#9A9A9A"
    property color colorSurface: "#4E4E4E"
    property color colorHover: "#6C6C6C"

    // ---- Typography (unchanged from DefaultTheme) ----
    property string fontFamily: "JetBrainsMono Nerd Font Propo"
    property int fontSize: 14

    // ---- Sizing (unchanged) ----
    property int barHeight: 32
    property int radiusMedium: 6

    // ---- Bar framing (unchanged) ----
    property int barMargin: 8
    property int barRadius: 10

    // ---- Bar border (see DefaultTheme's comment for semantics) ----
    // -1 = width follows UserPrefs.hyprBorderSize live. Color: NOT
    // colorAccent here — Honeycomb's accent is white, which vanished
    // against a white wallpaper on first live run (2026-07-10).
    // Teal picked to be visible; change to taste (e.g. your
    // col.active_border hex from user/look.lua for an exact match).
    property int barBorderWidth: -1
    property color barBorderColor: "#35e0b4"
    property color barBorderColor2: "transparent"
    property real barBorderGradientAngle: 0
    property int barBorderFilletRadius: -1

    // ---- Spacing scale (unchanged) ----
    property int spacingSmall: 4
    property int spacingMedium: 8
    property int spacingLarge: 16

    // ---- Animation (unchanged) ----
    property int animationDuration: 180
    property int animationEasing: Easing.OutCubic
}
