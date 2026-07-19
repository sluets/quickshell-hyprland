//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/TopBar.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The bar itself — the panel that sits at the top (or bottom, per
// Settings.barPosition once that's wired up) of ONE screen. As of
// 2026-07-05 one of these exists PER MONITOR — shell.qml
// instantiates them through a Variants block and injects each one's
// ShellScreen as the required `modelData` property below.
//
// Hosts SystemMenu + Workspaces + a divider + NowPlaying (grouped on the
// left), Volume + Wifi + Bluetooth + Clock (grouped on the right,
// divider between each), and the Launcher + WallpaperPicker (two
// invisible anchors centered in the bar; their popouts open by
// hotkey/IPC only — the hotkeys/IPC themselves live in shell.qml
// now, routed here through the toggle functions below). The system tray
// was removed 2026-07-04 (widgets/TopBar/Tray.qml and TrayItem.qml
// still exist on disk, just unreferenced — re-add `Tray {}` plus its
// conditional Separator and the Quickshell.Services.SystemTray import
// here to bring it back). Further modules (Battery) get added as their
// own files inside widgets/TopBar/ the same way.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// QtQuick.Layouts   (for RowLayout, grouping the left- and right-side
//                     modules)
// Quickshell        (PanelWindow, ShellScreen)
// core/Theme.qml    (singleton, reached via `import qs.core` — NOT passed
//                     in as a property; see DESIGN NOTES)
// core/Settings.qml (singleton, same import — consumed by Clock.qml,
//                     Workspaces.qml, NowPlaying.qml, etc.)
// widgets/TopBar/Clock.qml      (neighboring file, no import needed)
// widgets/TopBar/Workspaces.qml (neighboring file, no import needed)
// widgets/TopBar/SystemMenu.qml (neighboring file, no import needed)
// widgets/TopBar/NowPlaying.qml (neighboring file, no import needed)
// widgets/TopBar/Volume.qml     (neighboring file, no import needed)
// widgets/TopBar/Wifi.qml       (neighboring file, no import needed)
// widgets/TopBar/Bluetooth.qml  (neighboring file, no import needed)
// widgets/TopBar/Launcher.qml   (neighboring file, no import needed)
// widgets/TopBar/WallpaperPicker.qml (neighboring file, no import needed)
// widgets/TopBar/Separator.qml  (used here directly AND inside Clock.qml)
// widgets/TopBar/MenuButton.qml (used inside SystemMenu.qml, not directly here)
//
//=============================================================================
// USED BY
//=============================================================================
//
// shell.qml (the only place this is instantiated — once per screen,
// inside a Variants block that supplies `modelData`)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No bar renders on any monitor — this is currently the main visible
// piece of the entire shell (the OSD and notification popups are the
// only other windows).
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ONE INSTANCE PER MONITOR:
//
// `modelData` is the ShellScreen this bar belongs to, injected by the
// Variants block in shell.qml, and `screen: modelData` pins the
// PanelWindow (and its exclusive zone) to that output. Do NOT
// instantiate this widget without providing modelData — `required`
// makes that a load error instead of a silently misplaced bar (the
// pre-2026-07-05 single instance set no screen at all, and Quickshell
// put it on whatever output it enumerated first, which on this machine
// was the wrong one).
//
// Everything INSIDE the bar is safe to duplicate per-screen: the
// module widgets only read singletons/services, and services are
// singletons precisely so N bars share one PipeWire/NetworkManager/
// Hyprland connection. The two things that were NOT safe to duplicate
// — the launcher's and wallpaper picker's GlobalShortcut/IpcHandler
// registrations — moved to shell.qml; this file exposes
// toggleLauncher()/toggleWallpapers()/closePopouts() for it to call on
// whichever bar sits on the focused monitor.
//
// THEME/SETTINGS ARE REACHED VIA IMPORT, NOT PASSED-IN PROPERTIES:
//
// core/Theme.qml and core/Settings.qml are `pragma Singleton` types,
// so this file just does `import qs.core` and reads `Theme.colorBackground`
// etc. directly — there's no property to declare and nothing that can be
// forgotten when this widget is instantiated. See shell.qml's DESIGN
// NOTES and docs/PROBLEMS_AND_FIXES.md for the full reasoning.
//
// WHY anchors instead of a fixed x/y position:
// `anchors { top: true; left: true; right: true }` tells Quickshell to
// stick this panel to the top edge and stretch it full width, which
// automatically adapts if you change monitor resolution later.
//
// WHY THE RIGHT SIDE IS A RowLayout INSTEAD OF A LONE Clock:
//
// Volume/Wifi/Bluetooth all needed the same right-anchored, vertically-
// centered treatment Clock already had. Rather than anchor each
// separately (four separate anchor blocks, easy to get inconsistent
// spacing between), they're grouped into one RowLayout the same way
// SystemMenu/Workspaces/NowPlaying already are on the left — one
// `spacing:` controls the gap between all of them, and a `Separator {}`
// between each keeps the "|" divider look consistent across the bar.
//
// FUTURE: Settings.barPosition currently isn't actually read yet — the
// bar is hardcoded to anchor top. Wiring up bottom-bar support is a
// planned improvement.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-12  (Sonnet 5) Margins split from one Theme.barMargin into
//             Theme.barPaddingTop/Side/Bottom (settings window,
//             Appearance page — per-edge overrides, default -1
//             follows the theme's barMargin exactly as before).
//             exclusiveZone now also reserves barPaddingBottom, so a
//             larger bottom pad actually pushes tiled windows down.
// 2026-07-05  Multi-monitor: now instantiated once per screen (required
//             `modelData` ShellScreen, bound to `screen:`). Launcher/
//             WallpaperPicker got ids plus routing functions
//             (toggleLauncher/toggleWallpapers/closePopouts and the
//             wallpaper IPC wrappers) — their hotkey/IPC registrations
//             moved to shell.qml so N bars don't register N copies.
//             Opening one centered popout closes the other.
// 2026-07-10  (Fable 5) Bar border project: contents wrapped in
//             `barRoot` (an Item marker BarPopout finds by parent-walk
//             — a PanelWindow isn't an Item, so the walk needed a
//             target) carrying the popout-gap API, plus a Canvas that
//             strokes a rounded border around the bar with gaps in the
//             bottom edge where open popouts attach. Width/color from
//             the new Theme.barBorderWidth/Color tokens (width follows
//             UserPrefs.hyprBorderSize by default). No geometry
//             changes — the wrapper fills the window exactly.
//             Same-day extension: optional gradient stroke
//             (barBorderColor2/GradientAngle tokens; transparent
//             color2 = solid, unchanged).
// 2026-07-09  (Fable 5) SettingsMenu {} added to the right RowLayout
//             (far right, after Clock). It was DISCOVERED MISSING
//             during Phase-1 live testing: the 07-05 manual
//             flat-file restore brought back a pre-07-05 TopBar.qml,
//             so the gear menu existed as a file but was never
//             instantiated — dark since the incident (manual-restore
//             casualty #3, after the NotificationPopups misplacement
//             and the duplicate themes folder).
// 2026-07-04  Added WallpaperPicker, centered in the bar (second
//             invisible centered anchor alongside the Launcher's; see
//             WallpaperPicker.qml's DESIGN NOTES).
// 2026-07-04  Bar restyle: inset from screen edges by Theme.barMargin
//             (top/left/right), corners rounded with Theme.barRadius.
//             Window is now transparent with the visible bar drawn as
//             an inner Rectangle; exclusive zone set explicitly to
//             barHeight + barMargin. Also REMOVED the system tray from
//             the bar (Tray.qml/TrayItem.qml left on disk, unused).
// 2026-07-04  Added Launcher, centered in the bar (invisible — just the
//             anchor its centered popout hangs from; see Launcher.qml).
// 2026-07-02  Added Volume, Wifi, and Bluetooth (all read-only for now —
//             see each file's own REVISION HISTORY), grouped with Clock
//             into one right-anchored RowLayout instead of Clock being
//             anchored on its own. Separator between each module, same
//             as the left-side grouping.
// 2026-07-01  Added a Separator right after Workspaces (one divider
//             marking the end of the workspace list, not one between
//             each number), and NowPlaying after that. Both live in the
//             same left-anchored RowLayout as SystemMenu/Workspaces, so
//             NowPlaying collapsing to zero width (no player active)
//             doesn't leave a gap — the layout just closes up around it.
// 2026-07-01  Added SystemMenu (widgets/TopBar/SystemMenu.qml), grouped
//             with Workspaces in a single left-anchored RowLayout instead
//             of Workspaces being anchored on its own — so the OS icon
//             sits directly left of the workspace numbers with a
//             consistent gap, rather than floating separately.
// 2026-07-01  Added Workspaces (widgets/TopBar/Workspaces.qml),
//             left-anchored, vertically centered.
// 2026-07-01  Added Clock (widgets/TopBar/Clock.qml), right-anchored,
//             vertically centered. First real module in the bar.
// 2026-07-01  Removed `property var theme` / `property var settings`.
//             Now reaches Theme directly via `import qs.core` instead of
//             requiring the instantiator to pass it in. No visual change.
// 2026-07-01  Initial working version. Renders an empty themed bar.
//             Confirmed working before any modules were added.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

