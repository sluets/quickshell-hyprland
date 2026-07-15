//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/Launcher.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The app launcher. A search field that scrolls down out of the MIDDLE
// of the bar (same BarPopout pattern as every other dropdown), opened by
// a Hyprland global shortcut or an IPC call, never by clicking anything
// in the bar (there's nothing to click — this widget draws nothing in
// the bar itself; it's an invisible anchor).
//
// NOTE (2026-07-05): the GlobalShortcut/IpcHandler registrations no
// longer live in this file — with one bar (and so one of these anchors)
// per monitor, per-instance registration would collide. shell.qml
// registers them ONCE and routes to the focused monitor's instance via
// the public toggle()/close() functions below.
//
// Behavior:
//
// • Opens empty — NO apps are listed until you start typing. Deliberate.
// • Typing filters the installed .desktop applications (via Quickshell's
//   built-in DesktopEntries) with a small ranked matcher that tolerates
//   simple typos — see DESIGN NOTES ("Matching / typo tolerance").
// • Enter launches the selected (top by default) result. Up/Down/Tab
//   move the selection. Escape closes. Clicking a row also launches.
//   Clicking anywhere outside dismisses (standard BarPopout behavior).
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// QtQuick.Layouts
// Quickshell                    (DesktopEntries, Quickshell.iconPath,
//                                Quickshell.execDetached)
// core/Theme.qml, core/Settings.qml (singletons via `import qs.core`)
// widgets/TopBar/BarPopout.qml  (neighboring file — needs its "center"
//                                alignment, added 2026-07-04)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/TopBar.qml (instantiated once PER BAR — i.e. once per
// monitor — centered; TopBar exposes toggle/close wrappers that
// shell.qml routes the global hotkey and IPC through)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No app launcher, and TopBar fails to load (its routing functions
// reference the `launcher` id). Remove the instantiation and those
// functions together; shell.qml's `shell:launcher` shortcut and
// `launcher` IPC target would then need their handlers removed too.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY THIS IS A BAR WIDGET AND NOT ITS OWN WINDOW:
//
// The requirement is "scrolls down out of the middle of the bar" — which
// is exactly what BarPopout already does for every other dropdown. So
// this rides the same component: TopBar instantiates this widget
// centered, the widget itself is a 1px-wide invisible Item spanning the
// bar's height, and the popout hangs from it with the "center"
// alignment. One pattern, one place to fix it. A side benefit under
// multi-monitor: because the popout is anchored to ITS bar's window, an
// instance opened on monitor 2's bar is automatically ON monitor 2 —
// no output math anywhere.
//
// The 1px width matters: the anchor rect BarPopout computes comes from
// this item's geometry, and a zero-area anchor rect is degenerate under
// the Wayland xdg-positioner rules this maps to. 1×barHeight keeps the
// math (rect bottom lands exactly at the bar's bottom edge) while
// drawing nothing.
//
// MATCHING / TYPO TOLERANCE:
//
// Ranked scoring, best match first, all standard techniques:
//
//   100  name starts with the query           ("fire" -> Firefox)
//    90  any word in the name starts with it  ("code" -> VS Code)
//    80  name contains it anywhere            ("edit" -> GIMP Image Editor)
//    50  query is an in-order subsequence     ("frfx" -> Firefox — covers
//         of the name                          typos where you MISSED keys)
//    40  query is one typo away from the      ("forefox" -> Firefox —
//         name's prefix (one wrong character   covers wrong-key and
//         or two adjacent characters swapped;  swapped-key typos; only
//         a bounded edit-distance-1 check)     checked for queries >= 3
//                                              chars so 1-2 char queries
//                                              don't match everything)
//
// Ties break alphabetically. Results are capped at
// Settings.launcherMaxResults so a 2-char query doesn't unroll a
// 40-row popup. What this does NOT do: frequency/recency ranking (no
// launch-count database — deliberately out of
// scope for now), and no multi-typo correction (edit distance > 1 —
// that's the "don't invent it" line; distance-1 covers the common
// fat-finger cases without false positives).
//
// SELECTION STATE LIVES HERE, NOT IN THE DELEGATES:
//
// `selectedIndex` is a single property on this widget; rows highlight
// when their index matches. Keyboard (Up/Down/Tab) and mouse hover both
// write the same property, so there's never a "keyboard says row 2,
// mouse says row 4" split-highlight state.
//
// runInTerminal APPS:
//
// .desktop entries with Terminal=true (htop, etc.) can't just be
// execute()'d — they'd launch with no terminal and die instantly. Those
// get wrapped in Settings.launcherTerminalCommand (default kitty, since
// that's the installed terminal). Everything else goes through
// entry.execute(), which handles the .desktop Exec field codes properly.
//
// THE HOTKEY / IPC (lives in shell.qml — see its DESIGN NOTES):
//
//     hl.bind(mainMod .. " + R", hl.dsp.global("shell:launcher"))
//     qs ipc call launcher toggle
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Multi-monitor: GlobalShortcut + IpcHandler MOVED OUT to
//             shell.qml (single registration, focused-monitor
//             routing — one of these now exists per bar/monitor).
//             Added close(). No other behavior change.
// 2026-07-04  Created. First centered popout, first keyboard-driven
//             widget, first use of DesktopEntries in the project.
//             Written offline against verified Quickshell API usage
//             (DesktopEntries.applications.values,
//             entry.execute()/command/runInTerminal,
//             Quickshell.iconPath).
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

