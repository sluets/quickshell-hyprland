import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

Rectangle {
    id: toggleRow

    property string label: ""
    property string description: ""
    property bool value: false
    property bool staged: false

    // All toggles share one fixed action column measured from the row's left.
    property int toggleColumnX: 250

    signal toggled()

    Layout.fillWidth: true
    implicitHeight: Math.max(44, labels.implicitHeight + Theme.spacingSmall * 2)
    radius: Theme.radiusMedium
    color: toggleMouse.containsMouse ? Theme.colorHover : "transparent"

    Rectangle {
        visible: toggleRow.staged
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
        anchors.right: switchTrack.left
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
                text: toggleRow.label
                color: toggleRow.staged ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
                width: Math.min(implicitWidth, Math.max(0, labels.width - infoText.width - labelRow.spacing))
            }

            Text {
                id: infoText
                visible: toggleRow.description !== ""
                text: "ⓘ"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.78)
                anchors.verticalCenter: labelText.verticalCenter
            }
        }

        ToolTip.visible: toggleRow.description !== "" && toggleMouse.containsMouse
        ToolTip.text: toggleRow.description
        ToolTip.delay: 450
    }

    Rectangle {
        id: switchTrack
        anchors.left: parent.left
        anchors.leftMargin: Math.min(toggleRow.toggleColumnX,
                                     Math.max(Theme.spacingMedium, parent.width - width - Theme.spacingMedium))
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(Theme.fontSize * 2.4)
        height: Math.round(Theme.fontSize * 1.25)
        radius: height / 2
        color: toggleRow.value ? Theme.colorAccent : Theme.colorControl

        Rectangle {
            width: parent.height - 4
            height: width
            radius: width / 2
            y: 2
            x: toggleRow.value ? parent.width - width - 2 : 2
            color: toggleRow.value ? Theme.colorBackground : Theme.colorMuted
            Behavior on x { NumberAnimation { duration: Theme.animationDuration } }
        }
    }

    MouseArea {
        id: toggleMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleRow.toggled()
    }
}
