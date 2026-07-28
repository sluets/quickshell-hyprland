import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

Rectangle {
    id: stepper

    property string label: ""
    property string description: ""
    property string valueText: ""
    property bool staged: false
    property bool showReset: false
    // Legacy compatibility: existing pages still assign this property.
    // Rev 3 uses a shared fixed form grid, so the per-row value is accepted but ignored.
    property int labelColumnWidth: 0
    property int valueColumnWidth: 86

    // Form-grid positions are measured from the left edge of every row.
    // Controls therefore remain aligned regardless of label length.
    property int controlColumnX: 250
    property int resetColumnX: 540

    signal minus()
    signal plus()
    signal reset()

    Layout.fillWidth: true
    implicitHeight: Math.max(44, labels.implicitHeight + Theme.spacingSmall * 2)
    radius: Theme.radiusMedium
    color: hover.containsMouse ? Theme.colorHover : "transparent"

    Rectangle {
        visible: stepper.staged
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
        anchors.right: control.left
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
                text: stepper.label
                color: stepper.staged ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
                width: Math.min(implicitWidth, Math.max(0, labels.width - infoText.width - labelRow.spacing))
            }

            Text {
                id: infoText
                visible: stepper.description !== ""
                text: "ⓘ"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.78)
                anchors.verticalCenter: labelText.verticalCenter
            }
        }

        MouseArea {
            id: labelHover
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }

        ToolTip.visible: stepper.description !== "" && labelHover.containsMouse
        ToolTip.text: stepper.description
        ToolTip.delay: 450
    }

    // A single joined segmented control anchored to a fixed form column.
    Rectangle {
        id: control
        anchors.left: parent.left
        anchors.leftMargin: Math.min(stepper.controlColumnX,
                                     Math.max(Theme.spacingMedium, parent.width - implicitWidth - Theme.spacingMedium))
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: minusButton.width + stepper.valueColumnWidth + plusButton.width
        implicitHeight: Math.max(minusText.implicitHeight,
                                 valueTextItem.implicitHeight,
                                 plusText.implicitHeight) + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: Theme.colorControl
        border.width: 1
        border.color: Theme.colorDivider
        clip: true

        Rectangle {
            id: minusButton
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: minusText.implicitHeight + Theme.spacingMedium * 2
            color: minusMouse.containsMouse ? Theme.colorHover : "transparent"

            Text {
                id: minusText
                anchors.centerIn: parent
                text: "−"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: minusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stepper.minus()
            }
        }

        Rectangle {
            anchors.left: minusButton.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.colorDivider
        }

        Text {
            id: valueTextItem
            anchors.left: minusButton.right
            anchors.right: plusButton.left
            anchors.verticalCenter: parent.verticalCenter
            text: stepper.valueText
            color: stepper.staged ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            anchors.right: plusButton.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Theme.colorDivider
        }

        Rectangle {
            id: plusButton
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: plusText.implicitHeight + Theme.spacingMedium * 2
            color: plusMouse.containsMouse ? Theme.colorHover : "transparent"

            Text {
                id: plusText
                anchors.centerIn: parent
                text: "+"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: plusMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: stepper.plus()
            }
        }
    }

    Rectangle {
        id: resetButton
        visible: stepper.showReset
        anchors.left: parent.left
        anchors.leftMargin: Math.min(stepper.resetColumnX,
                                     Math.max(control.x + control.width + Theme.spacingMedium,
                                              parent.width - implicitWidth - Theme.spacingMedium))
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: resetText.implicitWidth + Theme.spacingMedium * 2
        implicitHeight: control.implicitHeight
        radius: Theme.radiusMedium
        color: resetMouse.containsMouse ? Theme.colorHover : Theme.colorControl
        border.width: 1
        border.color: Theme.colorDivider

        Text {
            id: resetText
            anchors.centerIn: parent
            text: "Reset"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.82)
        }

        MouseArea {
            id: resetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: stepper.reset()
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        propagateComposedEvents: true
    }
}
