//=============================================================================
// FILE
//=============================================================================
//
// shell.qml  (the config root entry point Quickshell actually loads —
// see 2026-07-05 note below; older project notes call this
// "core/Shell.qml", which is stale)
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The real body of the desktop. shell.qml just instantiates Quickshell's
// built-in ShellRoot and loads this file inside it — everything that
// actually gets drawn on screen (bars, popups, overlays) gets created
// here, or is created by something this file loads.
//
// Responsibilities:
//
// • Create one TopBar PER MONITOR (via Variants over Quickshell.screens,
//   minus anything matched by Settings.barExcludedScreens)
// • Own the shell's GLOBAL entry points — the Hyprland global shortcuts
//   and IPC handlers for the launcher, wallpaper picker, and power screen
//   — and route them to the bar on the currently FOCUSED monitor (launcher/
//   wallpapers) or straight to the single top-level instance (power)
// • Instantiate the single-instance widgets (VolumeOsd,
//   NotificationPopups, PowerScreen)
//
// This file does NOT create Theme/Settings/Globals instances and does
// NOT pass them down as properties — see DESIGN NOTES.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell               (Scope, Variants, Quickshell.screens)
// Quickshell.Io            (IpcHandler)
// Quickshell.Hyprland      (GlobalShortcut, Hyprland.focusedMonitor)
// core/Settings.qml        (singleton — barExcludedScreens)
// widgets/TopBar/TopBar.qml (imported as qs.widgets.TopBar)
// widgets/OSD/VolumeOsd.qml (imported as qs.widgets.OSD)
// widgets/Notifications/NotificationPopups.qml
//                           (imported as qs.widgets.Notifications)
// widgets/PowerMenu/PowerScreen.qml
//                           (imported as qs.widgets.PowerMenu)
//
//=============================================================================
// USED BY
//=============================================================================
//
// shell.qml (only)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Nothing renders. This is where every visible piece of the shell actually
// gets instantiated — removing it removes the whole desktop, not just one
// module. It's also now where the launcher/wallpaper/power hotkeys live, so
// those die with it too.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ONE BAR PER MONITOR — Variants over Quickshell.screens:
//
// Variants is Quickshell's "instantiate this component once per model
// entry" type — the standard per-screen pattern for Quickshell
// windows. The model is Quickshell.screens filtered against
// Settings.barExcludedScreens (a list of regex strings matched against
// screen names like "DP-1"), so out of the box the bar appears on EVERY
// monitor and nobody has to know their output names for a correct first
// run — excluding one is a one-line Settings change. Each instance gets
// its ShellScreen injected as `modelData` (TopBar declares it as a
// required property and binds its window to it), and Quickshell.screens
// is reactive, so plugging/unplugging a monitor adds/removes its bar
// automatically. `Variants.instances` (verified in the Quickshell
// source, src/core/variants.hpp) exposes the live instance list — the
// routing functions below iterate it.
//
// WHY THE SHORTCUTS AND IPC LIVE HERE, NOT IN THE WIDGETS:
//
// Launcher.qml and WallpaperPicker.qml used to register their own
// GlobalShortcut + IpcHandler. That was correct when exactly one of
// each existed; with a bar (and therefore a launcher anchor) on every
// monitor, letting each instance register "shell:launcher" would mean
// duplicate registrations and every monitor's popout answering the same
// keypress — the "mirrored popouts" bug seen when two shell processes
// ran side by side. So registration is hoisted HERE, exactly once, and
// a keypress is routed to ONE bar: the one whose screen name matches
// Hyprland.focusedMonitor.name (verified properties — Quickshell
// source, hyprland/ipc/qml.hpp + monitor.hpp). Under Hyprland's
// focus-follows-mouse this is "the monitor you're looking at", which is
// what makes the launcher usable while a fullscreen game owns the other
// monitor. Everything else (search state, scanning, applying) stays in
// the per-screen widget instances — only one is ever open.
//
// toggleLauncher()/toggleWallpapers() also close popouts on every
// NON-focused bar first, and TopBar's own toggle functions close the
// sibling popout on the same bar — so opening the launcher closes a
// stray wallpaper picker (and vice versa) everywhere, instead of the
// two stacking (which also fired Wayland "transient parent" grab
// warnings when both grabbed focus).
//
// POWER SCREEN IS DIFFERENT — SINGLE INSTANCE, NO PER-MONITOR ROUTING:
//
// Unlike the launcher/wallpaper picker, PowerScreen isn't anchored to any
// particular bar — it's a single fullscreen overlay (same category as
// VolumeOsd), so there's no "which monitor's instance" question to route
// between. The GlobalShortcut and IpcHandler below call `powerScreen.
// toggle()` directly. The bar's own trigger (every monitor's SystemMenu
// icon) goes through Signals.togglePowerScreen() instead, since a
// per-monitor bar module has no direct reference to a singly-instantiated
// top-level window — see PowerScreen.qml's DESIGN NOTES for the full
// reasoning.
//
// THEME PATTERN — READ THIS BEFORE ADDING A NEW WIDGET:
//
// core/Theme.qml, core/Settings.qml, and core/Globals.qml are `pragma
// Singleton` types — each has exactly one instance, and any file can
// reach it just by adding `import qs.core` and referencing it by name
// (e.g. `Theme.colorBackground`). No instance to create here, nothing
// to pass down, nothing to forget. This replaced an earlier
// instantiate-and-pass-down pattern whose failure mode (forgetting to
// pass `theme:` produced silently unstyled UI) was real — see
// docs/PROBLEMS_AND_FIXES.md.
//
// To add a new top-level widget: import it here and instantiate it —
// inside the Variants block if it should exist per-monitor, at Scope
// level if there should only ever be one (anything owning a D-Bus name,
// a hotkey, or other machine-global state).
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-09  (Fable 5) Phase 2: SettingsWindow instance + `settings`
//             IpcHandler (toggle) + `import qs.widgets.Settings`.
// 2026-07-09  (Fable 5) Added the `config` IpcHandler (snapshot/list/
//             restore/prune/status) and a ConfigManager.ready read on
//             the Scope root to force-instantiate the lazy singleton
//             at launch — that read is what triggers the one-time
//             Original Backup. Settings-manager plan, Phase 1. Also
//             `import qs.services` (first time shell.qml needs it).
// 2026-07-05  Added PowerScreen — single top-level instance, GlobalShortcut
//             (SUPER+P, appid "shell" name "power") and IpcHandler
//             (`qs ipc call power toggle`) added alongside the existing
//             launcher/wallpaper ones. See "POWER SCREEN IS DIFFERENT"
//             above for why this one doesn't go through the
//             focused-monitor routing the launcher/wallpapers use.
// 2026-07-05  NAMING FIX: this file is the literal config-root
//             `shell.qml` Quickshell loads — older revisions of this
//             file (and its own header) called it "core/Shell.qml",
//             which doesn't match what's actually on disk. No
//             behavior change from the fix itself, just accurate
//             self-description. If a `core/Shell.qml` file exists
//             separately from this one, it's dead/unused — this file
//             is the one that runs.
// 2026-07-05  Multi-monitor: TopBar now instantiated per-screen via
//             Variants (all monitors by default; opt out via new
//             Settings.barExcludedScreens). GlobalShortcut + IpcHandler
//             for launcher/wallpapers HOISTED here from the widgets —
//             single registration, routed to the focused monitor's bar
//             via Hyprland.focusedMonitor. Opening either popout now
//             closes the other, on every monitor.
// 2026-07-04  Added VolumeOsd and NotificationPopups — the first
//             top-level windows besides the bar. Both follow the
//             singleton pattern (nothing passed in).
// 2026-07-01  Rebuilt from core/ShellRoot.qml. No longer creates or wires
//             Theme/Settings/Globals — those are singletons now. Renamed
//             to avoid shadowing Quickshell's built-in ShellRoot type.
//             Root type changed from Item to Scope.
//
//=============================================================================

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.core
import qs.services
import qs.widgets.Settings
import qs.widgets.TopBar
import qs.widgets.OSD
import qs.widgets.Notifications
import qs.widgets.PowerMenu
import qs.widgets.Desktop

