// Gear icon: opens the full Settings window directly. // GPT Rev 49
import QtQuick
import qs.core

Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        text: "\uf013"
        color: mouseArea.containsMouse ? Theme.colorAccent : Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        id: mouseArea
        anchors.fill: icon
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Signals.toggleSettingsWindow()
    }
}
