//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/SectionLabel.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A small, muted "eyebrow"-style header for grouping rows inside a
// dropdown (e.g. "PAIRED DEVICES", "NEW DEVICES"). Replaces the old
// pattern of a plain bold Text at the SAME size as the rows below it —
// which reads as "another row" rather than "a section boundary."
// Genuine typographic hierarchy: smaller and muted-colored, not bigger
// and bolder, is what actually separates a header from its content —
// same convention Plasma/GNOME/macOS system menus use.
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
// widgets/TopBar/Wifi.qml, widgets/TopBar/Bluetooth.qml. Any future
// dropdown with more than one logical group of rows should use this
// instead of a bare bold Text.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Callers fail to resolve the type. Revert to a plain bold Text label
// (loses the size/color hierarchy this file exists to add).
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// SIZE IS SMALLER THAN BODY TEXT, ON PURPOSE — not bold-at-the-same-
// size. `Theme.fontSize` has no separate "small" token in this
// project's Theme yet, so this scales down by a fixed ratio (0.85)
// rather than adding a new Theme property for a single consumer —
// consistent with Settings.qml's "don't add speculatively" rule
// applied to Theme.qml too. If a THIRD place ever wants "small text,"
// that's the signal to promote a real `Theme.fontSizeSmall` token.
//
// UPPERCASE + LETTER-SPACING: `font.capitalization: Font.AllUppercase`
// plus `font.letterSpacing` is what gives this the "eyebrow label"
// read (small-caps-adjacent styling) rather than just "smaller text."
// Both are plain QtQuick Text properties, nothing font-file-dependent.
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
import qs.core

Text {
    id: root

    color: Theme.colorMuted
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(Theme.fontSize * 0.85)
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1
    font.bold: true

    // Breathing room above the section — headers need MORE separation
    // from what's above them than from the rows they introduce, which
    // is what actually reads as grouping (rows below sit close; the
    // gap above signals "new group starts here").
    topPadding: Theme.spacingSmall
}
