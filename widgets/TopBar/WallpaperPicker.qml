//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/WallpaperPicker.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The wallpaper picker. A grid of square thumbnails that scrolls down
// out of the MIDDLE of the bar (same BarPopout "center" pattern as the
// launcher), opened by a Hyprland global shortcut (SUPER+W) or IPC —
// never by clicking anything in the bar (this widget draws nothing in
// the bar; it's an invisible anchor, exactly like Launcher.qml).
//
// NOTE (2026-07-05): the GlobalShortcut/IpcHandler registrations no
// longer live in this file — with one bar (and so one of these anchors)
// per monitor, per-instance registration would collide. shell.qml
// registers them ONCE and routes to the focused monitor's instance via
// the public functions below (toggle/close/setFromIpc/listPaths/
// randomFromIpc).
//
// Behavior:
//
// • On open, rescans the wallpaper folder and asks `awww query` which
//   wallpaper is current. Both are async Processes; the grid fills in
//   a frame or two later.
// • Click a thumbnail (or arrow-key to it and press Enter) → applies it
//   on ALL outputs via `awww img` with the transition configured in
//   Settings, then closes.
// • The currently-active wallpaper gets a corner badge. Keyboard/
//   hover selection gets an accent border.
// • "Random" button in the header picks one at random (also exposed
//   over IPC for scripting/keybinding), and a "Shuffle" checkbox
//   randomizes the GRID ORDER — re-rolled on every open — so a big
//   collection doesn't always show the same alphabetical top rows
//   (IPC list() stays sorted regardless; see the state comments).
// • If awww-daemon isn't running, a warning row appears instead of the
//   pick silently doing nothing — see DESIGN NOTES.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// QtQuick.Layouts
// Quickshell                    (Quickshell.execDetached, Quickshell.env)
// Quickshell.Io                 (Process, StdioCollector)
// core/Theme.qml, core/Settings.qml (singletons via `import qs.core`)
// widgets/TopBar/BarPopout.qml  (neighboring file — "center" alignment)
// External: `awww` + `awww-daemon` (official repo package), `sh`,
//           GNU `find` (coreutils/findutils — always present on Arch)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/TopBar.qml (instantiated once PER BAR — i.e. once per
// monitor — centered; coexists with the Launcher's centered anchor.
// TopBar exposes wrapper functions that shell.qml routes the
// global hotkey and the `wallpapers` IPC target through.)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No wallpaper picker, and TopBar fails to load (its routing functions
// reference the `wallpaperPicker` id). Remove the instantiation and
// those functions together; shell.qml's `shell:wallpapers`
// shortcut and `wallpapers` IPC target would then need their handlers
// removed too. `awww` itself still works from the terminal.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// SCOPE CUTS (deliberate — from the original build plan, since archived):
//
// • No dynamic color-scheme-from-wallpaper. Separate large feature.
// • No per-monitor picking in v1 — one pick sets ALL outputs (plain
//   `awww img`, no `-o`). Per-output needs a picker-inside-the-picker;
//   that's v2 if ever. (The picker WINDOW is per-monitor now — it opens
//   on whichever monitor is focused — but a pick still applies
//   everywhere.)
// • No thumbnail GENERATION — the maintainer owns that via imagemagick.
//   A wallpaper without a thumb is NOT skipped: the cell falls back to
//   the full image with a capped sourceSize + PreserveAspectCrop. Costs
//   a slightly bigger decode for that one cell, never hides a wallpaper.
//
// FILE LISTING — Process + find, NOT FolderListModel:
//
// Qt.labs.folderlistmodel remains UNVERIFIED under Quickshell 0.3 —
// until someone runs that 2-minute test in testing/, this uses the
// guaranteed-to-work path: one `sh -c` Process running `find` over both
// the wallpaper dir and the thumbs dir, with marker lines separating
// the two listings. Same Process+StdioCollector pattern as
// services/Network.qml. The dirs are passed as $1/$2 arguments — never
// interpolated into the script string — so paths with spaces/quotes
// can't break or inject anything.
//
// THUMBNAIL MAPPING:
//
// Thumbs live in Settings.wallpapersThumbDir (a subdir of the wallpaper
// folder, default ".thumbs") and are matched by BASENAME WITHOUT
// EXTENSION — so sunset.jpg ↔ .thumbs/sunset.jpg, .thumbs/sunset.png,
// or .thumbs/sunset.webp all work. imagemagick pipelines often change
// the extension; requiring an exact filename match would silently drop
// thumbs.
//
// GRID SCROLL PERFORMANCE (reuseItems + cacheBuffer):
//
// Two things make a 1000-thumb grid feel laggy: delegate churn
// (GridView destroys cells that scroll out of view and rebuilds
// object trees when they scroll back) and image reload cost when a
// rebuilt cell's pixmap fell out of Qt's global pixmap cache.
// `reuseItems: true` addresses the first — scrolled-out delegates go
// to a pool and get their `modelData` reassigned instead of being
// destroyed (this is why the delegate uses required properties, which
// reusable delegates update correctly). `cacheBuffer` addresses the
// second at the margins by keeping a few extra rows instantiated
// beyond the visible area, so wheel scrolling hits pre-built,
// pre-decoded cells. Decoded thumbs are small (120px cells ≈ 58KB
// each), so a few extra rows is noise memory-wise.
//
// THE DAEMON PROBLEM:
//
// awww is client/daemon: `awww img` does nothing (exits nonzero) if
// awww-daemon isn't running. execDetached gives no feedback, so a dead
// daemon would look like "clicking does nothing". The `awww query`
// Process (which runs on every open anyway, for the current-wallpaper
// highlight) doubles as the health check: nonzero exit → daemonOk=false
// → warning row in the popout. The daemon belongs to the compositor's
// autostart (hyprland.lua) — see docs/INTEGRATION_NOTES.md.
//
// GRID SIZING:
//
// BarPopout sizes itself from its content column's implicitWidth/
// Height, and GridView derives NO implicit size from its contents —
// same lesson as the launcher's search field. So the grid declares
// explicit implicit sizes: columns × cellSize wide, and
// min(rowsNeeded, wallpaperGridMaxRows) rows tall, clipped, scrolling
// natively (wheel + drag) beyond that. No scrollbar in v1; we still
// have no reusable scroll container.
//
// SELECTION STATE:
//
// Follows the launcher's rule — one source of truth. Here that's the
// GridView's own currentIndex: keyboard (arrows) moves it via
// moveCurrentIndex*(), mouse hover writes it, Enter applies it. No
// separate selectedIndex property needed because GridView already
// maintains exactly one. VISUALS: selection = accent border, active
// wallpaper = corner badge. Do NOT indicate selection with a cell
// fill — the thumbnail image covers all but a few px of the cell, so
// a fill is effectively invisible (first live test found this).
//
// THE HOTKEY / IPC (lives in shell.qml — see its DESIGN NOTES):
//
//     hl.bind(mainMod .. " + W", hl.dsp.global("shell:wallpapers"))
//     qs ipc call wallpapers toggle
//     qs ipc call wallpapers set /path/to/img
//     qs ipc call wallpapers get
//     qs ipc call wallpapers list
//     qs ipc call wallpapers random
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-13  wallpaperTransition{Type,Duration,Fps,Angle} migrated
//             from core/Settings.qml to UserPrefs.qml (per-page-
//             ownership rule) so the settings window's Appearance
//             page can stage/apply them. New: wallpaperTransitionPos
//             (grow/outer only) — stored as a semantic corner name
//             matching notifCorner/desktopClockCorner's vocabulary,
//             converted to swww's coordinate syntax in
//             _transitionPosArg() rather than stored as the literal
//             CLI value, so a wrong assumption about swww's coordinate
//             origin is a one-function fix, not another migration.
// 2026-07-05  RESET TO THIS BASE + PageUp/PageDown added. The caching/
//             preload/shuffle-interaction work attempted the same
//             night (skip-rescan-on-reopen, then a shuffle-freeze
//             workaround, then a startup preload pool with live
//             diagnostics) never actually solved the underlying lag —
//             see docs/PROBLEMS_AND_FIXES.md ("Wallpaper picker
//             thumbnail caching — investigated, not solved, reset to
//             base") for the full investigation, what was ruled out,
//             and the key finding: scrolling top-to-bottom-to-top
//             WITHOUT ever closing the popout also re-triggers
//             decoding, meaning this was never really about
//             open/close or shuffle at all — it's inherent to
//             GridView's own cacheBuffer/reuseItems recycling. Also
//             dropped the "Wallpapers · N" count from the header (no
//             longer wanted).
// 2026-07-05  Multi-monitor: GlobalShortcut + IpcHandler MOVED OUT to
//             shell.qml (single registration, focused-monitor
//             routing — one of these now exists per bar/monitor).
//             Added close()/setFromIpc()/listPaths()/randomFromIpc()
//             as the routed surface. Transition: now also passes
//             --transition-angle (new Settings.wallpaperTransitionAngle;
//             with the new "wipe" default type + 45°, applies sweep
//             from the top-right corner to the bottom-left). Grid:
//             reuseItems + cacheBuffer for smooth scrolling on large
//             collections (see DESIGN NOTES).
// 2026-07-04  (post-first-live-test) Added the Shuffle checkbox:
//             randomizes grid order (Fisher–Yates on a copy;
//             canonical `wallpapers` stays sorted for IPC list()),
//             re-rolled on every open so large collections don't
//             fossilize into the same visible top rows. New
//             `displayList` property is what the grid renders;
//             selection sync + Enter-to-apply follow display order.
//             Initial checkbox state from new
//             Settings.wallpaperShuffleDefault.
// 2026-07-04  (post-first-live-test) FIRST LIVE BUG: keyboard
//             selection was invisible — the colorHover cell fill only
//             showed through the thin gap around the thumbnail image.
//             Reworked: selection is now a 2px accent border, and the
//             active-wallpaper marker (which previously used the
//             accent border) moved to a corner badge dot, so the two
//             states are distinct even when overlapping. General
//             lesson (also in docs/PROBLEMS_AND_FIXES.md):
//             image-covered cells need border/overlay indicators,
//             never fills.
// 2026-07-04  (later, same session) Verified against real sources:
//             `awww query` line format confirmed from swww source
//             (BgInfo/BgImg Display impls) — parse is correct as
//             written. FIXED a latent bug found in the same read: the
//             awww client canonicalizes paths, so query returns
//             symlink-resolved paths; the scan now pipes wallpaper
//             paths through realpath so the current-wallpaper
//             highlight matches on symlinked wallpaper dirs
//             (stow-style setups) too.
// 2026-07-04  Created from a pre-written build plan (notes doc, since
//             deleted). Second
//             centered popout (after Launcher), first GridView, first
//             image-loading widget.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

