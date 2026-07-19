//=============================================================================
// !!! READ THIS BEFORE ADDING COMMENTS INSIDE THE JsonAdapter OR A FUNCTION !!!
//=============================================================================
//
// HARD-WON LESSON (2026-07-13, cost a multi-hour debugging session):
//
// Adding a specific multi-line comment block INSIDE the JsonAdapter block
// (between two adapter properties) silently broke this entire singleton.
// The exact trigger character was NOT positively identified -- see below --
// but REMOVING that comment block fixed it completely and immediately, proven
// by isolation testing (identical file with vs without the comment: broken vs
// working, 57 undefined warnings vs 0).
//
// WHAT THE FAILURE LOOKS LIKE (so you recognize it fast next time):
//   - NO syntax error. NO fatal log line. qmllint passes 100% clean.
//   - EVERY property and function on this singleton reads as `undefined` to
//     every other file. Cascades into Theme.qml, then every widget: tiny
//     fonts, no bar border, no popup fillets, broken settings window, giant
//     notifications. Looks catastrophic; is actually one comment.
//   - Detect with:  qs 2>&1 | grep -c undefined
//     0 (or a few transient DesktopClock ones) = healthy. ~50+ = broken.
//
// WHAT WE KNOW vs DON'T:
//   - PROVEN: that particular comment block, inside the adapter, broke it;
//     removing it fixed it. Quickshell compiles singletons ahead-of-time, so
//     the theory is its compiler choked on something in that comment.
//   - NOT PROVEN: the exact character. The broken comment contained backticks
//     (`) and double-quotes (") and em-dashes. BUT other comments in THIS
//     file (e.g. the fontFamilyOverride and themeName comments below) also
//     contain double-quotes and em-dashes inside the adapter and work fine --
//     so it is NOT simply "quotes or em-dashes break it." Something more
//     specific (a character sequence?) was the trigger and remains unisolated.
//
// THE SAFE RULE until someone isolates it: when adding a comment INSIDE the
// JsonAdapter block or a function body, keep it SHORT and plain ASCII. Avoid
// backticks entirely. If you must document at length, put the prose comment
// ABOVE the adapter/function block (in normal file scope, where the rich
// comment style is proven safe) rather than wedged between properties inside
// it. ALWAYS re-run the grep check above after editing this file.
//
// Full post-mortem: docs/PROBLEMS_AND_FIXES.md (2026-07-13 entry).
//
//=============================================================================
// FILE
//=============================================================================
//
// core/UserPrefs.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Persisted user preferences editable from widgets/TopBar/SettingsMenu.qml
// — the ones this project's `core/Settings.qml` explicitly does NOT cover,
// because Settings.qml's properties are hand-edited-in-the-file tuning
// knobs (per its own header: "Add to this file as real configurable
// behavior comes up"), not things meant to be flipped from a live UI and
// stick across restarts. This file is that second category: a small set
// of options with an actual on-screen control, saved to disk so choosing
// them once is permanent.
//
// Currently holds: which theme is active, whether the wallpaper picker
// caches its scan instead of rescanning every open, and the clock's
// 24-hour/seconds display (moved here FROM core/Settings.qml — see that
// file's own REVISION HISTORY).
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell               (Singleton, Quickshell.env)
// Quickshell.Io            (FileView, JsonAdapter, Process — see DESIGN NOTES)
// QtQuick
//
//=============================================================================
// USED BY
//=============================================================================
//
// core/Theme.qml (themeName — picks which themes/*.qml instance is active)
// widgets/TopBar/Clock.qml (clockUse24Hour, clockShowSeconds)
// widgets/TopBar/WallpaperPicker.qml (wallpaperCachingEnabled)
// widgets/TopBar/SettingsMenu.qml (reads AND writes every property here —
// this is the file that gives the user a UI for all of the above)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Theme.qml, Clock.qml, WallpaperPicker.qml, and SettingsMenu.qml all fail
// to resolve `UserPrefs` and the shell fails to load. Bigger blast radius
// than it looks for four properties — this is now a load-bearing file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY A SEPARATE FILE FROM core/Settings.qml, NOT MORE PROPERTIES THERE:
//
// Settings.qml's whole model is "guessed defaults become one-line tokens
// you hand-edit in the file" — there's no persistence layer, and every
// existing property assumes editing the file IS the save mechanism. Adding
// a runtime-writable, disk-persisted property to that same singleton would
// mean two totally different mutation models living in one file (some
// properties only ever change via a git commit, others get silently
// overwritten by whatever the settings UI last wrote) — confusing to
// read and easy to accidentally hand-edit a value that a JsonAdapter
// would then immediately overwrite from disk on next launch anyway. A
// separate file keeps the split obvious: Settings.qml = edit the file,
// UserPrefs.qml = use the UI (or hand-edit the JSON it reads/writes,
// which works too — see PERSISTENCE below).
//
// PERSISTENCE — FileView + JsonAdapter (verified against Quickshell's own
// docs, quickshell.org/docs/types/Quickshell.Io/JsonAdapter — NOT guessed):
// each `property` inside the JsonAdapter block becomes a JSON key,
// read on load and rewritten on any change (`onAdapterUpdated:
// writeAdapter()`), and `watchChanges + onFileChanged: reload()` means an
// external hand-edit of the JSON file (or a `git pull` on a synced
// dotfiles setup) picks up live instead of getting silently clobbered on
// next write.
//
// WHY ~/.local/state, NOT INSIDE THE REPO:
//
// This file lives at ~/.config/quickshell/user-prefs.json if pointed at
// the repo — deliberately NOT done here. This project's config files
// (Settings.qml, Theme.qml, themes/*.qml) are all meant to be committed to
// the maintainer's dotfiles git repo; a JSON file that the shell itself
// rewrites every time a setting changes is exactly the kind of file that
// does NOT belong in that repo (constant unstaged diffs, or an accidental
// commit of a real-machine path). XDG_STATE_HOME is the correct home for
// "state that should survive a reboot but isn't config you'd hand-edit or
// share" — falls back to ~/.local/state if the env var isn't set, which
// covers every actually-existing Linux setup.
//
// CORRUPT/INVALID JSON ON DISK (verified live, 2026-07-09): JsonAdapter
// logs one WARN ("Failed to deserialize json: ...") and KEEPS ITS
// CURRENT IN-MEMORY VALUES — nothing resets to defaults, the UI keeps
// working, the shell effectively runs on last-known-good. Corollaries:
// (a) the shell self-heals a corrupt prefs file the moment any toggle
// is flipped (a write serializes valid JSON from memory over the
// garbage); (b) the same mechanism means a MALFORMED HAND-EDIT to
// user-prefs.json is silently clobbered by the next toggle write —
// hand-edit this file only with valid JSON, or your edit is lost.
//
// THE DIRECTORY MUST EXIST BEFORE FileView WILL WRITE — unlike the file
// itself (FileView creates a MISSING FILE on first write), it does NOT
// create missing parent directories. `mkdir -p` runs once via a Process
// in Component.onCompleted so
// this works out of the box on a fresh machine with no manual step.
//
// DEFAULTS MATCH WHAT'S CURRENTLY HARDCODED, so the very first launch
// after adding this file changes nothing visually — themeName defaults to
// "Honeycomb" (core/Theme.qml's current hardcoded active theme),
// wallpaperCachingEnabled defaults to true (this is the behavior the
// maintainer actually asked for), and the clock defaults match the old
// core/Settings.qml values they're replacing.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-12  (Opus) setFontFamilyOverride no longer validates the
//             name against Qt.fontFamilies(). That guard rejected any
//             family not exactly present in Qt's list — but Qt's
//             reported strings didn't match the picker's names on a
//             real machine, so EVERY real pick was silently dropped
//             and only "" (theme default) ever persisted: Apply looked
//             like it worked (pending cleared) then snapped back to
//             default. The picker (SettingsWindow.qml, same-day note)
//             now derives its list straight from Qt.fontFamilies(), so
//             whatever it offers is already a valid Qt string; the
//             setter just stores it. An unresolvable name would fall
//             back at render (no crash), so no backstop is lost.
// 2026-07-12  (Sonnet 5) barPaddingTop/Side/BottomOverride + first
//             font family override (see earlier entry same day) got
//             a v2: barPaddingBottomOverride can now go genuinely
//             negative (canceling the persistent under-bar gap from
//             Hyprland's own gaps_out), so its "follow theme" sentinel
//             moved from -1 to barPaddingBottomOffSentinel (-9999) —
//             top/side are unaffected, still -1. Also added
//             hyprActiveBorderUseThemeColor/CustomColor — Hyprland
//             page, active-window border color, same theme-or-hex
//             pattern as barBorder*.
// 2026-07-11  (Fable 5) Notification position (corner + x/y offsets)
//             and the full desktop clock pref set (enabled, corner
//             incl. centered, x/y offsets, per-monitor, text color
//             theme-or-hex, shadow on/off + color theme-or-hex) —
//             backing the settings window's Notifications additions
//             and new Desktop page (thoughts_next_session.txt).
//             desktopClockCorner/Margin migrated FROM
//             core/Settings.qml; shared _validHex/_clampOffset
//             helpers (three hex setters now exist).
//
// 2026-07-10  (Fable 5) Added bar-border overrides for the Appearance
//             page: `barBorderWidthOverride` (-1 = follow theme),
//             `barBorderUseThemeColor`, `barBorderCustomColor`
//             (hex-validated in the setter — the backstop; the
//             settings window validates before staging).
//
// 2026-07-05  Created. First use of FileView/JsonAdapter in this project —
//             activates real theme switching (core/Theme.qml's `active:`
//             line was hardcoded since 2026-07-01, documented there as
//             "planned, not done") and moves clockUse24Hour/
//             clockShowSeconds out of core/Settings.qml (see that file's
//             own REVISION HISTORY for the removal). Backs
//             widgets/TopBar/SettingsMenu.qml, the new settings dropdown.
//
//=============================================================================

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    signal preferencesReloaded()

    function reloadFromDisk(): void {
        prefsFile.reload();
        Qt.callLater(function() { root.preferencesReloaded(); });
    }

    readonly property string stateDir: {
        const base = Quickshell.env("XDG_STATE_HOME");
        return (base && base.length > 0 ? base : Quickshell.env("HOME") + "/.local/state") + "/quickshell";
    }

    // ---- Public read surface — widgets bind to THESE ----
    readonly property string themeName: adapter.themeName
    readonly property real fontScale: adapter.fontScale
    readonly property bool notifShowAppName: adapter.notifShowAppName
    readonly property int notifIconSize: adapter.notifIconSize
    readonly property int notifBodyLines: adapter.notifBodyLines
    readonly property real notifFontScale: adapter.notifFontScale
    readonly property string notifCorner: adapter.notifCorner
    readonly property int notifOffsetX: adapter.notifOffsetX
    readonly property int notifOffsetY: adapter.notifOffsetY
    readonly property bool desktopClockEnabled: adapter.desktopClockEnabled
    readonly property string desktopClockCorner: adapter.desktopClockCorner
    readonly property int desktopClockOffsetX: adapter.desktopClockOffsetX
    readonly property int desktopClockOffsetY: adapter.desktopClockOffsetY
    readonly property string desktopClockMonitor: adapter.desktopClockMonitor
    readonly property bool desktopClockUseThemeColor: adapter.desktopClockUseThemeColor
    readonly property string desktopClockCustomColor: adapter.desktopClockCustomColor
    readonly property bool desktopClockShadowEnabled: adapter.desktopClockShadowEnabled
    readonly property bool desktopClockShadowUseThemeColor: adapter.desktopClockShadowUseThemeColor
    readonly property string desktopClockShadowCustomColor: adapter.desktopClockShadowCustomColor
    readonly property bool desktopClockShowWeatherIcon: adapter.desktopClockShowWeatherIcon
    readonly property bool desktopClockShowTemperature: adapter.desktopClockShowTemperature
    readonly property real desktopClockScale: adapter.desktopClockScale
    readonly property int desktopClockShadowStrength: adapter.desktopClockShadowStrength
    readonly property int desktopClockShadowOffsetX: adapter.desktopClockShadowOffsetX
    readonly property int desktopClockShadowOffsetY: adapter.desktopClockShadowOffsetY
    readonly property int hyprGapsIn: adapter.hyprGapsIn
    readonly property int hyprGapsOut: adapter.hyprGapsOut
    readonly property int hyprBorderSize: adapter.hyprBorderSize
    readonly property int hyprRounding: adapter.hyprRounding
    // Hyprland active-window border color (settings window, Hyprland
    // page, 2026-07-12) — same use-theme-or-custom-hex pattern as
    // barBorderUseThemeColor/barBorderCustomColor. "Theme" here means
    // this shell's Theme.colorAccent (there's no separate per-theme
    // Hyprland token — the shell's accent color IS "the theme" for
    // this purpose). Unlike the bar border, this writes into
    // generated/appearance.lua (general.col.active_border) via
    // ConfigManager's hypr regen, so it also requires the one-time
    // hand-edit to user/look.lua described in ConfigManager.qml's
    // DESIGN NOTES — it does nothing until that's done.
    readonly property bool hyprActiveBorderUseThemeColor: adapter.hyprActiveBorderUseThemeColor
    readonly property string hyprActiveBorderCustomColor: adapter.hyprActiveBorderCustomColor
    readonly property int barBorderWidthOverride: adapter.barBorderWidthOverride
    readonly property bool barBorderUseThemeColor: adapter.barBorderUseThemeColor
    readonly property string barBorderCustomColor: adapter.barBorderCustomColor
    // Bar padding overrides (settings window, Appearance page,
    // 2026-07-12) — Top/Side use -1 = follow theme (same convention as
    // barBorderWidthOverride: a real padding value is never negative
    // there). Bottom is DIFFERENT (2026-07-12, v2): the maintainer
    // found that even at 0 there's still a visible gap under the bar
    // (Hyprland's own gaps_out reserves space on every screen edge,
    // stacking with the shell's own exclusiveZone), so Bottom needs to
    // go negative to cancel that out — which means -1 can no longer
    // double as its "follow theme" sentinel. barPaddingBottomOffSentinel
    // is that sentinel instead, parked far outside any real padding
    // value anyone would intentionally choose. Top/side covers left
    // AND right symmetrically (no maintainer ask yet for asymmetric
    // left/right, so one knob instead of two).
    readonly property int barPaddingBottomOffSentinel: -9999
    readonly property int barPaddingTopOverride: adapter.barPaddingTopOverride
    readonly property int barPaddingSideOverride: adapter.barPaddingSideOverride
    readonly property int barPaddingBottomOverride: adapter.barPaddingBottomOverride
    // "" = follow the active theme's fontFamily; anything else is a
    // family name pulled from Qt.fontFamilies() by the settings
    // window dropdown (so it's always something actually installed).
    readonly property string fontFamilyOverride: adapter.fontFamilyOverride
    readonly property string wallpaperTransitionType: adapter.wallpaperTransitionType
    readonly property real wallpaperTransitionDuration: adapter.wallpaperTransitionDuration
    readonly property int wallpaperTransitionFps: adapter.wallpaperTransitionFps
    readonly property real wallpaperTransitionAngle: adapter.wallpaperTransitionAngle
    readonly property string wallpaperTransitionPos: adapter.wallpaperTransitionPos
    readonly property string wallpapersPath: adapter.wallpapersPath
    readonly property int settingsWindowDefaultWidth: adapter.settingsWindowDefaultWidth
    readonly property int settingsWindowDefaultHeight: adapter.settingsWindowDefaultHeight
    readonly property bool wallpaperCachingEnabled: adapter.wallpaperCachingEnabled
    readonly property bool clockUse24Hour: adapter.clockUse24Hour
    readonly property bool clockShowSeconds: adapter.clockShowSeconds

    // ---- Public write surface — SettingsMenu.qml calls these, never
    // writes `adapter.*` directly, so every mutation path is in one place ----
    function setHyprGapsIn(v: int): void {
        adapter.hyprGapsIn = Math.min(30, Math.max(0, v));
    }

    function setHyprGapsOut(v: int): void {
        adapter.hyprGapsOut = Math.min(60, Math.max(0, v));
    }

    function setHyprBorderSize(v: int): void {
        adapter.hyprBorderSize = Math.min(10, Math.max(0, v));
    }

    function setHyprRounding(v: int): void {
        adapter.hyprRounding = Math.min(30, Math.max(0, v));
    }

    function setHyprActiveBorderUseThemeColor(v: bool): void {
        adapter.hyprActiveBorderUseThemeColor = v;
    }

    function setHyprActiveBorderCustomColor(v: string): void {
        if (_validHex(v))
            adapter.hyprActiveBorderCustomColor = v;
    }

    // Bar border overrides (settings window, Appearance page,
    // 2026-07-10). Width -1 = no override, follow the theme (which by
    // default follows hyprBorderSize — see core/Theme.qml).
    function setBarBorderWidthOverride(v: int): void {
        adapter.barBorderWidthOverride = Math.min(12, Math.max(-1, v));
    }

    function setBarBorderUseThemeColor(v: bool): void {
        adapter.barBorderUseThemeColor = v;
    }

    function setBarBorderCustomColor(v: string): void {
        // Validation via the shared _validHex (see the helpers above)
        // — bad input dropped silently; the settings window validates
        // before staging, so this is the backstop.
        if (_validHex(v))
            adapter.barBorderCustomColor = v;
    }

    // Bar padding overrides (settings window, Appearance page,
    // 2026-07-12). -1 = no override, follow the theme's barMargin
    // (same convention as setBarBorderWidthOverride). Clamped
    // generously — a floating bar padded off-screen is a foot-gun,
    // not a feature.
    function setBarPaddingTopOverride(v: int): void {
        adapter.barPaddingTopOverride = Math.min(200, Math.max(-1, v));
    }

    function setBarPaddingSideOverride(v: int): void {
        adapter.barPaddingSideOverride = Math.min(200, Math.max(-1, v));
    }

    function setBarPaddingBottomOverride(v: int): void {
        // Anything AT or below the sentinel collapses to the sentinel
        // itself (the "follow theme" state) — only the settings
        // window's toggle should ever actually send the sentinel, but
        // clamping defensively means a stray call can't wedge a
        // half-off state. Otherwise: real px value, clamped generously
        // negative (canceling out Hyprland's gaps_out) to generously
        // positive.
        adapter.barPaddingBottomOverride =
            v <= barPaddingBottomOffSentinel ? barPaddingBottomOffSentinel
                : Math.min(200, Math.max(-100, v));
    }

    // "" = follow theme; anything else is a family name the settings
    // window's curated dropdown offered.
    //
    // NO Qt.fontFamilies() validation (2026-07-12, Opus): this guard
    // used to reject any name not exactly present in Qt.fontFamilies().
    // On a real machine Qt's reported family strings didn't match the
    // curated nerd-font names (only the theme's own default matched),
    // so EVERY real pick failed the check and the assignment was
    // silently skipped — Apply appeared to work (pending cleared) but
    // the value never landed and the UI snapped back to "theme
    // default". Same exact-match trap that had gutted the dropdown
    // list. A name that truly isn't installed just falls back to Qt's
    // default at render (no crash), so we accept any string; the
    // dropdown is the real gate on what's offerable.
    function setFontFamilyOverride(v: string): void {
        adapter.fontFamilyOverride = v;
    }

    function setWallpaperTransitionType(v: string): void {
        if (["none","simple","fade","left","right","top","bottom","wipe","wave","grow","center","any","outer","random"].indexOf(v) !== -1)
            adapter.wallpaperTransitionType = v;
    }
    function setWallpaperTransitionDuration(v: real): void {
        adapter.wallpaperTransitionDuration = Math.min(5.0, Math.max(0.1, v));
    }
    function setWallpaperTransitionFps(v: int): void {
        adapter.wallpaperTransitionFps = Math.min(240, Math.max(1, v));
    }
    function setWallpaperTransitionAngle(v: real): void {
        adapter.wallpaperTransitionAngle = Math.min(360, Math.max(0, v));
    }
    function setWallpaperTransitionPos(v: string): void {
        if (["center","top-left","top-right","bottom-left","bottom-right"].indexOf(v) !== -1)
            adapter.wallpaperTransitionPos = v;
    }
    function setWallpapersPath(v: string): void {
        const cleaned = v.trim();
        if (cleaned.length > 0)
            adapter.wallpapersPath = cleaned;
    }
    function setSettingsWindowDefaultWidth(v: int): void {
        adapter.settingsWindowDefaultWidth = Math.min(1800, Math.max(700, v));
    }
    function setSettingsWindowDefaultHeight(v: int): void {
        adapter.settingsWindowDefaultHeight = Math.min(1200, Math.max(500, v));
    }
    function setNotifShowAppName(v: bool): void {
        adapter.notifShowAppName = v;
    }

    function setNotifIconSize(v: int): void {
        adapter.notifIconSize = Math.min(96, Math.max(24, v));
    }

    function setNotifBodyLines(v: int): void {
        adapter.notifBodyLines = Math.min(10, Math.max(1, v));
    }

    function setNotifFontScale(v: real): void {
        adapter.notifFontScale = Math.min(2.0, Math.max(0.8, v));
    }

    // ---- Shared validators (2026-07-11 — three hex colors and two
    // corner pickers now exist; inline regexes stopped scaling) ----
    // #RRGGBB, or 8 digits read Qt-style #AARRGGBB (alpha FIRST — not
    // CSS's trailing alpha). Same rule the settings window enforces
    // before staging; these setters are the backstop.
    function _validHex(v: string): bool {
        return /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(v);
    }
    // Offsets are "distance from the chosen corner, px" — positive
    // moves inward. Clamped generously (a fine-tune knob, not a
    // layout engine): enough to cross any sane monitor, sign allowed
    // so a widget can tuck INTO the base inset (e.g. under the bar).
    function _clampOffset(v: int): int {
        return Math.min(2000, Math.max(-500, v));
    }

    // Notification popup position (settings window, Notifications
    // page, 2026-07-11). Corner whitelist — an unrecognized string
    // is dropped, widgets never see garbage.
    function setNotifCorner(v: string): void {
        if (["top-left", "top-right", "bottom-left", "bottom-right"].indexOf(v) !== -1)
            adapter.notifCorner = v;
    }

    function setNotifOffsetX(v: int): void {
        adapter.notifOffsetX = _clampOffset(v);
    }

    function setNotifOffsetY(v: int): void {
        adapter.notifOffsetY = _clampOffset(v);
    }

    // Desktop clock (settings window, Desktop page, 2026-07-11 —
    // migrated OUT of core/Settings.qml per the plan's rule: when the
    // settings window takes ownership of a value, it moves here).
    function setDesktopClockEnabled(v: bool): void {
        adapter.desktopClockEnabled = v;
    }

    function setDesktopClockCorner(v: string): void {
        if (["top-left", "top-right", "bottom-left", "bottom-right", "centered"].indexOf(v) !== -1)
            adapter.desktopClockCorner = v;
    }

    function setDesktopClockOffsetX(v: int): void {
        adapter.desktopClockOffsetX = _clampOffset(v);
    }

    function setDesktopClockOffsetY(v: int): void {
        adapter.desktopClockOffsetY = _clampOffset(v);
    }

    // "" = every monitor; otherwise a screen name (e.g. "DP-1"). NOT
    // whitelisted — screen names are only knowable at runtime, and a
    // name for a monitor that's currently unplugged must stay legal
    // (the clock just doesn't appear until it's back).
    function setDesktopClockMonitor(v: string): void {
        adapter.desktopClockMonitor = v;
    }

    function setDesktopClockUseThemeColor(v: bool): void {
        adapter.desktopClockUseThemeColor = v;
    }

    function setDesktopClockCustomColor(v: string): void {
        if (_validHex(v))
            adapter.desktopClockCustomColor = v;
    }

    function setDesktopClockShadowEnabled(v: bool): void {
        adapter.desktopClockShadowEnabled = v;
    }

    function setDesktopClockShadowUseThemeColor(v: bool): void {
        adapter.desktopClockShadowUseThemeColor = v;
    }

    function setDesktopClockShadowCustomColor(v: string): void {
        if (_validHex(v))
            adapter.desktopClockShadowCustomColor = v;
    }

    function setDesktopClockShowWeatherIcon(v: bool): void { adapter.desktopClockShowWeatherIcon = v; }
    function setDesktopClockShowTemperature(v: bool): void { adapter.desktopClockShowTemperature = v; }
    function setDesktopClockScale(v: real): void { adapter.desktopClockScale = Math.min(2.5, Math.max(0.5, v)); }
    function setDesktopClockShadowStrength(v: int): void { adapter.desktopClockShadowStrength = Math.min(100, Math.max(0, v)); }
    function setDesktopClockShadowOffsetX(v: int): void { adapter.desktopClockShadowOffsetX = Math.min(20, Math.max(-20, v)); }
    function setDesktopClockShadowOffsetY(v: int): void { adapter.desktopClockShadowOffsetY = Math.min(20, Math.max(-20, v)); }

    function setFontScale(v: real): void {
        // Clamp to sane bounds — a fat-fingered 14.0 would make the
        // bar unusable, and this file is the shell's own write path.
        adapter.fontScale = Math.min(2.5, Math.max(0.8, v));
    }

    function setThemeName(name: string): void {
        adapter.themeName = name;
    }

    function setWallpaperCachingEnabled(enabled: bool): void {
        adapter.wallpaperCachingEnabled = enabled;
    }

    function setClockUse24Hour(enabled: bool): void {
        adapter.clockUse24Hour = enabled;
    }

    function setClockShowSeconds(enabled: bool): void {
        adapter.clockShowSeconds = enabled;
    }

    // Ensure the directory exists before FileView ever tries to write —
    // see DESIGN NOTES. Harmless/no-op if it's already there.
    Component.onCompleted: mkdirProc.running = true

    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.stateDir]
    }

    FileView {
        id: prefsFile
        path: root.stateDir + "/user-prefs.json"
        watchChanges: true
        onFileChanged: root.reloadFromDisk()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: adapter

            // Must match a key in core/Theme.qml's `themes` map exactly
            // (currently "Default" or "Honeycomb"). An unrecognized value
            // falls back safely — see Theme.qml.
            property string themeName: "Honeycomb"
            // Multiplier for Theme.fontSize. Moved here from core/Settings.qml
            // 2026-07-09 when the settings window took ownership (the plan's
            // per-page migration rule). 1.4 was the long-standing Settings value.
            property real fontScale: 1.4
        // Notification card prefs (settings window, Notifications
        // page, 2026-07-09). notifShowAppName defaults FALSE per the
        // maintainer's own hand-edit (THOUGHTS.txt: the app name
        // shared the summary's row and truncated long song titles).
        // Other defaults match the previously hardcoded card values.
        property bool notifShowAppName: false
        property int notifIconSize: 48
        property int notifBodyLines: 4
        property real notifFontScale: 1.0
        // Notification popup position (2026-07-11). Defaults MATCH the
        // previously hardcoded placement (top-right, offsets 0 — the
        // widget's own base margins already clear the bar), so first
        // launch after the migration changes nothing visually.
        property string notifCorner: "top-right"
        property int notifOffsetX: 0
        property int notifOffsetY: 0
        // Desktop clock (2026-07-11) — corner/offsets MIGRATED from
        // core/Settings.qml (see its revision history for the
        // removal); enabled/monitor/colors/shadow are new. Defaults
        // reproduce the old hardcoded look exactly: top-left, the old
        // 32px margin as both offsets, every monitor... which is ALSO
        // a behavior change worth noting — the old widget was
        // default-output-only; "" now means all. Text follows theme
        // foreground, shadow on, shadow follows theme background
        // (that was Text.Raised + colorBackground, hardcoded).
        property bool desktopClockEnabled: true
        property string desktopClockCorner: "top-left"
        property int desktopClockOffsetX: 32
        property int desktopClockOffsetY: 32
        property string desktopClockMonitor: ""
        property bool desktopClockUseThemeColor: true
        property string desktopClockCustomColor: "#ffffff"
        property bool desktopClockShadowEnabled: true
        property bool desktopClockShadowUseThemeColor: true
        property string desktopClockShadowCustomColor: "#000000"
        property bool desktopClockShowWeatherIcon: true
        property bool desktopClockShowTemperature: true
        property real desktopClockScale: 1.0
        property int desktopClockShadowStrength: 100
        property int desktopClockShadowOffsetX: 2
        property int desktopClockShadowOffsetY: 2
        // Hyprland look values (settings window, Hyprland page,
        // 2026-07-09). Defaults MATCH the live hyprland.lua at the
        // time of the generated/user split — so the first generated
        // appearance.lua is a no-op change visually.
        property int hyprGapsIn: 5
        property int hyprGapsOut: 10
        property int hyprBorderSize: 2
        property int hyprRounding: 10
        // Hyprland active border color (Hyprland page, 2026-07-12).
        // Defaults to "follow theme" — true/empty custom means this
        // pref writes nothing different until someone turns it on;
        // the custom default hex matches barBorderCustomColor's for
        // visual consistency if they DO turn it on immediately.
        property bool hyprActiveBorderUseThemeColor: true
        property string hyprActiveBorderCustomColor: "#35e0b4"
        // Bar border overrides (Appearance page, 2026-07-10) — these
        // sit ABOVE the theme's barBorder tokens; see core/Theme.qml
        // for the precedence chain. Width -1 = follow theme.
        property int barBorderWidthOverride: -1
        property bool barBorderUseThemeColor: true
        property string barBorderCustomColor: "#35e0b4"
        // Bar padding overrides (Appearance page, 2026-07-12) — every
        // edge defaults to "follow theme" (top/side: -1, bottom: the
        // -9999 sentinel — see barPaddingBottomOffSentinel above for
        // why bottom's is different), reproducing the pre-existing
        // look exactly (every edge uses the active theme's single
        // barMargin token, same as before this feature existed).
        property int barPaddingTopOverride: -1
        property int barPaddingSideOverride: -1
        property int barPaddingBottomOverride: -9999
        // Font family override (Appearance page, 2026-07-12) — ""
        // follows the active theme's fontFamily token, so a fresh
        // install changes nothing visually.
        property string fontFamilyOverride: ""
        property string wallpaperTransitionType: "wipe"
        property real wallpaperTransitionDuration: 0.8
        property int wallpaperTransitionFps: 60
        property real wallpaperTransitionAngle: 45.0
        property string wallpaperTransitionPos: "center"
        property string wallpapersPath: "~/Pictures/Wallpapers"
        // Initial Settings window geometry. The current historical defaults
        // are preserved so laptop behavior does not change until customized.
        property int settingsWindowDefaultWidth: 1036
        property int settingsWindowDefaultHeight: 616

            // If true, the wallpaper picker scans the folder once and
            // keeps that list (and every already-decoded thumbnail) in
            // memory across opens instead of re-scanning + re-decoding
            // every time — see widgets/TopBar/WallpaperPicker.qml's
            // DESIGN NOTES. Default true per the maintainer's request;
            // flip off if wallpapers get added/removed often enough that
            // stale results are more annoying than the reopen delay.
            property bool wallpaperCachingEnabled: true

            // Moved from core/Settings.qml — see this file's DESIGN NOTES
            // for why. Same defaults as before the move.
            property bool clockUse24Hour: false
            property bool clockShowSeconds: false
        }
    }
}
