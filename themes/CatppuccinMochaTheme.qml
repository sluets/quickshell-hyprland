//=============================================================================
// FILE
//=============================================================================
//
// themes/CatppuccinMochaTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Catppuccin Mocha — the most popular flavor of the pastel Catppuccin
// palette. Warm dark base, soft mauve/pink accents. Plain data file,
// full theme property contract (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   CatppuccinMochaTheme { id: catppuccinMochaThemeInst }
//   "CatppuccinMochaTheme": catppuccinMochaThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical Mocha names):
//   background #1e1e2e (Base)      foreground #cdd6f4 (Text)
//   accent     #cba6f7 (Mauve)     urgent     #f38ba8 (Red)
//   muted      #6c7086 (Overlay0)  surface    #11111b (Crust — Mocha's
//   hover      #313244 (Surface0)  own "Surface" names are LIGHTER than
//                                  Base, so Crust is used instead to keep
//                                  the "popups darker" house rule)
//
// BORDER: mauve → pink (#f5c2e7), the classic Catppuccin duo. Other
// flavors (Latte/Frappe/Macchiato) can be built later as sibling files
// if wanted — same role mapping, different published hex tables.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical Mocha palette.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#1e1e2e"
    property color colorForeground: "#cdd6f4"
    property color colorAccent: "#cba6f7"
    property color colorUrgent: "#f38ba8"
    property color colorMuted: "#6c7086"
    property color colorSurface: "#11111b"
    property color colorHover: "#313244"

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
    property color barBorderColor: "#cba6f7"
    property color barBorderColor2: "#f5c2e7"
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
