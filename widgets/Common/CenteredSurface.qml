// Reusable centered, focus-grabbing surface for launcher/wallpaper-style tools. // GPT Rev 41
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core

PanelWindow {
    id: root

    required property ShellScreen targetScreen
    property bool open: false
    property int offsetX: 0
    property int offsetY: 0
    default property alias contentData: contentColumn.data

    screen: targetScreen
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: 0
    color: "transparent"
    visible: reveal > 0.001

    property real reveal: open ? 1 : 0
    Behavior on reveal {
        NumberAnimation { duration: Theme.animationDuration; easing.type: Theme.animationEasing }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.open = false
    }
    onOpenChanged: focusGrab.active = open

    MouseArea {
        anchors.fill: parent
        onClicked: root.open = false
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.offsetX
        anchors.verticalCenterOffset: root.offsetY
        implicitWidth: contentColumn.implicitWidth + Theme.spacingMedium * 2
        implicitHeight: contentColumn.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: Theme.colorBackground
        border.width: Theme.barBorderWidth
        border.color: Theme.barBorderColor
        opacity: root.reveal
        scale: 0.96 + root.reveal * 0.04

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: contentColumn
            anchors.centerIn: parent
            spacing: Theme.spacingSmall
        }
    }
}
