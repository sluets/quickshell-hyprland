//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/SystemMenu.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Arch icon, leftmost item in the bar. Click opens the fullscreen power
// screen (widgets/PowerMenu/PowerScreen.qml) — restart Hyprland, restart
// PC, shut down. Used to be its own dropdown menu; see REVISION HISTORY.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// core/Theme.qml, core/Signals.qml (singletons, via `import qs.core`)
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
// TopBar loses the arch icon / power screen trigger. The SUPER+P keybind
// and IPC (`qs ipc call power toggle`) still open the power screen on their
// own — this file is just one more way in, not the only one.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// Emits Signals.togglePowerScreen() rather than holding a direct reference
// to PowerScreen — this file lives once PER MONITOR (inside each TopBar
// instance) while PowerScreen is a single top-level window instantiated in
// shell.qml, so there's no natural id to reach across that boundary. See
// core/Signals.qml and PowerScreen.qml's DESIGN NOTES for the full reasoning.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Dropdown menu REPLACED with widgets/PowerMenu/PowerScreen.qml
//             — a centered fullscreen screen instead of a bar dropdown, per
//             maintainer request. This
//             file shrank from the dropdown-pattern reference
//             implementation down to a single icon + signal emit.
//             MenuButton/MenuDivider no longer used here (still used
//             elsewhere — Wifi.qml, Bluetooth.qml).
// 2026-07-04  flushToScreenEdge -> flushToBarEdge (BarPopout property
//             rename, no behavior change here). [Superseded by the above —
//             this file no longer uses BarPopout at all.]
// 2026-07-03  Refactored onto the shared BarPopout component.
// 2026-07-01  Initial dropdown (reference implementation of the popup
//             pattern — since replaced, see entries above).
//
//=============================================================================

import QtQuick
import qs.core

Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        text: "\uf303" // nf-linux-archlinux
        color: mouseArea.containsMouse ? Theme.colorAccent : Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        id: mouseArea
        anchors.fill: icon
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Signals.togglePowerScreen()
    }
}
