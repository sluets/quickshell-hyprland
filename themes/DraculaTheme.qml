//=============================================================================
// FILE
//=============================================================================
//
// themes/DraculaTheme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Dracula — the classic high-color dark theme. Charcoal base, purple/
// pink/cyan accents. Plain data file, full theme property contract
// (see themes/DefaultTheme.qml).
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml — register as a named child + `themes` map entry:
//   DraculaTheme { id: draculaThemeInst }
//   "DraculaTheme": draculaThemeInst
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ROLE MAPPING (canonical spec names):
//   background #282a36 (Background)  foreground #f8f8f2 (Foreground)
//   accent     #bd93f9 (Purple)      urgent     #ff5555 (Red)
//   muted      #6272a4 (Comment)     surface    #21222c (the "darker
//   hover      #44475a (Current      background" from Dracula PRO /
//              Line/Selection)       common terminal ports)
//
// BORDER: purple → pink (#ff79c6), Dracula's two loudest signature
// colors. This is the most saturated theme of the batch — if the
// gradient border is too much on top of colorful window content, set
// barBorderColor2 to "transparent".
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  Initial version. Canonical Dracula spec palette.
//
//=============================================================================

import QtQuick

QtObject {
    // ---- Colors ----
    property color colorBackground: "#282a36"
    property color colorForeground: "#f8f8f2"
    property color colorAccent: "#bd93f9"
    property color colorUrgent: "#ff5555"
    property color colorMuted: "#6272a4"
    property color colorSurface: "#21222c"
    property color colorHover: "#44475a"

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
    property color barBorderColor: "#bd93f9"
    property color barBorderColor2: "#ff79c6"
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