Item {
    id: root

    // Invisible anchor: 1px wide (NOT zero — degenerate anchor rects
    // break the xdg-positioner math, see Launcher.qml), bar height tall
    // so the popout's top lands exactly at the bar's bottom edge.
    width: 1
    height: Theme.barHeight

    // ---- State ----
    // Array of { path, thumb, name } — thumb falls back to path itself
    // when no matching thumbnail exists (see DESIGN NOTES). ALWAYS
    // sorted: this is the canonical list, and IPC list() reads it so
    // scripting gets deterministic output regardless of the shuffle
    // toggle below.
    property var wallpapers: []
    // What the grid actually shows: either `wallpapers` as-is, or a
    // shuffled copy. Re-rolled on EVERY rescan (i.e. every open) while
    // shuffle is on — a one-time shuffle would just freeze a different
    // top row; a fresh order per open is what actually surfaces the
    // stuff that alphabetical order buries.
    property var displayList: []
    // Shuffle toggle (header checkbox). Initial state from Settings so
    // a preferred default survives restarts; flipping the checkbox is
    // session-local.
    property bool shuffled: Settings.wallpaperShuffleDefault
    // Absolute path of the wallpaper awww is currently displaying
    // (from `awww query`, or set optimistically when we apply one).
    property string currentWallpaper: ""
    // False when `awww query` exits nonzero — daemon not running.
    property bool daemonOk: true

    function rebuildDisplayList(): void {
        if (root.shuffled) {
            // Fisher–Yates on a copy — never mutate the canonical list.
            const a = [...root.wallpapers];
            for (let i = a.length - 1; i > 0; i--) {
                const j = Math.floor(Math.random() * (i + 1));
                [a[i], a[j]] = [a[j], a[i]];
            }
            root.displayList = a;
        } else {
            root.displayList = root.wallpapers;
        }
        root.syncSelectionToCurrent();
    }

    // ---- Path helpers ----
    // find/sh don't expand "~" — that's the login shell's job — so do
    // it here. Only a LEADING "~" (the only form worth supporting).
    function expandHome(p: string): string {
        if (p === "~")
            return Quickshell.env("HOME");
        if (p.startsWith("~/"))
            return Quickshell.env("HOME") + p.slice(1);
        return p;
    }

    readonly property string wallsDir: expandHome(UserPrefs.wallpapersPath)
    readonly property string thumbsDir: wallsDir + "/" + Settings.wallpapersThumbDir

    function baseNameNoExt(p: string): string {
        const base = p.slice(p.lastIndexOf("/") + 1);
        const dot = base.lastIndexOf(".");
        return dot > 0 ? base.slice(0, dot) : base;
    }

    // ---- Public interface (called via TopBar by shell.qml) ----
    function toggle(): void {
        popout.open = !popout.open;
    }

    function close(): void {
        popout.open = false;
    }

    function setFromIpc(path: string): void {
        root.apply(root.expandHome(path));
    }

    function listPaths(): string {
        return root.wallpapers.map(w => w.path).join("\n");
    }

    function randomFromIpc(): void {
        // IPC random works even with the popout closed, so make sure
        // there's a list to pick from on a fresh shell start.
        if (root.wallpapers.length === 0)
            root.rescan();
        else
            root.applyRandom();
    }

    // Converts UserPrefs.wallpaperTransitionPos's semantic corner name
    // (same vocabulary as notifCorner/desktopClockCorner) into swww's
    // actual --transition-pos syntax. "center" is the one keyword
    // confirmed in swww's own docs; the four corners are expressed as
    // percentage coordinates, assuming the standard top-left-origin
    // convention (0%,0% = top-left). ONLY grow/outer read this flag at
    // all — see apply() below.
    function _transitionPosArg(): string {
        switch (UserPrefs.wallpaperTransitionPos) {
        case "top-left": return "0%,0%";
        case "top-right": return "100%,0%";
        case "bottom-left": return "0%,100%";
        case "bottom-right": return "100%,100%";
        default: return "center";
        }
    }

    // ---- Actions ----
    function apply(path: string): void {
        if (!path)
            return;
        const args = [
            "awww", "img", path,
            "--transition-type", UserPrefs.wallpaperTransitionType,
            "--transition-duration", String(UserPrefs.wallpaperTransitionDuration),
            "--transition-fps", String(UserPrefs.wallpaperTransitionFps),
            // Only wipe/wave read the angle; awww ignores it for other
            // types, so passing it unconditionally is safe and keeps
            // the command in one shape.
            "--transition-angle", String(UserPrefs.wallpaperTransitionAngle)
        ];
        // --transition-pos is ONLY read by grow/outer (swww ignores it
        // for every other type, per swww-img(1)) — only added for
        // those two so an unrelated transition type never sees a flag
        // that means nothing to it.
        if (UserPrefs.wallpaperTransitionType === "grow"
                || UserPrefs.wallpaperTransitionType === "outer") {
            args.push("--transition-pos", root._transitionPosArg());
        }
        Quickshell.execDetached(args);
        // Optimistic — if the daemon is down we already showed the
        // warning row, and the next open re-queries the truth anyway.
        root.currentWallpaper = path;
        popout.open = false;
    }

    function applySelected(): void {
        if (root.displayList.length === 0)
            return;
        const i = Math.min(Math.max(grid.currentIndex, 0), root.displayList.length - 1);
        root.apply(root.displayList[i].path);
    }

    function applyRandom(): void {
        if (root.wallpapers.length === 0)
            return;
        // With 2+ wallpapers, never "randomly" re-pick the current one.
        let pool = root.wallpapers;
        if (pool.length > 1)
            pool = pool.filter(w => w.path !== root.currentWallpaper);
        root.apply(pool[Math.floor(Math.random() * pool.length)].path);
    }

    function rescan(): void {
        listProc.running = true;
        queryProc.running = true;
    }

    // Move the grid's selection to the current wallpaper (called after
    // scan/query results land and after any reorder, so opening the
    // picker starts "where you are" instead of at cell 0 — in whatever
    // order the grid is currently showing).
    function syncSelectionToCurrent(): void {
        const i = root.displayList.findIndex(w => w.path === root.currentWallpaper);
        grid.currentIndex = i >= 0 ? i : 0;
    }

    // ---- Folder scan (see DESIGN NOTES, "FILE LISTING") ----
    // One sh -c invocation lists both dirs with marker lines between.
    // Dirs are passed as $1/$2 — NEVER interpolated into the script.
    // Wallpaper paths are piped through realpath because the awww
    // CLIENT canonicalizes paths before sending them to the daemon
    // (verified in swww source, client/src/main.rs) — so `awww query`
    // reports symlink-RESOLVED paths, and the current-wallpaper
    // highlight (path equality) would silently never match on a
    // symlinked wallpapers dir (stow-style dotfiles) without this.
    // Extensions match what awww can actually display (minus the
    // exotic ones nobody keeps wallpapers in).
    Process {
        id: listProc

        command: ["sh", "-c",
            "echo ===WALLS===; " +
            "find -L \"$1\" -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' " +
            "-o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \\) " +
            "2>/dev/null | xargs -r -d '\\n' realpath | sort -f; " +
            "echo ===THUMBS===; " +
            "find -L \"$2\" -maxdepth 1 -type f 2>/dev/null | sort -f",
            "sh", root.wallsDir, root.thumbsDir]

        stdout: StdioCollector {
            onStreamFinished: {
                const walls = [];
                const thumbByBase = {};
                let section = "";
                for (const rawLine of text.split("\n")) {
                    const line = rawLine.trim();
                    if (line === "===WALLS===") {
                        section = "walls";
                        continue;
                    }
                    if (line === "===THUMBS===") {
                        section = "thumbs";
                        continue;
                    }
                    if (line.length === 0)
                        continue;
                    if (section === "walls")
                        walls.push(line);
                    else if (section === "thumbs")
                        thumbByBase[root.baseNameNoExt(line)] = line;
                }
                root.wallpapers = walls.map(p => ({
                    path: p,
                    thumb: thumbByBase[root.baseNameNoExt(p)] ?? p,
                    name: root.baseNameNoExt(p)
                }));
                // Rebuild (and, if shuffle is on, re-roll) the display
                // order — this runs on every open since open triggers
                // a rescan.
                root.rebuildDisplayList();
            }
        }
    }

    // ---- Current wallpaper + daemon health (see DESIGN NOTES) ----
    // Line format VERIFIED against swww source (common/src/ipc/
    // types.rs, BgInfo/BgImg Display impls): "<output>: WxH, scale:
    // N, currently displaying: image: <path>" — or "color: RRGGBB"
    // after a `clear`, which the "image: " search correctly skips.
    // Parsing takes everything after the first "image: " on the first
    // line that has one — paths with spaces survive because it's the
    // rest of the line. Multi-monitor: v1 sets all outputs together,
    // so any line's answer is THE answer.
    Process {
        id: queryProc

        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const at = line.indexOf("image: ");
                    if (at >= 0) {
                        root.currentWallpaper = line.slice(at + 7).trim();
                        root.syncSelectionToCurrent();
                        return;
                    }
                }
            }
        }
        onExited: code => { // qmllint disable signal-handler-parameters
            root.daemonOk = (code === 0);
        }
    }

    // ---- The popout itself ----

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "center"

        // Fresh scan + query + keyboard focus on every open. Runs IN
        // ADDITION to BarPopout's internal onOpenChanged (both
        // connections fire; the internal visible-sync runs first), same
        // as the launcher.
        onOpenChanged: {
            if (open) {
                root.rescan();
                grid.forceActiveFocus();
            }
        }

        // ---- Header: title/count + Shuffle + Random ----
        RowLayout {
            // Same trick as the launcher's search field: implicitWidth
            // on the first child is what makes the whole popout this
            // wide (BarPopout sizes from the column's implicit sizes).
            implicitWidth: grid.implicitWidth
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: "Wallpapers"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Shuffle toggle — checked = filled accent box (no glyph:
            // a checkmark would mean gambling on an unverified font
            // codepoint, and a filled/empty box reads just as well).
            Rectangle {
                implicitWidth: shuffleContent.implicitWidth + Theme.spacingMedium * 2
                implicitHeight: shuffleLabel.implicitHeight + Theme.spacingSmall
                radius: Theme.radiusMedium
                color: shuffleMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                visible: root.wallpapers.length > 0

                Row {
                    id: shuffleContent
                    anchors.centerIn: parent
                    spacing: Theme.spacingSmall

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 14
                        height: 14
                        radius: 3
                        color: root.shuffled ? Theme.colorAccent : "transparent"
                        border.width: root.shuffled ? 0 : 2
                        border.color: Theme.colorMuted
                    }

                    Text {
                        id: shuffleLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Shuffle"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                MouseArea {
                    id: shuffleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.shuffled = !root.shuffled;
                        // Immediate feedback: re-order (or restore
                        // sorted order) right now, not on next open.
                        root.rebuildDisplayList();
                    }
                }
            }

            Rectangle {
                implicitWidth: randomLabel.implicitWidth + Theme.spacingMedium * 2
                implicitHeight: randomLabel.implicitHeight + Theme.spacingSmall
                radius: Theme.radiusMedium
                color: randomMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                visible: root.wallpapers.length > 0

                Text {
                    id: randomLabel
                    anchors.centerIn: parent
                    text: "Random"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                MouseArea {
                    id: randomMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.applyRandom()
                }
            }
        }

        // ---- Daemon-down warning (see DESIGN NOTES) ----
        Text {
            visible: !root.daemonOk
            text: "awww-daemon isn't running — picks won't apply"
            color: Theme.colorUrgent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        // ---- Empty state ----
        Text {
            visible: root.wallpapers.length === 0
            text: "No wallpapers found in " + root.wallsDir
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        // ---- The grid ----
        GridView {
            id: grid

            // Cell = thumb + breathing room; grid declares REAL sizes
            // because GridView has no content-derived implicit size
            // (see DESIGN NOTES, "GRID SIZING").
            readonly property int cellSize: Settings.wallpaperThumbSize + Theme.spacingSmall

            visible: root.wallpapers.length > 0
            implicitWidth: Settings.wallpaperGridColumns * cellSize
            implicitHeight: Math.min(
                Math.max(1, Math.ceil(root.wallpapers.length / Settings.wallpaperGridColumns)),
                Settings.wallpaperGridMaxRows) * cellSize
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight

            cellWidth: cellSize
            cellHeight: cellSize
            clip: true
            focus: true
            model: root.displayList

            // Scroll performance on big collections (see DESIGN NOTES,
            // "GRID SCROLL PERFORMANCE"): pool + reuse scrolled-out
            // delegates instead of destroying them, and keep ~4 extra
            // rows instantiated beyond the visible area.
            reuseItems: true
            cacheBuffer: 0

            Keys.onLeftPressed: moveCurrentIndexLeft()
            Keys.onRightPressed: moveCurrentIndexRight()
            Keys.onUpPressed: moveCurrentIndexUp()
            Keys.onDownPressed: moveCurrentIndexDown()
            Keys.onReturnPressed: root.applySelected()
            Keys.onEnterPressed: root.applySelected()
            Keys.onEscapePressed: popout.open = false

            // PageUp/PageDown: no dedicated Keys.on*Pressed signal
            // exists for these (unlike arrows/Return/Escape above), so
            // handle via the generic onPressed and only mark the ones
            // we actually use as accepted — everything else falls
            // through to the specific handlers above unaffected. Jumps
            // a full visible page (columns × visible rows) at a time;
            // GridView's default currentIndex-follows-into-view
            // behavior handles the actual scrolling, same as arrow keys
            // already rely on.
            Keys.onPressed: event => {
                const page = Settings.wallpaperGridColumns * Settings.wallpaperGridMaxRows;
                if (event.key === Qt.Key_PageUp) {
                    grid.currentIndex = Math.max(0, grid.currentIndex - page);
                    event.accepted = true;
                } else if (event.key === Qt.Key_PageDown) {
                    grid.currentIndex = Math.min(root.displayList.length - 1, grid.currentIndex + page);
                    event.accepted = true;
                }
            }

            delegate: Item {
                id: cell
                required property var modelData
                required property int index

                width: grid.cellSize
                height: grid.cellSize

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingSmall / 2
                    radius: Theme.radiusMedium
                    // SELECTION (keyboard/hover) = accent BORDER — a
                    // fill alone is invisible because the image covers
                    // all but a few px of the cell (learned live, see
                    // revision history). ACTIVE wallpaper = corner
                    // badge below, so the two states stay readable
                    // even when overlapping.
                    color: cell.GridView.isCurrentItem ? Theme.colorHover : "transparent"
                    border.width: cell.GridView.isCurrentItem ? 2 : 0
                    border.color: Theme.colorAccent

                    Image {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingSmall / 2
                        source: "file://" + cell.modelData.thumb
                        // Decode at cell size, NOT native size — without
                        // this a missing thumb would decode a 4K
                        // original for a ~120px cell.
                        sourceSize.width: Settings.wallpaperThumbSize
                        sourceSize.height: Settings.wallpaperThumbSize
                        // No-op for the pre-squared thumbs; only does
                        // work on the full-image fallback.
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Active-wallpaper badge: small accent dot, ringed
                    // in the background colour so it reads over any
                    // image content.
                    Rectangle {
                        visible: cell.modelData.path === root.currentWallpaper
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Theme.spacingSmall
                        width: 12
                        height: 12
                        radius: 6
                        color: Theme.colorAccent
                        border.width: 2
                        border.color: Theme.colorBackground
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: grid.currentIndex = cell.index
                    onClicked: root.apply(cell.modelData.path)
                }
            }
        }
    }
}
