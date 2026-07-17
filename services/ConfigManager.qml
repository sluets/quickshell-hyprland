//=============================================================================
// FILE
//=============================================================================
//
// services/ConfigManager.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Phase 1 of the settings-manager plan (notes/settings-manager-plan.md):
// the snapshot/restore engine, standalone — built and trusted BEFORE
// anything writes configuration. Provides: a one-time Original Backup
// (full copy of the quickshell + hypr config dirs, taken once, never
// touched again), timestamped snapshots of the MANAGED file set
// (manual / daily / auto kinds), restore from any snapshot, and
// auto-pruning of auto/daily snapshots beyond a retention count.
//
// No UI exists yet. Testable entirely via IPC (see shell.qml's
// `config` IpcHandler): snapshot / list / restore / prune / status.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell                (Singleton, Quickshell.env)
// Quickshell.Io             (Process)
// QtQuick
// core/UserPrefs.qml        (stateDir — the ONE definition of where
//                            shell state lives; snapshots live under it)
// core/Settings.qml         (configAutoSnapshotKeep)
//
//=============================================================================
// USED BY
//=============================================================================
//
// shell.qml (the `config` IpcHandler, plus a force-instantiation read —
// singletons are lazy, and the Original Backup should exist from first
// launch, not from first IPC call). Nothing else yet — the settings
// app (plan Phase 2+) becomes the real consumer.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No snapshot engine. shell.qml's `config` IPC target and its
// force-load property fail to resolve ConfigManager. Existing
// snapshots on disk are plain directories of copied files — still
// restorable BY HAND (each contains a manifest.tsv mapping stored
// file -> original absolute path), which is deliberate: recovery must
// never depend on the tool that created the backup.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// DIRECTORY LAYOUT (all under UserPrefs.stateDir, i.e.
// ~/.local/state/quickshell unless XDG_STATE_HOME says otherwise):
//
//   original/                       one-time full backup, never modified
//     .complete                     marker — its presence means "taken"
//     config-quickshell/            full copy of ~/.config/quickshell
//     config-hypr/                  full copy of ~/.config/hypr
//   snapshots/
//     <ISO-ts>_manual_<label>/      never auto-pruned
//     <ISO-ts>_daily/               pruned beyond Settings.configAutoSnapshotKeep
//     <ISO-ts>_auto_<label>/        pruned beyond the same count
//       manifest.tsv                storedName <TAB> originalAbsolutePath
//       files/                      the copies themselves
//
// THE MANAGED SET: `managedPaths` below lists every file a snapshot
// captures. As of Phase 1 that is exactly ONE file — UserPrefs'
// user-prefs.json — because nothing else manager-owned exists yet.
// Later phases APPEND here as they take ownership (settings.json when
// it's born, hypr/generated/ when Phase 3 creates it). A path that
// doesn't exist on disk is skipped silently at snapshot time (so the
// list can name future files early without breaking anything).
//
// MANIFEST-DRIVEN RESTORE: each snapshot records where every stored
// file came from, and restore replays the manifest — meaning restore
// logic never needs updating when the managed set grows, and a
// snapshot taken under an old managed set restores correctly under a
// new one (it restores what IT captured, nothing else). Stored names
// are index-prefixed (0_user-prefs.json) so two managed files with
// the same basename can never collide.
//
// ONE Process, ONE op AT A TIME: every operation is a single /bin/sh
// script run through one shared Process, with all paths passed as
// POSITIONAL ARGUMENTS, never interpolated into the script text (the
// project-standard injection guard — WallpaperPicker's find/realpath
// calls set the precedent). `busy` gates overlapping calls; callers
// check `lastError`/`lastOutput` after `busy` drops. Ops are
// deliberately synchronous-in-spirit: nothing here needs concurrency,
// and a serialized engine is a debuggable engine.
//
// WHY sh SCRIPTS AND NOT QML FILE APIS: cp -a preserves everything
// (permissions, symlinks, timestamps) and recurses for free;
// re-implementing that in QML would be new code with new bugs guarding
// the thing whose whole job is being more reliable than everything
// else. The scripts are POSIX sh, no bashisms.
//
// THE ORIGINAL BACKUP RUNS AS AN IDEMPOTENT SCRIPT ON EVERY
// INSTANTIATION: the script itself checks for the .complete marker
// and exits 0 immediately if present — so QML never needs an async
// "does it exist yet?" round-trip before deciding to run it. First
// launch pays one full config-dir copy; every launch after is one
// no-op process spawn.
//
// SINGLETONS ARE LAZY (docs/ARCHITECTURE.md gotcha): nothing here
// runs until something reads a property. shell.qml therefore reads
// `ConfigManager.ready` at startup, same force-instantiation pattern
// Bluetooth.qml uses on BluetoothAgent.active — that read is what
// triggers the Original Backup on first ever launch.
//
// RESTORING DOES NOT RELOAD ANYTHING (Phase 1): restore puts bytes
// back on disk. UserPrefs' FileView watches its file and picks the
// restored content up live; future managed files are each responsible
// for their own pickup (Hyprland auto-reloads its config on save —
// docs/HYPRLAND_INFO.md). The full transaction loop
// (snapshot→write→health-check→auto-restore) is Phase 2's job and
// composes ON TOP of these primitives; it does not live here yet.
//
// THE APPLY-WITH-REVERT-WINDOW TRANSACTION (2026-07-10): a second,
// riskier apply path alongside applyChanges, for managed files whose
// bad values can make the machine unusable (currently only
// generated/monitors.lua — a wrong monitor mode can black a screen,
// and you can't click "restore" on a screen you can't see). Sequence:
// auto snapshot -> current file copied to <path>.revert-pending ->
// new content written -> service-level countdown. confirmKeep()
// deletes the backup; revertNow() or timer expiry moves it back
// (Hyprland auto-reloads either way). The countdown Timer lives in
// THIS singleton so auto-revert works even if every piece of UI is on
// a dead monitor. A stale .revert-pending found at startup means a
// crash interrupted an unconfirmed window — it is restored
// automatically (chained after the Original Backup op). The
// transaction is deliberately generic: nothing but the startup sweep
// hardcodes which file it's for.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-12  (Opus) Session features REBUILT on the clean original
//             after a cold-start bug. First pass (Sonnet 5) had
//             ConfigManager read Theme directly inside
//             _performStagedWrites for the active-border color; that
//             added a ConfigManager->Theme->UserPrefs init chain which
//             failed on COLD start only (shell.qml's force-instantiate
//             read fired before the chain resolved; lazy singleton
//             init failed and cached undefined, so EVERY
//             ConfigManager.* read came back undefined all session —
//             "Working (undefined)" status + permanently-disabled
//             Apply; hot-reload masked it). Full write-up in
//             PROBLEMS_AND_FIXES.md. This version:
//               - Adds the same switch cases (barPadding*/fontFamily
//                 Override, hyprActiveBorderUseThemeColor/CustomColor)
//                 — all plain UserPrefs writes, no Theme.
//               - active_border regen restored WITH gradient, but the
//                 theme-derived colors are now supplied by the CALLER
//                 (SettingsWindow, via live Bindings) into four plain
//                 properties (hyprActiveBorderThemeHex/Hex2/Angle/Grad)
//                 — ConfigManager NEVER reads Theme. Custom-color
//                 resolution stays inline (_hexToHyprHex, no Theme).
//               - themeName change still forces a regen when the
//                 border follows the theme; correctness on switch is
//                 handled by the caller's Bindings being live when the
//                 async regen reads them.
// 2026-07-11  (Fable 5) Fourteen new cases in _performStagedWrites:
//             notifCorner/OffsetX/OffsetY and the desktopClock* set
//             (plain UserPrefs writes, no hypr regen) — the settings
//             window's Notifications-position and Desktop-page work.
// 2026-07-10  (Fable 5) (later) Three barBorder* cases in
//             _performStagedWrites for the Appearance page's new Bar
//             Border section (plain UserPrefs writes, no hypr regen).
// 2026-07-10  (Fable 5) The apply-with-revert-window transaction
//             (applyFileWithRevert / confirmKeep / revertNow +
//             revertPending/revertSecondsLeft state, three new sh
//             scripts, startup stale-revert sweep) and
//             generated/monitors.lua added to managedPaths. Built for
//             the Displays page (services/DisplayManager.qml is the
//             caller); pattern doc in docs/DISPLAYS.md.
// 2026-07-09  (Fable 5) Phase 3: hypr generated-config machinery —
//             generated/appearance.lua joins managedPaths (snapshot-
//             skipped until the restructure exists), and applyChanges
//             chains a whole-file Lua regeneration when any hypr* key
//             is in the staged set. Fixed-shape template, integers
//             only, values pre-clamped in UserPrefs.
// 2026-07-09  (Fable 5) Phase 2: applyChanges() — the Apply
//             transaction (auto snapshot, then staged UserPrefs
//             writes; snapshot failure aborts the write). Used by
//             widgets/Settings/SettingsWindow.qml.
// 2026-07-09  (Fable 5) Created — Phase 1 of
//             notes/settings-manager-plan.md. Written offline (the
//             established pattern for build sessions without machine
//             access) — NOT yet run live. First-run bugs go in
//             docs/PROBLEMS_AND_FIXES.md. Test procedure is in the
//             plan doc's success criteria + shell.qml's IPC notes.
//
//=============================================================================

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    // Reading this is what force-instantiates the singleton (and with
    // it, the Original Backup check) — see DESIGN NOTES.
    readonly property bool ready: true

    // ---- Where everything lives (built on UserPrefs' ONE stateDir) ----
    readonly property string snapshotsDir: UserPrefs.stateDir + "/snapshots"
    readonly property string originalDir: UserPrefs.stateDir + "/original"

    readonly property string configDir: {
        const base = Quickshell.env("XDG_CONFIG_HOME");
        return (base && base.length > 0 ? base : Quickshell.env("HOME") + "/.config");
    }

    readonly property string hyprConfDir: configDir + "/hypr"
    readonly property string hyprGeneratedAppearance:
        hyprConfDir + "/generated/appearance.lua"
    readonly property string hyprGeneratedMonitors:
        hyprConfDir + "/generated/monitors.lua"

    // ---- The managed set (see DESIGN NOTES) — later phases append ----
    // The hypr paths are skipped silently by snapshots until the
    // generated/user restructure exists on disk (by design).
    readonly property var managedPaths: [
        UserPrefs.stateDir + "/user-prefs.json",
        hyprGeneratedAppearance,
        hyprGeneratedMonitors
    ]

    // ---- Operation state ----
    // What the engine is currently doing: "" (idle), "original",
    // "snapshot", "restore", "list", "prune".
    property string busy: ""
    property string lastError: ""
    property string lastOutput: ""

    // Refreshed by list(); newest first (names sort that way).
    property var snapshots: []

    // ---------------------------------------------------------------
    // Public API — everything below is what Phase 2's transaction
    // loop (and the IPC test surface) calls.
    // ---------------------------------------------------------------

    // kind: "manual" | "daily" | "auto". Label is slugified into the
    // directory name (manual snapshots keep it; it's how the user
    // finds "before-blur-experiment" later).
    function createSnapshot(label: string, kind: string): bool {
        if (busy !== "") { lastError = "busy: " + busy; return false; }
        const k = (kind === "daily" || kind === "auto") ? kind : "manual";
        const slug = (label || "").toLowerCase()
            .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 40);
        const name = timestamp() + "_" + k + (slug ? "_" + slug : "");
        const args = [snapshotsDir + "/" + name].concat(managedPaths);
        run("snapshot", snapshotScript, args);
        return true;
    }

    // Restores every file a snapshot's manifest names, to the absolute
    // paths it recorded. Does NOT touch anything the snapshot didn't
    // capture, and does NOT reload anything (see DESIGN NOTES).
    function restoreSnapshot(name: string): bool {
        if (busy !== "") { lastError = "busy: " + busy; return false; }
        if (!name || name.indexOf("/") !== -1 || name.indexOf("..") !== -1) {
            lastError = "invalid snapshot name";
            return false;
        }
        run("restore", restoreScript, [snapshotsDir + "/" + name]);
        return true;
    }

    // Refreshes `snapshots` (newest first).
    function list(): bool {
        if (busy !== "") { lastError = "busy: " + busy; return false; }
        run("list", listScript, [snapshotsDir]);
        return true;
    }

    // Deletes auto/daily snapshots beyond the retention count.
    // Manual and the Original are never touched.
    function pruneAutos(): bool {
        if (busy !== "") { lastError = "busy: " + busy; return false; }
        run("prune", pruneScript,
            [snapshotsDir, String(Math.max(1, Settings.configAutoSnapshotKeep))]);
        return true;
    }

    // Background retention sweep. Uses its own Process so routine pruning
    // never replaces the Settings status line with "Working (prune)" or
    // "pruned ..." output. Manual IPC pruning still uses pruneAutos().
    function _pruneAutosSilent(): void {
        if (silentPruneProc.running)
            return;
        silentPruneProc.command = ["sh", "-c", pruneScript, "configmanager-prune",
            snapshotsDir, String(Math.max(1, Settings.configAutoSnapshotKeep))];
        silentPruneProc.running = true;
    }

    // Takes today's daily snapshot if none exists yet, then prunes.
    // Phase 2's settings window calls this on open; harmless to call
    // any time. (Implemented in sh so "does today's exist" needs no
    // async QML round-trip.)
    function dailySnapshotIfNeeded(): bool {
        if (busy !== "") { lastError = "busy: " + busy; return false; }
        const today = timestamp().slice(0, 10); // YYYY-MM-DD
        const args = [snapshotsDir, today, timestamp() + "_daily"]
            .concat(managedPaths);
        run("snapshot", dailyScript, args);
        return true;
    }

    // ---- Phase 2: the Apply transaction (settings window) ----
    // changes = [{key, value}, ...] with keys matching the switch in
    // _performStagedWrites. Sequencing: auto snapshot FIRST; writes
    // happen only after the snapshot Process exits successfully — so
    // every Apply is undoable by definition, and a failed snapshot
    // aborts the apply rather than proceeding unprotected.
    // No post-write health check yet: these writes only touch the
    // shell's own JSON (worst case is the verified last-known-good
    // JsonAdapter behavior). The check earns its place in Phase 3
    // when generated Hyprland config joins the managed set.
    property var _stagedApply: null
    // Immutable active-border appearance captured by SettingsWindow at the
    // moment Apply is pressed. The snapshot/write transaction is asynchronous,
    // so the UI clears its staged state before _performStagedWrites() runs.
    // Carrying this object with the transaction prevents an empty/stale rgba()
    // value from being generated during that gap.  // GPT
    property var _stagedHyprBorderSnapshot: null

    function applyChanges(changes: var, summary: string,
                          finalBorderSnapshot: var): bool {
        if (busy !== "") { lastError = "busy: " + busy; return false; }
        if (!changes || changes.length === 0) {
            lastError = "nothing to apply";
            return false;
        }
        _stagedApply = changes;
        _stagedHyprBorderSnapshot = finalBorderSnapshot || null;
        return createSnapshot("before " + (summary || "apply"), "auto");
    }

    // ---- The apply-with-revert-window transaction (Displays page) ----
    // For managed-file writes that can make the machine UNUSABLE if
    // they go wrong (a bad monitor mode can black a screen — clicking
    // "restore snapshot" is not an option on a screen you can't see).
    // Sequence: auto snapshot -> copy the current file aside
    // (<path>.revert-pending) -> write the new content -> open a
    // countdown window. Unless confirmKeep() arrives before it hits
    // zero, the previous file is restored AUTOMATICALLY — the timer
    // lives HERE in the service, deliberately independent of any UI
    // being visible, clickable, or on a monitor that still works.
    //
    // One window at a time; a crash mid-window is covered by the
    // startup sweep (see the "original" chain in onExited): a stale
    // .revert-pending on disk means the window was never resolved, so
    // it's restored on next launch — the safe default.
    //
    // GENERIC BY DESIGN: nothing in here is monitors-specific except
    // the startup sweep path. A future risky managed file reuses this
    // as-is (that reusability is half the reason it was built).

    property bool revertPending: false
    property int revertSecondsLeft: 0
    property string revertFilePath: ""
    property var _pendingFileApply: null      // {path, content, seconds}
    property var _pendingRevertWindow: null   // {path, seconds}
    property string _revertIntent: ""         // "" | "keep" | "revert"

    function applyFileWithRevert(path: string, content: string, label: string, seconds: int): bool {
        if (busy !== "") { lastError = "busy: " + busy; return false; }
        if (revertPending) {
            lastError = "a revert window is already open — Keep or Revert first";
            return false;
        }
        if (!content || content.length === 0) {
            lastError = "refusing to write empty content";
            return false;
        }
        _pendingFileApply = {
            path: path, content: content,
            seconds: Math.max(5, seconds || 15)
        };
        return createSnapshot("before " + (label || "file apply"), "auto");
    }

    // The overlay's "Keep" / the page's confirm. Safe to call any time.
    function confirmKeep(): void {
        if (!revertPending && _revertIntent === "")
            return;
        _revertIntent = "keep";
        _tryExecuteRevertIntent();
    }

    // The overlay's "Revert" / manual bail-out before the timer fires.
    function revertNow(): void {
        if (!revertPending && _revertIntent === "")
            return;
        _revertIntent = "revert";
        _tryExecuteRevertIntent();
    }

    // Intent executes the moment the engine is idle; if an op is in
    // flight, the 1 s tick retries. revertPending only drops when the
    // op actually STARTS, so the tick keeps running until then.
    function _tryExecuteRevertIntent(): void {
        if (_revertIntent === "" || busy !== "")
            return;
        const intent = _revertIntent;
        _revertIntent = "";
        revertPending = false;
        const bak = revertFilePath + ".revert-pending";
        if (intent === "keep")
            run("keepcleanup", revertDiscardScript, [bak]);
        else
            run("revert", revertRestoreScript, [revertFilePath, bak]);
    }

    Timer {
        id: revertTimer
        interval: 1000
        repeat: true
        running: root.revertPending
        onTriggered: {
            if (root._revertIntent !== "") {
                // A Keep/Revert click landed while the engine was
                // busy — retry it; the countdown is frozen.
                root._tryExecuteRevertIntent();
                return;
            }
            root.revertSecondsLeft = root.revertSecondsLeft - 1;
            if (root.revertSecondsLeft <= 0) {
                root._revertIntent = "revert";
                root._tryExecuteRevertIntent();
            }
        }
    }

    function _performStagedWrites(): void {
        const staged = _stagedApply;
        const borderSnapshot = _stagedHyprBorderSnapshot;
        _stagedApply = null;
        _stagedHyprBorderSnapshot = null;
        let n = 0;
        for (let i = 0; i < staged.length; i++) {
            const ch = staged[i];
            switch (ch.key) {
            case "themeName":
                UserPrefs.setThemeName(ch.value);
                n++;
                // Active border follows the theme? Then a theme switch
                // must re-bake generated/appearance.lua too (the color
                // is a static string there, not a live binding). The
                // RESOLVED color is supplied by the caller via
                // hyprActiveBorderArgs before this runs — ConfigManager
                // deliberately does NOT read Theme itself (that
                // dependency broke cold-start init ordering, 2026-07-12
                // — see DESIGN NOTES + PROBLEMS_AND_FIXES.md).
                if (UserPrefs.hyprActiveBorderUseThemeColor)
                    _hyprDirty = true;
                break;
            case "fontScale": UserPrefs.setFontScale(ch.value); n++; break;
            case "wallpaperTransitionType": UserPrefs.setWallpaperTransitionType(ch.value); n++; break;
            case "wallpaperTransitionDuration": UserPrefs.setWallpaperTransitionDuration(ch.value); n++; break;
            case "wallpaperTransitionFps": UserPrefs.setWallpaperTransitionFps(ch.value); n++; break;
            case "wallpaperTransitionAngle": UserPrefs.setWallpaperTransitionAngle(ch.value); n++; break;
            case "wallpaperTransitionPos": UserPrefs.setWallpaperTransitionPos(ch.value); n++; break;
            case "clockUse24Hour": UserPrefs.setClockUse24Hour(ch.value); n++; break;
            case "clockShowSeconds": UserPrefs.setClockShowSeconds(ch.value); n++; break;
            case "wallpaperCachingEnabled": UserPrefs.setWallpaperCachingEnabled(ch.value); n++; break;
            case "notifShowAppName": UserPrefs.setNotifShowAppName(ch.value); n++; break;
            case "notifIconSize": UserPrefs.setNotifIconSize(ch.value); n++; break;
            case "notifBodyLines": UserPrefs.setNotifBodyLines(ch.value); n++; break;
            case "notifFontScale": UserPrefs.setNotifFontScale(ch.value); n++; break;
            case "notifCorner": UserPrefs.setNotifCorner(ch.value); n++; break;
            case "notifOffsetX": UserPrefs.setNotifOffsetX(ch.value); n++; break;
            case "notifOffsetY": UserPrefs.setNotifOffsetY(ch.value); n++; break;
            case "desktopClockEnabled": UserPrefs.setDesktopClockEnabled(ch.value); n++; break;
            case "desktopClockCorner": UserPrefs.setDesktopClockCorner(ch.value); n++; break;
            case "desktopClockOffsetX": UserPrefs.setDesktopClockOffsetX(ch.value); n++; break;
            case "desktopClockOffsetY": UserPrefs.setDesktopClockOffsetY(ch.value); n++; break;
            case "desktopClockMonitor": UserPrefs.setDesktopClockMonitor(ch.value); n++; break;
            case "desktopClockUseThemeColor": UserPrefs.setDesktopClockUseThemeColor(ch.value); n++; break;
            case "desktopClockCustomColor": UserPrefs.setDesktopClockCustomColor(ch.value); n++; break;
            case "desktopClockShadowEnabled": UserPrefs.setDesktopClockShadowEnabled(ch.value); n++; break;
            case "desktopClockShadowUseThemeColor": UserPrefs.setDesktopClockShadowUseThemeColor(ch.value); n++; break;
            case "desktopClockShadowCustomColor": UserPrefs.setDesktopClockShadowCustomColor(ch.value); n++; break;
            case "desktopClockShowWeatherIcon": UserPrefs.setDesktopClockShowWeatherIcon(ch.value); n++; break;
            case "desktopClockShowTemperature": UserPrefs.setDesktopClockShowTemperature(ch.value); n++; break;
            case "desktopClockScale": UserPrefs.setDesktopClockScale(ch.value); n++; break;
            case "desktopClockShadowStrength": UserPrefs.setDesktopClockShadowStrength(ch.value); n++; break;
            case "desktopClockShadowOffsetX": UserPrefs.setDesktopClockShadowOffsetX(ch.value); n++; break;
            case "desktopClockShadowOffsetY": UserPrefs.setDesktopClockShadowOffsetY(ch.value); n++; break;
            case "barBorderWidthOverride": UserPrefs.setBarBorderWidthOverride(ch.value); n++; break;
            case "barBorderUseThemeColor": UserPrefs.setBarBorderUseThemeColor(ch.value); n++; break;
            case "barBorderCustomColor": UserPrefs.setBarBorderCustomColor(ch.value); n++; break;
            case "barPaddingTopOverride": UserPrefs.setBarPaddingTopOverride(ch.value); n++; break;
            case "barPaddingSideOverride": UserPrefs.setBarPaddingSideOverride(ch.value); n++; break;
            case "barPaddingBottomOverride": UserPrefs.setBarPaddingBottomOverride(ch.value); n++; break;
            case "fontFamilyOverride": UserPrefs.setFontFamilyOverride(ch.value); n++; break;
            case "hyprActiveBorderUseThemeColor": UserPrefs.setHyprActiveBorderUseThemeColor(ch.value); n++; _hyprDirty = true; break;
            case "hyprActiveBorderCustomColor": UserPrefs.setHyprActiveBorderCustomColor(ch.value); n++; _hyprDirty = true; break;
            case "hyprGapsIn": UserPrefs.setHyprGapsIn(ch.value); n++; _hyprDirty = true; break;
            case "hyprGapsOut": UserPrefs.setHyprGapsOut(ch.value); n++; _hyprDirty = true; break;
            case "hyprBorderSize": UserPrefs.setHyprBorderSize(ch.value); n++; _hyprDirty = true; break;
            case "hyprRounding": UserPrefs.setHyprRounding(ch.value); n++; _hyprDirty = true; break;
            default:
                lastError = (lastError ? lastError + "\n" : "") + "unknown key: " + ch.key;
            }
        }
        lastOutput = "applied " + n + " change(s)";
        if (_hyprDirty) {
            _hyprDirty = false;
            // Resolve the active-border color to what Hyprland wants
            // (RRGGBBAA, no '#') WITHOUT reading Theme here — see the
            // hyprActiveBorder* properties below for why ConfigManager
            // must not depend on Theme (cold-start init ordering).
            // When following the theme, the caller (SettingsWindow)
            // has already stashed the resolved theme colors into
            // hyprActiveBorderThemeHex / hyprActiveBorderThemeHex2 /
            // hyprActiveBorderThemeGrad; when using a custom color, we
            // convert the stored hex ourselves (no Theme needed).
            // Prefer the immutable value captured when Apply was pressed.
            // Legacy property fallbacks remain for any non-Settings caller that
            // does not provide the third applyChanges() argument.  // GPT
            const useTheme = borderSnapshot !== null
                ? Boolean(borderSnapshot.useTheme)
                : UserPrefs.hyprActiveBorderUseThemeColor;
            const activeBorderHex = borderSnapshot !== null
                ? (useTheme
                    ? String(borderSnapshot.primaryHex || "")
                    : _hexToHyprHex(String(borderSnapshot.customHex || "")))
                : (useTheme
                    ? hyprActiveBorderThemeHex
                    : _hexToHyprHex(UserPrefs.hyprActiveBorderCustomColor));
            const hasGradient = borderSnapshot !== null
                ? (useTheme && Boolean(borderSnapshot.gradient)
                    && String(borderSnapshot.secondaryHex || "") !== "")
                : (useTheme && hyprActiveBorderThemeGrad
                    && hyprActiveBorderThemeHex2 !== "");
            const activeBorderHex2 = hasGradient
                ? (borderSnapshot !== null
                    ? String(borderSnapshot.secondaryHex)
                    : hyprActiveBorderThemeHex2)
                : "";
            const activeBorderAngle = borderSnapshot !== null
                ? Number(borderSnapshot.angle || 0)
                : hyprActiveBorderThemeAngle;
            // Chain the Lua regeneration as its own engine op (busy
            // was just released by onExited). Hyprland auto-reloads
            // when the file lands; a syntax error would make it keep
            // the last good config (docs/HYPRLAND_INFO.md) — the
            // template is fixed-shape with only integers and
            // pre-validated hex/angle values substituted.
            run("hyprgen", hyprGenScript, [
                hyprGeneratedAppearance,
                String(UserPrefs.hyprGapsIn),
                String(UserPrefs.hyprGapsOut),
                String(UserPrefs.hyprBorderSize),
                String(UserPrefs.hyprRounding),
                activeBorderHex,
                activeBorderHex2,
                String(activeBorderAngle),
                hasGradient ? "1" : "0"
            ]);
        }
    }

    property bool _hyprDirty: false

    // ---- Active-border color, resolved by the CALLER (2026-07-12) ----
    // ConfigManager must NOT `import`/read `Theme`: doing so added a
    // ConfigManager -> Theme -> UserPrefs init chain that failed on
    // COLD start (the shell.qml force-instantiation read fired before
    // the chain resolved; the lazy singleton init failed and cached
    // undefined, so EVERY ConfigManager.* read came back undefined all
    // session — "Working (undefined)" + dead Apply). See
    // PROBLEMS_AND_FIXES.md. So the theme-derived colors are computed
    // in SettingsWindow (which safely depends on Theme) and pushed in
    // here as plain strings right before applyChanges. Custom-color
    // resolution needs no Theme and stays inline (via _hexToHyprHex).
    // Defaults are harmless: if the caller never sets these and the
    // border is theme-following, the regen writes an empty color the
    // Lua tolerates until the next real apply corrects it.
    property string hyprActiveBorderThemeHex: ""     // RRGGBBAA
    property string hyprActiveBorderThemeHex2: ""    // RRGGBBAA, "" = no 2nd stop
    property real hyprActiveBorderThemeAngle: 0
    property bool hyprActiveBorderThemeGrad: false

    // ---- Hyprland active-border color hex helpers (2026-07-12) ----
    // This project's own hex convention (HexColorRow, UserPrefs'
    // _validHex) is Qt-style #AARRGGBB / #RRGGBB — alpha FIRST when
    // present. Hyprland's rgba() literal wants RRGGBBAA — alpha LAST,
    // no '#'. _hexToHyprHex lands on that second form. (The Qt-color ->
    // hex conversion for THEME colors lives in SettingsWindow now,
    // since only it reads Theme.)
    function _hexToHyprHex(hex: string): string {
        return hex.length === 9
            ? hex.slice(3) + hex.slice(1, 3)   // #AARRGGBB -> RRGGBBAA
            : hex.slice(1) + "ff";              // #RRGGBB -> RRGGBBff
    }

    // $1 = generated/appearance.lua path; $2..$5 = gaps_in, gaps_out,
    // border_size, rounding (integers, pre-clamped by UserPrefs); $6 =
    // active border color, 8 hex digits RRGGBBAA; $7 = second gradient
    // color, same format, EMPTY when $9 is "0"; $8 = gradient angle
    // (degrees, only meaningful when $9 is "1"); $9 = "1" for a
    // two-stop gradient, "0" for solid.
    // Skips gracefully if the generated/user restructure hasn't been
    // done yet (docs/HYPR_RESTRUCTURE.md) — prefs still persist, the
    // file just isn't born until there's a config that requires it.
    readonly property string hyprGenScript: `
set -eu
dest="$1"; gin="$2"; gout="$3"; bs="$4"; rnd="$5"; ab="$6"; ab2="$7"; ang="$8"; grad="$9"
if [ ! -d "$(dirname "$dest")" ]; then
    echo "hypr not restructured yet - generation skipped (see docs/HYPR_RESTRUCTURE.md)"
    exit 0
fi
if [ "$grad" = "1" ]; then
    border_lua="{ colors = { \\"rgba($ab)\\", \\"rgba($ab2)\\" }, angle = $ang }"
else
    border_lua="\\"rgba($ab)\\""
fi
cat > "$dest" <<LUAEOF
-- MANAGED FILE - generated by the shell's ConfigManager
-- (settings window -> Hyprland page). Do NOT hand-edit: the next
-- settings Apply overwrites this file completely.
-- Managed values: general.gaps_in, general.gaps_out,
-- general.border_size, general.col.active_border, decoration.rounding.
-- Everything ELSE from the old general/decoration blocks lives in
-- user/look.lua - yours. IMPORTANT: user/look.lua must NOT also set
-- general.col.active_border (remove that one line there, keep
-- inactive_border) or the two files fight over the same key — see
-- ConfigManager.qml's DESIGN NOTES for the one-time manual step.

hl.config({
    general = {
        gaps_in     = $gin,
        gaps_out    = $gout,
        border_size = $bs,
        col = {
            active_border = $border_lua,
        },
    },
    decoration = {
        rounding = $rnd,
    },
})
LUAEOF
echo "generated appearance.lua (gaps $gin/$gout, border $bs, rounding $rnd, active border #$ab)"
`


    function timestamp(): string {
        // ISO, filesystem-safe (":" -> "-"), second precision, local-
        // agnostic (UTC — snapshots sort correctly across DST).
        return new Date().toISOString().replace(/:/g, "-").replace(/\..*$/, "");
    }

    // ---------------------------------------------------------------
    // Internals
    // ---------------------------------------------------------------

    function run(what: string, script: string, args: var): void {
        busy = what;
        lastError = "";
        lastOutput = "";
        _lines = [];
        proc.command = ["sh", "-c", script, "configmanager"].concat(args);
        proc.running = true;
    }

    property var _lines: []

    Process {
        id: silentPruneProc
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: proc

        stdout: SplitParser {
            onRead: data => root._lines.push(data)
        }
        stderr: SplitParser {
            onRead: data => {
                root.lastError = (root.lastError ? root.lastError + "\n" : "") + data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            const what = root.busy;
            root.busy = "";
            root.lastOutput = root._lines.join("\n");
            if (exitCode !== 0 && root.lastError === "")
                root.lastError = what + " failed (exit " + exitCode + ")";
            if (what === "list")
                root.snapshots = root._lines.filter(l => l.length > 0);

            // Captured BEFORE the two chains below null these out on
            // their success path — needed so the auto-prune check
            // near the bottom can tell "this snapshot belonged to a
            // staged transaction" from "this was a plain daily/manual
            // snapshot", even though both tag `what` as "snapshot".
            const wasStagedApplySnapshot = (what === "snapshot" && root._stagedApply !== null);
            const wasFileApplySnapshot = (what === "snapshot" && root._pendingFileApply !== null);

            // Apply transaction, step 2: snapshot landed -> write.
            if (root._stagedApply !== null) {
                if (what === "snapshot" && exitCode === 0)
                    root._performStagedWrites();
                else {
                    root._stagedApply = null;
                    root._stagedHyprBorderSnapshot = null;
                    root.lastError = "apply aborted: snapshot failed — nothing was written";
                }
            }

            // File-with-revert transaction, step 2: snapshot landed ->
            // back the current file up and write the new content.
            if (root._pendingFileApply !== null) {
                const pfa = root._pendingFileApply;
                root._pendingFileApply = null;
                if (what === "snapshot" && exitCode === 0) {
                    root._pendingRevertWindow = { path: pfa.path, seconds: pfa.seconds };
                    root.run("filewrite", root.writeRevertScript,
                             [pfa.path, pfa.path + ".revert-pending", pfa.content]);
                } else {
                    root.lastError = "apply aborted: snapshot failed — nothing was written";
                }
            }

            // Step 3: file written -> open the countdown window.
            if (what === "filewrite" && root._pendingRevertWindow !== null) {
                const w = root._pendingRevertWindow;
                root._pendingRevertWindow = null;
                if (exitCode === 0) {
                    root.revertFilePath = w.path;
                    root.revertSecondsLeft = w.seconds;
                    root.revertPending = true;
                }
                // Failure: lastError is already set above; no window
                // opens because nothing was written.
            }

            // Auto-prune (2026-07-13): any completed daily or manual
            // snapshot is a good moment to sweep auto/daily snapshots
            // past Settings.configAutoSnapshotKeep — cheap, a no-op
            // when there's nothing to prune, and means old snapshots
            // never need to be cleared out by hand. Deliberately
            // EXCLUDES the two staged-transaction snapshots above:
            // those chains call root.run() again themselves in this
            // same handler, and a same-tick prune call here would
            // overwrite `proc.command` before that run ever starts,
            // silently corrupting the apply/file-apply transaction it
            // was supposed to protect. Manual snapshots are never
            // pruned themselves (pruneScript only ever matches
            // `_auto_`/`_daily_` names) — this just triggers the
            // sweep, it doesn't make manual snapshots prunable.
            if (what === "snapshot" && exitCode === 0
                    && !wasStagedApplySnapshot && !wasFileApplySnapshot) {
                root._pruneAutosSilent();
            }

            // Startup chain: after the Original Backup check, sweep a
            // stale .revert-pending left by a crash inside an
            // unconfirmed window — restoring it is the safe default
            // (the change was never confirmed; re-applying is cheap).
            if (what === "original")
                root.run("revertcheck", root.revertRestoreScript,
                         [root.hyprGeneratedMonitors,
                          root.hyprGeneratedMonitors + ".revert-pending"]);
        }
    }

    // ---- The scripts (POSIX sh; paths arrive as "$1".. only) ----

    // $1 = snapshot dir to create; $2.. = managed files to capture.
    readonly property string snapshotScript: `
set -eu
dest="$1"; shift
mkdir -p "$dest/files"
: > "$dest/manifest.tsv"
i=0
for src in "$@"; do
    [ -e "$src" ] || continue
    stored="\${i}_$(basename "$src")"
    cp -a "$src" "$dest/files/$stored"
    printf '%s\t%s\n' "$stored" "$src" >> "$dest/manifest.tsv"
    i=$((i+1))
done
echo "created $(basename "$dest") ($i file(s))"
`

    // $1 = snapshots root; $2 = today prefix (YYYY-MM-DD);
    // $3 = new daily dir name; $4.. = managed files.
    readonly property string dailyScript: `
set -eu
snaps="$1"; today="$2"; name="$3"; shift 3
mkdir -p "$snaps"
if ls -1 "$snaps" 2>/dev/null | grep -q "^\${today}.*_daily"; then
    echo "daily already exists for $today"
    exit 0
fi
dest="$snaps/$name"
mkdir -p "$dest/files"
: > "$dest/manifest.tsv"
i=0
for src in "$@"; do
    [ -e "$src" ] || continue
    stored="\${i}_$(basename "$src")"
    cp -a "$src" "$dest/files/$stored"
    printf '%s\t%s\n' "$stored" "$src" >> "$dest/manifest.tsv"
    i=$((i+1))
done
echo "created $name ($i file(s))"
`

    // $1 = full path of the snapshot dir to restore from.
    readonly property string restoreScript: `
set -eu
snap="$1"
[ -f "$snap/manifest.tsv" ] || { echo "no manifest in $snap" >&2; exit 1; }
n=0
while IFS="	" read -r stored dest; do
    [ -n "$stored" ] || continue
    mkdir -p "$(dirname "$dest")"
    cp -a "$snap/files/$stored" "$dest"
    n=$((n+1))
done < "$snap/manifest.tsv"
echo "restored $n file(s) from $(basename "$snap")"
`

    // $1 = snapshots root. Prints one snapshot name per line, newest first.
    readonly property string listScript: `
set -eu
[ -d "$1" ] || exit 0
ls -1 "$1" | sort -r
`

    // $1 = snapshots root; $2 = how many auto/daily to KEEP.
    readonly property string pruneScript: `
set -eu
[ -d "$1" ] || exit 0
cd "$1"
ls -1 | grep -E '_(auto|daily)(_|$)' | sort -r | tail -n +"$(( $2 + 1 ))" | \\
while IFS= read -r d; do
    rm -rf -- "./$d"
    echo "pruned $d"
done
`

    // ---- The revert-window scripts (apply-with-revert transaction) ----

    // $1 = dest file; $2 = backup path; $3 = new content (a plain
    // positional argument — never interpolated into the script text,
    // the project-standard injection guard).
    readonly property string writeRevertScript: `
set -eu
dest="$1"; bak="$2"; content="$3"
mkdir -p "$(dirname "$dest")"
if [ -e "$dest" ]; then cp -a "$dest" "$bak"; fi
printf '%s' "$content" > "$dest"
echo "wrote $(basename "$dest") — revert window open"
`

    // $1 = dest file; $2 = backup path. Quietly a no-op when there is
    // nothing to revert (that's what makes the startup sweep free).
    readonly property string revertRestoreScript: `
set -eu
dest="$1"; bak="$2"
if [ -e "$bak" ]; then
    mv -f "$bak" "$dest"
    echo "reverted $(basename "$dest") to previous version"
else
    echo "no pending revert"
fi
`

    // $1 = backup path. Confirming keeps the NEW file; the backup of
    // the old one is deleted (the auto snapshot taken at step 1 still
    // holds it for durable undo).
    readonly property string revertDiscardScript: `
set -eu
rm -f "$1"
echo "display settings kept"
`

    // ---- Original Backup — idempotent, runs on every instantiation ----
    // $1 = original dir; $2 = quickshell config dir; $3 = hypr config dir.
    readonly property string originalScript: `
set -eu
dest="$1"; qsdir="$2"; hyprdir="$3"
[ -e "$dest/.complete" ] && exit 0
mkdir -p "$dest"
if [ -d "$qsdir" ];   then cp -a "$qsdir"   "$dest/config-quickshell"; fi
if [ -d "$hyprdir" ]; then cp -a "$hyprdir" "$dest/config-hypr"; fi
touch "$dest/.complete"
echo "original backup created"
`

    Component.onCompleted: {
        // Fire-and-forget through the same serialized Process; runs
        // before anything else can queue since instantiation is the
        // first touch by definition.
        run("original", originalScript,
            [originalDir, configDir + "/quickshell", configDir + "/hypr"]);
    }
}
