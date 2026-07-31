//=============================================================================
// widgets/TopBar/AudioSliderRow.qml
//
// One volume row: icon, name (+ optional subtitle), track, percentage,
// mute button. Used for master output, per-application streams, and the
// microphone in the Audio popout (Volume.qml).
//
//=============================================================================
// WHY EVERY SIZE HERE IS A MULTIPLE OF Theme.fontSize (2026-07-29)
//=============================================================================
//
// The previous version pinned the label column to `Layout.maximumWidth:
// 112`, the percentage to `Layout.preferredWidth: 40`, the icon to 24 and
// the mute button to 30 — all raw pixels. Theme.fontSize is the theme's
// base size TIMES the user's fontScale, so at any scale above ~1.1 the
// label elided early ("Master volu…"), and "100%" — which has no elide —
// simply got cut off inside its 40 px box. That was the reported text
// clipping; it was never a layout bug, it was hardcoded pixels meeting a
// bigger font.
//
// Rules this file now follows, worth copying into any new row widget:
//   - Text boxes are measured (TextMetrics) or expressed in em-ish
//     multiples of Theme.fontSize, never px constants.
//   - The name column has a PREFERRED and a MINIMUM width but no
//     maximum: it can grow with the font, and elide only handles
//     genuinely long names (app and device descriptions are arbitrary),
//     not the normal case.
//   - The percentage is measured against its widest possible value
//     ("100%") in the live font, so it can never clip.
//
// `labelAbove` puts the name on its own line above a full-width slider —
// the maintainer's mockup layout for the master and microphone rows,
// where there's one obvious label and the slider deserves the width.
// Application rows keep the inline label (their names vary, and the
// stacked form would triple the list's height).
//
//=============================================================================
// ⚠ WRITTEN OFFLINE — NOT YET RUN LIVE. Test checklist:
//   - fontScale 1.0 / 1.25 / 1.5: no ellipsis on "Master volume" or
//     "Microphone", "100%" fully visible at every scale (set master to
//     100%), mute buttons square and aligned down the column.
//   - Drag, click-to-seek and wheel on the track still set volume;
//     mute button still toggles; disabled (no input device) row still
//     dims to 45%.
//   - Application rows: long names (e.g. a browser tab title) elide
//     with "…" rather than pushing the slider off the card.
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-29  (Claude Fable 5) All fixed pixel sizes replaced with
//             Theme.fontSize multiples / measured text widths — fixes
//             the reported label and percentage clipping at larger font
//             scales. Added `labelAbove` (stacked label + full-width
//             slider) for the master/microphone rows.
//=============================================================================

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
    // Stack the name above a full-width slider instead of putting it in
    // a fixed column to the left. See DESIGN NOTES.
    property bool labelAbove: false

    signal valueEdited(real value)
    signal muteClicked()

    Layout.fillWidth: true
    // Vertical breathing room, font-relative (was a hardcoded 46 floor).
    implicitHeight: outerColumn.implicitHeight + Theme.spacingSmall * 2
    opacity: enabled ? 1.0 : 0.45

    // Measured once against the widest value this row can ever show, in
    // whatever font/scale is live — this is what makes clipping
    // impossible rather than merely unlikely.
    TextMetrics {
        id: percentMetrics
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.82)
        text: "100%"
    }

    readonly property int controlSize: Math.max(28, Math.round(Theme.fontSize * 2.1))

    ColumnLayout {
        id: outerColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.spacingSmall
        anchors.rightMargin: Theme.spacingSmall
        spacing: Theme.spacingSmall

        // Stacked label (labelAbove only).
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.labelAbove
            spacing: 0

            Text {
                // preferredWidth 0: an elided Text still reports its FULL
                // single-line implicitWidth to the layout, which would let
                // one long device description set the whole popout's width.
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: root.label
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                visible: root.subtitle !== ""
                text: root.subtitle
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.78)
                elide: Text.ElideRight
            }
        }

        RowLayout {
            id: contentRow
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            Item {
                Layout.preferredWidth: Math.max(20, Math.round(Theme.fontSize * 1.6))
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    anchors.fill: parent
                    visible: root.iconName !== ""
                    source: root.iconName === ""
                        ? ""
                        : Quickshell.iconPath(root.iconName, "audio-volume-high-symbolic")
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

            // Inline label column — preferred + minimum, NO maximum, so
            // it grows with the font instead of eliding at 112 px.
            ColumnLayout {
                visible: !root.labelAbove
                Layout.preferredWidth: Math.round(Theme.fontSize * 8.5)
                Layout.minimumWidth: Math.round(Theme.fontSize * 5.5)
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    text: root.label
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
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
                Layout.minimumWidth: Math.round(Theme.fontSize * 7)
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: Math.max(20, Math.round(Theme.fontSize * 1.4))

                readonly property real knobSize: Math.max(12, Math.round(Theme.fontSize * 0.95))

                Rectangle {
                    id: track
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.max(4, Math.round(Theme.fontSize * 0.34))
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
                    width: slider.knobSize
                    height: slider.knobSize
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
                // Measured, not guessed — "100%" always fits.
                Layout.preferredWidth: Math.ceil(percentMetrics.width) + 2
                Layout.minimumWidth: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter
                text: Math.round(Math.max(0, Math.min(1, root.value)) * 100) + "%"
                color: root.muted ? Theme.colorMuted : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.82)
                horizontalAlignment: Text.AlignRight
            }

            Rectangle {
                visible: root.showMute
                Layout.preferredWidth: root.controlSize
                Layout.preferredHeight: root.controlSize
                Layout.minimumWidth: root.controlSize
                Layout.alignment: Qt.AlignVCenter
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
}
