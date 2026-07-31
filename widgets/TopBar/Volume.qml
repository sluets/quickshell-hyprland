//=============================================================================
// widgets/TopBar/Volume.qml
//
// The Audio popout: master output, output-device picker, per-application
// streams, and input. PipeWire ownership stays in services/Audio.qml —
// this file is presentation only.
//
//=============================================================================
// SIZING (2026-07-29 — same lesson as Clock.qml and AudioSliderRow.qml)
//=============================================================================
//
// BarPopout's width is content-driven and Theme.fontSize already includes
// the user's fontScale, so every dimension here is a multiple of
// Theme.fontSize rather than a pixel constant. The previous fixed values
// (470 min width, 42 device button, 38 dropdown row, 220/230 list caps)
// were all tuned at one scale and cramped at larger ones. Scroll-area
// caps are now expressed as "N rows tall", which is what they actually
// mean.
//
// TWO THINGS THAT SILENTLY SET A POPOUT'S WIDTH (found 2026-07-29, after
// this popout came out far wider than its contents needed):
//
//   1. `elide: Text.ElideRight` does NOT reduce a Text's implicitWidth.
//      An elided Text still reports the width of its full single line to
//      the layout, so ONE long PipeWire device description ("Family 17h/
//      19h HD Audio Controller Digital Microphone") was setting the
//      width of the entire popout — and it looked like a design choice,
//      not a bug, because the text itself was neatly elided.
//   2. A wrapping Text reports its UNWRAPPED width as implicit. The
//      empty-applications sentence alone was worth ~500 px.
//
// Both are fixed the same way: `Layout.preferredWidth: 0` alongside
// `Layout.fillWidth: true`. The text then takes whatever width the row
// has and elides/wraps into it, instead of dictating the row's width.
// Any new Text that elides or wraps inside a layout needs this.
//
// The min width is only a JITTER FLOOR — set just under what the widest
// row genuinely needs. A floor above that doesn't make the popout
// roomier, it makes it empty.
//
//=============================================================================
// ⚠ WRITTEN OFFLINE — NOT YET RUN LIVE. Test checklist:
//   - fontScale 1.0 / 1.25 / 1.5: no clipped labels or percentages;
//     device button text elides (long Bluetooth names) but the chevron
//     stays visible; nothing overlaps the card edges.
//   - Output device dropdown still opens over the sections below without
//     changing the popout's height, scrolls past ~5 devices, and picking
//     one closes it.
//   - Application list scrolls past ~4 streams (wheel over the list);
//     empty state message still shows with nothing playing.
//   - Middle-click and wheel on the bar icon still mute / change volume.
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-29  (Claude Fable 5) Width fix: floor lowered to
//             fontSize * 25, and the elided/wrapping Texts that were
//             actually dictating the width given
//             `Layout.preferredWidth: 0` (see SIZING above).
// 2026-07-29  (Claude Fable 5) Font-relative sizing throughout; header
//             row (icon + "Audio") to match the other redesigned
//             popouts; master and microphone rows use AudioSliderRow's
//             new `labelAbove` so the slider gets the full card width.
// 2026-07-xx  (GPT Rev 30) Redesigned popout with sections and cards.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: barRow.implicitWidth
    implicitHeight: barRow.implicitHeight

    property bool deviceListOpen: false

    // One row of the output-device dropdown, and the dropdown's cap in
    // rows rather than pixels.
    readonly property int deviceRowHeight: Math.max(34, Math.round(Theme.fontSize * 2.4))
    readonly property int deviceListMaxRows: 5
    readonly property int appListMaxRows: 4

    function iconGlyph(): string {
        if (Audio.muted) return "\uf026";
        return Audio.volume < 0.5 ? "\uf027" : "\uf028";
    }

    RowLayout {
        id: barRow
        spacing: Theme.spacingSmall

        Text {
            text: root.iconGlyph()
            color: (popout.open || barMouse.containsMouse)
                ? Theme.colorAccent : Theme.colorForeground
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

        onOpenChanged: {
            if (!open)
                root.deviceListOpen = false;
        }

        // Width floor scales with the font — audio rows (icon + label +
        // track + percentage + mute) need more of it than the clock's.
        Item {
            Layout.minimumWidth: Math.max(400, Math.round(Theme.fontSize * 25))
            implicitHeight: 0
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            Text {
                text: root.iconGlyph()
                color: Theme.colorAccent
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.2)
            }

            Text {
                text: "Audio"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.35)
                font.bold: true
            }
        }

        SectionLabel { text: "OUTPUT VOLUME" }
        AudioSectionCard {
            AudioSliderRow {
                labelAbove: true
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
            contentSpacing: Theme.spacingSmall
            z: root.deviceListOpen ? 50 : 0

            Text {
                Layout.fillWidth: true
                text: "Output device"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Rectangle {
                id: deviceButton
                Layout.fillWidth: true
                implicitHeight: Math.max(38, Math.round(Theme.fontSize * 2.7))
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
                        // See AudioSliderRow: an elided Text reports its
                        // full width to the layout, so a long Bluetooth
                        // device name would widen the whole popout.
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        text: Audio.sink?.description
                            || Audio.sink?.nickname
                            || Audio.sink?.name
                            || "No output device"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        elide: Text.ElideRight
                    }

                    // Chevron keeps its own width so a long device name
                    // elides instead of pushing it out of the button.
                    Text {
                        Layout.minimumWidth: implicitWidth
                        text: root.deviceListOpen ? "\uf077" : "\uf078"
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
                    onClicked: root.deviceListOpen = !root.deviceListOpen
                }
            }

            // Floats over the sections below (AudioSectionCard's overlay
            // layer) so opening it never changes the popout's height.
            overlayContent: Rectangle {
                id: deviceDropdown
                visible: root.deviceListOpen
                x: Theme.spacingMedium
                y: deviceButton.y + deviceButton.height + Theme.spacingSmall
                width: outputDeviceCard.width - Theme.spacingMedium * 2
                implicitHeight: Math.min(
                    deviceRows.implicitHeight + Theme.spacingSmall * 2,
                    root.deviceRowHeight * root.deviceListMaxRows)
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
                                readonly property bool activeDevice:
                                    Audio.sink?.id === modelData.id
                                Layout.fillWidth: true
                                implicitHeight: root.deviceRowHeight
                                radius: Theme.radiusMedium
                                color: activeDevice
                                    ? Theme.colorSelected
                                    : (sinkMouse.containsMouse
                                        ? Theme.colorHover : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingMedium
                                    anchors.rightMargin: Theme.spacingMedium
                                    spacing: Theme.spacingSmall

                                    Text {
                                        text: parent.parent.activeDevice ? "●" : "○"
                                        color: parent.parent.activeDevice
                                            ? Theme.colorAccent : Theme.colorMuted
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
                                        root.deviceListOpen = false;
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
                            parent.contentY = Math.max(0,
                                Math.min(maximum, parent.contentY - delta));
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
                id: appFlick
                Layout.fillWidth: true
                // Cap expressed in rows, so it scales with the font.
                Layout.preferredHeight: Math.min(
                    appRows.implicitHeight,
                    Math.round(Theme.fontSize * 3.4) * root.appListMaxRows)
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
                        const maximum = Math.max(0, appFlick.contentHeight - appFlick.height);
                        appFlick.contentY = Math.max(0,
                            Math.min(maximum, appFlick.contentY - delta));
                        event.accepted = true;
                    }
                }
            }
        }

        AudioSectionCard {
            visible: Audio.playbackGroups.length === 0

            Text {
                // A wrapping Text reports its UNWRAPPED width as implicit —
                // this one sentence was worth ~500 px of popout on its own.
                Layout.fillWidth: true
                Layout.preferredWidth: 0
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
                labelAbove: true
                label: "Microphone"
                subtitle: Audio.source?.description
                    || Audio.source?.nickname
                    || Audio.source?.name
                    || "No input device"
                fallbackIcon: "\uf130"
                value: Audio.sourceVolume
                muted: Audio.sourceMuted
                enabled: Audio.source !== null
                onValueEdited: value => Audio.setSourceVolume(value)
                onMuteClicked: Audio.toggleSourceMute()
            }
        }
    }
}
