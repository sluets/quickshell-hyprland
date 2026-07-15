//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/Volume.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Volume in the bar — now interactive:
//
//   • Scroll on the bar text/icon  -> volume up/down (Settings.volumeStep)
//   • Middle-click                 -> toggle mute
//   • Left-click                   -> popout with a slider, a mute
//                                     button, and an output-device picker
//
// Bar display stays value-then-icon ("42% <icon>") — a deliberate
// layout choice (see docs/REVISION_HISTORY.md 2026-07-02).
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// core/Theme.qml, core/Settings.qml  (singletons via `import qs.core`)
// services/Audio.qml                 (singleton via `import qs.services`)
// widgets/TopBar/BarPopout.qml       (neighboring file)
// widgets/TopBar/MenuButton.qml      (neighboring file)
// widgets/TopBar/MenuDivider.qml     (neighboring file)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/TopBar.qml
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// TopBar loses the volume indicator and all volume control. Nothing else
// depends on this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// THE SLIDER IS HAND-ROLLED (track + fill + drag MouseArea) instead of
// QtQuick.Controls Slider — a Controls Slider drags in its platform
// style's look, which fights the theme, and restyling one takes more
// code than this does. The whole thing is ~30 lines and every color
// comes from Theme.
//
// DEVICE LIST shows Audio.sinks with the active one accented; clicking
// one calls Audio.setSink(). Descriptions come from PipeWire
// (node.description — e.g. "Navi 31 HDMI/DP Audio" / "Family 17h..."),
// with node.name as fallback since some nodes ship empty descriptions.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-03  Interactive rewrite: scroll-to-adjust, middle-click mute,
//             click-for-popout (slider + mute + output device picker).
//             Was display-only before.
// 2026-07-02  Reordered to value-then-icon; NaN fix landed in the
//             service, not here.
// 2026-07-01  Initial display-only widget.
//
//=============================================================================

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
            visible: !Audio.muted
            text: Math.round(Audio.volume * 100) + "%"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

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
            if (mouse.button === Qt.LeftButton)
                popout.open = !popout.open;
            else if (mouse.button === Qt.MiddleButton)
                Audio.toggleMute();
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                Audio.incrementVolume();
            else if (wheel.angleDelta.y < 0)
                Audio.decrementVolume();
        }
    }

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "right"

        // ---- Volume readout + slider ----
        Text {
            text: "Volume — " + (Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%")
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        // Hand-rolled slider — see DESIGN NOTES.
        Item {
            id: slider
            Layout.fillWidth: true
            Layout.minimumWidth: 220
            implicitHeight: Theme.fontSize

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.colorMuted
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: track.width * Audio.volume
                height: track.height
                radius: track.radius
                color: Audio.muted ? Theme.colorMuted : Theme.colorAccent
            }

            Rectangle {
                x: track.width * Audio.volume - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.fontSize * 0.85
                height: width
                radius: width / 2
                color: Audio.muted ? Theme.colorForeground : Theme.colorAccent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => Audio.setVolume(mouse.x / width)
                onPositionChanged: mouse => {
                    if (pressed)
                        Audio.setVolume(Math.max(0, Math.min(1, mouse.x / width)));
                }
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (wheel.angleDelta.y < 0)
                        Audio.decrementVolume();
                }
            }
        }

        MenuButton {
            Layout.fillWidth: true
            icon: Audio.muted ? "\uf026" : "\uf028"
            text: Audio.muted ? "Unmute" : "Mute"
            onClicked: Audio.toggleMute()
        }

        MenuDivider { Layout.fillWidth: true }

        // ---- Output device picker ----
        Text {
            text: "Output Device"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        Repeater {
            model: Audio.sinks

            MenuButton {
                required property var modelData
                readonly property bool isActive: Audio.sink?.id === modelData.id

                Layout.fillWidth: true
                icon: isActive ? "●" : "○"
                text: modelData.description || modelData.name
                onClicked: Audio.setSink(modelData)
            }
        }
    }
}
