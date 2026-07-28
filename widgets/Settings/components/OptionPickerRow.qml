import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

Rectangle {
    id: optionPicker

    property string label: ""
    property string description: ""
    property var options: []
    property string shownValue: ""
    property bool staged: false
    property int controlColumnX: 250
    property int maximumControlWidth: 430

    signal picked(string value)

    Layout.fillWidth: true
    implicitHeight: 44
    radius: Theme.radiusMedium
    color: rowHover.containsMouse ? Theme.colorHover : "transparent"

    Rectangle {
        visible: optionPicker.staged
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: Math.max(18, parent.height - Theme.spacingMedium * 2)
        radius: 2
        color: Theme.colorAccent
    }

    Item {
        id: labels
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMedium
        anchors.right: picker.left
        anchors.rightMargin: Theme.spacingLarge
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: labelRow.implicitHeight

        Row {
            id: labelRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingSmall

            Text {
                id: labelText
                text: optionPicker.label
                color: optionPicker.staged ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
                width: Math.min(implicitWidth, Math.max(0, labels.width - infoText.width - labelRow.spacing))
            }
            Text {
                id: infoText
                visible: optionPicker.description !== ""
                text: "ⓘ"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.78)
                anchors.verticalCenter: labelText.verticalCenter
            }
        }
        MouseArea { id: labelHover; anchors.fill: parent; acceptedButtons: Qt.NoButton; hoverEnabled: true }
        ToolTip.visible: optionPicker.description !== "" && labelHover.containsMouse
        ToolTip.text: optionPicker.description
        ToolTip.delay: 450
    }

    Row {
        id: picker
        anchors.left: parent.left
        anchors.leftMargin: Math.min(optionPicker.controlColumnX,
                                     Math.max(Theme.spacingMedium, parent.width - width - Theme.spacingMedium))
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        clip: true

        Repeater {
            model: optionPicker.options
            Rectangle {
                id: optionCell
                required property var modelData
                required property int index
                readonly property bool isCurrent: optionPicker.shownValue === modelData.value
                implicitWidth: Math.min(150, cellText.implicitWidth + Theme.spacingMedium * 2)
                implicitHeight: cellText.implicitHeight + Theme.spacingSmall * 2
                color: isCurrent ? Theme.colorSelected : cellMouse.containsMouse ? Theme.colorHover : Theme.colorControl
                border.width: 1
                border.color: Theme.colorDivider
                radius: index === 0 || index === optionPicker.options.length - 1 ? Theme.radiusMedium : 0
                Text {
                    id: cellText
                    anchors.centerIn: parent
                    width: parent.width - Theme.spacingMedium
                    text: optionCell.modelData.text
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    color: optionCell.isCurrent ? Theme.colorAccent : Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.88)
                }
                MouseArea { id: cellMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: optionPicker.picked(optionCell.modelData.value) }
            }
        }
    }

    MouseArea { id: rowHover; anchors.fill: parent; acceptedButtons: Qt.NoButton; hoverEnabled: true }
}