PanelWindow {
    id: topBar

    // ---- Which monitor this bar belongs to (see DESIGN NOTES) ----
    // Injected by the Variants block in shell.qml — one bar per
    // non-excluded screen.
    required property ShellScreen modelData

    screen: modelData

    // ---- Popout routing (called by shell.qml — see DESIGN NOTES) ----
    // Each toggle closes the OTHER centered popout first so the two
    // never stack (a stacked open also fired Wayland "transient parent"
    // grab warnings). closePopouts() is what Shell.qml calls on every
    // NON-focused bar before opening anything on the focused one.
    function toggleLauncher(): void {
        wallpaperPicker.close();
        launcher.toggle();
    }

    function toggleWallpapers(): void {
        launcher.close();
        wallpaperPicker.toggle();
    }

    function closePopouts(): void {
        launcher.close();
        wallpaperPicker.close();
    }

    // Wallpaper IPC wrappers — Shell.qml's `wallpapers` IpcHandler
    // routes here (to the focused monitor's bar). One pick still sets
    // ALL outputs; these just decide which instance's popout/state
    // answers.
    function wallpaperSet(path: string): void {
        wallpaperPicker.setFromIpc(path);
    }

    function wallpaperGet(): string {
        return wallpaperPicker.currentWallpaper;
    }

    function wallpaperList(): string {
        return wallpaperPicker.listPaths();
    }

    function wallpaperRandom(): void {
        wallpaperPicker.randomFromIpc();
    }

    // ---- Anchoring ----
    // Sticks to the top edge. The bar FLOATS: inset from the screen's
    // top/left/right edges by Theme.barPaddingTop/Side instead of running
    // edge-to-edge. See DESIGN NOTES for why Settings.barPosition isn't
    // wired up to this yet.
    anchors {
        top: true
        left: true
        right: true
    }

    // Per-edge, not a single Theme.barMargin (2026-07-12) — see
    // core/Theme.qml's barPaddingTop/Side/Bottom for the override
    // precedence. "Side" covers left AND right symmetrically.
    margins {
        top: Theme.barPaddingTop
        left: Theme.barPaddingSide
        right: Theme.barPaddingSide
    }

    // ---- Sizing and appearance, entirely theme-driven ----
    // No hardcoded colors or pixel values below this line — everything
    // comes from the Theme singleton (see DESIGN NOTES above).
    implicitHeight: Theme.barHeight

    // The WINDOW is transparent; the visible bar is the rounded
    // Rectangle below. A window itself can't have rounded corners —
    // it's a rect by definition — so rounding means drawing the bar as
    // a shape inside a see-through window.
    color: "transparent"

    // Reserve bar + top gap explicitly rather than trusting auto
    // exclusive-zone to account for the margin — deterministic either
    // way Quickshell computes it. Tiled windows start right below the
    // bar's bottom edge (any gap under it is Hyprland's gaps_out job,
    // not the shell's).
    // Reserve bar + top gap + bottom gap, clamped so a negative bottom
    // padding (canceling out Hyprland's own gaps_out — see
    // core/Theme.qml's barPaddingBottom) can't push this below zero;
    // Wayland's exclusiveZone doesn't accept negative values.
    exclusiveZone: Math.max(0, Theme.barHeight + Theme.barPaddingTop + Theme.barPaddingBottom)

    // The visible bar + everything in it, wrapped in one Item so
    // BarPopout instances can find their bar by walking anchorItem's
    // parent chain to this marker (a PanelWindow isn't an Item, so the
    // chain can't end at `topBar` itself). Same geometry as before —
    // the wrapper fills the window exactly.
    Item {
        id: barRoot
        anchors.fill: parent

        // ---- Bar-border gap API (called by BarPopout) ----
        // Each OPEN popout registers the x-range where it hangs off
        // the bar's bottom edge; the border Canvas leaves the bottom
        // border open there so bar + popout read as one outlined
        // shape. Map is REASSIGNED, never mutated (reactivity rule).
        readonly property bool isBarBorderHost: true
        property var popoutGaps: ({})

        function setPopoutGap(key: string, x: real, w: real): void {
            const m = {};
            for (const k in popoutGaps)
                m[k] = popoutGaps[k];
            m[key] = { x: x, w: w };
            popoutGaps = m;
            borderCanvas.requestPaint();
        }

        function clearPopoutGap(key: string): void {
            if (popoutGaps[key] === undefined)
                return;
            const m = {};
            for (const k in popoutGaps)
                if (k !== key)
                    m[k] = popoutGaps[k];
            popoutGaps = m;
            borderCanvas.requestPaint();
        }

        // The visible bar. Declared first so it paints UNDER everything
        // below (QML paints children in declaration order).
        Rectangle {
            anchors.fill: parent
            radius: Theme.barRadius
            color: Theme.colorBackground
        }

        // ---- Modules ----
        // SystemMenu, Workspaces, Separator, NowPlaying, Volume, Wifi,
        // Bluetooth, and Clock are all neighboring files in this same
        // folder, so none need an import — Quickshell auto-imports
        // uppercase-named files from the same directory. Each reaches
        // Theme/Settings/services itself via `import qs.core` / `import
        // qs.services`, same as this file does; nothing to pass in here.
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingMedium
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingMedium

            SystemMenu {}
            Separator {}
            Workspaces {}
            Separator {}
            NowPlaying {}
        }

        // Invisible 1px anchor in the exact middle of the bar — the launcher
        // draws nothing here; it exists so its BarPopout can hang centered.
        // Opened only via shell.qml's routing (hotkey/IPC on the
        // focused monitor).
        Launcher {
            id: launcher
            modelData: topBar.modelData
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        // Second invisible centered anchor, same deal — the wallpaper
        // picker's popout hangs from it. Two centered 1px anchors coexist
        // fine: both draw nothing, and the toggle functions above guarantee
        // only one popout is open at a time.
        WallpaperPicker {
            id: wallpaperPicker
            modelData: topBar.modelData
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingMedium
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingMedium

            Volume {}
            Separator {}
            Wifi {}
            Separator {}
            Bluetooth {}
            Separator {}
            Clock {}
            Separator {}
            SettingsMenu {}
        }

        // ---- The bar border ----
        // Drawn with a Canvas (not Rectangle.border) because the
        // bottom edge needs GAPS where open popouts attach — a
        // Rectangle border is all-or-nothing. Declared LAST so it
        // paints above everything; only the perimeter is inked and
        // there's no MouseArea, so it neither covers content nor eats
        // clicks. Repaints are explicit: the gap API above calls
        // requestPaint(), and the property change handlers below cover
        // theme/size changes (Canvas does not track bindings used
        // inside onPaint).
        Canvas {
            id: borderCanvas
            anchors.fill: parent

            property int bw: Theme.barBorderWidth
            property color bc: Theme.barBorderColor
            property color bc2: Theme.barBorderColor2
            property real bgAng: Theme.barBorderGradientAngle
            property int br: Theme.barRadius
            onBwChanged: requestPaint()
            onBcChanged: requestPaint()
            onBc2Changed: requestPaint()
            onBgAngChanged: requestPaint()
            onBrChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const bwv = bw;
                if (bwv <= 0)
                    return;
                const w = width, h = height;
                const inset = bwv / 2;      // stroke centerline inset
                const cr = Math.max(br, inset); // corner center offset
                const ar = Math.max(0, cr - inset); // arc radius on centerline
                // Solid color, or a linear gradient across the bar's
                // box (angle convention: 0° = left→right, 90° =
                // top→bottom, increasing clockwise). BarPopout draws
                // the SAME line shifted into its own coords, so the
                // gradient flows through the seam unbroken.
                if (bc2.a <= 0.001) {
                    ctx.strokeStyle = bc;
                } else {
                    const ang = bgAng * Math.PI / 180;
                    const dx = Math.cos(ang), dy = Math.sin(ang);
                    const L = (Math.abs(w * dx) + Math.abs(h * dy)) / 2;
                    const g = ctx.createLinearGradient(
                        w / 2 - dx * L, h / 2 - dy * L,
                        w / 2 + dx * L, h / 2 + dy * L);
                    g.addColorStop(0, "rgba(" + Math.round(bc.r * 255) + ","
                        + Math.round(bc.g * 255) + "," + Math.round(bc.b * 255)
                        + "," + bc.a + ")");
                    g.addColorStop(1, "rgba(" + Math.round(bc2.r * 255) + ","
                        + Math.round(bc2.g * 255) + "," + Math.round(bc2.b * 255)
                        + "," + bc2.a + ")");
                    ctx.strokeStyle = g;
                }
                ctx.lineWidth = bwv;

                // Everything EXCEPT the bottom edge, one continuous
                // stroke: bottom-left corner -> left -> top-left ->
                // top -> top-right -> right -> bottom-right corner.
                ctx.beginPath();
                ctx.moveTo(cr, h - inset);
                ctx.arc(cr, h - cr, ar, Math.PI / 2, Math.PI, false);
                ctx.lineTo(inset, cr);
                ctx.arc(cr, cr, ar, Math.PI, 1.5 * Math.PI, false);
                ctx.lineTo(w - cr, inset);
                ctx.arc(w - cr, cr, ar, 1.5 * Math.PI, 2 * Math.PI, false);
                ctx.lineTo(w - inset, h - cr);
                ctx.arc(w - cr, h - cr, ar, 0, Math.PI / 2, false);
                ctx.stroke();

                // Bottom edge: the complement of the registered gaps,
                // clamped between the two bottom corners.
                const gaps = [];
                for (const k in barRoot.popoutGaps) {
                    const g = barRoot.popoutGaps[k];
                    const x1 = Math.max(cr, g.x);
                    const x2 = Math.min(w - cr, g.x + g.w);
                    if (x2 > x1)
                        gaps.push([x1, x2]);
                }
                gaps.sort((a, b) => a[0] - b[0]);
                ctx.beginPath();
                let cursor = cr;
                for (let i = 0; i < gaps.length; i++) {
                    if (gaps[i][0] > cursor) {
                        ctx.moveTo(cursor, h - inset);
                        ctx.lineTo(gaps[i][0], h - inset);
                    }
                    cursor = Math.max(cursor, gaps[i][1]);
                }
                if (cursor < w - cr) {
                    ctx.moveTo(cursor, h - inset);
                    ctx.lineTo(w - cr, h - inset);
                }
                ctx.stroke();
            }
        }
    }
}
