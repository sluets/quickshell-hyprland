//=============================================================================
// FILE
//=============================================================================
//
// core/Signals.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A central signal bus — a place to declare signals that multiple
// unrelated widgets need to react to, without wiring every widget directly
// to every other widget.
//
//=============================================================================
// STATUS: ACTIVE (as of 2026-07-05)
//=============================================================================
//
// First real signal: togglePowerScreen(). widgets/TopBar/SystemMenu.qml
// (one instance per monitor, inside each bar) emits it when the arch icon
// is clicked; widgets/PowerMenu/PowerScreen.qml (a single top-level window
// instantiated once in shell.qml) listens and toggles itself. Neither file
// holds a reference to the other — this bus is what makes that possible.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell (for the Singleton type)
// QtQuick
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/SystemMenu.qml (emits togglePowerScreen)
// widgets/PowerMenu/PowerScreen.qml (listens for togglePowerScreen)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// SystemMenu.qml's icon click and PowerScreen.qml's Connections block both
// fail to resolve `Signals` — the arch icon would stop opening the power
// screen (the SUPER+P keybind and `qs ipc call power toggle` would still
// work, since those call PowerScreen directly via shell.qml).
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// Don't add signals here speculatively "just in case." Add a signal only
// when a second widget actually needs to react to something a first widget
// did — togglePowerScreen is the first real case of that; direct property
// bindings (the theme pattern) are still simpler and easier to trace for
// everything else in this project.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Activated — added togglePowerScreen(), the first signal ever
//             declared here. See widgets/PowerMenu/PowerScreen.qml's DESIGN
//             NOTES for the full reasoning.
// 2026-07-01  Converted to `pragma Singleton`, matching Theme/Settings/
//             Globals. Not wired into anything yet at that point.
//
//=============================================================================

pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Emitted to open/close widgets/PowerMenu/PowerScreen.qml. Emitted by
    // widgets/TopBar/SystemMenu.qml's arch-icon click; PowerScreen.qml
    // listens and calls its own toggle().
    signal togglePowerScreen()

    // Emitted by the gear menu's "Open Settings…" entry; consumed by
    // widgets/Settings/SettingsWindow.qml. Added 2026-07-09 (Fable 5).
    signal toggleSettingsWindow()
}
