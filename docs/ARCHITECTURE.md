# Architecture

How this project is structured, and why. Read this if you're new to the
codebase — human or AI — before making structural changes.

## Folder layout

## Current border-color ownership

The top-bar border and Hyprland active-window border are separate settings
paths, even though they may intentionally share theme tokens. The Appearance
page stages the bar border source/color; the Hyprland page stages the
compositor active-border source/color. Since the Settings transaction split,
`SettingsTransaction.resolvedHyprBorderForApply()` resolves one immutable final
border state from the complete staged transaction before any files are written.

Do not add ad-hoc page bindings or read partially saved values during Apply.
The centralized rule is:

- Hyprland “Use theme color” enabled: follow the effective Appearance border
  (theme gradient or custom solid color).
- Hyprland “Use theme color” disabled: keep its independent custom value.

This centralized resolution is also reused by the UI Profiles post-restore
Hyprland reapply path.


```
quickshell/
├── shell.qml          The config root Quickshell loads — a Scope, not a
│                       window. Instantiates one TopBar per monitor
│                       (Variants over Quickshell.screens, filtered by
│                       Settings.barExcludedScreens) plus the
│                       single-instance widgets (VolumeOsd,
│                       NotificationPopups, PowerScreen, DesktopClock),
│                       and owns ALL GlobalShortcuts and IpcHandlers
│                       (single registration, focused-monitor routing).
│                       Because this file sits directly in
│                       ~/.config/quickshell/, the shell has NO config
│                       name — IPC is plain `qs ipc call ...`, no -c flag.
│
├── core/               Shell-wide infrastructure. Nothing here is visual.
│   ├── Theme.qml         Singleton. The property INTERFACE widgets read
│   │                     for colors/fonts/sizes, via `import qs.core`.
│   │                     Does not hold actual values — forwards the
│   │                     active themes/ file.
│   ├── Settings.qml      Singleton. User-configurable BEHAVIOR (not
│   │                     appearance) — launcher sizing, wallpaper
│   │                     paths/transition, OSD timing, notification
│   │                     timeouts, desktop clock position, weather ZIP,
│   │                     `fontScale`, etc. Hand-edit-the-file knobs, no
│   │                     UI. The project's rule: every guessed default
│   │                     or tunable behavior becomes a token here, so a
│   │                     wrong guess is a one-line fix (this has paid
│   │                     off repeatedly — see PROBLEMS_AND_FIXES).
│   ├── UserPrefs.qml     Singleton. The FEW prefs with a live UI
│   │                     (SettingsMenu toggles) that persist to disk
│   │                     via FileView+JsonAdapter: clock format,
│   │                     thumbnail caching, theme name. Settings =
│   │                     edit-the-file; UserPrefs = toggle-in-the-UI.
│   ├── Globals.qml       Singleton. Shared RUNTIME state. Still mostly
│   │                     empty — services own their own state so far.
│   └── Signals.qml       Singleton. Central signal bus. First real use:
│                         togglePowerScreen() (SystemMenu → PowerScreen).
│
├── services/           System integrations. A "service" talks to the
│   │                    outside system (D-Bus, a socket, a CLI tool)
│   │                    and exposes clean QML properties/signals.
│   │                    Widgets read services; they don't shell out
│   │                    themselves. All singletons (pragma Singleton
│   │                    AND Singleton root type — BOTH, see
│   │                    PROBLEMS_AND_FIXES 2026-07-03).
│   ├── Audio.qml         PipeWire default sink: volume, mute, sink
│   │                     list/switching. Read by Volume (bar) and
│   │                     VolumeOsd.
│   ├── Network.qml       Wifi state/control: status from
│   │                     Quickshell.Networking, scan list + connect via
│   │                     nmcli. Read by Wifi. (NetworkManager is
│   │                     Quickshell's ONLY network backend — see
│   │                     PROBLEMS_AND_FIXES.)
│   ├── Notifs.qml        THE notification daemon — owns Quickshell's
│   │                     NotificationServer and with it the
│   │                     org.freedesktop.Notifications D-Bus name
│   │                     (exactly one owner allowed system-wide, which
│   │                     is why this is a service even while only one
│   │                     widget reads it — the name is a singleton
│   │                     resource). The machine's only notification
│   │                     daemon since 2026-07-05.
│   ├── BluetoothAgent.qml Keeps a bluetoothctl process registered as
│   │                     the BlueZ pairing agent (NoInputNoOutput /
│   │                     "Just Works") so pairing from the Bluetooth
│   │                     popout actually completes.
│   ├── Weather.qml       ZIP → coords (zippopotam.us) → current temp +
│   │                     condition (Open-Meteo), on a refresh timer.
│   │                     Read by DesktopClock. No-op until
│   │                     Settings.weatherZipCode is set.
│   ├── ConfigManager.qml The snapshot/restore engine + the Apply
│   │                     transaction (settings-manager plan, Phases
│   │                     1–2): one-time Original Backup, manifest-
│   │                     driven manual/daily/auto snapshots, restore,
│   │                     retention pruning, applyChanges (auto
│   │                     snapshot, then staged UserPrefs writes).
│   │                     User guide: docs/BACKUPS.md.
│   └── README.md         Folder-level notes.
│
├── widgets/             Visual components. widgets/TopBar/ is the bar
│   │                    and everything anchored to it; other subfolders
│   │                    are standalone top-level windows.
│   ├── TopBar/
│   │   ├── TopBar.qml     The bar: a floating, rounded, inset panel
│   │   │                  (barMargin/barRadius tokens), one instance
│   │   │                  per monitor. Instantiates every bar module
│   │   │                  below.
│   │   ├── BarPopout.qml  THE dropdown/popout component — the "scroll
│   │   │                  down out of the bar" PopupWindow pattern.
│   │   │                  Alignments: under its anchor, flush to the
│   │   │                  bar's end, or centered. Read its DESIGN
│   │   │                  NOTES before touching popup behavior — the
│   │   │                  open/visible sync trap lives there.
│   │   ├── SystemMenu.qml Arch icon; emits Signals.togglePowerScreen().
│   │   ├── SettingsMenu.qml Gear icon; QUICK live toggles (clock
│   │   │                  format, thumbnail caching) + "Open
│   │   │                  Settings…" into the settings window. Durable
│   │   │                  settings live in the window, quick ones
│   │   │                  here — the transient/durable split.
│   │   ├── Workspaces.qml One indicator per existing workspace
│   │   │                  (display-only; click-to-switch was abandoned
│   │   │                  pre-Lua-discovery and is probably fixable
│   │   │                  now — see PROBLEMS_AND_FIXES).
│   │   ├── NowPlaying.qml MPRIS track + click controls.
│   │   ├── Volume.qml     Volume module + slider popout; scroll to
│   │   │                  adjust, middle-click mute.
│   │   ├── Wifi.qml       Wifi status + popout (toggle, rescan,
│   │   │                  connect).
│   │   ├── Bluetooth.qml  Bluetooth popout (paired devices + scan/pair;
│   │   │                  reads Quickshell.Bluetooth directly — the
│   │   │                  "don't wrap until shared" rule).
│   │   ├── Clock.qml      Date/time + calendar popout (SystemClock).
│   │   ├── Launcher.qml   Hotkeyed app launcher (SUPER+R /
│   │   │                  shell:launcher). Shared launcher content can
│   │   │                  be hosted either in a connected BarPopout or
│   │   │                  a centered floating surface, with staged X/Y
│   │   │                  offsets. Supports initial app visibility,
│   │   │                  favorites, launch counts, hidden apps, and
│   │   │                  typo-tolerant ranked DesktopEntries search.
│   │   ├── WallpaperPicker.qml  Hotkeyed wallpaper grid (SUPER+W /
│   │   │                  shell:wallpapers). Shared picker content can
│   │   │                  be attached to the bar or centered, using the
│   │   │                  same library scan, .thumbs cache, current-
│   │   │                  wallpaper marker, shuffle, and awww path.
│   │   ├── DeviceRow.qml / SignalBars.qml  Rows/indicators shared by
│   │   │                  the Wifi and Bluetooth popouts.
│   │   ├── ToggleRow.qml / ToggleSwitch.qml / SectionLabel.qml
│   │   │                  Building blocks for SettingsMenu-style
│   │   │                  popout content.
│   │   ├── MenuButton.qml Reusable dropdown row (icon+label, hover).
│   │   ├── MenuDivider.qml Reusable dropdown divider line.
│   │   ├── Separator.qml  Reusable "|" bar divider.
│   │   ├── Tray.qml       System tray host — UNREFERENCED since the
│   │   └── TrayItem.qml   2026-07-04 restyle removed the tray from
│   │                      the bar. Kept on disk; TopBar.qml's header
│   │                      documents how to re-add.
│   ├── OSD/
│   │   └── VolumeOsd.qml  Bottom-center volume pill on any volume/mute
│   │                      change; click-through (empty Region mask),
│   │                      reserves no space, startup-flash grace
│   │                      timer. First top-level window besides the
│   │                      bar.
│   ├── Notifications/
│   │   ├── NotificationPopups.qml  Presentation router for detached
│   │   │                  versus monitor-routed bar-attached mode.
│   │   ├── DetachedNotificationSurface.qml  Original corner-positioned
│   │   │                  floating notification host.
│   │   ├── AttachedNotificationSurface.qml  BarPopout-based host with
│   │   │                  left/center/right anchors, safe edge inset,
│   │   │                  X offset, connected border-gap registration,
│   │   │                  and close-seam handoff timing.
│   │   └── NotificationCards.qml  Shared card stack: icon/image,
│   │                      summary/body, actions, timeout policy,
│   │                      optional attached borders, urgent treatment,
│   │                      and delayed model removal for exit animation.
│   ├── PowerMenu/
│   │   └── PowerScreen.qml  Centered floating card (Restart Hyprland /
│   │                      Restart / Shut Down) on the Overlay layer;
│   │                      SUPER+P, `qs ipc call power toggle`, or the
│   │                      bar's arch icon.
│   ├── Settings/
│   │   ├── SettingsWindow.qml  Settings application host: FloatingWindow
│   │   │                  lifecycle, preferred sizing, navigation, page
│   │   │                  hosting, shared popups, and compatibility aliases
│   │   │                  connecting pages/footer to the transaction controller.
│   │   ├── SettingsTransaction.qml  Shared staged-settings controller. Owns
│   │   │                  staged values, effective shown values, pending-diff
│   │   │                  generation, discard/reset, validation helpers, and
│   │   │                  Apply orchestration, including final Hyprland border
│   │   │                  resolution.
│   │   ├── components/SettingsPendingFooter.qml
│   │   │                  Fixed pending-change/status/Apply/Cancel UI.
│   │   │                  Presentation only; emits apply/cancel signals
│   │   │                  back to SettingsWindow and owns no transaction
│   │   │                  state. Extracted in Rev 20.
│   │   └── pages/         Page-specific controls and presentation.
│   │                      Hyprland alone owns the outer border, gradient,
│   │                      and rounded window shape. Dropdowns reserve a
│   │                      permanent gutter beside the draggable scrollbar.
│   │                      See docs/SETTINGS_ARCHITECTURE.md before further
│   │                      splitting or changing Apply/Cancel ownership.
│   └── Desktop/
│       └── DesktopClock.qml  Borderless clock/date/weather sitting on
│                          the wallpaper (Background layer — behind app
│                          windows), click-through, corner set by
│                          Settings.desktopClockCorner.
│
├── themes/              Actual theme DATA files (colors/fonts/sizes).
│   ├── DefaultTheme.qml  Grey/black/blue-accent base theme. Plain
│   │                      QtObject — NOT a singleton itself; core/Theme.qml
│   │                      creates the one instance of the ACTIVE theme
│   │                      internally.
│   └── HoneycombTheme.qml Warm dark theme built from the hexagon
│                          wallpaper (the default/fallback). Runtime
│                          switching is LIVE as of 2026-07-09:
│                          core/Theme.qml's themes map +
│                          UserPrefs.themeName, picked in the settings
│                          window.
│
├── assets/              Static files — icons, images.
│   └── icons/            weather/ (7 SVGs for DesktopClock) and power/
│                          (6 SVGs for PowerScreen) — both optional,
│                          both degrade gracefully when missing. See
│                          notes/power_icons.txt and DesktopClock.qml's
│                          DESIGN NOTES for the exact filenames.
│
├── docs/                 Project-level documentation (this file,
│                          REVISION_HISTORY.md, PROBLEMS_AND_FIXES.md,
│                          HYPRLAND_INFO.md, INTEGRATION_NOTES.md —
│                          the hyprland.lua bind/autostart lines).
│
├── notes/                Scratch space. Not part of the running shell —
│                          safe to put half-finished ideas, design
│                          sketches, or reference material here without
│                          it affecting anything.
│
├── testing/              Reserved for standalone test .qml files — a
│                          place to try something in isolation before
│                          wiring it into the real widget tree.
│
└── scripts/              Repo tooling, not loaded by the shell.
    └── flatten-for-kb.sh  Flattens the tree for the Claude Project
                           knowledge base (see the root README.md).
```

