//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/MenuDivider.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A thin horizontal line for separating rows inside a dropdown menu
// (e.g. between SystemMenu.qml's power options) — the vertical
// counterpart to Separator.qml's "|", which separates things side by
// side instead of stacked.
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
// widgets/TopBar/SystemMenu.qml (neighboring file, no import needed).
// Intended for future dropdown menus (Wifi, Bluetooth, Volume) too.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Anything instantiating `MenuDivider {}` fails to resolve the type.
// Purely cosmetic otherwise — no shared state depends on this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// `Layout.fillWidth: true` is expected to be set by whoever instantiates
// this inside a ColumnLayout (see SystemMenu.qml), same convention as
// MenuButton.qml — this file doesn't set it itself since it isn't always
// used inside a ColumnLayout.
//
// Uses `Theme.colorMuted` — same color as SystemMenu's popup border, so
// the divider reads as "part of the same surface," not a separate
// element competing for attention.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-01  Initial version.
//
//=============================================================================

import QtQuick
import qs.core

Rectangle {
    implicitHeight: 1
    color: Theme.colorMuted
}
