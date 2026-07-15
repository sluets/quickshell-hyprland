//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/Separator.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A small "|" divider. Meant to be
// dropped between adjacent pieces of information anywhere in the bar —
// currently used inside Clock.qml (between date and time), and available
// for future modules (Volume, Battery, Bluetooth, Tray) to reuse the same
// way once they exist.
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
// widgets/TopBar/Clock.qml (neighboring file, no import needed)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Anything instantiating `Separator {}` will fail to resolve the type.
// Purely cosmetic otherwise — no shared state depends on this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// Deliberately a literal "|" character (Text), not a drawn Rectangle
// line — the reference screenshot's separators are monospace glyphs, not
// custom-drawn dividers, so matching that exactly was simpler and looked
// more consistent than reimplementing it as a shape. If the font ever
// changes to something where "|" renders oddly (too tall/short relative
// to the surrounding text), revisit this — a thin Rectangle would be the
// fallback.
//
// Uses `Theme.colorMuted` rather than `Theme.colorForeground` so
// separators visually recede behind the content they're separating,
// same intent as the muted/empty-state color used elsewhere.
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

Text {
    text: "|"
    color: Theme.colorMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
}
