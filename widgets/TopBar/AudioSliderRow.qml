import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core

Item {
    id: root

    property string label: ""
    property string subtitle: ""
    property string iconName: ""
    property string fallbackIcon: "\uf028"
    property real value: 0
    property bool muted: false
    property bool enabled: true
    property bool showMute: true

    signal valueEdited(real value)
    signal muteClicked()

    Layout.fillWidth: true
    implicitHeight: Math.max(46, contentRow.implicitHeight)
    opacity: enabled ? 1.0 : 0.45

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingSmall
        anchors.rightMargin: Theme.spacingSmall
        spacing: Theme.spacingMedium

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            IconImage {
                anchors.fill: parent
                visible: root.iconName !== ""
                source: root.iconName === "" ? "" : Quickshell.iconPath(root.iconName, "audio-volume-high-symbolic")
            }

            Text {
                anchors.centerIn: parent
                visible: root.iconName === ""
                text: root.fallbackIcon
                color: root.muted ? Theme.colorMuted : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 112
            Layout.maximumWidth: 112
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.label
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.76)
                elide: Text.ElideRight
            }
        }

        Item {
            id: slider
            Layout.fillWidth: true
            Layout.minimumWidth: 120
            implicitHeight: 24

            Rectangle {
                id: track
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 5
                radius: height / 2
                color: Theme.colorControl
                border.width: 1
                border.color: Theme.colorDivider
            }

            Rectangle {
                anchors.left: track.left
                anchors.verticalCenter: track.verticalCenter
                width: track.width * Math.max(0, Math.min(1, root.value))
                height: track.height
                radius: track.radius
                color: root.muted ? Theme.colorMuted : Theme.colorAccent
            }

            Rectangle {
                x: Math.max(0, Math.min(track.width - width,
                                       track.width * Math.max(0, Math.min(1, root.value)) - width / 2))
                anchors.verticalCenter: track.verticalCenter
                width: 13
                height: 13
                radius: width / 2
                color: root.muted ? Theme.colorMuted : Theme.colorAccent
                border.width: 2
                border.color: Theme.colorCard
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.enabled
                cursorShape: Qt.PointingHandCursor

                function applyAt(xPos) {
                    root.valueEdited(Math.max(0, Math.min(1, xPos / width)));
                }

                onPressed: mouse => applyAt(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        applyAt(mouse.x);
                }
                onWheel: wheel => {
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    root.valueEdited(Math.max(0, Math.min(1, root.value + step)));
                    wheel.accepted = true;
                }
            }
        }

        Text {
            Layout.preferredWidth: 40
            text: Math.round(Math.max(0, Math.min(1, root.value)) * 100) + "%"
            color: root.muted ? Theme.colorMuted : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.82)
            horizontalAlignment: Text.AlignRight
        }

        Rectangle {
            visible: root.showMute
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: Theme.radiusMedium
            color: muteMouse.containsMouse ? Theme.colorHover : Theme.colorControl
            border.width: 1
            border.color: Theme.colorDivider

            Text {
                anchors.centerIn: parent
                text: root.muted ? "\uf6a9" : "\uf028"
                color: root.muted ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.86)
            }

            MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.enabled
                onClicked: root.muteClicked()
            }
        }
    }
}
