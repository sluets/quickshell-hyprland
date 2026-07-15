//=============================================================================
// FILE
//=============================================================================
//
// themes/TokyoNightTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Tokyo Night (night variant) — the VS Code / neovim palette by enkia.
// Deep navy base with blue/cyan/purple accents. Plain data file, full
// theme property contract (see themes/DefaultTheme.qml), no behavior.
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   TokyoNightTheme { id: tokyoNightThemeInst }
//   "TokyoNightTheme": tokyoNightThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical Tokyo Night values):
//   background #1a1b26 (bg)        foreground #c0caf5 (fg)
//   accent     #7aa2f7 (blue)      urgent     #f7768e (red/pink)
//   muted      #565f89 (comment)   surface    #16161e (bg_dark — keeps
//   hover      #292e42 (bg_hl)     the "popups elevated by darker" rule)
//
// BORDER: cyan #7dcfff fading to purple #bb9af7, left→right — the two
// signature Tokyo Night accents. Set barBorderColor2 to "transparent"
// for a solid cyan border instead.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical palette, no sampled values.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#1a1b26"
    property color colorForeground: "#c0caf5"
    property color colorAccent: "#7aa2f7"
    property color colorUrgent: "#f7768e"
    property color colorMuted: "#565f89"
    property color colorSurface: "#16161e"
    property color colorHover: "#292e42"

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
    property color barBorderColor: "#7dcfff"
    property color barBorderColor2: "#bb9af7"
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
