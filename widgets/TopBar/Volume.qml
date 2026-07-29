// Redesigned Audio popout with output, device, application-stream, and input
// controls. PipeWire ownership remains in services/Audio.qml. // GPT Rev 30

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: barRow.implicitWidth
    implicitHeight: barRow.implicitHeight

    function iconGlyph(): string {
        if (Audio.muted) return "\uf026";
        return Audio.volume < 0.5 ? "\uf027" : "\uf028";
    }

    RowLayout {
        id: barRow
        spacing: Theme.spacingSmall

        Text {
            text: root.iconGlyph()
            color: (popout.open || barMouse.containsMouse) ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: barMouse
        anchors.fill: barRow
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                const opening = !popout.open;
                popout.open = opening;
                if (opening)
                    Audio.rebuildNodes();
            } else if (mouse.button === Qt.MiddleButton)
                Audio.toggleMute();
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                Audio.incrementVolume();
            else if (wheel.angleDelta.y < 0)
                Audio.decrementVolume();
            wheel.accepted = true;
        }
    }

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "right"

        // Give the audio controls and application sliders more breathing room.
        Item { Layout.minimumWidth: 470; implicitHeight: 0 }

        SectionLabel { text: "OUTPUT VOLUME" }
        AudioSectionCard {
            AudioSliderRow {
                label: "Master volume"
                fallbackIcon: root.iconGlyph()
                value: Audio.volume
                muted: Audio.muted
                onValueEdited: value => Audio.setVolume(value)
                onMuteClicked: Audio.toggleMute()
            }
        }

        SectionLabel { text: "OUTPUT DEVICE" }
        AudioSectionCard {
            id: outputDeviceCard
            contentSpacing: 0
            z: deviceListOpen ? 50 : 0

            Rectangle {
                id: deviceButton
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Theme.radiusMedium
                color: deviceMouse.containsMouse ? Theme.colorHover : Theme.colorControl
                border.width: 1
                border.color: Theme.colorDivider

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.rightMargin: Theme.spacingMedium
                    spacing: Theme.spacingSmall

                    Text {
                        text: "\uf025"
                        color: Theme.colorAccent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Text {
                        Layout.fillWidth: true
                        text: Audio.sink?.description || Audio.sink?.nickname || Audio.sink?.name || "No output device"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        elide: Text.ElideRight
                    }

                    Text {
                        text: deviceListOpen ? "\uf077" : "\uf078"
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 0.75)
                    }
                }

                MouseArea {
                    id: deviceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: deviceListOpen = !deviceListOpen
                }
            }

            overlayContent: Rectangle {
                id: deviceDropdown
                visible: deviceListOpen
                x: Theme.spacingMedium
                y: deviceButton.y + deviceButton.height + Theme.spacingSmall
                width: outputDeviceCard.width - Theme.spacingMedium * 2
                implicitHeight: Math.min(deviceRows.implicitHeight + Theme.spacingSmall * 2, 220)
                height: implicitHeight
                radius: Theme.radiusMedium
                color: Theme.colorCard
                border.width: 1
                border.color: Theme.colorDivider
                z: 200
                clip: true

                Flickable {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingSmall
                    contentWidth: width
                    contentHeight: deviceRows.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height
                    clip: true

                    ColumnLayout {
                        id: deviceRows
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: Audio.sinks

                            Rectangle {
                                required property var modelData
                                readonly property bool activeDevice: Audio.sink?.id === modelData.id
                                Layout.fillWidth: true
                                implicitHeight: 38
                                radius: Theme.radiusMedium
                                color: activeDevice ? Theme.colorSelected
                                                    : (sinkMouse.containsMouse ? Theme.colorHover : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingMedium
                                    anchors.rightMargin: Theme.spacingMedium
                                    spacing: Theme.spacingSmall

                                    Text {
                                        text: parent.parent.activeDevice ? "●" : "○"
                                        color: parent.parent.activeDevice ? Theme.colorAccent : Theme.colorMuted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Math.round(Theme.fontSize * 0.72)
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: parent.parent.modelData.description
                                              || parent.parent.modelData.nickname
                                              || parent.parent.modelData.name
                                        color: Theme.colorForeground
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Math.round(Theme.fontSize * 0.88)
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: sinkMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Audio.setSink(parent.modelData);
                                        deviceListOpen = false;
                                    }
                                }
                            }
                        }
                    }

                    WheelHandler {
                        target: null
                        onWheel: event => {
                            const delta = event.pixelDelta.y !== 0
                                ? event.pixelDelta.y
                                : event.angleDelta.y / 2;
                            const maximum = Math.max(0, parent.contentHeight - parent.height);
                            parent.contentY = Math.max(0, Math.min(maximum, parent.contentY - delta));
                            event.accepted = true;
                        }
                    }
                }
            }
        }

        SectionLabel { text: "APPLICATIONS" }
        AudioSectionCard {
            visible: Audio.playbackGroups.length > 0

            Flickable {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(appRows.implicitHeight, 230)
                contentWidth: width
                contentHeight: appRows.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                ColumnLayout {
                    id: appRows
                    width: parent.width
                    spacing: Theme.spacingSmall

                    Repeater {
                        model: Audio.playbackGroups

                        AudioSliderRow {
                            required property var modelData
                            label: modelData.name
                            subtitle: Audio.groupDescription(modelData)
                            iconName: modelData.iconName
                            fallbackIcon: "\uf1c7"
                            value: Audio.groupVolume(modelData)
                            muted: Audio.groupMuted(modelData)
                            onValueEdited: value => Audio.setGroupVolume(modelData, value)
                            onMuteClicked: Audio.toggleGroupMute(modelData)
                        }
                    }
                }

                WheelHandler {
                    target: null
                    onWheel: event => {
                        const delta = event.pixelDelta.y !== 0
                            ? event.pixelDelta.y
                            : event.angleDelta.y / 2;
                        const maximum = Math.max(0, parent.contentHeight - parent.height);
                        parent.contentY = Math.max(0, Math.min(maximum, parent.contentY - delta));
                        event.accepted = true;
                    }
                }
            }
        }

        AudioSectionCard {
            visible: Audio.playbackGroups.length === 0

            Text {
                Layout.fillWidth: true
                text: "Active applications will appear here when they start playing audio."
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.82)
                wrapMode: Text.WordWrap
            }
        }

        SectionLabel { text: "INPUT" }
        AudioSectionCard {
            AudioSliderRow {
                label: "Microphone"
                subtitle: Audio.source?.description || Audio.source?.nickname || Audio.source?.name || "No input device"
                fallbackIcon: "\uf130"
                value: Audio.sourceVolume
                muted: Audio.sourceMuted
                enabled: Audio.source !== null
                onValueEdited: value => Audio.setSourceVolume(value)
                onMuteClicked: Audio.toggleSourceMute()
            }
        }
    }

    property bool deviceListOpen: false
}
