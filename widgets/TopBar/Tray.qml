//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/Tray.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The system tray (StatusNotifierItem host) — one TrayItem per app that
// registers a tray icon (steam, discord, nm-applet, etc). Collapses to
// zero width when nothing is registered, same trick as NowPlaying.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// Quickshell.Services.SystemTray  (SystemTray singleton)
// core/Theme.qml                  (singleton via `import qs.core`)
// widgets/TopBar/TrayItem.qml     (neighboring file — one per icon)
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
// TopBar loses the tray. Tray-only apps become unreachable from the bar
// (they keep running — you just can't click their icon).
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// SystemTray.items is Quickshell's reactive ObjectModel of registered
// items — usable directly as a Repeater model. Per-item behavior
// (clicks, menus, icon rendering) lives in TrayItem.qml; this file is
// just the row.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-03  Created.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.core

Item {
    id: root

    readonly property bool hasItems: SystemTray.items.values.length > 0

    visible: hasItems
    implicitWidth: visible ? row.implicitWidth : 0
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        spacing: Theme.spacingMedium

        Repeater {
            model: SystemTray.items

            TrayItem {}
        }
    }
}