## Imports: module-style, not relative paths

Every cross-folder import in this project uses Quickshell's module-style
syntax: `import qs.core`, `import qs.services`, `import qs.widgets.OSD`,
etc. — `qs` always means "the shell root folder" (where shell.qml lives),
and dotted paths walk down from there. New widget subfolders become
importable modules automatically (`widgets/OSD/` → `qs.widgets.OSD`);
no qmldir needed.

This project used to use relative path imports (`import "../themes"`,
`import "core"`). Those aren't wrong exactly, but Quickshell's own docs
call module imports out as "much more LSP friendly," and relative-path
imports are one of the things that can cause trouble with singletons and
language-server features. Switched project-wide — see
`docs/REVISION_HISTORY.md`.

**Rule going forward:** any new file that needs something from another
folder imports it via `qs.<path>`, not a relative `"../"` path. Files in
the SAME folder reference each other by type name with no import at all
(how TopBar.qml uses Launcher, WallpaperPicker, etc.).

## Shared state: singletons, not passed-in properties

`core/Theme.qml`, `core/Settings.qml`, `core/UserPrefs.qml`,
`core/Globals.qml`, and `core/Signals.qml` are all `pragma Singleton`
types. Any file that needs
one adds `import qs.core` and reads it by name directly:

```qml
// Inside any widget file:
import qs.core

Rectangle {
    color: Theme.colorBackground
    height: Theme.barHeight
}
```

