//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/DeviceRow.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A full-width dropdown row for one item in a device/network list —
// leading status indicator, a TWO-LINE label (title + optional
// subtitle), optional trailing SignalBars, hover + press animation.
// Replaces the old single-line pattern of cramming everything into one
// Text ("DeviceName  73%  (connected)") via MenuButton.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// core/Theme.qml                  (singleton, via `import qs.core`)
// widgets/TopBar/SignalBars.qml   (neighboring file, only used when
//                                  showSignal is true)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/Wifi.qml (network list — title=SSID, subtitle=status,
// showSignal=true), widgets/TopBar/Bluetooth.qml (paired + new device
// lists — title=device name, subtitle=status, showSignal=false)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Wifi.qml / Bluetooth.qml fail to resolve the type. Revert their
// device/network lists to plain MenuButton rows.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// STATUS AS A LEADING DOT, NOT AN ICON COLUMN CHARACTER: `statusColor`
// drives a small filled circle, replacing MenuButton's fixed-width
// icon-column convention (which was built for glyphs, not status
// indicators — a colored dot reads faster than a "●"/"○" character at
// small sizes, and doesn't depend on a specific glyph rendering
// crisply at 14px). `pulsing` (for "connecting…"/"pairing…" states)
// animates the dot's opacity — the one place in this pass motion
// carries actual information (in-progress vs settled), not just
// polish.
//
// SUBTITLE IS OPTIONAL, NOT ALWAYS TWO LINES: when `subtitle` is
// empty, the row collapses to single-line height automatically
// (Column's implicit height just doesn't include the second Text) —
// a plain unconnected network doesn't need a second line saying
// nothing, only connected/pairing/error states earn the subtitle.
//
// CLICK TARGET is the whole row (MouseArea anchors.fill: parent),
// same "click anywhere" ergonomics as MenuButton/ToggleRow — this
// project doesn't do small tap-targets-inside-rows anywhere, staying
// consistent matters more than any single row's ideal layout.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Created as part of the Wi-Fi/Bluetooth menu visual
//             refresh.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property color statusColor: "transparent"
    property bool pulsing: false
    property bool showSignal: false
    property real signalStrength: 0
    signal clicked()

    implicitWidth: content.implicitWidth + Theme.spacingMedium * 2
    implicitHeight: content.implicitHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    color: mouseArea.containsMouse ? Theme.colorHover : "transparent"
    scale: mouseArea.pressed ? 0.98 : 1.0

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.animationEasing
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animationDuration / 2
            easing.type: Theme.animationEasing
        }
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingSmall
        anchors.rightMargin: Theme.spacingSmall
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingSmall

        // ---- Leading status dot ----
        Rectangle {
            Layout.preferredWidth: Theme.spacingSmall
            Layout.preferredHeight: Theme.spacingSmall
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: root.statusColor
            visible: root.statusColor.a > 0

            SequentialAnimation on opacity {
                running: root.pulsing
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.3; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.3; to: 1; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        // ---- Title + optional subtitle ----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Text {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                elide: Text.ElideRight
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.8)
            }
        }

        // ---- Trailing signal bars ----
        SignalBars {
            visible: root.showSignal
            Layout.alignment: Qt.AlignVCenter
            strength: root.signalStrength
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
