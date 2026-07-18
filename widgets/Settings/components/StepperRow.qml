import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: stepper

    property string label: ""
    property string valueText: ""
    property bool staged: false
    property bool showReset: false
    property int labelColumnWidth: 140
    property int valueColumnWidth: 64

    signal minus()
    signal plus()
    signal reset()

    Layout.fillWidth: true
    spacing: Theme.spacingMedium

    Text {
        text: stepper.label
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        Layout.minimumWidth: stepper.labelColumnWidth
        Layout.preferredWidth: stepper.labelColumnWidth
    }

    Rectangle {
        implicitWidth: minusText.implicitHeight + Theme.spacingMedium * 2
        implicitHeight: minusText.implicitHeight + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: minusMouse.containsMouse ? Theme.colorHover : Theme.colorSurface

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

    Text {
        text: stepper.valueText
        color: stepper.staged ? Theme.colorAccent : Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        horizontalAlignment: Text.AlignHCenter
        Layout.minimumWidth: stepper.valueColumnWidth
        Layout.preferredWidth: stepper.valueColumnWidth
    }

    Rectangle {
        implicitWidth: plusText.implicitHeight + Theme.spacingMedium * 2
        implicitHeight: plusText.implicitHeight + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: plusMouse.containsMouse ? Theme.colorHover : Theme.colorSurface

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

    Rectangle {
        visible: stepper.showReset
        implicitWidth: resetText.implicitWidth + Theme.spacingMedium * 2
        implicitHeight: resetText.implicitHeight + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: resetMouse.containsMouse ? Theme.colorHover : Theme.colorSurface

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

    Item { Layout.fillWidth: true }
}
