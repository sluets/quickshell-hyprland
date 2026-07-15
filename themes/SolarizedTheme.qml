//=============================================================================
// FILE
//=============================================================================
//
// themes/SolarizedTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Solarized (dark variant) — Ethan Schoonover's precision-luminance
// palette. Muted cyan/blue/green/yellow on a blue-tinted near-black.
// Plain data file, full theme property contract (see
// themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   SolarizedTheme { id: solarizedThemeInst }
//   "SolarizedTheme": solarizedThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical Solarized base0X names):
//   background #002b36 (base03)    foreground #839496 (base0 — the
//   accent     #268bd2 (blue)      spec's own designated body-text
//   urgent     #dc322f (red)       tone, deliberately muted rather
//   muted      #586e75 (base01)    than stark white; that IS Solarized)
//   surface    #00212b (hand-      hover      #073642 (base02)
//   darkened step below base03,
//   which is already the palette's
//   darkest official color)
//
// BORDER: cyan → yellow (#2aa198 → #b58900) — spans the palette's full
// accent range, cyan and yellow being its two least-related hues.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical dark palette except
//             colorSurface (hand-darkened, see notes).
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#002b36"
    property color colorForeground: "#839496"
    property color colorAccent: "#268bd2"
    property color colorUrgent: "#dc322f"
    property color colorMuted: "#586e75"
    property color colorSurface: "#00212b"
    property color colorHover: "#073642"

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
    property color barBorderColor: "#2aa198"
    property color barBorderColor2: "#b58900"
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
