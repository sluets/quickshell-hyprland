import QtQuick
import QtQuick.Layouts
import qs.core

Text {
    property string title: ""
    text: title.toUpperCase()
    color: Theme.colorMuted
    font.family: Theme.fontFamily
    font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.72))
    font.bold: true
    font.letterSpacing: 1.2
    Layout.fillWidth: true
    Layout.topMargin: Theme.spacingLarge
    Layout.bottomMargin: Theme.spacingSmall
}