There is no instance to create, and nothing to pass in when a widget is
instantiated. This project originally did the opposite — one shared
instance created in the (now-renamed) core wiring file, manually passed
down as a `theme:` property to every widget that needed it — because of a
mistaken belief that `pragma Singleton` needed extra qmldir setup. It
doesn't, for local files referenced within your own shell directory. See
`docs/PROBLEMS_AND_FIXES.md` for the full story if you're wondering why
an older version of a file looked different.

**Why this matters in practice:** the old pattern's failure mode was
silent — forget to pass `theme: theme` into a new widget, and it renders
with QML default styling (often white-on-white) with no error message.
The singleton pattern removes that failure mode: if a widget imports
`qs.core` and references `Theme.something`, it works, full stop.

**One gotcha specific to singletons:** they're instantiated lazily, on
first property access — not necessarily the moment the shell launches. If
a future `services/` file needs to start doing something (e.g. running a
background `Process`) as soon as the shell starts, rather than only when
some widget happens to read a property from it, something needs to
actively touch a property on it early to force instantiation. This
wasn't a concern under the old manual-instantiation pattern, so it's
worth remembering now. (services/Notifs.qml sidesteps this naturally:
NotificationPopups reads `Notifs.count` from its `visible` binding at
load, which instantiates the service and registers the D-Bus name.)


