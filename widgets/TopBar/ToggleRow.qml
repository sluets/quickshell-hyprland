//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/ToggleRow.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A full-width dropdown row for a binary on/off control — icon + label
// on the left, an animated ToggleSwitch on the right, the WHOLE row
// clickable (not just the switch itself — larger click target). Direct
// replacement for the old pattern of a MenuButton whose label text
// changed between "Turn Wi-Fi On" / "Turn Wi-Fi Off".
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// core/Theme.qml               (singleton, via `import qs.core`)
// widgets/TopBar/ToggleSwitch.qml (neighboring file)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/Wifi.qml (Wi-Fi on/off), widgets/TopBar/Bluetooth.qml
// (adapter on/off)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Wifi.qml / Bluetooth.qml fail to resolve the type. Revert their
// enable rows to plain MenuButton with a changing label.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHOLE-ROW CLICK, NOT JUST THE SWITCH: the row's own MouseArea
// (declared after `content` below, so it paints on top and captures
// input across the whole row) is what actually fires on every click,
// including clicks landing directly on the switch — ToggleSwitch's own
// internal MouseArea is shadowed underneath it and never fires WHEN
// USED INSIDE ToggleRow (it only matters if ToggleSwitch is
// instantiated standalone, with no wrapping click-catcher, elsewhere).
// This is deliberate, not a bug: one handler, one source of truth for
// the click, and "click anywhere on the row" (same ergonomics as
// MenuButton) rather than requiring precision on the small switch
// itself.
//
// `checked` IS NOT TWO-WAY BOUND TO A CALLER PROPERTY: this component
// only emits `toggled(value)` — the caller (Wifi.qml/Bluetooth.qml)
// still owns the real state (Network.wifiEnabled,
// Bluetooth.defaultAdapter.enabled) and passes it back in via the
// `checked` property, same one-way-data-down pattern the rest of this
// project already uses (e.g. MenuButton's plain `text`/`icon`). The
// switch shows checked immediately on click for responsiveness
// (ToggleSwitch flips its own visual state on click before waiting for
// the real backend state to come back), and settles to match reality
// once the caller's bound `checked` value actually changes — if
// NetworkManager/BlueZ ever rejects the change, the switch will snap
// back on next data refresh rather than lying indefinitely.
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

    property string icon: ""
    property string text: ""
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: content.implicitWidth + Theme.spacingMedium * 2
    implicitHeight: content.implicitHeight + Theme.spacingMedium * 2
    radius: Theme.radiusMedium
    color: mouseArea.containsMouse ? Theme.colorHover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
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

        Text {
            text: root.icon
            visible: root.icon.length > 0
            Layout.preferredWidth: Theme.fontSize
            horizontalAlignment: Text.AlignHCenter
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: root.text
            Layout.fillWidth: true
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        ToggleSwitch {
            id: toggleSwitch
            checked: root.checked
            onToggled: value => root.toggled(value)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleSwitch.checked = !toggleSwitch.checked;
            root.toggled(toggleSwitch.checked);
        }
    }
}
