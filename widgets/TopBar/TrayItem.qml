//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/TrayItem.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// One tray icon. Left-click activates the app (what left-clicking the
// icon in any other bar does); right-click opens the app's own tray
// menu if it publishes one, or falls back to secondaryActivate if not.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// Quickshell                      (QsMenuAnchor, Edges)
// Quickshell.Widgets              (IconImage)
// Quickshell.Services.SystemTray  (SystemTrayItem type)
// core/Theme.qml                  (singleton via `import qs.core`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/Tray.qml (as the Repeater delegate)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Tray.qml's Repeater fails to load and the tray disappears.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// MENUS VIA QsMenuAnchor: tray menus arrive as DBusMenu handles
// (modelData.menu). QsMenuAnchor hands the handle back to the platform
// to display at our anchor — the menu renders in native style, NOT this
// project's theme. That's a deliberate v1 tradeoff: the alternative
// is walking the menu tree yourself with
// QsMenuOpener and rebuilding every entry/submenu/checkbox as themed
// QML — a whole popout of its own. If native-styled tray menus grate,
// that's the upgrade path; the handle plumbing here stays the same.
//
// ICONS VIA IconImage (Quickshell.Widgets): renders the icon name/pixmap
// the app publishes. No recoloring — tray icons are arbitrary app art,
// and tinting them universally looks
// wrong with this project's flat grey bar.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-03  Created.
//
//=============================================================================

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.core

MouseArea {
    id: root

    required property SystemTrayItem modelData

    implicitWidth: Theme.fontSize + Theme.spacingSmall
    implicitHeight: Theme.fontSize + Theme.spacingSmall

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            modelData.activate();
        } else {
            if (modelData.hasMenu)
                menuAnchor.open();
            else
                modelData.secondaryActivate();
        }
    }

    IconImage {
        anchors.fill: parent
        source: root.modelData.icon
    }

    QsMenuAnchor {
        id: menuAnchor
        menu: root.modelData.menu

        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
    }
}