## Launcher, wallpaper, and notification presentation

The launcher and wallpaper picker each use one shared content implementation hosted by either an attached `BarPopout` shell or a centered detached shell. Placement, offsets, and feature state are persisted through `UserPrefs` and staged through the normal Settings transaction. Do not fork their app model or wallpaper scan when adding another presentation mode.

Attached notifications follow the same connected-border language but have a dedicated lifecycle because notifications can arrive, expire, stack, and disappear independently. `NotificationPopups.qml` chooses the surface, `AttachedNotificationSurface.qml` owns bar geometry and gap lifetime, and `NotificationCards.qml` owns card rendering and delayed dismissal.

The final-notification close path has a compositor-sensitive seam handoff: the bar gap is released during the last part of host retraction while the remaining popup fillet still covers the seam. Moving gap release to the absolute end causes visible empty frames before the bar border repaints. Preserve this ordering when changing notification animation durations or `BarPopout` close behavior.

## Dropdown menu pattern

**Historical note:** this section describes the mechanics as originally
worked out in SystemMenu.qml. The pattern has since been EXTRACTED into
`widgets/TopBar/BarPopout.qml` — new bar dropdowns declare a
`BarPopout {}` instead of copying this boilerplate, and BarPopout's own
DESIGN NOTES are the authoritative reference (including the alignment
modes added since: flush-to-bar-edge and centered). The mechanics below
still explain WHY BarPopout is built the way it is:

