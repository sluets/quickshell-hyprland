// User-defined palette theme. Non-color metrics inherit from the selected base theme. // GPT
import QtQuick
QtObject {
    required property var baseTheme
    required property color customBackground
    required property color customForeground
    required property color customAccent
    required property color customUrgent
    required property color customMuted
    required property color customSurface
    required property color customHover
    required property color customBorder
    required property color customBorder2
    required property real customBorderAngle

    property color colorBackground: customBackground
    property color colorForeground: customForeground
    property color colorAccent: customAccent
    property color colorUrgent: customUrgent
    property color colorMuted: customMuted
    property color colorSurface: customSurface
    property color colorHover: customHover
    property string fontFamily: baseTheme.fontFamily
    property int fontSize: baseTheme.fontSize
    property int barHeight: baseTheme.barHeight
    property int radiusMedium: baseTheme.radiusMedium
    property int barMargin: baseTheme.barMargin
    property int barRadius: baseTheme.barRadius
    property int barBorderWidth: baseTheme.barBorderWidth
    property color barBorderColor: customBorder
    property color barBorderColor2: customBorder2
    property real barBorderGradientAngle: customBorderAngle
    property int barBorderFilletRadius: baseTheme.barBorderFilletRadius
    property int spacingSmall: baseTheme.spacingSmall
    property int spacingMedium: baseTheme.spacingMedium
    property int spacingLarge: baseTheme.spacingLarge
    property int animationDuration: baseTheme.animationDuration
    property int animationEasing: baseTheme.animationEasing
}