Scope {
    id: shellScope

    // Force-instantiate ConfigManager at launch (singletons are lazy) —
    // this read is what triggers the one-time Original Backup and makes
    // the snapshot engine alive from first boot, not first IPC call.
    // See services/ConfigManager.qml's DESIGN NOTES.
    readonly property bool _configManagerLoaded: ConfigManager.ready

    // ---- Focused-monitor routing (see DESIGN NOTES) ----
    // The bar whose screen matches Hyprland's focused monitor, falling
    // back to the first bar if Hyprland hasn't reported one yet (very
    // early startup) or the focused monitor's bar is excluded.
    function barForFocused(): var {
        const focused = Hyprland.focusedMonitor;
        let fallback = null;
        for (let i = 0; i < bars.instances.length; i++) {
            const bar = bars.instances[i];
            if (fallback === null)
                fallback = bar;
            if (focused && bar.modelData.name === focused.name)
                return bar;
        }
        return fallback;
    }

    // Bar anchor used by the single notification renderer. It follows the
    // focused monitor and the saved left/center/right attachment setting. // GPT Rev 54
    readonly property var notificationAnchorItem: {
        const bar = shellScope.barForFocused();
        if (!bar)
            return null;
        switch (UserPrefs.notifBarPosition) {
        case "left": return bar.notificationLeftAnchorItem;
        case "center": return bar.notificationCenterAnchorItem;
        default: return bar.notificationRightAnchorItem;
        }
    }

    function toggleLauncher(): void {
        const target = shellScope.barForFocused();
        for (let i = 0; i < bars.instances.length; i++) {
            if (bars.instances[i] !== target)
                bars.instances[i].closePopouts();
        }
        if (target)
            target.toggleLauncher();
    }

    function toggleWallpapers(): void {
        const target = shellScope.barForFocused();
        for (let i = 0; i < bars.instances.length; i++) {
            if (bars.instances[i] !== target)
                bars.instances[i].closePopouts();
        }
        if (target)
            target.toggleWallpapers();
    }

    // ---- One bar per (non-excluded) monitor ----
    Variants {
        id: bars

        model: Quickshell.screens.filter(s =>
            !Settings.barExcludedScreens.some(p => new RegExp(p).test(s.name)))

        TopBar {} // receives its ShellScreen as required `modelData`
    }

    // ---- Global entry points (single registration — see DESIGN NOTES) ----
    // hyprland.lua binds (unchanged from when these lived in the widgets):
    //     hl.bind(mainMod .. " + R", hl.dsp.global("shell:launcher"))
    //     hl.bind(mainMod .. " + W", hl.dsp.global("shell:wallpapers"))
    //     hl.bind(mainMod .. " + P", hl.dsp.global("shell:power"))

    GlobalShortcut {
        appid: "shell"
        name: "launcher"
        description: "Toggle the app launcher"
        onPressed: shellScope.toggleLauncher()
    }

    GlobalShortcut {
        appid: "shell"
        name: "wallpapers"
        description: "Toggle the wallpaper picker"
        onPressed: shellScope.toggleWallpapers()
    }

    GlobalShortcut {
        appid: "shell"
        name: "power"
        description: "Toggle the power screen"
        onPressed: powerScreen.toggle()
    }

    // Terminal equivalents (no -c flag on a rootless config layout):
    //     qs ipc call launcher toggle
    //     qs ipc call wallpapers toggle | set <path> | get | list | random
    //     qs ipc call power toggle
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            shellScope.toggleLauncher();
        }
    }

    IpcHandler {
        target: "wallpapers"

        function toggle(): void {
            shellScope.toggleWallpapers();
        }

        function set(path: string): void {
            const bar = shellScope.barForFocused();
            if (bar)
                bar.wallpaperSet(path);
        }

        function get(): string {
            const bar = shellScope.barForFocused();
            return bar ? bar.wallpaperGet() : "";
        }

        function list(): string {
            const bar = shellScope.barForFocused();
            return bar ? bar.wallpaperList() : "";
        }

        function random(): void {
            const bar = shellScope.barForFocused();
            if (bar)
                bar.wallpaperRandom();
        }
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            powerScreen.toggle();
        }
    }

    // Snapshot engine test surface (settings-manager plan, Phase 1).
    // The future settings app calls ConfigManager directly; this IPC
    // target exists so the engine is exercisable live before any UI:
    //     qs ipc call config snapshot "before blur experiment"
    //     qs ipc call config list
    //     qs ipc call config restore <name-from-list>
    //     qs ipc call config prune
    //     qs ipc call config status
    // Ops are async — run `status` after an op to see its result.
    IpcHandler {
        target: "settings"

        function toggle(): string {
            // GPT: Settings is Loader-owned. Route IPC through the same
            // signal path used by the gear menu instead of referencing the
            // removed pre-split settingsWindow id.
            Signals.toggleSettingsWindow();
            return "ok: settings toggle requested";
        }
    }

    // Safe external torture-test surface. This deliberately exposes only
    // visual/runtime settings and never calls UI-profile save/delete/restore.
    // The Python harness in testing/ uses it to exercise the live shell. // GPT
    IpcHandler {
        target: "soak"

        function _bool(value: string): bool {
            return value === "1" || value === "true" || value === "on";
        }

        function set(key: string, value: string): string {
            switch (key) {
            case "themeName": UserPrefs.setThemeName(value); break;
            case "fontScale": UserPrefs.setFontScale(Number(value)); break;
            case "clockUse24Hour": UserPrefs.setClockUse24Hour(_bool(value)); break;
            case "clockShowSeconds": UserPrefs.setClockShowSeconds(_bool(value)); break;
            case "launcherPlacement": UserPrefs.setLauncherPlacement(value); break;
            case "launcherOffsetX": UserPrefs.setLauncherOffsetX(Number(value)); break;
            case "launcherOffsetY": UserPrefs.setLauncherOffsetY(Number(value)); break;
            case "launcherShowAppsOnOpen": UserPrefs.setLauncherShowAppsOnOpen(_bool(value)); break;
            case "wallpaperPickerPlacement": UserPrefs.setWallpaperPickerPlacement(value); break;
            case "wallpaperPickerOffsetX": UserPrefs.setWallpaperPickerOffsetX(Number(value)); break;
            case "wallpaperPickerOffsetY": UserPrefs.setWallpaperPickerOffsetY(Number(value)); break;
            case "wallpaperTransitionType": UserPrefs.setWallpaperTransitionType(value); break;
            case "wallpaperTransitionDuration": UserPrefs.setWallpaperTransitionDuration(Number(value)); break;
            case "notifPresentation": UserPrefs.setNotifPresentation(value); break;
            case "notifBarPosition": UserPrefs.setNotifBarPosition(value); break;
            case "notifBarOffsetX": UserPrefs.setNotifBarOffsetX(Number(value)); break;
            case "notifBarShowCardBorders": UserPrefs.setNotifBarShowCardBorders(_bool(value)); break;
            case "notifShowAppName": UserPrefs.setNotifShowAppName(_bool(value)); break;
            case "notifIconSize": UserPrefs.setNotifIconSize(Number(value)); break;
            case "notifBodyLines": UserPrefs.setNotifBodyLines(Number(value)); break;
            case "notifFontScale": UserPrefs.setNotifFontScale(Number(value)); break;
            case "notifCorner": UserPrefs.setNotifCorner(value); break;
            case "notifOffsetX": UserPrefs.setNotifOffsetX(Number(value)); break;
            case "notifOffsetY": UserPrefs.setNotifOffsetY(Number(value)); break;
            case "desktopClockEnabled": UserPrefs.setDesktopClockEnabled(_bool(value)); break;
            case "desktopClockCorner": UserPrefs.setDesktopClockCorner(value); break;
            case "desktopClockOffsetX": UserPrefs.setDesktopClockOffsetX(Number(value)); break;
            case "desktopClockOffsetY": UserPrefs.setDesktopClockOffsetY(Number(value)); break;
            case "desktopClockScale": UserPrefs.setDesktopClockScale(Number(value)); break;
            case "desktopClockShadowEnabled": UserPrefs.setDesktopClockShadowEnabled(_bool(value)); break;
            case "desktopClockShadowStrength": UserPrefs.setDesktopClockShadowStrength(Number(value)); break;
            case "desktopClockShadowOffsetX": UserPrefs.setDesktopClockShadowOffsetX(Number(value)); break;
            case "desktopClockShadowOffsetY": UserPrefs.setDesktopClockShadowOffsetY(Number(value)); break;
            case "desktopClockShowWeatherIcon": UserPrefs.setDesktopClockShowWeatherIcon(_bool(value)); break;
            case "desktopClockShowTemperature": UserPrefs.setDesktopClockShowTemperature(_bool(value)); break;
            case "barBorderWidthOverride": UserPrefs.setBarBorderWidthOverride(Number(value)); break;
            case "barBorderUseThemeColor": UserPrefs.setBarBorderUseThemeColor(_bool(value)); break;
            case "barBorderCustomColor": UserPrefs.setBarBorderCustomColor(value); break;
            case "barPaddingTopOverride": UserPrefs.setBarPaddingTopOverride(Number(value)); break;
            case "barPaddingSideOverride": UserPrefs.setBarPaddingSideOverride(Number(value)); break;
            case "barPaddingBottomOverride": UserPrefs.setBarPaddingBottomOverride(Number(value)); break;
            default: return "rejected: unsupported soak key " + key;
            }
            return "ok: " + key + "=" + value;
        }
    }

    IpcHandler {
        target: "config"

        function snapshot(label: string): string {
            return ConfigManager.createSnapshot(label, "manual")
                ? "snapshot started" : ConfigManager.lastError;
        }

        function list(): string {
            ConfigManager.list();
            // list() is async; give the caller last-known + hint.
            return ConfigManager.snapshots.length > 0
                ? ConfigManager.snapshots.join("\n")
                : "(refreshing — call list again for current results)";
        }

        function restore(name: string): string {
            return ConfigManager.restoreSnapshot(name)
                ? "restore started" : ConfigManager.lastError;
        }

        function prune(): string {
            return ConfigManager.pruneAutos()
                ? "prune started" : ConfigManager.lastError;
        }

        function status(): string {
            if (ConfigManager.busy !== "")
                return "busy: " + ConfigManager.busy;
            if (ConfigManager.lastError !== "")
                return "error: " + ConfigManager.lastError;
            return "idle. last: " + (ConfigManager.lastOutput || "(nothing yet)");
        }
    }

    // ---- Single-instance widgets ----
    // Volume OSD — its own click-through PanelWindow at the bottom of
    // the screen, NOT a bar module (see its DESIGN NOTES). Still
    // single-instance: it doesn't set a screen, so it appears on the
    // default output. Making it (and notifications) follow the focused
    // monitor is a candidate next step now that the bar is per-screen.
    VolumeOsd {}

    // Notification popups — the visible half of the shell's own
    // notification daemon. The NotificationServer itself lives in
    // services/Notifs.qml (singleton — the D-Bus name can only have
    // one owner).
    NotificationPopups { anchorItem: shellScope.notificationAnchorItem }

    // Power screen — fullscreen dimmed overlay, single instance (same
    // "default output only" limitation as VolumeOsd — see its DESIGN
    // NOTES). Triggered by the shortcut/IPC above, or by
    // Signals.togglePowerScreen() (emitted by every bar's SystemMenu
    // icon — see that file's DESIGN NOTES).
    // The settings application, v0 (settings-manager plan, Phase 2) —
    // single instance, same Overlay-layer recipe as PowerScreen.
    // Opened via the gear menu ("Open Settings…" -> Signals) or IPC.
    // GPT: Settings is loaded separately so a changed preferred window size
    // can take effect without restarting the entire Quickshell process. A
    // ProxyFloatingWindow only consumes implicit geometry when it is created;
    // direct width/height writes are deprecated.
    property bool openSettingsAfterReload: false

    Loader {
        id: settingsWindowLoader
        active: true
        sourceComponent: Component {
            SettingsWindow {}
        }

        onLoaded: {
            if (shellScope.openSettingsAfterReload && item) {
                shellScope.openSettingsAfterReload = false;
                item.open();
            }
        }
    }

    Timer {
        id: settingsWindowReloadTimer
        interval: 0
        repeat: false
        onTriggered: settingsWindowLoader.active = true
    }

    Connections {
        target: Signals

        function onToggleSettingsWindow(): void {
            const win = settingsWindowLoader.item;
            if (!win) {
                shellScope.openSettingsAfterReload = true;
                settingsWindowLoader.active = true;
                return;
            }

            if (win.shown) {
                win.close();
                return;
            }

            const sizeChanged =
                win.createdDefaultWidth !== UserPrefs.settingsWindowDefaultWidth
                || win.createdDefaultHeight !== UserPrefs.settingsWindowDefaultHeight;

            if (sizeChanged) {
                shellScope.openSettingsAfterReload = true;
                settingsWindowLoader.active = false;
                settingsWindowReloadTimer.restart();
            } else {
                win.open();
            }
        }
    }

    PowerScreen { id: powerScreen }

    // Desktop clock — borderless time/date/weather sitting directly on
    // the desktop over the wallpaper (WlrLayer.Background — renders
    // BEHIND normal app windows, opposite direction from PowerScreen's
    // Overlay layer). Click-through, no card/border. As of 2026-07-11
    // it's per-monitor INTERNALLY (Scope + Variants over
    // Quickshell.screens — this one declaration is still all shell.qml
    // needs) and everything visible about it — enabled, corner,
    // offsets, monitor filter, colors, shadow — lives in UserPrefs,
    // edited from the settings window's Desktop page. Weather is fully
    // optional — empty Settings.weatherZipCode just hides that row.
    DesktopClock {}
}