1. An `Item` wrapping a clickable icon (`Text` + `MouseArea` toggling a
   `property bool menuOpen` on the widget itself — NOT bound directly to
   the popup's `visible`, see point 5).
2. A `PopupWindow` (from `import Quickshell`) with:
   - `anchor.item: <the icon>` — no need to reference the parent
     `PanelWindow` directly, the popup resolves it from the item.
   - `anchor.edges: Edges.Bottom | Edges.Left` — anchors to the icon's
     bottom-left corner.
   - `anchor.gravity: Edges.Bottom | Edges.Right` — expands down and
     right from that point, so menus near the left edge of the bar don't
     run off-screen.
   - `implicitWidth` / `implicitHeight` bound to the content's own
     implicit size (see point 3) — NOT hardcoded pixels, and NOT
     `width`/`height`, which are deprecated on `PopupWindow`.
3. **Content-driven sizing.** `MenuButton.qml` computes its own
   `implicitWidth` from its icon+label. Inside a `ColumnLayout` with
   `Layout.fillWidth: true` on each row, the column's own implicit width
   becomes the WIDEST row's width — bind the popup's `implicitWidth` to
   that. Add a longer label to any row later and the whole popup grows
   to fit automatically; no manual width tuning anywhere.
4. **Animated reveal in both directions.** The popup surface remains
   alive while a clipping item animates `revealProgress` from 0→1 on
   open and 1→0 on close. On close, input focus/grab is released first,
   the reverse animation runs, and only its completion hides the
   `PopupWindow`. This is not a QML limitation; snap-closing was only a
   lifecycle choice in the early implementation. The current duration is
   intentionally slower than the original reveal (about 250 ms).

   **Pixel-grid rule:** popup size, anchor coordinates, and the gap cut
   into the bar border must all use the same rounded whole-pixel geometry.
   Wayland places the popup surface on physical pixels; allowing the Canvas
   gap to retain fractional RowLayout coordinates creates a visible 1–3 px
   seam at the fillets. Change the popup anchor math and `_updateGap()`
   together.
5. **Dismiss on outside click.** Set `grabFocus: true` on the
   `PopupWindow`. This makes Quickshell set `visible` to `false`
   whenever the user clicks outside the popup — which means `visible`
   must NOT be a declarative binding (`visible: menuOpen`), because that
   automatic dismissal would imperatively overwrite it and permanently
   break the binding (standard QML: assigning a bound property removes
   the binding). Instead, sync the two properties manually in both
   directions:
   ```qml
   property bool menuOpen: false
   onMenuOpenChanged: menuPopup.visible = menuOpen

   PopupWindow {
       id: menuPopup
       grabFocus: true
       onVisibleChanged: {
           if (root.menuOpen !== visible) root.menuOpen = visible
       }
   }
   ```
   See `docs/PROBLEMS_AND_FIXES.md` for the full story on why the
   simpler direct binding doesn't work. (This grabFocus trap is
   specific to PopupWindow. Plain PanelWindows like the OSD, which
   nothing external dismisses, CAN bind `visible` declaratively —
   VolumeOsd.qml's DESIGN NOTES cover the distinction.)
6. A themed `Rectangle` filling the clip (`Theme.colorSurface`,
   `Theme.radiusMedium`, a `Theme.colorMuted` border) containing the
   actual content.
7. For menus that are just a list of actions (like SystemMenu's power
   options), a `ColumnLayout` of `MenuButton {}` rows (each
   `Layout.fillWidth: true`), separated by `MenuDivider {}` (also
   `Layout.fillWidth: true`) between each row.

**Is this themable?** Yes — nothing here is hardcoded outside the
`Theme` singleton (`colorSurface`, `colorHover`, `radiusMedium`,
`animationDuration`, `animationEasing`, plus everything already themed
elsewhere), so a new `themes/YourTheme.qml` reskins dropdown menus —
including their open-animation speed and feel — the same one-line swap
as everything else (see "Adding a new theme" below).

## Top-level windows vs bar modules

Two kinds of visual component now exist, and they go in different
places:

- **Bar modules and their popouts** (clock, volume, launcher, wallpaper
  picker...) live in `widgets/TopBar/` and are instantiated by
  TopBar.qml. If it's anchored to the bar — even invisibly, like the
  launcher's 1px anchor — it's a bar module.
- **Standalone windows** (the volume OSD, notification popups, the
  power screen, the desktop clock) get their own folder under
  `widgets/` and are instantiated by `shell.qml`. These are
  PanelWindows positioned relative to the SCREEN, with
  `exclusiveZone: 0` (reserve no space) and deliberate input policy:
  the OSD and desktop clock are click-through (`mask: Region {}` — an
  empty input region); the notification window and power screen take
  real input. They also pick their wlr-layer deliberately: the power
  screen pins to Overlay (above everything), the desktop clock to
  Background (behind app windows) — see each file's DESIGN NOTES.


## Desktop clock placement invariant

`widgets/Desktop/DesktopClock.qml` uses a full-screen, click-through `PanelWindow` on the Background layer. The window surface itself must remain full-screen; only the inner clock content moves. Corner and center placement are calculated with explicit `x`/`y` bindings from the screen dimensions. Do not reintroduce dynamic anchor switching or content-derived `implicitWidth`/`implicitHeight` on the window, because both approaches previously caused the clock to disappear, clamp to top-left, or stop responding to live position changes until Quickshell restarted.

Weather icons are rendered with the same effective color as the desktop clock text.

**Known limitation:** X/Y offsets currently work for corner positions but not for Center. This is deferred until after the Settings pages are fully split.

## Settings transaction ownership (Rev 21)

`widgets/Settings/SettingsTransaction.qml` is the authoritative owner of the
normal Settings staged transaction. It contains the `staged...` properties,
the staged-or-live `shown...` values used by controls, pending-change derivation,
`discardStaged()`, validation helpers, and `apply()`. It also resolves the final
Hyprland active-border snapshot from the complete staged state before persistence,
which avoids page-local apply-order races.

`SettingsWindow.qml` is now only the window host: lifecycle, preferred geometry,
open/close/toggle behavior, native movement, and mounting `SettingsContext` plus
`SettingsView`. Page-facing aliases and shared state live in `SettingsContext.qml`;
staged/diff/apply logic lives in `SettingsTransaction.qml`; visible shell UI lives
in `components/SettingsView.qml`; overlays live in `components/SettingsOverlays.qml`.
New Settings features must follow that split from their first revision.

The SDDM page keeps its separate preview/install workflow. Do not silently fold
root-owned SDDM installation into the normal desktop Apply transaction.


## Hyprland animation preset architecture (Revs 30–39)

Animation ownership is manager-owned, not hand-owned:

- `widgets/Settings/pages/HyprlandPage.qml` owns the preset control.
- `SettingsTransaction.qml` owns staged/shown/diff/discard/apply behavior.
- `SettingsContext.qml` forwards the page-facing state.
- `core/UserPrefs.qml` persists the selected preset.
- `services/ConfigManager.qml` writes both `generated/appearance.lua` and `generated/animations.lua`.
- `scripts/install-hypr-animation-presets.sh` performs the one-time ownership migration out of `user/look.lua`.

The generated animation file must load after `user.look`, so old hand-owned values
cannot override it. The normal Apply sequence is intentionally simple and safe:

```text
write appearance.lua completely
write animations.lua completely
hyprctl reload
```

Do not use `hyprctl reload full-reset`; repeated full context resets crashed
Hyprland during live testing. Do not use `hyprctl eval`/`dofile`; that experiment
was unnecessary and unreliable. Generated Lua uses the existing global `hl` API
directly, and color values are strings such as `"rgba(33ccffee)"`, not Lua
function calls.

## UI Profiles restore-point architecture (Rev 22–24)

The current UI Profiles implementation is intentionally one restore point, not
yet a full named-profile manager. Its pieces are separated by responsibility:

- `widgets/Settings/pages/UiProfilesPage.qml` owns buttons, confirmations,
  status text, and restore orchestration.
- `scripts/settings-profile.sh` owns user-level snapshot file I/O and current
  wallpaper capture/restore.
- `SettingsTransaction.reapplyCurrentHyprland()` owns the post-restore bridge
  into the existing Hyprland generator.
- `ConfigManager` remains the only normal Settings apply/generation engine.

The saved snapshot lives outside the repository at
`~/.local/state/quickshell/ui-profiles/my-default/`. It contains the complete
persisted `user-prefs.json` plus a wallpaper path. Wallpaper image data is not
copied, so the original image library still needs its own backup.

Restoring the JSON alone is insufficient for compositor visuals because
Hyprland consumes a separately generated appearance file. The page therefore
waits for `UserPrefs` to reload and requests the controller's reapply function.
Do not move that generator into the shell script or simulate user input to make
it fire.

UI Profiles does not capture or install SDDM. SDDM remains a separate
root-owned, manually applied snapshot boundary.


## UI Profiles restore synchronization (Rev 25)

UI Profiles stores one user-owned known-good restore point. Restoring is a cross-component operation and must preserve this ownership chain:

```text
settings-profile.sh
    atomically replaces user-prefs.json and restores wallpaper
        ↓
UiProfilesPage.qml
    discards open staged values and calls UserPrefs.reloadFromDisk()
        ↓
core/UserPrefs.qml
    reloads the FileView and emits preferencesReloaded() on the next event-loop turn
        ↓
UiProfilesPage.qml
    calls SettingsWindow.reapplyCurrentHyprland() only while awaiting that restore
        ↓
SettingsTransaction.qml / ConfigManager.qml
    regenerate and apply the normal Hyprland appearance output
```

Do not replace this with a fixed timeout. Do not move preference-file copying into QML, and do not duplicate Hyprland generation in the profile helper. SDDM remains outside this user-owned restore path.

## Displays feature boundary (Rev 25)

The old disabled Displays prototype was removed from `SettingsWindow.qml`. Displays is not currently implemented. Future work must start with a real display-management service and a fresh page built against current Hyprland monitor behavior; the removed block-commented prototype is not a valid implementation parent.

## Adding a new widget — checklist

1. Create a new folder under `widgets/` for a standalone window, or a
   new file inside `widgets/TopBar/` for a bar module (see the section
   above for which is which).
2. Give it the standard file header (see any existing file for the
   template — FILE / PURPOSE / DEPENDENCIES / USED BY / IF REMOVED /
   DESIGN NOTES / REVISION HISTORY).
3. If it needs colors/fonts/sizes, add `import qs.core` and use
   `Theme.colorBackground` etc — never hardcode a hex value, and never
   declare a `property var theme` for this (see "Shared state" above).
   Behavior knobs (sizes, timeouts, paths) become `Settings` tokens,
   especially anything guessed — guessed defaults should be one-line
   fixes.
4. If it needs to run a shell command, do that via a `Process`, and
   consider whether
   the logic belongs in a `services/` file instead if more than one
   widget would need the same data — or if it owns a singleton system
   resource (a D-Bus name, a daemon socket), in which case it's a
   service even with one consumer (see services/Notifs.qml).
5. Wire it in wherever it belongs (`shell.qml` for a top-level
   window, `TopBar.qml` for a bar module). Unlike the old pattern,
   there's no `theme:`/`settings:` to remember to pass — just
   instantiate it.
6. Add an entry to `docs/REVISION_HISTORY.md`.
7. If you hit a non-obvious problem while building it, add an entry to
   `docs/PROBLEMS_AND_FIXES.md` before moving on.

## Adding a new theme

1. Copy `themes/DefaultTheme.qml` to `themes/YourThemeName.qml`.
2. Change the values.
3. In `core/Theme.qml`: add one child instance
   (`YourThemeName { id: yourThemeInst }`) and one line in the
   `themes` map (`"YourThemeName": yourThemeInst`). That's all —
   it appears in the settings window's picker automatically
   (themeNames derives from the map).

## Services vs Widgets — the distinction

A **service** talks to the outside world (D-Bus, a system file like
`/sys/class/power_supply`, a CLI tool via `Process`) and exposes clean
data. A **widget** displays data and handles clicks/hovers. Widgets
should generally not shell out to system commands directly if the same
data would be useful to more than one widget — put that logic in
`services/` instead and have widgets read from it.

`services/` currently holds Audio (PipeWire), Network
(NetworkManager/nmcli), Notifs (the notification daemon),
BluetoothAgent (BlueZ pairing agent), and Weather (Open-Meteo). All are
singletons — a service is exactly the "one shared instance, many
readers" case singletons exist for.

**Not every system integration needs a hand-written service.** Check
whether Quickshell already ships a built-in module first — `SystemClock`
covers clocks, `Quickshell.Hyprland` covers Hyprland IPC,
`Quickshell.Services.Mpris` covers media players,
`Quickshell.Bluetooth` covers bluetooth (Bluetooth.qml reads it
directly), `DesktopEntries` covers installed apps (Launcher.qml reads it
directly). Only build a real service when you need logic the built-in
doesn't give you, need to share DERIVED state across widgets, or — the
case Notifs.qml added — the integration owns a system-wide singleton
resource that future consumers must share rather than re-create.

**Widget-local `Process` calls are fine** when the data genuinely
belongs to one widget: WallpaperPicker.qml's folder scan and
`awww query` live in the widget because no one else needs them. If a
second consumer ever appears (e.g. a lock screen showing the current
wallpaper), that's the signal to extract a Wallpapers service.

## A note on Quickshell's own version

This project targets **Quickshell 0.3.0** (released 2026-05-04). An
earlier draft of this document referred to "Quickshell 3.0," which does
not exist — Quickshell's versioning is 0.x, not a major-version scheme.
If you're reading an old note or an AI-generated summary that says
"Quickshell 3.0," it's wrong; trust `quickshell --version` on the actual
machine, or the project's own changelog, over any scratch note.

## Settings architecture after Rev 29

Settings is now split into five explicit layers:

- `SettingsWindow.qml`: window lifecycle and hosting only;
- `SettingsContext.qml`: page-facing facade, shared models, popup state, and transaction forwards;
- `SettingsTransaction.qml`: staged values, effective values, pending diffs, discard, validation, and Apply;
- `components/SettingsView.qml`: titlebar, navigation, pages, scrolling, footer, and overlay mounting;
- `components/SettingsOverlays.qml`: shared dropdown and color-picker popup layer.

`SettingsWindow.qml` fell from the historical 2,400+ line monolith to 495 lines by Rev 29. Future Settings features must start in a dedicated page/component/context/transaction/service boundary rather than being embedded in the window and split later. The detailed rules and regression checklist are in `docs/SETTINGS_ARCHITECTURE.md`.

## Small native utility architecture (2026-07-23)

### Calculator

`widgets/Calculator/CalculatorWindow.qml` is one persistent application-style window instantiated once by `shell.qml`. `core/Signals.qml` carries the toggle request. The launcher exposes a normal internal entry (`internal:calculator`) so favorites, hidden state, usage counts, aliases, and ranking use the same machinery as desktop applications; only the final launch action differs. No Settings keys exist.

### Clock tools

`services/ClockTools.qml` owns all timer, stopwatch, lap, alarm, sound, and notification state. `widgets/TopBar/Clock.qml` is presentation and interaction only. The date and time retain one visual row but have independent hit targets and independent persistent popouts. Runtime elapsed/remaining values derive from timestamps plus the service's reactive `nowMs`, not from decrementing/incrementing counters.

### Clipboard history

`services/ClipboardHistory.qml` owns the bounded model and reusable `Process` objects for list, restore, delete, wipe, trim, and sequential thumbnail decode. `widgets/TopBar/Clipboard.qml` refreshes once when opened and mutates the visible model in place for delete/clear, preserving scroll position. The service depends on external session processes; verify them and `cliphist list` before changing QML. Thumbnail files use stable IDs under `$XDG_RUNTIME_DIR/qs-clipboard-thumbs/`, never the source-controlled assets directory.

### Lifecycle rule

All three utilities use persistent objects/windows/popouts. Runtime opening and closing changes visibility/state; it does not construct and destroy windows or spawn unbounded process instances.


## Documentation hierarchy

- `README.md`, setup, architecture, maintenance, and current plans are authoritative.
- `FEATURE_BACKLOG.md` is the canonical active backlog.
- `SMALL_ADDITIONS_BACKLOG.md` expands only the small-utility portion.
- `docs/history/` contains completed plans, superseded designs, incident reports, and old reviews; those files are context, not active work orders.
- `notes/` is temporary scratch space and must not become a second backlog.
