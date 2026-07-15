import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: toggleRow

    property string label: ""
    property bool value: false
    property bool staged: false

    signal toggled()

    Layout.fillWidth: true
    implicitHeight: toggleText.implicitHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    color: toggleMouse.containsMouse ? Theme.colorHover : "transparent"

    Text {
        id: toggleText
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMedium
        anchors.verticalCenter: parent.verticalCenter
        text: (toggleRow.value ? "■ " : "□ ") + toggleRow.label
        color: toggleRow.staged ? Theme.colorAccent : Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleRow.toggled()
    }
}
