//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/Workspaces.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Shows one indicator per currently-existing Hyprland workspace (not a
// fixed numbered range — only workspaces that actually exist show up
// here), highlighting whichever one is focused and flagging urgent ones.
// Display-only — see DESIGN NOTES for why click-to-switch was removed.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// QtQuick.Layouts     (for RowLayout)
// Quickshell.Hyprland  (Quickshell's built-in Hyprland IPC integration —
//                       see DESIGN NOTES for why this isn't a custom
//                       services/Hyprland.qml file)
// core/Theme.qml      (singleton, via `import qs.core`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/TopBar.qml (instantiated directly — no import needed,
// since Quickshell auto-imports uppercase-named neighboring files in the
// same folder)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// TopBar loses its workspace indicator; everything else in the bar is
// unaffected. Nothing else depends on this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY THIS TALKS TO Quickshell.Hyprland DIRECTLY, NOT A services/ FILE:
//
// See docs/PROBLEMS_AND_FIXES.md's "Almost built a custom Hyprland
// service that already exists" entry. Short version: Quickshell ships a
// first-party `Quickshell.Hyprland` module with a reactive `Hyprland`
// singleton — no hand-rolled IPC parsing needed, so there's nothing for
// a wrapper service to add yet.
//
// WHY ONLY EXISTING WORKSPACES ARE SHOWN, NOT A FIXED 1..N RANGE:
//
// An earlier version showed a fixed `Settings.workspaceCount` range
// (1..5) regardless of whether each workspace actually existed, dimming
// the empty ones. Changed to only render `Hyprland.workspaces.values` —
// i.e. exactly the workspaces that currently exist across all monitors
// — because that's what was actually wanted: with two monitors and one
// active workspace on each, this now shows exactly "1 2", not "1 2 3 4
// 5" with three dimmed placeholders. `Settings.workspaceCount` was
// removed from core/Settings.qml since nothing reads it anymore.
//
// This does mean the indicator list length changes as workspaces are
// created/destroyed, rather than staying fixed — that's intentional now,
// not a bug.
//
// WHY THERE'S NO CLICK-TO-SWITCH ANYMORE:
//
// The original version dispatched `Hyprland.dispatch("workspace " + id)`
// on click. In practice this failed for any workspace other than the
// currently focused one, with a Lua-syntax error from Hyprland's IPC
// layer (`quickshell.hyprland.ipc: Dispatch request "workspace 4" failed
// ... dispatch in lua is a shorthand for hl.dispatch(...), your syntax
// might need to be updated`) — see docs/PROBLEMS_AND_FIXES.md for the
// full error text. Rather than chase that down, click-to-switch was
// removed outright: workspace switching happens via Hyprland keybinds
// day-to-day, so this widget is now purely a status display. If
// click-to-switch is wanted again later, that error is the starting
// point — it points at a Hyprland/Quickshell dispatch-syntax mismatch,
// not anything specific to this widget.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-01  Bumped indicator spacing from Theme.spacingSmall to
//             Theme.spacingLarge (wider visual gap between workspace
//             numbers).
// 2026-07-01  Switched from a fixed 1..workspaceCount range to only
//             showing workspaces that actually exist
//             (`Hyprland.workspaces.values`). Removed click-to-switch
//             (MouseArea + dispatch) — see DESIGN NOTES for the error
//             that caused this. Removed the now-unused empty/muted
//             color state along with it.
// 2026-07-01  Initial version. Fixed 1..workspaceCount range, click to
//             switch, focused/urgent/occupied/empty color states.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.core

RowLayout {
    id: root

    spacing: Theme.spacingLarge

    Repeater {
        // Only workspaces that currently exist — see DESIGN NOTES above.
        // Quickshell keeps this sorted by id already.
        model: Hyprland.workspaces.values

        Text {
            id: wsText
            required property var modelData

            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id
            readonly property bool isUrgent: modelData.urgent

            text: modelData.id

            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: isFocused

            color: isFocused
                ? Theme.colorAccent
                : (isUrgent ? Theme.colorUrgent : Theme.colorForeground)
        }
    }
}
