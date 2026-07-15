//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/SettingsMenu.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Gear icon, rightmost item in the bar. Click for a dropdown with the
// options the maintainer asked for a "settings menu" for:
//
//   • Appearance — pick which theme is active (radio list, built from
//     core/Theme.qml's `themes` map — add a theme there and it appears
//     here automatically, nothing to change in this file)
//   • Wallpapers — "Cache thumbnails" toggle
//     (UserPrefs.wallpaperCachingEnabled — see WallpaperPicker.qml)
//   • Clock — "24-hour time" / "Show seconds" toggles
//     (UserPrefs.clockUse24Hour / clockShowSeconds — see Clock.qml)
//
// Every option here reads/writes core/UserPrefs.qml, which persists to
// disk — so choices survive a shell restart. Same dropdown-menu pattern
// as every other bar popout: BarPopout + MenuButton + MenuDivider (see
// ARCHITECTURE.md's "dropdown menu pattern" checklist item 7 — this file
// is entirely built from that, no new UI primitives).
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// core/Theme.qml, core/UserPrefs.qml (singletons via `import qs.core`)
// widgets/TopBar/BarPopout.qml    (neighboring file)
// widgets/TopBar/MenuButton.qml   (neighboring file)
// widgets/TopBar/MenuDivider.qml  (neighboring file)
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
// TopBar loses the gear icon and the settings dropdown. Theme switching,
// wallpaper caching, and clock display all still work via their existing
// mechanisms (hand-editing core/Theme.qml's map lookup default, hand-
// editing user-prefs.json, etc.) — this file is a UI on top of
// core/UserPrefs.qml, not the thing that makes those options exist.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// EVERY ROW IS A MenuButton — no new toggle/radio component built for
// this. Theme rows reuse the same "●/○" filled/empty-dot convention
// Wifi.qml already uses for "connected network"; caching/clock toggles
// reuse "■/□" filled/empty-box, same idea as WallpaperPicker's Shuffle
// checkbox but through MenuButton's icon column instead of a bespoke
// Rectangle, since these rows don't need anything MenuButton doesn't
// already do (full-width clickable row, icon + label). Keeps this file
// small and means a future MenuButton improvement (e.g. real hover
// animation) applies here for free.
//
// ■/□ AND ●/○ ARE PLAIN UNICODE, NOT NERD FONT GLYPHS — same reasoning
// as SystemMenu.qml's old ⟳/↻/⏻ and Wifi.qml's ●/○: these render through
// any font, so there's nothing to verify against a Nerd Font glyph table.
// The one NEW glyph this file introduces is the gear icon itself
// (`\uf013`, nf-fa-cog) — this is the Font Awesome "cog" codepoint,
// about as standardized as Nerd Font codepoints get (same certainty
// tier as the arch icon `\uf303` already in use), but it's still new to
// this project, so give it a glance on first run the way any new glyph
// gets checked here.
//
// THEME LIST IS GENERATED, NOT HARDCODED:
//
// `Object.keys(Theme.themes)` — see core/Theme.qml's DESIGN NOTES. Adding
// a third theme means touching Theme.qml only; this file's Repeater picks
// it up with no changes.
//
// WHY THIS DOESN'T LIVE IN core/UserPrefs.qml:
//
// UserPrefs.qml is data + persistence, no UI, same split as Theme.qml
// (data) vs. whatever reads Theme.colorBackground (UI). Keeping the
// dropdown itself here, as an ordinary bar widget, means UserPrefs.qml
// stays testable/reasoned-about independent of any particular menu
// layout — the same reasoning ARCHITECTURE.md gives for why Theme.qml
// holds no layout logic.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  (Fable 5) Popout shifted left via BarPopout's new
//             xOffset (token-derived — see the comment at the
//             property) so its right fillet clears the bar's rounded
//             corner instead of colliding with it.
// 2026-07-05  Created. First consumer of core/UserPrefs.qml's write
//             surface (setThemeName/setWallpaperCachingEnabled/
//             setClockUse24Hour/setClockShowSeconds) and of
//             core/Theme.qml's new `themes` map.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        text: "\uf013" // nf-fa-cog — see DESIGN NOTES
        color: (popout.open || mouseArea.containsMouse) ? Theme.colorAccent : Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        id: mouseArea
        anchors.fill: icon
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popout.open = !popout.open
    }

    BarPopout {
        id: popout
        anchorItem: icon
        alignment: "right"
        // Shift left so the RIGHT fillet clears the bar's rounded
        // corner (found live 2026-07-11): the gear sits spacingMedium
        // from the bar's end, and a right-aligned popout's window
        // extends one fillet radius PAST its anchor — with default
        // tokens (fillet 10, barRadius 10, margin 8) the fillet's
        // tangent point landed 2 px beyond the bar itself, its arc
        // colliding with the bar's corner arc instead of meeting
        // straight border. Terms, not a magic number, so it tracks
        // token changes: back the window's right edge off by the
        // corner arc's span plus a spacingSmall of straight border
        // for the fillet to land on. (The principled alternative —
        // flushToBarEdge, which drops the right fillet and ends the
        // panel flush with the bar's end — was considered; the
        // maintainer prefers the fillet, moved inward.)
        xOffset: -(Theme.barBorderFillet + Theme.barRadius
                   - Theme.spacingMedium + Theme.spacingSmall)

        // ---- Appearance: theme picker ----
        // Durable settings (theme, font scale) live in the settings
        // WINDOW behind this button, where changes go through the
        // ConfigManager Apply transaction. This popout keeps only the
        // quick live toggles below — the transient/durable split.
        MenuButton {
            Layout.fillWidth: true
            Layout.minimumWidth: 220
            icon: "\uf013"
            text: "Open Settings…"
            onClicked: {
                popout.open = false;
                Signals.toggleSettingsWindow();
            }
        }

        MenuDivider { Layout.fillWidth: true }

        // ---- Wallpapers ----
        Text {
            text: "Wallpapers"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        MenuButton {
            Layout.fillWidth: true
            icon: UserPrefs.wallpaperCachingEnabled ? "■" : "□"
            text: "Cache Thumbnails"
            onClicked: UserPrefs.setWallpaperCachingEnabled(!UserPrefs.wallpaperCachingEnabled)
        }

        MenuDivider { Layout.fillWidth: true }

        // ---- Clock ----
        Text {
            text: "Clock"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        MenuButton {
            Layout.fillWidth: true
            icon: UserPrefs.clockUse24Hour ? "■" : "□"
            text: "24-Hour Time"
            onClicked: UserPrefs.setClockUse24Hour(!UserPrefs.clockUse24Hour)
        }

        MenuButton {
            Layout.fillWidth: true
            icon: UserPrefs.clockShowSeconds ? "■" : "□"
            text: "Show Seconds"
            onClicked: UserPrefs.setClockShowSeconds(!UserPrefs.clockShowSeconds)
        }
    }
}
