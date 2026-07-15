//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/ToggleSwitch.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A proper pill-shaped on/off switch — animated sliding knob, animated
// track color — for binary controls in dropdown menus (Wi-Fi on/off,
// Bluetooth on/off). Replaces rendering toggle state as plain text
// (previously the literal characters "●"/"○" or a MenuButton whose
// LABEL changed between "Turn X On" / "Turn X Off").
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// core/Theme.qml (singleton, via `import qs.core`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/ToggleRow.qml (the usual way to reach this — a full
// menu row with a label). Can be used standalone if a bare switch with
// no row chrome is ever needed.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// ToggleRow.qml fails to resolve. Wifi.qml / Bluetooth.qml's enable
// rows would need reverting to plain MenuButton-with-changing-label.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY A SEPARATE COMPONENT FROM ToggleRow: this is the switch ITSELF —
// no label, no row padding, no click target beyond its own bounds — so
// it's reusable anywhere a bare toggle is wanted, not just inside a
// full-width menu row. ToggleRow composes this with a label and makes
// the WHOLE ROW clickable (larger, easier target — Fitts's law), which
// is why ToggleRow is what Wifi/Bluetooth actually use day to day.
//
// ANIMATION: both the knob's x position and the track's color are
// `Behavior`-animated (Theme.animationDuration, same shared timing
// every dropdown-open animation already uses — see
// ARCHITECTURE.md's "Dropdown menu pattern"). This is the single
// biggest visual-polish gap this whole pass addresses: nothing in the
// project animated a state CHANGE before now, only popout open/close.
//
// SIZE is content-driven from Theme.fontSize (a switch scaled to the
// surrounding text, not a hardcoded pixel size) so it stays
// proportional if fontSize ever changes via a future theme.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Created as part of the Wi-Fi/Bluetooth menu visual
//             refresh — see ARCHITECTURE.md and the REVISION_HISTORY
//             entry for the full pass.
//
//=============================================================================

import QtQuick
import qs.core

Item {
    id: root

    property bool checked: false
    signal toggled(bool value)

    readonly property real trackHeight: Theme.fontSize + Theme.spacingSmall
    readonly property real trackWidth: trackHeight * 1.8
    readonly property real knobMargin: 2
    readonly property real knobSize: trackHeight - knobMargin * 2

    implicitWidth: trackWidth
    implicitHeight: trackHeight

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.colorAccent : Theme.colorSurface
        border.width: root.checked ? 0 : 1
        border.color: Theme.colorMuted

        Behavior on color {
            ColorAnimation {
                duration: Theme.animationDuration
                easing.type: Theme.animationEasing
            }
        }
    }

    Rectangle {
        id: knob
        width: root.knobSize
        height: root.knobSize
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        // Checked color is chosen for contrast against colorAccent —
        // colorBackground reliably reads over an accent fill across
        // both shipped themes (dark blue-grey accent in DefaultTheme,
        // white accent in HoneycombTheme — colorBackground is the dark
        // end of each, giving contrast either way). Unchecked knob
        // uses colorForeground so it reads clearly against the plain
        // surface track.
        color: root.checked ? Theme.colorBackground : Theme.colorForeground
        x: root.checked
            ? root.trackWidth - width - root.knobMargin
            : root.knobMargin

        Behavior on x {
            NumberAnimation {
                duration: Theme.animationDuration
                easing.type: Theme.animationEasing
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
