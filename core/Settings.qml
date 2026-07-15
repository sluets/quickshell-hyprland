//=============================================================================
// FILE
//=============================================================================
//
// core/Settings.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Holds user-configurable BEHAVIOR options — things you'd want to change
// about how the shell works, as opposed to how it looks (that's Theme.qml's
// job) or live runtime state that changes on its own (that's Globals.qml's
// job). Every property here is a hand-edit-the-file tuning knob with no
// persistence layer — for options with an actual on-screen control that
// need to survive a restart, see the newer core/UserPrefs.qml instead (its
// DESIGN NOTES explain the split).
//
// Examples of what belongs here: which monitors show a bar, whether
// the bar auto-hides, click-to-mute vs scroll-to-adjust for volume,
// global text scaling, etc.
//
// Examples of what does NOT belong here: colors/fonts (Theme.qml),
// current volume level or battery percentage (Globals.qml, or more likely
// a services/ file once those exist), or anything with a live toggle in
// widgets/TopBar/SettingsMenu.qml (core/UserPrefs.qml).
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell (for the Singleton type)
// QtQuick
//
//=============================================================================
// USED BY
//=============================================================================
//
// Any file that does `import qs.core` and references `Settings.something`.
// Currently: shell.qml reads `barExcludedScreens`.
// widgets/TopBar/NowPlaying.qml reads `nowPlayingIgnoredPlayers` and
// `nowPlayingMaxLength`. widgets/TopBar/WallpaperPicker.qml reads the
// whole `wallpaper*` / `wallpapers*` block. // services/Audio.qml reads `volumeStep`. widgets/PowerMenu/PowerScreen.qml
// reads `powerScreenDimOpacity` and `powerScreenIconSize`.
// `barPosition` is declared but still not read by anything — see
// DESIGN NOTES.
// (widgets/TopBar/Clock.qml used to read `clockUse24Hour`/
// `clockShowSeconds` here — MOVED to core/UserPrefs.qml, see REVISION
// HISTORY.)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Any widget referencing `Settings.something` will fail to resolve that
// name. As of this writing that includes shell.qml (bar-per-screen
// filtering), widgets/TopBar/NowPlaying.qml, widgets/PowerMenu/
// PowerScreen.qml — removing this
// file breaks a good chunk of the shell, not just something silent. See
// docs/REVISION_HISTORY.md before assuming otherwise.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// NOW A SINGLETON — see core/Theme.qml's DESIGN NOTES for the full
// explanation of why. In short: no instantiating this anywhere and
// passing it down as a property. Any file gets it via `import qs.core`
// and reads `Settings.barPosition` directly.
//
// Add to this file as real configurable behavior comes up, rather than
// letting widgets grow their own ad-hoc settings — UNLESS it's the kind
// of option a settings-menu UI should control and persist, in which case
// it goes in core/UserPrefs.qml instead (see that file's DESIGN NOTES).
//
// WHERE fontScale WENT (2026-07-09): it lived here for the project's
// first week, deliberately theme-independent ("make all text bigger
// regardless of theme" is a preference, not a design choice — putting
// it inside a theme file would let theme switches silently reset your
// text size). That rationale still holds; only the ADDRESS changed:
// it's now `UserPrefs.fontScale` (persisted, editable in the settings
// window), and Theme.fontSize computes `active.fontSize *
// UserPrefs.fontScale`.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  (Fable 5) REMOVED `desktopClockCorner` and
//             `desktopClockMargin` — moved to core/UserPrefs.qml
//             (corner + per-axis desktopClockOffsetX/Y) when the
//             settings window's Desktop page took ownership; same
//             migration rule as fontScale below. Only consumer was
//             widgets/Desktop/DesktopClock.qml, updated in the same
//             session — grep verified. desktopClockFontSize stays (no
//             UI asked for it).
// 2026-07-09  (Fable 5) REMOVED `fontScale` — moved to core/UserPrefs.qml
//             (persisted, editable from the new settings window). Its
//             ONLY consumer, core/Theme.qml's fontSize computation,
//             was updated in the same edit — grep verified, per the
//             stale-reference lesson this project keeps relearning.
// 2026-07-09  (Fable 5) Added configAutoSnapshotKeep for the new
//             services/ConfigManager.qml snapshot engine (settings-
//             manager plan, Phase 1).
// 2026-07-05  REMOVED `clockUse24Hour` and `clockShowSeconds` — moved to
//             the new core/UserPrefs.qml, which persists them and gives
//             them a real UI control (widgets/TopBar/SettingsMenu.qml).
//             See UserPrefs.qml's DESIGN NOTES for why they didn't just
//             stay here. Same default values, different file.
// 2026-07-05  Added `powerScreenDimOpacity` (0.55) and
//             `powerScreenIconSize` (64), read by the new
//             widgets/PowerMenu/PowerScreen.qml — replaces the old
//             SystemMenu.qml dropdown with a fullscreen power screen.
// 2026-07-05  Added `barExcludedScreens` ([]) — regex list matched
//             against screen names by shell.qml; the bar appears
//             on every monitor NOT matched (default: all of them).
//             Added `wallpaperTransitionAngle` (45) and changed
//             `wallpaperTransitionType` default "grow" -> "wipe" — a
//             45° wipe sweeps from the top-right corner to the
//             bottom-left (awww angle semantics verified in the swww
//             source: 0 = right-to-left, 90 = top-to-bottom).
// 2026-07-04  (post-first-live-test) Added `wallpaperShuffleDefault`
//             (false) — initial state of the picker's Shuffle checkbox.
// 2026-07-04  (post-first-live-test) `wallpapersThumbDir` default
//             changed "thumbs" -> ".thumbs" per maintainer preference
//             (hidden dir, doesn't clutter the wallpapers folder).
// 2026-07-04  Added `osdHideDelay` (1500) + `osdWidth` (320) for the
//             new widgets/OSD/VolumeOsd.qml, and `notifWidth` (380),
//             `notifDefaultTimeout` (5000), `notifMaxVisible` (5) for
//             the new widgets/Notifications/NotificationPopups.qml.
// 2026-07-04  Added the wallpaper-picker block — `wallpapersPath`
//             ("~/Pictures/Wallpapers"), `wallpapersThumbDir`
//             ("thumbs"), `wallpaperThumbSize` (120),
//             `wallpaperGridColumns` (5), `wallpaperGridMaxRows` (3),
//             `wallpaperTransitionType` ("grow"),
//             `wallpaperTransitionDuration` (0.8s), and
//             `wallpaperTransitionFps` (60) — all read by the new
//             widgets/TopBar/WallpaperPicker.qml.
// 2026-07-04  Added `launcherWidth` (480), `launcherMaxResults` (8),
//             and `launcherTerminalCommand` (["kitty"]), read by the
//             new widgets/TopBar/Launcher.qml.
// 2026-07-03  Added `volumeStep` (default 0.05), read by
//             services/Audio.qml's incrementVolume()/decrementVolume()
//             for the new scroll-to-adjust behavior.
// 2026-07-02  Flipped `clockUse24Hour` default from true to false — the
//             12-hour/AM-PM format string already existed in
//             widgets/TopBar/Clock.qml but was never the default, so
//             AM/PM never actually showed.
// 2026-07-01  Added `nowPlayingIgnoredPlayers` (default `["firefox"]`)
//             and `nowPlayingMaxLength` (default 60), read by the new
//             widgets/TopBar/NowPlaying.qml.
// 2026-07-01  Removed `workspaceCount` — widgets/TopBar/Workspaces.qml
//             switched to showing only workspaces that actually exist
//             (via Hyprland.workspaces) instead of a fixed numbered
//             range, so this stopped being read by anything.
// 2026-07-01  Bumped `fontScale` default from 1.0 to 1.4 — the bar's
//             text read noticeably smaller than intended at 1.0 on
//             this display. This is exactly the kind of adjustment
//             `fontScale` was built for; no other file needed to change.
// 2026-07-01  Added `workspaceCount`, read by the new
//             widgets/TopBar/Workspaces.qml.
// 2026-07-01  Added `fontScale` (default 1.0) — a multiplier applied on
//             top of whatever the active theme's base `fontSize` is.
//             Read by core/Theme.qml, not by widgets directly (widgets
//             should still only ever read `Theme.fontSize`).
// 2026-07-01  Added `clockUse24Hour` and `clockShowSeconds`, read by the
//             new widgets/TopBar/Clock.qml. [Both REMOVED 2026-07-05 —
//             see top entry.]
// 2026-07-01  Converted to `pragma Singleton`.
//
//=============================================================================

pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Which edge of the screen the bar attaches to.
    // Valid values: "top", "bottom"
    // NOTE: not actually read by TopBar.qml yet — the bar is still
    // hardcoded to anchor top. See docs/REVISION_HISTORY.md.
    property string barPosition: "top"

    // ---- Bar placement (shell.qml) ----
    // The bar appears on EVERY monitor whose name does NOT match one of
    // these regexes (matched against Quickshell screen names — the same
    // names `hyprctl monitors` shows, e.g. "DP-1", "HDMI-A-1"). Empty
    // by default: a bar everywhere, no monitor names to configure for a
    // correct first run. To turn the bar off on one output:
    //     barExcludedScreens: ["HDMI-A-1"]
    property var barExcludedScreens: []


    // ---- Volume (services/Audio.qml, widgets/TopBar/Volume.qml) ----
    // How much one scroll notch (on the bar widget or the popout
    // slider) changes the volume. 0.05 = 5%.
    property real volumeStep: 0.05

    // ---- Now Playing (widgets/TopBar/NowPlaying.qml) ----
    // MPRIS players whose name should never be shown, even if they're
    // the only thing playing. Case-insensitive substring match against
    // the player's D-Bus service name / desktop entry. Default excludes
    // Firefox — browser tabs playing audio/video register as MPRIS
    // players the same as real media apps, which gets noisy fast.
    property var nowPlayingIgnoredPlayers: ["firefox"]

    // Track title+artist text longer than this gets truncated with an
    // ellipsis, so one long tag doesn't stretch the whole bar.
    property int nowPlayingMaxLength: 60

    // ---- Launcher (widgets/TopBar/Launcher.qml) ----
    // Width of the launcher popout's search field, in px. The popout is
    // at least this wide; long app names/comments elide rather than
    // stretching it.
    property int launcherWidth: 480

    // Most results shown at once — a short query can match a lot of
    // apps, and an uncapped list would unroll a screen-tall popup.
    property int launcherMaxResults: 8

    // What .desktop entries marked Terminal=true get wrapped in (htop
    // and friends would otherwise launch with no terminal and instantly
    // die). The entry's own command gets appended to this. kitty runs a
    // trailing command directly, no `-e` needed.
    property var launcherTerminalCommand: ["kitty"]

    // ---- Wallpaper picker (widgets/TopBar/WallpaperPicker.qml) ----
    // Folder scanned for wallpapers (top level only, no recursion).
    // A leading "~" is expanded by the widget.
    property string wallpapersPath: "~/Pictures/Wallpapers"

    // Subdirectory of wallpapersPath holding the pre-squared
    // imagemagick thumbnails (hidden by default so it doesn't show up
    // in file managers next to the wallpapers themselves). Matched to
    // wallpapers by basename WITHOUT extension (.thumbs/sunset.png
    // matches sunset.jpg). A wallpaper with no matching thumb still
    // shows — the picker falls back to a downscaled crop of the full
    // image.
    property string wallpapersThumbDir: ".thumbs"

    // Displayed size of each thumbnail cell's image, in px (cells add
    // a little padding on top of this). Also used as the decode size,
    // so bigger = crisper but more memory per cell.
    property int wallpaperThumbSize: 120

    // Grid shape: how many thumbnails per row, and how many rows show
    // before the grid scrolls (wheel/drag) instead of growing taller.
    property int wallpaperGridColumns: 5
    property int wallpaperGridMaxRows: 3

    // wallpaperTransition* MIGRATED to UserPrefs.qml 2026-07-13 — the
    // settings window's Appearance page now owns these (Wallpaper
    // Transition section), per this project's per-page-ownership rule
    // ("when the settings window takes ownership of a value, it moves
    // to UserPrefs"). Old comment here (valid --transition-type list,
    // angle semantics) now lives on UserPrefs.qml's copies — don't
    // recreate these properties here, WallpaperPicker.qml reads
    // UserPrefs now, not Settings.

    // Initial state of the picker's Shuffle checkbox (randomized grid
    // order, re-rolled each open). The checkbox itself still toggles
    // it per-session; this is just where it starts.
    property bool wallpaperShuffleDefault: false

    // ---- Volume OSD (widgets/OSD/VolumeOsd.qml) ----
    // How long the OSD stays up after the last volume/mute change, ms.
    property int osdHideDelay: 1500

    // Width of the OSD's level bar, in px (the pill sizes around it).
    property int osdWidth: 320

    // ---- Notifications (widgets/Notifications/NotificationPopups.qml) ----
    // Card width, px.
    property int notifWidth: 380

    // Auto-expiry for notifications whose sender didn't specify a
    // timeout, ms. Senders CAN override per-notification (see the
    // widget's DESIGN NOTES for the full policy — critical urgency
    // never auto-expires).
    property int notifDefaultTimeout: 5000

    // Most popup cards shown at once; the overflow stays queued and
    // slides in as older cards close, so a notification storm can't
    // fill the screen.
    property int notifMaxVisible: 5

    // ---- Power screen (widgets/PowerMenu/PowerScreen.qml) ----
    // Backdrop darkness behind the buttons. 0 = invisible, 1 = opaque
    // black. Guessed default, like everything else in this block —
    // one-line fix if it reads too light/heavy live.
    property real powerScreenDimOpacity: 0.55

    // Icon size inside each circular button, px. The circle itself is
    // drawn at (this + spacingLarge*2) so there's always breathing room
    // around the icon.
    property int powerScreenIconSize: 64

    // ---- Desktop Clock (widgets/Desktop/DesktopClock.qml) ----
    // Corner and margin MOVED to core/UserPrefs.qml 2026-07-11
    // (desktopClockCorner / desktopClockOffsetX/Y) when the settings
    // window's Desktop page took ownership — the plan's per-page
    // migration rule, same as fontScale before them. Only the font
    // size below remains a hand-edited token.
    // ---- ConfigManager (services/ConfigManager.qml) ----

    // How many auto+daily snapshots pruneAutos() keeps. Manual
    // snapshots and the Original Backup are never pruned.
    // 2026-07-13: lowered 30 -> 10 — with pruneAutos() now firing
    // automatically (see ConfigManager.qml's onExited), 30 was going
    // to keep a month of dailies around by design; 10 was the
    // explicit ask once the backlog was noticed.
    property int configAutoSnapshotKeep: 10

    // Size of the time text, in px. Date and weather text scale off
    // this (roughly 32% of it) rather than having their own tokens —
    // one number controls the whole widget's proportions.
    property int desktopClockFontSize: 72

    // ---- Weather (services/Weather.qml) ----
    // US ZIP code to fetch local weather for. Empty (the default)
    // means no weather — the desktop clock just shows time/date with
    // no error, no placeholder. Config-file only for now, no in-app UI
    // to set this yet.
    property string weatherZipCode: "11735"

    // "fahrenheit" or "celsius".
    property string weatherUnits: "fahrenheit"

    // How often to re-fetch, in minutes.
    property int weatherRefreshMinutes: 30
}
