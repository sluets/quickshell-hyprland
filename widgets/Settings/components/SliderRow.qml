import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

Rectangle {
    id: row
    property string label: ""
    property string description: ""
    property real value: 1.0
    property bool staged: false
    property real from: 0.0
    property real to: 1.0
    property real stepSize: 0.01
    signal moved(real value)

    Layout.fillWidth: true
    implicitHeight: 44
    radius: Theme.radiusMedium
    color: hover.containsMouse ? Theme.colorHover : "transparent"

    Rectangle { visible: row.staged; anchors.left: parent.left; anchors.leftMargin: 2; anchors.verticalCenter: parent.verticalCenter; width: 3; height: Math.max(18, parent.height - Theme.spacingMedium * 2); radius: 2; color: Theme.colorAccent }
    Text { id: labelText; anchors.left: parent.left; anchors.leftMargin: Theme.spacingMedium; anchors.verticalCenter: parent.verticalCenter; width: Math.max(0, slider.x - x - Theme.spacingLarge); text: row.label; elide: Text.ElideRight; color: row.staged ? Theme.colorAccent : Theme.colorForeground; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
    Slider {
        id: slider
        anchors.left: parent.left
        anchors.leftMargin: Math.min(250, Math.max(Theme.spacingMedium, parent.width - width - Theme.spacingMedium))
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(330, parent.width - x - Theme.spacingMedium)
        from: row.from; to: row.to; stepSize: row.stepSize; value: row.value
        onMoved: row.moved(value)
    }
    Text { anchors.right: slider.right; anchors.bottom: slider.top; anchors.bottomMargin: -4; text: Math.round(row.value * 100) + "%"; color: row.staged ? Theme.colorAccent : Theme.colorMuted; font.family: Theme.fontFamily; font.pixelSize: Math.round(Theme.fontSize * 0.78) }
    MouseArea { id: hover; anchors.fill: parent; acceptedButtons: Qt.NoButton; hoverEnabled: true }
    ToolTip.visible: row.description !== "" && hover.containsMouse
    ToolTip.text: row.description
    ToolTip.delay: 450
}