Item {
    id: root

    // Invisible anchor: 1px wide (NOT zero — see DESIGN NOTES), bar
    // height tall so BarPopout's anchor-rect math puts the popout's top
    // exactly at the bar's bottom edge. TopBar centers this in the bar.
    width: 1
    height: Theme.barHeight

    // ---- Selection + results state (see DESIGN NOTES) ----
    property int selectedIndex: 0
    property var results: []

    // ---- Public interface (called via TopBar by shell.qml) ----
    function toggle(): void {
        popout.open = !popout.open;
    }

    function close(): void {
        popout.open = false;
    }

    // ---- Matching (see DESIGN NOTES, "Matching / typo tolerance") ----

    // True if a and b (same length) differ by exactly one substituted
    // character, or exactly one swap of two adjacent characters.
    function isOneTypo(a: string, b: string): bool {
        const diffs = [];
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i])
                diffs.push(i);
        }
        if (diffs.length === 1)
            return true; // one wrong character
        return diffs.length === 2
            && diffs[1] === diffs[0] + 1
            && a[diffs[0]] === b[diffs[1]]
            && a[diffs[1]] === b[diffs[0]]; // adjacent swap
    }

    function scoreEntry(q: string, name: string): int {
        const n = name.toLowerCase();
        if (n.startsWith(q))
            return 100;
        const words = n.split(/[\s\-_./()]+/);
        for (const w of words) {
            if (w.startsWith(q))
                return 90;
        }
        if (n.includes(q))
            return 80;
        // In-order subsequence: every query char appears in the name,
        // in order, possibly with gaps ("frfx" in "firefox").
        let qi = 0;
        for (let i = 0; i < n.length && qi < q.length; i++) {
            if (n[i] === q[qi])
                qi++;
        }
        if (qi === q.length)
            return 50;
        // One-typo check against the name's same-length prefix. Only
        // for queries of 3+ chars — at 1-2 chars nearly everything is
        // "one typo away" from something.
        if (q.length >= 3 && q.length <= n.length && isOneTypo(q, n.slice(0, q.length)))
            return 40;
        return 0;
    }

    function computeResults(rawQuery: string): var {
        const q = rawQuery.trim().toLowerCase();
        if (q.length === 0)
            return []; // nothing shown until typing starts — deliberate
        const scored = [];
        for (const entry of DesktopEntries.applications.values) {
            if (entry.noDisplay)
                continue;
            const s = root.scoreEntry(q, entry.name);
            if (s > 0)
                scored.push({ entry: entry, score: s });
        }
        scored.sort((a, b) => (b.score - a.score) || a.entry.name.localeCompare(b.entry.name));
        return scored.slice(0, Settings.launcherMaxResults).map(x => x.entry);
    }

    function launch(entry: var): void {
        popout.open = false;
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: [...Settings.launcherTerminalCommand, ...entry.command]
            });
        else
            entry.execute();
    }

    function launchSelected(): void {
        if (root.results.length > 0)
            root.launch(root.results[Math.min(root.selectedIndex, root.results.length - 1)]);
    }

    function moveSelection(delta: int): void {
        if (root.results.length === 0)
            return;
        root.selectedIndex = (root.selectedIndex + delta + root.results.length) % root.results.length;
    }

    // ---- The popout itself ----

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "center"

        // Reset to a blank search on every open. This handler runs IN
        // ADDITION to BarPopout's own internal onOpenChanged (QML signal
        // handlers at the instantiation site don't replace the
        // component's — both connections fire), and the internal one
        // (which sets `visible`) is connected first, so the window is
        // already visible when focus is forced here.
        onOpenChanged: {
            if (open) {
                searchField.text = "";
                root.results = [];
                root.selectedIndex = 0;
                searchField.forceActiveFocus();
            }
        }

        // ---- Search field ----
        Rectangle {
            // implicitWidth (not just Layout.minimumWidth) because
            // BarPopout sizes itself from the content column's
            // implicitWidth — this is what makes the whole popout
            // launcherWidth wide.
            implicitWidth: Settings.launcherWidth
            Layout.fillWidth: true
            implicitHeight: searchField.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: Theme.colorSurface

            TextInput {
                id: searchField
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMedium
                anchors.rightMargin: Theme.spacingMedium
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                clip: true
                focus: true

                onTextChanged: {
                    root.results = root.computeResults(text);
                    root.selectedIndex = 0;
                }

                Keys.onDownPressed: root.moveSelection(1)
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onTabPressed: root.moveSelection(1)
                Keys.onBacktabPressed: root.moveSelection(-1)
                Keys.onReturnPressed: root.launchSelected()
                Keys.onEnterPressed: root.launchSelected()
                Keys.onEscapePressed: popout.open = false

                // Ghost prompt, only while empty.
                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: searchField.text.length === 0
                    text: "Search apps…"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }

        // ---- Results ----
        // Empty until there's a query (computeResults returns [] for "").
        // Rows are built inline rather than reusing MenuButton because
        // these need an image icon (from the .desktop entry's Icon=) and
        // a two-line name+comment layout, neither of which MenuButton's
        // glyph+label shape fits.
        Repeater {
            model: root.results

            Rectangle {
                id: row
                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: rowContent.implicitHeight + Theme.spacingSmall * 2
                radius: Theme.radiusMedium
                color: index === root.selectedIndex ? Theme.colorHover : "transparent"

                RowLayout {
                    id: rowContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.spacingSmall
                    anchors.rightMargin: Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingMedium

                    Image {
                        Layout.preferredWidth: Theme.fontSize * 2
                        Layout.preferredHeight: Theme.fontSize * 2
                        sourceSize.width: Theme.fontSize * 2
                        sourceSize.height: Theme.fontSize * 2
                        source: Quickshell.iconPath(row.modelData.icon, "image-missing")
                        asynchronous: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            elide: Text.ElideRight
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: row.modelData.comment ?? ""
                            elide: Text.ElideRight
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.8)
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = row.index
                    onClicked: root.launch(row.modelData)
                }
            }
        }
    }
}
