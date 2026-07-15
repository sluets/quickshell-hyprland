//=============================================================================
// FILE
//=============================================================================
//
// core/Globals.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Holds shared RUNTIME state — values that change while the shell is
// running and that more than one widget might care about. Examples this
// will hold once services exist: current volume level, battery percentage,
// active Hyprland workspace, network connection status.
//
// This is NOT currently doing anything — it's a documented placeholder.
// It's set up now as a singleton so the pattern (any file can reach
// shared state via `import qs.core`) is established before we need it,
// rather than bolting it on awkwardly later.
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
// Nothing yet — no widget currently reads from this.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Nothing breaks today — nothing depends on it yet. Once services/ files
// start writing into this and widgets start reading from it, removing it
// would break whatever's been wired up by that point. Check this file's
// REVISION HISTORY below before assuming it's still safe to delete.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY THIS EXISTS SEPARATELY FROM Settings.qml:
// Settings = things a person deliberately configures (rarely changes).
// Globals  = things the system reports that change on their own
//            (battery %, volume, network state — updates continuously
//            while the shell runs).
//
// Mixing these two together gets confusing fast — a widget reading
// `Settings.volume` would look like it's reading a user preference for
// default volume, when it's actually live system state. Keeping them in
// separate files keeps that distinction obvious just from the type name
// (`Settings.x` vs `Globals.x`).
//
// WHEN ADDING TO THIS FILE:
// The actual VALUE should usually be written by something in services/
// (e.g. services/Audio.qml would update Globals.volume when pipewire
// reports a change), not hardcoded here. This file just declares the
// property exists and its default/fallback value.
//
// NOW A SINGLETON — same reasoning as core/Theme.qml and
// core/Settings.qml. One consequence worth knowing for THIS file
// specifically: Quickshell instantiates singletons lazily, on first
// property access. If a future services/ file needs something in here
// to start running the moment the shell launches (not just whenever a
// widget happens to read a property), something needs to actively touch
// a property on this singleton early — don't assume it's "alive" just
// because the shell started.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-01  Converted to `pragma Singleton`. Still empty — no
//             properties defined yet. No longer instantiated by
//             shell.qml (see that file's DESIGN NOTES).
//
//=============================================================================

pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Intentionally empty as of 2026-07-01.
    // See DESIGN NOTES above for what belongs here once services exist.
}
