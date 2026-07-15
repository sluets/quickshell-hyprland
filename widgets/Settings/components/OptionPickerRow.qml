import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: optionPicker

    property string label: ""
    property var options: []
    property string shownValue: ""
    property bool staged: false

    signal picked(string value)

    Layout.fillWidth: true
    spacing: Theme.spacingSmall

    Text {
        text: optionPicker.label
        color: optionPicker.staged ? Theme.colorAccent : Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        Layout.minimumWidth: 140
    }

    Repeater {
        model: optionPicker.options

        Rectangle {
            id: optionCell
            required property var modelData
            readonly property bool isCurrent: optionPicker.shownValue === modelData.value

            implicitWidth: cellText.implicitWidth + Theme.spacingMedium * 2
            implicitHeight: cellText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: isCurrent ? Theme.colorSurface
                 : cellMouse.containsMouse ? Theme.colorHover : "transparent"

            Text {
                id: cellText
                anchors.centerIn: parent
                text: optionCell.modelData.text
                color: optionCell.isCurrent ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: cellMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: optionPicker.picked(optionCell.modelData.value)
            }
        }
    }

    Item { Layout.fillWidth: true }
}
