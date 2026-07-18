## 2026-07-18 — SDDM preview, layout controls, clock scaling, and X11 monitor setup (GPT)

**Live-tested before clock-scale revision:**

- Added clock and login-panel horizontal/vertical offsets in 10 px steps.
- Added Reset buttons for every offset.
- Added a temporary Test SDDM path that previews unsaved controls from `/tmp` without `pkexec` or writes to `/usr/share`.
- Confirmed layout-only Apply works with theme and wallpaper unchecked.
- Aligned SDDM stepper labels and values using fixed columns.

**Built and under live test:**

- Added clock scale from 50% to 200% in 10% steps; Reset returns to 100%.
- Clock scale affects both time and date and is included in preview and installed snapshot generation.

**Machine-specific SDDM display fix:**

- Confirmed the real SDDM greeter uses X11 and executes `/usr/share/sddm/scripts/Xsetup`.
- Confirmed SDDM/Xorg connector names differ from Hyprland/Xwayland names.
- Set `DisplayPort-1` left and `DisplayPort-0` right/primary, both at `2560x1440 @ 143.97 Hz`.
- Kept this monitor layout outside the portable theme because connector names and physical ordering are machine-specific.

## 2026-07-17 — Desktop clock shadow strength

## 2026-07-17 — SDDM completion, Settings fixes, desktop-clock controls, and Hyprland window behavior (GPT-5.6 Thinking)

**Completed and live-tested:**

- SDDM Phases 0–4: approved theme, generated snapshot contract, hash-aware privileged installer, activation/rollback, and manual Settings apply for the current theme and wallpaper.
- Appearance/Hyprland border-color linkage race fixed by carrying an immutable final border snapshot through Apply.
- Hyprland readiness warning changed to a machine-specific `look.lua` check.
- Automatic backup pruning moved to a silent background process.
- Desktop clock center X/Y offsets fixed.
- Added independent weather-icon and temperature toggles, whole-clock scale, shadow strength, and shadow X/Y offsets.
- Reduced the Settings QML minimum size, while preserving all newer staged clock properties after an older-parent regression was caught.
- Determined that inconsistent Settings spawn geometry was Hyprland tiling behavior, not a QML implicit-size bug. Added an exact float/center/size rule (`1440 820`) for `org.quickshell` / `Quickshell Settings`.
- Replaced the broken shell-based `Super+M` exit command with `hl.dsp.exit()`.

**Important maintenance lesson:**

- When several revisions touch the same large file quickly, always rebuild from the newest approved parent. An older `SettingsWindow.qml` briefly removed newer staged properties and produced `undefined` errors. Refresh the project archive/repository before starting the next work session.

**Machine-transfer requirement:**

- The Quickshell Git repository does not automatically install the Hyprland Settings window rule. Apply the rule separately to each machine's `rules.lua`; see `docs/HYPRLAND_WINDOW_RULES.md`.


- Added a 0–100% **Shadow strength** control to Desktop settings.
- The control adjusts the desktop clock/date/temperature shadow opacity as one simple setting.
- A value of 0% disables the visible shadow while preserving the existing Shadow toggle and color controls.


## 2026-07-16 — Hyprland readiness warning and silent backup pruning (GPT-5.6 Thinking)

- Replaced the permanent Hyprland setup warning with a machine-specific
  check of `~/.config/hypr/user/look.lua`. The warning is hidden when no
  uncommented `active_border = ...` assignment remains and reports a missing
  setup file separately.
- Moved automatic retention sweeps onto a dedicated background Process.
  Routine pruning no longer changes `ConfigManager.busy`, `lastOutput`, or
  the Settings status line. Manual IPC pruning remains visible and unchanged.

# Revision History

## 2026-07-15 — Hyprland settings page extraction (GPT)

- Extracted the active Hyprland settings UI from `widgets/Settings/SettingsWindow.qml` into `widgets/Settings/pages/HyprlandPage.qml`.
- Preserved staged values, validation, Apply/Cancel behavior, generated Hyprland writes, and existing setup-warning behavior.
- Reduced `SettingsWindow.qml` from 2,276 lines to 2,182 lines.
- Live-tested and approved on the user's Arch/Hyprland system.
- This revision is the approved parent for the next Settings-menu split.
- No unrelated behavior changes were included.

## 2026-07-15 — Desktop settings page extraction and live clock-position repair

- Extracted the Desktop settings UI from `SettingsWindow.qml` into `widgets/Settings/pages/DesktopPage.qml` while retaining staged values and Apply/Cancel ownership in the parent window.
- Updated weather SVG rendering so icons are tinted with the same effective color as the desktop clock text.
- Fixed the desktop clock disappearing or becoming stuck after live corner changes by using a full-screen click-through Background-layer surface and explicit content `x`/`y` positioning based on screen dimensions.
- Confirmed live switching among center and all four corners works without restarting Quickshell.
- Known deferred bug: desktop clock X/Y offsets do not currently apply in Center position; corner offsets work. Finish the Settings page split before returning to this and other deferred behavior bugs.


## 2026-07-14 — BarPopout pixel alignment + reverse close; Settings window redesign and geometry fixes (GPT)

**BarPopout:**
- Fixed 1–3 px border/fillet seams on Volume, Wi-Fi, Bluetooth, Calendar, and
  Settings by rounding popup dimensions, anchor coordinates, and the TopBar
  border-gap geometry through the same whole-pixel path.
- Added reverse close animation: popup remains visible until the reveal clip
  reaches zero, then hides. Closing is no longer a snap.
- Slowed reveal/close timing to approximately 250 ms.
- Launcher and Wallpaper Picker behavior remained intact.

**Settings window:**
- Replaced the extremely tall centered overlay card with a compositor-managed
  `FloatingWindow` using a permanent left sidebar, fixed header/footer, and an
  independently scrolling content page. The user can use normal Hyprland
  window actions such as `SUPER+V`, move, and resize.
- Preserved existing staged values, validation, Apply/Cancel transaction,
  persistence, and ConfigManager calls; this was a shell/layout redesign, not
  a settings-behavior rewrite.
- Removed the QML outer border so Hyprland alone renders the active border,
  gradient, and rounding.
- Corrected sidebar geometry for thick borders and rounded lower-left corners.
- Added a permanent scrollbar gutter and width caps so dropdowns do not paint
  through the scrollbar.
- Verified visually with an exaggerated 10 px Hyprland border.

**Refactor status:** extracting reusable settings controls was attempted later
in the session but is not recorded here as complete until the newest revision
is explicitly live-tested and approved.

**Known border-color coupling issue discovered during page extraction:**
- Appearance top-bar border color and Hyprland active-window border color are
  currently separate staged settings and do not reliably update each other in
  the same Apply transaction.
- A later change/revert can make them match because the regenerated output then
  sees both saved values.
- This is deferred to the future `SettingsStore` / centralized Apply refactor.
  The intended rule is: Hyprland follows the effective Appearance border only
  while Hyprland “Use theme color” is enabled; otherwise Hyprland remains
  independent.
- Do not solve this with more page-local bindings while pages are being split.

---

Project-wide changelog. Each `.qml` file also keeps its own short revision
history in its header (for changes local to just that file) — this file is
for tracking the shape of the whole project over time: what was added, what
was restructured, what was replaced.

If you're a future instance of Claude (or a human) picking this project up
cold, read this file top-to-bottom before touching anything. It's the
fastest way to understand how the project got to its current state.

## Session workflow — read this first, future Claude

This project is built across many separate chat sessions, and a new
session starts with NO memory of the previous ones. The project
knowledge files plus this document are the entire handoff. These
conventions exist because their failure modes are real (2026-07-04: a
session started against project files that were one session stale, and
edits built on them would have silently deleted the just-built launcher
if the mismatch hadn't been caught mid-edit):

- **The knowledge base is synced at the END of each session** (flatten
  script, re-upload). Mid-session, the copies in project knowledge may
  be one session behind — during a session, the authoritative versions
  of any file touched recently are the ones produced in that session's
  own conversation, not the KB copies.
- **Start of session, the maintainer opens with a one-line state note:**
  whether the KB is synced, whether the last session's files actually
  run on the live machine, and any errors hit since. Claude should trust
  that note over the KB timestamps, and if no note is given, ask before
  editing anything a recent session touched.
- **Mid-session divergence gets reported:** if the maintainer hand-edits
  a file Claude produced (bug fix, value tweak, commented-out block),
  they say so or paste the current version — otherwise Claude's next
  edit regenerates from its own copy and silently stomps the fix.
- **Entries note which Claude model wrote the session's work** (in the
  entry title) — cheap provenance that makes cross-model review a grep.
- **Note to self (Claude): update THIS file as part of every session,
  not only the per-file headers.** Hand over a ready-to-paste changelog
  entry alongside the session's files as a standard closing step. The
  per-file REVISION HISTORY headers cover local detail; this file is the
  only place a whole session's shape gets recorded, and it fell a
  session behind once already — the 2026-07-04 entries below were
  written late, in the session after the work they describe.

---

## 2026-07-13 — Weather icons, settings-window visual pass, wallpaper transition settings, auto-prune fix, SDDM Phase 0 (Sonnet 5)

**BUGFIX (same day, after first live test):** the first cut of this
work shipped `UserPrefs.qml` with `property real
wallpaperTransitionAngle: 45` — a bare integer default on a `real`
property *inside the JsonAdapter*. Quickshell's JsonAdapter reflection
rejects that (the file's every other `real` default already used an
explicit `.0` for exactly this reason), and the failure aborts the
ENTIRE adapter — so every UserPrefs property became `undefined`,
cascading into Theme and every widget reading it (tiny font, no bar
border, no popup fillets, broken settings window). Fixed by writing
the default as `45.0`. Lesson for future migrations: any `real`
default inside a JsonAdapter must be written with a decimal point.

**Context:** Several separate threads in one long session, done
offline (maintainer away from the machine) — nothing below has been
live-tested yet. Applying these files is a straight drop-in; none of
them have been merged into the running config as of this entry.

**Weather icons:** 7 SVGs built and delivered for
`assets/icons/weather/` (clear/partly-cloudy/cloudy/fog/rain/snow/
thunderstorm) — flat fill + soft dark halo, no stroke (avoids seam
artifacts between overlapping shapes). `assets-README.md` updated,
was still claiming the folder was empty.

**Settings window visual pass** (`SettingsWindow.qml`): divider line
under the tab row removed (was reading as an underline beneath the
active tab); active tab gets a real 1px outline; Theme/Font Family
dropdowns now visually "connect" to their open list (square bottom
corners while open, list overlaps the button by exactly the border
width) instead of floating as a separate box; extra spacing added
between control groups on the Appearance/Notifications/Desktop pages;
pending-changes panel now sits inside its own bordered container.

**Wallpaper Transition settings** (new, Appearance page):
`wallpaperTransitionType/Duration/Fps/Angle` migrated from
`core/Settings.qml` to `UserPrefs.qml` (per-page-ownership rule — see
that file's revision history), new `wallpaperTransitionPos` added.
Type dropdown covers the full real awww/swww `--transition-type` set
(14 values, including `random` — genuinely zero extra plumbing for
"make it random", swww supports it natively). Position picker only
shown for grow/outer (the only types that read it); stored as a
semantic corner name (matching notifCorner's vocabulary) and converted
to swww's coordinate syntax in `WallpaperPicker.qml` — that conversion
function is flagged as the one place to check if a corner ever looks
visually flipped, since the exact `--transition-pos` alias keywords
weren't independently confirmable from docs alone.

**ConfigManager auto-prune fix:** `pruneAutos()` existed and worked
(built in the original Phase 1 session) but nothing ever called it —
only `dailySnapshotIfNeeded()` was wired to the settings window
opening. `onExited` now fires a prune sweep after any completed daily
or manual snapshot, specifically excluding the two snapshots that are
step 1 of a staged transaction (Apply, file-with-revert) since those
chains call `root.run()` again in the same handler tick and a
same-tick prune would've overwritten `proc.command` before the real
second step ran. `configAutoSnapshotKeep` lowered 30 -> 10 (explicit
ask, once the existing backlog was noticed).

**SDDM login theme, Phase 0:** new, separate project (`sddm-rev0`,
not affiliated with the caelestia-dots project the Quickshell
reference files came from — deliberately not named after it). Just a
skeleton proving the `sddm-greeter-qt6 --test-mode` pipeline works —
`metadata.desktop`, empty `theme.conf`, `Main.qml` with a solid
background + confirmation text. See `docs/SDDM_THEME_PLAN.md` for
Phases 1+; nothing past Phase 0 exists yet.

**Two new planning docs, no code yet:** `docs/HYPR_ANIMATIONS_PLAN.md`
(Hyprland exposes deep per-leaf/per-curve animation control, but it
all lives in hand-owned `user/look.lua` — plan recommends starting
with 4 presets rather than full per-leaf editing, which is real new
territory) and `docs/FEATURE_BACKLOG.md` (consolidated list of
everything discussed this session, organized by status — done/small/
bigger-has-a-plan/needs-a-package/parked/idea — alongside the older,
more detailed `notes/SONNET_QUEUE.md`).

**Also discovered, not a bug:** notification position/corner + offset
X/Y turned out to already be built (2026-07-11, a prior session) —
briefly mis-stated as still-parked mid-conversation before being
checked against the actual code and corrected.

---

## 2026-07-12 — Font picker fix (list + rendering), settings-window stability: dropdowns as floating overlays, pages in a StackLayout (Opus)

**Context:** Follow-up polish on the settings window. Three asks, all
in the Appearance page: (1) the font-family picker's list was gigantic
(raw `Qt.fontFamilies()` dump), then after trimming, picking a font
didn't actually change anything; (2) opening the theme/font dropdowns
grew the whole window; (3) switching tabs resized the window because
each page had a different height.

**Font picker (the long one — full post-mortem in
docs/PROBLEMS_AND_FIXES.md):** Trimming the list to a hardcoded set of
popular Nerd Font names broke rendering, because the exact strings
`Qt.fontFamilies()` reports on the live machine don't match the names
`fc-list` shows (only CaskaydiaCove, the theme default, matched
verbatim). Two exact-match guards — a list filter in
SettingsWindow.qml and a validation check in
`UserPrefs.setFontFamilyOverride` — each hid this differently (empty
list / one-item list / Apply silently reverting to default). Final
design: the picker DERIVES its options from `Qt.fontFamilies()` at
runtime, showing the verbatim Qt strings (filtered to base
"... Nerd Font" families, popular picks floated up via
`preferredFontOrder`). Every offered name is therefore a real Qt
family, guaranteed to resolve; the setter's exact-match guard was
removed as redundant.

**Window stability:**
- Theme + Font dropdowns moved from inline `ListView`s (which added
  their height to the page and grew the card on open) to single
  card-level floating overlay panels, positioned via `mapToItem` off
  their button. The `mapToItem` binding is gated on the dropdown's
  open flag so it re-evaluates AFTER layout has settled — ungated it
  cached a stale pre-layout position and the panels spawned in the
  wrong place. Click-outside-to-dismiss; opening one closes the other;
  switching tabs closes both.
- The four pages are now wrapped in a `StackLayout` instead of four
  `visible:`-toggled `ColumnLayout`s. QtQuick.Layouts excludes
  `visible:false` items from a layout's implicit size, so the old
  setup made the card track whichever page was current; StackLayout
  sizes to its largest child up front, so the card height is stable
  across every tab.

**Files touched:** widgets/Settings/SettingsWindow.qml (font derive,
dropdown overlays, StackLayout), core/UserPrefs.qml (setter guard
removed). Both carry matching per-file revision notes.

**Live-confirmed:** font picking works and propagates shell-wide;
dropdowns float without resizing; tab switches hold a steady height.



**Context:** Maintainer wanted per-edge bar padding and a font family
picker in the settings window, then live-tested it and reported several
follow-ups in the same session: the Displays tab had always thrown
runtime errors (`DisplayManager` was never actually written), bottom
padding at `0` still left a visible gap under the bar, and — after a
separate ask to add a Hyprland active-border-color control — that
color went stale on theme switch and had no gradient option like the
bar border does. THEN, after all features were in and confirmed on
hot-reload, a cold `qs` restart broke the whole settings window
("Working (undefined)", dead Apply) — a singleton init-ordering bug
that took a diagnostic + bisect to pin down and a redesign to fix (see
below and PROBLEMS_AND_FIXES.md). Also a tiny NowPlaying declutter at
the end. Files: `core/UserPrefs.qml`, `core/Theme.qml`,
`widgets/TopBar/TopBar.qml`, `services/ConfigManager.qml`,
`widgets/Settings/SettingsWindow.qml`, `widgets/TopBar/NowPlaying.qml`.

**What was built / changed:**

- **Per-edge bar padding (Appearance page).** `Theme.barMargin` split
  into `barPaddingTop`/`barPaddingSide`/`barPaddingBottom`, each with a
  UserPrefs override (same `-1 = follow theme` convention as
  `barBorderWidthOverride`) and a "Custom padding" toggle + three
  steppers in the settings window. `TopBar.qml`'s `margins{}` and
  `exclusiveZone` now read the three values instead of one
  `Theme.barMargin`.
- **Bottom padding can go negative (v2, same day).** Live testing
  showed `0` still left a gap under the bar — Hyprland's own
  `gaps_out` reserves space on every screen edge independently of the
  shell's `exclusiveZone`, stacking with it. Bottom now goes down to
  `-100px` to cancel that out. Because `-1` was already taken as a
  real negative value, Bottom's "follow theme" sentinel moved to a
  dedicated `UserPrefs.barPaddingBottomOffSentinel` (`-9999`) — Top/Side
  are unchanged, still `-1`. `TopBar.qml`'s `exclusiveZone` is clamped
  to a minimum of 0 so a large negative bottom padding can't push it
  negative (Wayland rejects that).
- **Font family override (Appearance page).** Dropdown sourced live
  from `Qt.fontFamilies()` (whatever's actually installed on the
  machine, not a hardcoded guess), same closed-button +
  fixed-height-scrolling-list recipe as the theme dropdown.
  `Theme.fontFamily` now checks `UserPrefs.fontFamilyOverride` first,
  `""` = follow theme.
- **Displays page disabled, not deleted.** `services/DisplayManager.qml`
  was never actually written, so the page threw `ReferenceError`s at
  runtime the moment it (or even just the `pages` array, for the tab)
  referenced it — see PROBLEMS_AND_FIXES.md for the full write-up.
  `"Displays"` removed from `pages`; the page's UI and its supporting
  functions (`stageDisplay`, `shownDisp*`, `displayChanges`,
  `applyDisplays`) are block-commented (`/* ... */`) in place, ready to
  restore once a real `DisplayManager` exists.
- **Hyprland active-window border color (Hyprland page).** Same
  theme-or-custom-hex pattern as the bar border (toggle + swatch
  picker + hex field). Unlike the bar border, this writes into
  `generated/appearance.lua` (`general.col.active_border`) via
  ConfigManager's existing hypr-regen pipeline, gated behind a
  **one-time manual step**: `user/look.lua`'s `col` table must drop
  its own `active_border` line (keep `inactive_border`) or the two
  files fight over the same key — the exact ownership violation
  `HYPR_RESTRUCTURE.md` warns against. Not done automatically;
  `look.lua` is explicitly maintainer-owned.
- **Fixed: border color went stale on theme switch.** The color is
  baked into `generated/appearance.lua` as a static string at regen
  time, not a live Hyprland binding, and a theme switch alone never
  used to set `_hyprDirty` — so switching themes left the border on
  the OLD accent color until something else (e.g. toggling the color
  control off/on) happened to trigger a regen. `_hyprDirty` now also
  fires on `themeName` changes when the border is set to follow the
  theme.
- **Active border gradient support.** When following the theme, reuses
  the SAME `Theme.barBorderColor2` / `Theme.barBorderGradientAngle`
  tokens the bar border's own gradient uses as the second stop, so the
  compositor's window border and the shell's bar border read as one
  consistent look. Solid when a custom color is chosen, or when the
  theme's own `barBorderColor2` alpha is ~0 (same "no gradient" signal
  `TopBar.qml`'s border Canvas already uses).  `hyprGenScript` grew
  three params (second color, angle, gradient-on flag) and branches in
  bash between Hyprland's `{ colors = {...}, angle = ... }` table form
  and its plain-string form for `active_border`.
- **COLD-START FIX (Opus) — the border-color feature is Theme-free in
  ConfigManager.** The first cut had ConfigManager read `Theme`
  directly (inside `_performStagedWrites`) to resolve the theme accent.
  That added a ConfigManager → Theme → UserPrefs dependency that broke
  lazy-singleton init on a COLD `qs` start (not hot-reload): every
  `ConfigManager.*` read came back `undefined` for the whole session,
  so the settings status line stuck on "Working (undefined)" and Apply
  never enabled. Rebuilt on the proven-good original ConfigManager with
  all features re-added but ZERO Theme references: SettingsWindow (a
  normal component, safe to depend on Theme) resolves the accent + the
  bar border's 2nd color/angle into Hyprland hex and pushes them into
  four plain ConfigManager properties (`hyprActiveBorderThemeHex` /
  `Hex2` / `Angle` / `Grad`) via live `Binding`s. The Bindings being
  LIVE is what keeps theme-switching correct (the async regen reads the
  already-updated value). Custom-color resolution stayed inline (no
  Theme). Full post-mortem — including the `color`-param red herring
  that cost a round — in PROBLEMS_AND_FIXES.md.
- **NowPlaying declutter.** Dropped the ▶/⏸ glyph that preceded the
  track text — redundant (audible whether it's playing) and it ate
  horizontal bar space. `isPlaying` stays (the click handler toggles
  play/pause on it); only the visual indicator is gone. Now shows just
  track/artist.

**Explicitly NOT done yet:**

- Displays page — needs `services/DisplayManager.qml` written before
  it can be un-commented; see PROBLEMS_AND_FIXES.md for what that file
  needs to expose (`monitors`, `refresh()`, `refreshing`, `lastError`,
  `apply()`, `fmtScale()`, `parseMode()`, `validScalesFor()` — all
  inferred from the still-intact caller code).
- `user/look.lua`'s manual edit (removing its `active_border` line) is
  NOT done by the shell — the border color control does nothing
  visually until the maintainer does that by hand.
- No inactive-window border color control (only active was asked for).
- No asymmetric left/right bar padding — "Sides" is still one
  symmetric knob, per the original ask.

**Known constraints / gotchas discovered:**

- **A tab added to a settings page's `pages` array is live the moment
  it's added** — if anything the page (or even just its diff-computing
  properties, evaluated whether or not the tab is visible) references
  doesn't exist yet, it throws at runtime immediately, not just when
  clicked. See PROBLEMS_AND_FIXES.md.
- **Hyprland's `gaps_out` reserves space on every screen edge
  independently of Quickshell's `exclusiveZone`** — the two stack, so
  a shell-side "gap under the bar" can persist even at 0 padding if
  gaps_out is nonzero elsewhere. A negative shell-side override is a
  legitimate way to cancel that out, but the override system has to
  actually support negative values and a distinct "off" sentinel, or
  it's a debugging trap. See PROBLEMS_AND_FIXES.md.
- **A value baked into a generated file at regen time is only as fresh
  as the last regen** — anything computed from a live source (here:
  `Theme.colorAccent`, which changes on theme switch) needs an
  explicit trigger added for every event that could change it, not
  just the ones that obviously look hypr-related. See
  PROBLEMS_AND_FIXES.md.
- **This project's own hex convention (`#AARRGGBB`, alpha first,
  Qt-style) and Hyprland's `rgba()` literal (`RRGGBBAA`, alpha last)
  are different orders** — any value crossing that boundary needs an
  explicit reorder, not just a `#` strip.
- **A `pragma Singleton` that reads ANOTHER singleton can break
  cold-start init ordering — even from a function body.** Caught live
  at the end of this session (Opus): the border-color work had
  ConfigManager read `Theme.colorAccent` inside `_performStagedWrites`.
  That added ConfigManager → Theme → UserPrefs to the dependency graph;
  on a COLD start, `shell.qml`'s boot-time force-instantiation read of
  `ConfigManager.ready` fired before that chain resolved, the lazy init
  failed and got cached, and EVERY `ConfigManager.*` read came back
  `undefined` all session (settings: "Working (undefined)" + a dead
  Apply button). Hot-reload masked it (singleton already alive in
  memory). Fix: ConfigManager never reads Theme — SettingsWindow (a
  normal component, not a boot-forced singleton) resolves the theme
  colors and pushes them in via live `Binding`s. A first fix attempt
  wrongly blamed a `color`-typed function param and cost a round;
  removing the annotation changed nothing. Lessons: (a) if a singleton
  needs another singleton's value, have a non-singleton caller push it
  in rather than reading it directly; (b) always `pkill qs; qs` cold
  after touching a singleton's dependencies — hot-reload success is NOT
  proof; (c) when a singleton's object resolves but all its properties
  are `undefined`, stop inspecting and get DATA (a `typeof` log at a
  read site + a revert-one-file bisect localize it in one cold-start
  each). See PROBLEMS_AND_FIXES.md.

## 2026-07-11 — Themes wired up, theme picker → dropdown, color-swatch picker, and the custom-hex validation bug (Sonnet 5 + Opus)

Cross-model session (started under Sonnet 5, finished under Opus) driven
by the maintainer's next_session.txt wishlist plus live testing via screen
recordings and shell logs. Files: core/Theme.qml, SettingsWindow.qml
(v0.8 → v0.14). No changes to UserPrefs/ConfigManager needed — the final
bug was purely in SettingsWindow.

**What was built / changed:**

- **All 20 themes are actually selectable now (Theme.qml).** 18 theme
  files (AyuDark … TokyoNight) existed on disk but were never instantiated
  in core/Theme.qml — only DefaultTheme + HoneycombTheme were in the
  `themes` map, so the picker could never reach the rest. They were
  invisible, not broken (the guide's "a file nothing instantiates is
  invisible" rule, verbatim). Added a child instance + one map line each;
  `themeNames`/`active`/fallback were already generic, so nothing else
  changed. This is ALSO why the picker had to become a dropdown (below) —
  a flat row-per-theme list was fine at 2, unusable at 20.

- **Theme picker is now a dropdown (SettingsWindow v0.8).** Closed button
  + a fixed-height scrolling ListView on open, same recipe as the
  pending-changes panel (stable-geometry rule: grows downward, only on
  click). New root prop `themeDropdownOpen`, reset in discardStaged().

- **Preset color-swatch picker (SettingsWindow v0.8 → v0.14).** Clicking a
  HexColorRow's live preview swatch opens a small curated palette (24
  colors); picking one stages exactly like a valid typed hex. The hex
  field stays as the fine-tune path. Notable iteration (all live-caught):
  the popup CANNOT live inside the 22px swatch icon — Qt only delivers
  clicks to a child within its parent's bounds, so a ~180px popup
  overflowing a 22px parent renders but is dead. Final form: ONE shared
  popup rendered at CARD level, driven by root.colorPicker* state via
  root.openColorPicker(anchor, swatches, callback), positioned by mapping
  the swatch into card space and clamped to the card. Gained
  click-outside-to-dismiss for free.

- **THE BIG ONE — custom typed hex colors now persist (SettingsWindow
  v0.14).** For five debugging rounds, typed colors "never saved" while
  swatch picks always did. Root cause (found via per-keystroke logging):
  `hexValid` was a property binding with an INLINE regex literal
  containing `{6}`/`{8}` brace-quantifiers, which QML's binding parser
  misparses — it returned the OPPOSITE of the truth (empty = valid,
  `#00ff00` = invalid), so every complete typed color was rejected before
  staging. The identical regex in UserPrefs._validHex works because it's
  in a function body — which is exactly why swatches (validated only there)
  persisted and typed values (gated by the broken binding) didn't. Fixed
  by driving validity from a function using `new RegExp("…")` from a
  string. Full write-up in PROBLEMS_AND_FIXES.md — READ IT before adding
  any future validated input; this trap will recur otherwise. Also folded
  in along the way: select-all-on-focus (so typing replaces the seeded
  value cleanly) and a focus-independent `lastStagedByMe` resync (so
  swatch picks update the field even while it holds focus).

**Explicitly NOT done yet:**

- Wallpaper-derived color scheme (still the deferred matugen-sized
  project; custom hex remains the manual path).
- No new settings pages this session — this was picker/theme/validation
  work on the existing Appearance + Desktop pages.

**Known constraints / gotchas discovered:**

- **Inline regex literals with `{n}` quantifiers silently misparse in QML
  property bindings.** Validators go in FUNCTIONS (or use `new RegExp` from
  a string), never as inline-literal bindings. See PROBLEMS_AND_FIXES.md.
- **A popup larger than its parent is click-dead outside the parent's
  bounds**, even with high `z`. Render popups/overlays at a container large
  enough to receive their clicks (here: card level), not inside a tiny
  icon.
- **Same regex text in a function vs. a binding are NOT equivalent** under
  the QML parser — when one of two "identical" paths works and the other
  doesn't, suspect the context, not the pattern.

## 2026-07-11 — Notification positioning + the Desktop page (from thoughts_next_session.txt) (Fable 5)

Both items from the maintainer's thoughts note. Files: UserPrefs,
ConfigManager, SettingsWindow (v0.7), NotificationPopups, DesktopClock,
Settings, shell (comment only).

- **Notification popups are positionable**: notifCorner (4 corners,
  default = the old top-right) + notifOffsetX/Y (px from the chosen
  corner, negatives allowed) in UserPrefs; corner picker, offset
  steppers, and a Send Test Notification button (notify-send through
  our own daemon; previews APPLIED settings per the staged-not-live
  rule) on the Notifications page. Bottom-corner stacking order is a
  documented v1 limit.
- **Desktop clock fully configurable + per-monitor**: root is now
  Scope + Variants over Quickshell.screens (shell.qml unchanged);
  UserPrefs owns enabled / corner (incl. centered) / offsetX/Y /
  monitor ("" = all, else screen name) / text color / shadow on-off +
  color — colors use the bar-border theme-or-custom-hex pattern. New
  Desktop settings page drives it all; monitor cells come from live
  screens. Settings.qml's desktopClockCorner/Margin REMOVED (migrated;
  grep verified). DEFAULT CHANGE: clock shows on all monitors now, not
  just the default output. Wallpaper-derived colors deliberately
  deferred (matugen-sized project) — custom hex is the manual path.
- **Extractions at third use**: OptionPickerRow (segmented picker) and
  HexColorRow (from the bar-border hex field; resync generalized to
  watch the shown value). Tab padding Large -> Medium so five tabs fit
  the fixed card width at fontScale 1.0.


## 2026-07-10 (Fable 5) — bar border side-project

- Border around the whole bar that CONTINUES around any open popout
  (bluetooth, wifi, volume, wallpaper, launcher, clock, settings — all
  eight, since they share BarPopout). Bar strokes a rounded border via
  Canvas with a gap in its bottom edge where the open popout hangs;
  the popout draws its left/bottom/right sides inside the reveal clip,
  so the border grows with the slide-out.
- New theme tokens `barBorderWidth`/`barBorderColor` (both themes +
  Theme.qml forward). Width default -1 = follows UserPrefs.hyprBorderSize
  LIVE — the bar border tracks the Border Size slider on the Hyprland
  settings page. 0 disables. Color defaults to each theme's accent;
  Hyprland's actual border color lives in user/look.lua (never parsed),
  so set the token by hand to match.
- TopBar contents wrapped in `barRoot` (marker + gap API); BarPopout
  registers/clears its gap on open/close. Gap math mirrors the
  anchor-rect math — change together.
- Offline-tested: segment complement + gap-x math against real bar
  geometry. Live-untested; expected first-run rough edges: seam
  alignment at flush-edge popouts near the bar's rounded corners.

## Same-day extension — fillets + gradients

- Fillet joints where popouts meet the bar (the mockup): popout window
  widened by Theme.barBorderFillet per side, transparent flanks hold
  quarter arcs curving the bar's bottom border into the panel's sides;
  anchor-rect compensation keeps the panel exactly where it was. Flush
  popouts (settings/system menu) skip the fillet on their flush side.
  Token barBorderFilletRadius: -1 = follow barRadius, 0 = square joint.
- Gradient borders: barBorderColor2 (transparent = solid) +
  barBorderGradientAngle (0 = left→right, 90 = top→bottom, clockwise).
  The popout draws the bar's gradient line translated into its own
  coordinates, so color flows through the seam unbroken. Match your
  Hyprland col.active_border by using the same two colors and nudging
  the angle by eye.
- HoneycombTheme barBorderColor changed white → teal #35e0b4 (white
  border on white wallpaper: the invisible-feature incident).
- Offline-verified: border path endpoint continuity in all four flank
  configurations (both/left-only/right-only/none), gap tangency,
  anchor compensation. Known live caveats: f-wide click-dead strips
  beside an open menu (input-mask polish item), and reveal-animation
  interaction with the fillet arcs is untested.

## Fix: fillet-start clipping (found live 2026-07-10, same evening)

- SYMPTOM: a few pixels of border missing right where the bar's bottom
  border hands off to each fillet arc. CAUSE: the arc's top tangent
  point met the bar's border centerline at window-local y = -bw/2 —
  above the popup window's top edge, so the first ~sqrt(2·f·bw/2) px
  of ink were clipped (~4.5px at fillet 10 / border 2).
- FIX: the popup now overlaps the bar's bottom by one border width
  (anchor-rect height reduced by bw; panel shifted down by bw so it
  still starts at the bar's true bottom edge; the overlap strip is
  transparent, bar shows through). Tangent lands at window y = +bw/2 —
  fully drawable. bw = 0 degenerates to the old geometry exactly.
- BONUS while in there: the fillet WEBS are now filled with the
  background color (the concave area between arc, bar bottom, and
  panel side) — matching the mockup's solid silhouette instead of a
  bare curve floating over the wallpaper.
- Also: screenshot keybinds close open popouts — that's
  HyprlandFocusGrab's outside-focus dismiss working as designed, not a
  bug. `sleep 3 && grim /tmp/shot.png`, then open the menu.

PASTE INTO docs/PROBLEMS_AND_FIXES.md:
2026-07-10 — Fillet border: first pixels of each fillet arc missing.
The arc's tangent point sat half a border width above the popup
window's top edge (windows can't draw above themselves). Fixed by
overlapping the popup one border width up into the bar (transparent
strip, panel repositioned). Lesson: when two windows must share one
drawn shape, put the WHOLE joint inside one window — half-in/half-out
geometry gets clipped at the surface boundary.

## Bar Border settings (Appearance page)

- New UserPrefs overrides above the theme tokens: barBorderWidthOverride
  (-1 = follow theme -> hyprBorderSize chain), barBorderUseThemeColor,
  barBorderCustomColor (hex, validated at input AND in the setter).
- Appearance page: "Custom width" toggle + px stepper (0-12; toggling
  on seeds the current effective width so nothing jumps), "Use theme
  color" toggle, and the window's first TextInput — hex field with live
  swatch, red until valid, only valid hex can stage. 8-digit input is
  Qt-style #AARRGGBB (alpha FIRST), noted in the UI.
- Rides the normal staged Apply (snapshot -> write), three new switch
  cases in ConfigManager. Files: UserPrefs.qml, Theme.qml,
  SettingsWindow.qml, ConfigManager.qml.

## 2026-07-09 — SONNET_QUEUE.md: the handoff (Fable 5)

**Context:** Maintainer loses Fable access in ~2 days; the roadmap in
PROJECT_VISION.md was model-assigned accordingly. This session's tail
executed queue item 3 early: notes/SONNET_QUEUE.md — nine per-item
build plans with decisions locked, traps listed, and one API
pre-verified so the keybind cheat-sheet overlay (Q1) moved from
"needs Fable" to recipe work: `hyprctl binds -j` field set and
modmask bit values (SHIFT=1, CTRL=4, ALT=8, SUPER=64) confirmed
against Hyprland sources, including the historical stray-line
JSON-parsing caveat. Designed exclusions are marked as such (no
one-click Original restore; no hibernate without swap confirmation;
parked list at the bottom is binding). Remaining Fable queue:
restructure live-confirm + the Displays page with the
apply-with-revert-timer pattern — those need the next (final) Fable
session.

## 2026-07-09 — Phase 3 built: the Hyprland split (from the REAL config), Lua generation in the transaction, Hyprland settings page (Fable 5)

**Context:** hyprland.lua re-synced (and immediately banked at
notes/hyprland.lua so the wipe-and-drag KB workflow — which is
otherwise the CORRECT workflow, no stale files — can never lose it
again). First full read of the live compositor config, which
produced two findings before any building:

- **shell:power had no keybind.** Docs assumed SUPER+P since 07-05;
  SUPER+P is actually the screen recorder. The power screen has been
  arch-icon/IPC-only its whole life. Fixed in the restructure:
  SUPER+Escape (was free; rebind to taste).
- **SUPER+M's fallback was a no-op**: `hyprctl dispatch
  'hl.dsp.exit()'` isn't a dispatcher. Fixed to `hyprctl dispatch
  exit` in the restructure copy.

**Built:**

- **notes/hypr-restructure/** — the maintainer's ACTUAL config split
  byte-faithfully (coverage-audited line-by-line): requires-only
  hyprland.lua root; generated/appearance.lua (ONLY the four managed
  values — gaps in/out, border size, rounding) + generated/
  monitors.lua (static copy, future Displays page); user/look.lua
  (colors/blur/shadow/opacity/layout/animations/curves), user/
  startup.lua, user/rules.lua, user/keybinds.lua (with its own
  program locals — `local` doesn't cross require boundaries). The
  ownership boundary is per-key: hl.config() merges, and no key is
  set on both sides.
- **docs/HYPR_RESTRUCTURE.md** — the one-time by-hand procedure
  (snapshot + full hypr copy → install split → verify → one-file
  rollback), per the plan's rule that the manager never rewrites
  hand-written config, including during its own installation.
- **ConfigManager Phase 3 machinery** — generated/appearance.lua
  joins managedPaths (snapshot-skips silently until the restructure
  exists); applyChanges chains a whole-file Lua regeneration when any
  hypr* key is staged (fixed-shape heredoc template, integers only,
  pre-clamped; Hyprland auto-reloads on write; graceful
  "restructure not done, skipped" before the split exists).
- **UserPrefs**: hyprGapsIn/Out, hyprBorderSize, hyprRounding —
  defaults exactly match the live config, so the first generated
  file is a visual no-op.
- **SettingsWindow**: third page (Hyprland) — four steppers + a
  restructure-status note.

**Added same session — the project grows a north star:** the
maintainer's project-vision.md reviewed and banked as
docs/PROJECT_VISION.md (public release as an AI-maintainable Hyprland
DE — "KDE but with vastly superior window management"), and its
embedded AI-guide draft written out properly as
docs/AI-MAINTENANCE-GUIDE.md by its own target audience: corrected
against current reality, with the verified-behaviors list and the
session protocol that actually evolved here. README links both.

**⚠ Written offline — NOT yet run live**, and the restructure itself
is MAINTAINER-EXECUTED by design. Test order: (1) reload shell, prefs
page works in degraded mode ("generation skipped" on Apply); (2) run
docs/HYPR_RESTRUCTURE.md; (3) Hyprland page Apply → gaps change on
screen within a second → `config restore` puts them back.

## 2026-07-09 — Notifications settings page (from THOUGHTS.txt), page tabs, daily-snapshot wiring; maintainer edit adopted (Fable 5)

**Context:** Session continued after the maintainer synced the KB,
hand-edited NotificationPopups (commented out the app-name block),
and left THOUGHTS.txt — a wishlist for notification settings: hide
app name, icon size, font sizes. "Let it rip" + a wishlist = the
target picked itself. A bulk diff of the synced KB against the master
tree confirmed the comment-out was the ONLY maintainer code edit.

**THOUGHTS.txt, answered:**

- *"font sizes... by line? the band name and song are different
  boldness"* — the boldness inside the body is the SENDER's doing:
  Tauon sends `<b>…</b>` markup in the notification body and the card
  renders it (Text.StyledText, declared bodyMarkupSupported). Not
  ours to configure; a per-card font-scale multiplier covers size.
- *"it's only 2 lines so it would cut song names short"* — corrected
  diagnosis for the record: the body already allowed 4 lines. The
  truncation was the app name sharing the summary's ROW, stealing up
  to a third of its width. The instinct (kill the app name) was
  right; the mechanism was the row, not the line count.

**Built:**

- Four persisted prefs in UserPrefs (+ ConfigManager transaction
  keys): notifShowAppName (default FALSE — the maintainer's hand-edit
  adopted as policy), notifIconSize (48, steps of 8, 24–96),
  notifBodyLines (4, 1–10), notifFontScale (1.0×, 0.8–2.0).
- NotificationPopups reads all four; the commented block became
  `visible: UserPrefs.notifShowAppName`.
- SettingsWindow v0.2: page tabs (Appearance | Notifications), the
  Notifications page, StepperRow/ToggleSettingRow inline components
  (the −/+ control existed four times — extracted), and
  daily-snapshot-on-open finally wired (skips silently if the engine
  is mid-op). Staged changes survive tab switches; only close/Cancel
  discards.

**⚠ hyprland.lua fell out of the KB AGAIN** — external files don't
survive the flatten-and-replace sync cycle (second occurrence).
Permanent fix documented in the README: keep a copy at
notes/hyprland.lua inside the repo. **Maintainer action for next
sync: `cp ~/.config/hypr/hyprland.lua ~/.config/quickshell/notes/`.**
Phase 3 stays blocked until then.

**⚠ Written offline — NOT yet run live.** Quick test: reload →
notifications look identical to the hand-edited state → gear → Open
Settings → Notifications tab → stage "Show App Name" ON + Icon Size
64 → Apply → `notify-send "Song Title" "Artist — Album"` shows both
→ restore the auto snapshot → notify-send again shows neither.

## 2026-07-09 — Phase 2 built: the settings window, runtime theme switching (the 07-05 deferred item), Apply transaction (Fable 5)

**Context:** Same day, session continued straight from the Phase-1
closeout at the maintainer's call. hyprland.lua landed in the KB
(Phase-3 prerequisite satisfied). The plan's open questions were
resolved as the documented leans: in-process window; ONE JSON file
(user-prefs.json IS the settings store — no settings.json will be
born); themeName stored as the type name.

**The centerpiece — Theme.qml themes map (retry of the 07-05
incident):** theme instances as NAMED CHILDREN of the singleton
(never instantiated inline inside an object literal — QML can't, and
that's the prime suspect for the original breakage), a parenthesized
`themes` map, `themeNames` via Object.keys, and `active:
themes[UserPrefs.themeName] ?? fallback`. Legacy stored "Honeycomb"
hits the fallback and self-corrects on the first Apply. Widgets
needed ZERO changes — the forwarding layer earned its keep. Taken
with the standing rule this time: snapshot first (the engine built
this morning exists precisely because of what this file did in July).

**The settings application, v0:** widgets/Settings/SettingsWindow.qml
— centered Overlay card on PowerScreen's proven recipe. Appearance
page only: theme picker + font scale (−/+ 0.1 steps). Changes are
STAGED, not live: a pending panel shows the diff ("Theme:
HoneycombTheme → DefaultTheme"), Apply runs
ConfigManager.applyChanges (auto snapshot FIRST, staged UserPrefs
writes only after it lands; snapshot failure aborts the write), and
Cancel/close discards. Opened via the gear menu's new
"Open Settings…" entry (Signals.toggleSettingsWindow) or
`qs ipc call settings toggle`.

**Supporting changes:** fontScale moved Settings→UserPrefs (persisted,
clamped 0.8–2.5; sole consumer Theme.fontSize updated in the same
edit, grep-verified); the gear popout's dead Appearance section
replaced by the Open Settings button (quick toggles stay — the
transient/durable split); Signals gained toggleSettingsWindow;
docs updated throughout (ARCHITECTURE tree, services/README finally
lists ConfigManager, BACKUPS.md auto-snapshot note, README).

**LIVE-CONFIRMED same day** — maintainer's verdict: "no shit it
works." Theme switching reskins the whole shell on Apply, the auto
snapshot appears, restore snaps it back. THE 2026-07-05 INCIDENT ITEM
IS CLOSED: the exact change that broke the bar in July now works,
rebuilt with a different pattern on top of the safety net that exists
because it broke. Original first-launch checklist kept below for the
record:
1. Reload; any Theme.qml/SettingsWindow errors in the log = stop.
2. Bar should look IDENTICAL (Honeycomb via fallback, fontScale 1.4
   from the UserPrefs default).
3. Gear → Open Settings…; stage DefaultTheme; pending panel shows the
   diff; Apply → whole shell reskins live + an _auto_ snapshot
   appears in `config list`.
4. `config restore` that snapshot → theme snaps back (undo proven).
5. Font scale −/+ → Apply → all text resizes.
6. Escape / click-outside with staged changes → reopen → cleanly
   discarded.

**Explicitly NOT done yet:** daily-snapshot-on-open wiring (one line,
next session); live preview (deliberately staged-only — see
SettingsWindow DESIGN NOTES); Phase 3 (Hyprland split — now
designable, hyprland.lua is in the KB).

## 2026-07-09 — Phase 1 LIVE-CONFIRMED; gear menu found dark and fixed; JsonAdapter garbage behavior verified (Fable 5)

**Context:** Maintainer home, first live run of the Phase-1 tree.
Started with a false alarm (doubled bars per monitor = two shell
instances running, autostart + terminal — the "Could not register
notification server, one already registered" WARN was the tell, since
this shell is the machine's only daemon; dedupe with
`pgrep -af quickshell` / kill, no code change).

**Live-test results (see also the two new PROBLEMS_AND_FIXES entries):**

- **The snapshot engine works end-to-end:** original backup, manual
  snapshot, deliberate corruption of user-prefs.json, IPC restore →
  file back byte-correct, live UI picked it up via FileView watch.
- **New verified knowledge:** JsonAdapter fed garbage logs ONE WARN
  and keeps in-memory values — no reset, UI unaffected, shell runs on
  last-known-good. Self-healing on next write; also means malformed
  hand-edits get clobbered. Documented in UserPrefs.qml DESIGN NOTES.
- **Manual-restore casualty #3 found and fixed:** SettingsMenu.qml was
  never instantiated — the 07-05 manual restore had brought back a
  pre-gear-menu TopBar.qml. `SettingsMenu {}` added to the right
  RowLayout (applied live by the maintainer, mirrored here). With it
  visible, the 07-09 clock-toggle fixes were ALSO live-confirmed
  (both toggles now actually change both clocks).
- Expected degradations seen, no action: missing power + weather-rain
  SVGs hide themselves per design (icons still not sourced).

**Test list: ALL GREEN (final two confirmed later same day):**
prune with only manuals deletes nothing ✓; restore of a nonexistent
snapshot returns "error: no manifest" rather than silence ✓;
toggle-write persistence after restore confirmed implicitly through
continued gear-menu use post-restore ✓. The doubled-instance/pkill
oddity was written off by the maintainer as probable user error and
not pursued (`pgrep -af quickshell` is the tool if it recurs). Still
worth doing once, non-blocking: `diff -rq` of the live tree vs the
pre-phase1 manual backup to hunt for restore casualty #4.

**Added later same day:** docs/BACKUPS.md — user guide for the
snapshot commands (workflow, retention, on-disk layout, manual
recovery via manifest.tsv, the corrupt-JSON self-heal note), linked
from the README's documentation list.

**Phase 2 is now unblocked** (Appearance page + transaction loop +
the Theme.qml themes-map rebuild). New open question added to the
plan: stored themeName format ("Honeycomb" on disk vs the
HoneycombTheme type name).

## 2026-07-09 — ConfigManager Phase 1 built: the snapshot/restore engine (Fable 5)

**Context:** Same day as the housekeeping session below, after the
settings-manager v1 plan was written (notes/settings-manager-plan.md).
Maintainer green-lit starting Phase 1 — the phase that needs nothing
not on hand (no hyprland.lua copy, no UI decisions, no machine
access). Written OFFLINE, per the established build-session pattern.

**What was built:**

- `services/ConfigManager.qml` — new singleton (pragma Singleton +
  Singleton root). One-time Original Backup (full cp -a of the
  quickshell + hypr config dirs into
  `~/.local/state/quickshell/original/`, idempotent via a `.complete`
  marker, runs on every instantiation and no-ops after the first);
  manifest-driven snapshots (manual/daily/auto kinds) of the MANAGED
  file set (currently just user-prefs.json — later phases append);
  restore replays a snapshot's own manifest, so old snapshots restore
  correctly under a grown managed set; auto/daily pruning past
  `Settings.configAutoSnapshotKeep` (manual + Original never pruned);
  one serialized Process, POSIX-sh scripts, all paths as positional
  args (the project's injection guard). Reads UserPrefs.stateDir —
  one definition of where state lives.
- `core/Settings.qml` — `configAutoSnapshotKeep` (30).
- `shell.qml` — `import qs.services`, a `ConfigManager.ready` read on
  the Scope root (force-instantiates the lazy singleton at launch —
  that's what triggers the Original Backup), and a `config` IpcHandler
  test surface: snapshot(label) / list / restore(name) / prune /
  status. The future settings app calls ConfigManager directly; the
  IPC exists so the engine is exercisable live before any UI.
- `notes/settings-manager-plan.md` added to the repo (was
  chat-delivered only) with a Phase-1 status stamp.

**A first for this project — logic tested BEFORE first boot:** all six
sh scripts were extracted from the QML and run against a sandbox
config tree in the build environment. Every Phase-1 success criterion
passed: original-backup create-then-idempotent-rerun, snapshot
manifest correctness, deliberately-mangled prefs restored
byte-identical, daily snapshot deduped per-day, prune kept exactly N
newest auto/daily while the manual survived. Two real bugs were caught
and fixed in the process — JS template literals interpolating the
scripts' shell `${...}` (would have thrown at load; now escaped) and
`set -e` aborting the original-backup script on a missing hypr dir
(now if/fi).

**Explicitly NOT done yet:**

- QML wiring never run live (singleton load, Process plumbing,
  SplitParser output, IPC target). Live test procedure is in
  shell.qml's IPC comments: expect `original backup created` in the
  log on first launch, then snapshot → mangle user-prefs.json →
  restore → confirm the SettingsMenu toggles reflect the restored
  values.
- Phase 2 (Appearance page + transaction loop + the Theme.qml fix)
  not started — blocked on live-confirming Phase 1 and the
  ask-at-session-start questions in the plan.
- The plan's Q4 still stands: a current copy of hyprland.lua is
  needed in project knowledge before Phase 3 design.

## 2026-07-09 — Housekeeping session: folder structure repaired, two silent clock-pref bugs fixed, docs made self-contained (Fable 5)

**Context:** New-session review of everything built since the docs last
kept up (the 07-05/07-06 work below was found undocumented here — see
the catch-up entry that follows this one). Everything was confirmed
running live by the maintainer before this session touched anything.

**Bugs fixed:**

- `widgets/Desktop/DesktopClock.qml` and `widgets/TopBar/Clock.qml`
  both read `Settings.clockUse24Hour`/`clockShowSeconds` — properties
  REMOVED from Settings on 07-05 (moved to `core/UserPrefs.qml`). Both
  references evaluated to `undefined` silently: both clocks were stuck
  12-hour/no-seconds and the SettingsMenu toggles did nothing visible.
  Both now read `UserPrefs.*`. (Clock.qml was the known-deferred half
  of the 07-05 partial-revert finding in PROBLEMS_AND_FIXES;
  DesktopClock had recreated the same bug in a new file.) ⚠ The
  Theme.qml/Appearance-section half of that finding is STILL deferred.
- `services/Weather.qml` — root type `Item` → Quickshell's `Singleton`,
  matching every other pragma Singleton in the project.
- `widgets/PowerMenu/PowerScreen.qml` — the maintainer's hand-edited
  card-size tweak (`scale: 1.6 + reveal * 0.1`) refactored into a
  separate `cardScale` knob (1.7, same final size) multiplied by a
  standard grow-in, so size and animation are independently editable.

**Folder structure repaired (live-machine damage from a manual
flat-to-tree restore after the settings-menu incident):**

- A NEWER `NotificationPopups.qml` (with the 07-05 icon-hide-on-Error
  fix) was sitting in `widgets/TopBar/` while the OLD 07-04 version
  still occupied `widgets/Notifications/` — two same-named types across
  two imported modules, with the old one likely the one actually
  loading. The newer file now lives at its declared path; the stray and
  the stale copy are gone.
- A duplicate `colorthemes/` folder (byte-identical copies of both
  theme files) existed alongside the real `themes/` folder that
  `core/Theme.qml` actually imports. Removed.

**Docs made self-contained:** all references to the pre-Quickshell
setup's specific tools and to the since-removed external reference
config were scrubbed or genericized across every .qml header and doc
(the technical lessons stayed; the name-drops went). PROJECT_README →
rewritten as a current-state README (migration table removed);
ARCHITECTURE's folder tree rewritten to match reality (it still
described a `core/Shell.qml` that no longer exists);
INTEGRATION_NOTES slimmed to a hyprland.lua reference;
services/README rewritten. Two entries in THIS file had lost their
`## date — title` headers (the 07-05 wifi/bluetooth session and the
07-05 first-live-test session) — restored. Stale one-purpose docs
deleted: DESKTOP_CLOCK_SETUP.md (its Settings additions and shell.qml
wiring already landed), notes/wallpaper-picker-plan.md (twice marked
archivable after the picker was confirmed live).

**New convention:** changelog entries now note which Claude model wrote
the session's work, in the entry title — makes "which model did what"
a grep instead of forensics. Template below updated.

**Explicitly NOT done yet:**

- Theme.qml `themes` map / SettingsMenu Appearance section — still the
  standing deferred item (PROBLEMS_AND_FIXES 2026-07-05).
- The clock toggles now being live-wired needs a quick visual confirm
  on the machine (flip 24-Hour Time in the gear menu; both the bar
  clock and desktop clock should react immediately).

## 2026-07-05/06 — CATCH-UP ENTRY (written 2026-07-09): multi-monitor bar, power screen, HoneycombTheme, desktop clock + weather, wallpaper lag root cause

**Context:** These sessions happened after the entry below but never
got changelog entries — the per-file REVISION HISTORY headers carry the
detail; this entry exists so this file's top-to-bottom read doesn't
skip straight from "caching unsolved" to the present. In brief:

- **shell.qml became the real config root** (a `Scope`; the old
  `core/Shell.qml` intermediary is gone) and the bar went
  **multi-monitor**: one TopBar per screen via `Variants` over
  `Quickshell.screens`, `Settings.barExcludedScreens` regex filter,
  and focused-monitor routing for the launcher/wallpaper shortcuts.
  All GlobalShortcuts and IpcHandlers consolidated into shell.qml.
- **PowerScreen built** (`widgets/PowerMenu/`) — centered floating
  card replacing SystemMenu's dropdown; Overlay layer;
  HyprlandFocusGrab dismissal; SUPER+P + `qs ipc call power toggle`;
  first activation of `core/Signals.qml` (togglePowerScreen()).
- **HoneycombTheme created** (`themes/HoneycombTheme.qml`) and set as
  the active theme (hardcoded in core/Theme.qml).
- **Desktop clock + weather built** (`widgets/Desktop/DesktopClock.qml`
  + `services/Weather.qml`) — Background-layer, click-through
  clock/date/weather over the wallpaper; ZIP→Open-Meteo weather with
  graceful degradation at every layer.
- **The wallpaper "lag" root cause was found** — and it INVALIDATES
  the conclusions of the entry immediately below: the thumbnail dir
  Setting (`.thumbs`) never matched the generation script's folder
  (`thumbs`), so every cell had been silently decoding full-size
  originals the whole time. Full writeup in PROBLEMS_AND_FIXES
  ("full-size images silently loading instead of thumbnails"). Treat
  the entry below as historical record of a wrong turn, not guidance.
- `docs/HYPRLAND_INFO.md` gained verified notes on the Hyprland Lua
  config situation (2026-07-06).

## 2026-07-05 — Wallpaper caching: three attempts, none solved it — reset to clean base + PageUp/PageDown

> ⚠ **SUPERSEDED** — the real root cause (thumbnail-dir mismatch, full
> writeup in PROBLEMS_AND_FIXES) was found in a later session; see the
> catch-up entry above. The GridView/cacheBuffer theorizing below ran
> against a masked bug and should not be treated as reliable findings.

**Context:** Direct continuation of the wallpaper caching work from
earlier the same night (below). Three successive fix attempts (skip
rescan on reopen; freeze shuffle order while caching; startup preload
pool with live diagnostics) all failed to actually fix the ~1-1.5s lag
once Shuffle was involved on a 1000+ collection — full writeup,
including the key finding that reframes the whole problem, is in
docs/PROBLEMS_AND_FIXES.md ("Wallpaper picker thumbnail caching —
investigated, not solved, reset to base").

**The short version:** the lag was never actually about popout open/
close, shuffle, or array replacement — scrolling top-to-bottom-to-top
WITHOUT ever closing the popout also re-triggers reloading, meaning
it's inherent to GridView's own cacheBuffer/reuseItems scroll
recycling. Every attempt this session was solving a problem adjacent
to the real one. A live test of `cacheBuffer: 0` was in progress
(most promising remaining lead, given the finding above) when the
maintainer asked to stop and reset rather than keep iterating blind.

**What's actually in the file now:** reset to a clean pre-caching
base (maintainer's own backup upload), plus PageUp/PageDown added
(jumps a full page of rows — simple, unrelated, worth keeping). All
caching/preload/diagnostic code from this session's attempts is gone —
not preserved, since none of it worked. `UserPrefs.wallpaperCachingEnabled`
and SettingsMenu.qml's "Cache Thumbnails" toggle still exist and still
do nothing, exactly as before this investigation started.

**Explicitly flagged for whoever picks this up:** start from the
`cacheBuffer` lead (try 0, try smaller than `cellSize * 4`, or look at
`reuseItems` behavior directly) rather than re-attempting anything
about open/close timing or shuffle-order freezing — both already
individually confirmed not to be the cause.

## 2026-07-05 — Wallpaper thumbnail caching wired up; found (but deliberately deferred) a bigger settings-menu inconsistency

**Context:** Continuation of the same night as the Wifi/Bluetooth
session below, resumed after the maintainer re-synced project
knowledge and asked for a general "once over" of the updated files
plus a docs update. Original ask (from the maintainer's own notes at
the top of this file's session before last) was a simple "add a cache
toggle next to Shuffle" — turned into a bigger discovery along the
way.

**What was found (once-over, not from this specific ask):**
`widgets/TopBar/SettingsMenu.qml`, `core/UserPrefs.qml`, and
`Settings.qml`'s clock-property removal all survived the prior
session's partial revert, but `core/Theme.qml` itself went back to its
safe pre-session shape — the two halves were never reconciled. Result:
the gear-icon menu's "Appearance" (theme picker) section and "24-Hour
Time"/"Show Seconds" toggles are silently non-functional (full story
in docs/PROBLEMS_AND_FIXES.md). Explicitly NOT fixed this session —
maintainer's call, deferred to later, specifically to avoid
re-touching `core/Theme.qml` (the exact file that caused the prior
session's 1.5-hour dead end).

**What WAS fixed this session:** the one piece of that same leftover
work that the maintainer actually wanted right now —
`UserPrefs.wallpaperCachingEnabled` existed with a working persisted
toggle in SettingsMenu but no consumer. `widgets/TopBar/
WallpaperPicker.qml` now reads it: `rescan()` skips the folder
scan entirely on reopen when caching is on and a listing already
exists, relying on the popout window never being destroyed (so
already-decoded thumbnails just stay alive). Added a second checkbox
in the picker's own header (next to Shuffle) driving the same
`UserPrefs` property, so there are now two working entry points to one
real setting instead of one dead one.

**Explicitly NOT done yet / still open:**
- Theme.qml/SettingsMenu.qml Appearance section, and Clock.qml's
  UserPrefs wiring — found broken this session, fixing deferred to a
  future session by explicit maintainer request.
- Everything else already open as of the prior entry below (settings
  menu beyond the above, hyprland.lua bind confirmation, Volume OSD
  confirmation, previous-picker file cleanup) — unchanged, still open.

## 2026-07-05 — Wifi scan list fixed (nmcli-driven), bluetooth pairing fixed (BlueZ agent), one confirmed fix at a time

**Context:** Direct continuation after the prior session's settings-menu
attempt regressed `core/Theme.qml` to everything-undefined and got
reverted to backup without a root cause ever found (see that entry
below and the maintainer's own account at the top of this session).
This session deliberately picked up the original, still-open wifi/
bluetooth asks instead, one at a time, with live confirmation after
each fix before moving to the next — direct contrast with the previous
session's shotgun debugging.

**What was fixed — Wifi:**

- `services/Network.qml` — the wifi scan list was silently never
  populating from `Networking.wifiDevice.networks` (confirmed live: no
  errors, `nmcli` itself saw every network fine, Quickshell's own
  property just stayed empty). Rebuilt to parse `nmcli -t -f
  IN-USE,SSID,SIGNAL,SECURITY dev wifi list` directly instead — the
  same proven approach maintained real-world Quickshell configs use.
  Connection status/toggle
  (unaffected, confirmed already working) still comes from
  `Quickshell.Networking`.
- Refresh is event-driven only: `widgets/TopBar/Wifi.qml` triggers a
  cheap list refresh when the popout opens; Rescan forces a real scan.
  No background polling (an early draft's 15s timer was removed the
  same session).
- **Confirmed live:** toggle, status, scan list, and connect (tested
  against a saved network).

**What was fixed — Bluetooth:**

- `widgets/TopBar/Bluetooth.qml` — added a "New Devices" section:
  discovery starts when the popout opens (adapter must be enabled) and
  stops when it closes, same on-demand principle as the Wifi fix above.
  Click a discovered device to pair it.
- New `services/BluetoothAgent.qml` — pairing silently failed
  ("Authentication attempt without agent" in the bluetoothd journal;
  full story in docs/PROBLEMS_AND_FIXES.md) because nothing had ever
  registered a BlueZ pairing agent. This service keeps a `bluetoothctl`
  process alive for the shell's whole session purely to register one
  (`agent NoInputNoOutput` + `default-agent`), with a restart timer if
  it ever dies. NoInputNoOutput means "Just Works" pairing only — no
  PIN entry support, matching the scope the reference project also
  chose not to build.
- **Confirmed live:** scan, pairing (tested against a game controller),
  and existing paired-device connect/disconnect (already working,
  untouched this session).

**Bugs hit and fixed same-session (both documented in
docs/PROBLEMS_AND_FIXES.md):**

- Two separate `Timer is not a type` load failures — missing `import
  QtQuick` in two different new `pragma Singleton` files
  (`Network.qml`, then `BluetoothAgent.qml`). Both one-line fixes,
  caught immediately via the load-time error.

**Explicitly NOT done yet:**

- Settings menu (theme selection, thumbnail caching toggle, time/date
  display options) — the feature that broke last session and got
  reverted. Not reattempted this session; still fully absent.
- `hyprland.lua`: still unconfirmed whether the SUPER+W bind and
  awww-daemon autostart lines actually landed — flagged as open in an
  earlier entry, still open.
- Volume OSD: still not explicitly, consciously confirmed live as
  working — flagged as open in an earlier entry, still open.
- The previous wallpaper-picker's leftover files: marked safe to
  delete once the picker was confirmed working, not yet actually
  deleted.
- The README's Bluetooth capability note said "pairing NEW devices
  still needs bluetoothctl" — no longer true as of this session;
  needed updating. (Resolved 2026-07-09: the README was rewritten
  entirely and the note is gone.)

## 2026-07-05 — First live test of the 07-04 builds: notification daemon and wallpaper picker confirmed, first live bug fixed, shuffle added

**Context:** First live run of everything from the 2026-07-04 build
session (below). Maintainer tested on the real machine with Claude
assisting over chat. Date note: build was 07-04, testing ran into
07-05.

**Confirmed working live:**

- **Notification daemon** — worked on the FIRST live run, with the
  previous daemon removed from the system entirely (maintainer's call;
  Claude's suggested mask-first approach was skipped and it worked
  out). The shell has been the machine's only notification daemon
  since. Sub-behaviors
  (critical red border/never-expire, per-sender timeouts, action
  buttons) not individually walked through yet — flag anything odd in
  PROBLEMS_AND_FIXES if one misbehaves later.
- **Wallpaper picker** — grid opens, thumbnails load, clicking applies
  via awww. Confirmed as the machine's wallpaper picker.
- **Volume OSD** — installed with the rest; not yet explicitly
  confirmed live as of this entry. If it's been fine, mark it; if it
  flashed on startup or ate a click, that contradicts its design notes
  and belongs in PROBLEMS_AND_FIXES.

**Fixed live (details in PROBLEMS_AND_FIXES.md):**

- FIRST LIVE BUG of the project: keyboard selection in the wallpaper
  grid was invisible — the colorHover cell FILL hid behind the
  thumbnail image. Reworked: selection = 2px accent border, active
  wallpaper = corner badge dot (was previously the accent border).
- Environment, not code: awww wasn't installed on this machine;
  awww-daemon started manually (it's a plain daemon, not a systemd
  unit); junk `{core,services,...}` literal directories cleaned from
  the config root; `qs ipc` needs NO `-c` flag on this machine
  (shell.qml sits at the quickshell root, so there's no config name);
  wallpapersPath needed lowercase `~/Pictures/wallpapers`.

**Added live (maintainer requests):**

- `Settings.wallpapersThumbDir` default changed "thumbs" → ".thumbs"
  (hidden dir).
- **Shuffle checkbox** in the picker header: randomizes grid order
  (Fisher–Yates on a copy; canonical list stays sorted so IPC list()
  is deterministic), RE-ROLLED ON EVERY OPEN so large collections
  don't fossilize into the same visible top rows. New
  `Settings.wallpaperShuffleDefault` (false) sets the checkbox's
  starting state. New `displayList` property is what the grid renders;
  selection sync and Enter-to-apply follow display order.

**Explicitly NOT done yet:**

- Search/filter in the wallpaper picker (typed filter over basenames,
  launcher-style) — natural next picker feature now that shuffle makes
  "find wallpaper X by position" impossible.
- OSD live confirmation (above).
- hyprland.lua: confirm the SUPER+W bind and awww-daemon autostart
  lines actually made it in (both provided in
  docs/INTEGRATION_NOTES.md; SUPER+W was still being asked about at
  session end).

## 2026-07-04 — Offline verification pass: all new-module APIs source-verified, one latent bug found and fixed

**Context:** Same build session as the two entries below, remaining
budget spent verifying instead of building a fourth untested module.
Checked against the actual quickshell master source
(github.com/quickshell-mirror/quickshell) and swww source
(github.com/LGFae/swww — awww is renamed swww), plus a qmllint pass.

**What was verified / changed:**

- Every Quickshell API name used by the three new modules confirmed
  real: full NotificationServer/Notification/NotificationAction
  surface (including `bodySupported`),
  `NotificationUrgency.Critical`, ObjectModel's
  `modelData` role + reactive `values` (Repeater-over-ObjectModel is
  valid), window `mask` + `Region` (click-through), `Quickshell.env()`,
  `iconPath()`, GlobalShortcut props.
- `awww query` output format confirmed character-for-character from
  the swww Display impls — the picker's parse is correct, including
  skipping `color:` lines after a `clear`.
- **Bug found & fixed before it ever ran:** the awww client
  CANONICALIZES paths before sending, so `query` returns
  symlink-resolved paths; the picker's scan now pipes through
  `realpath` so the current-wallpaper highlight matches on symlinked
  wallpaper dirs (stow-style dotfiles).
- qmllint (Qt 6.4): all seven session files parse with zero syntax
  errors.

## 2026-07-04 — Volume OSD + the shell's own notification daemon

**Context:** Maintainer AFK with "use the session however"; built the
two items the 2026-07-03 "Explicitly NOT done yet" list called out.
Written offline this session; tested live 2026-07-05 (top entry).

**What was built:**

- `widgets/OSD/VolumeOsd.qml` — NEW (new folder, `qs.widgets.OSD`).
  Click-through (empty-Region mask) bottom-center pill on any
  volume/mute change from any source; fades after
  `Settings.osdHideDelay`. Startup-flash grace timer covers the async
  PipeWire bind. First top-level window besides the bar. Volume-only
  by design (desktop, no brightness service).
- `services/Notifs.qml` — NEW. Owns THE NotificationServer — the
  org.freedesktop.Notifications D-Bus name has exactly one owner, so
  the server must live in a singleton even with one consumer today
  (the exception the "don't wrap until shared" rule anticipated).
  tracked == visible in v1; no history layer yet.
- `widgets/Notifications/NotificationPopups.qml` — NEW (new folder).
  Top-right cards under the bar: icon/image, summary + app name, body
  (StyledText markup subset), action buttons (resident-aware),
  left-click dismiss / middle-click dismiss-all, per-sender timeout
  policy (sender timeout > default > 0=never; critical never expires,
  red border), `Settings.notifMaxVisible` cap with overflow queuing.
- `core/Shell.qml` — instantiates both (first additions since TopBar).
- `core/Settings.qml` — `osdHideDelay` (1500), `osdWidth` (320),
  `notifWidth` (380), `notifDefaultTimeout` (5000),
  `notifMaxVisible` (5).

**Explicitly NOT done yet:**

- Notification center/history (services/Notifs.qml's DESIGN NOTES say
  where that state layer goes), grouping, DND, inline reply.
- OSD brightness/mic rows.

## 2026-07-04 — Wallpaper picker: grid popout, awww integration, IPC, keyboard nav

**Context:** Built from notes/wallpaper-picker-plan.md (now archivable).
The plan's five open questions were answered with Settings-token
defaults per maintainer delegation. Replaces the previous wallpaper
picker — confirmed live 2026-07-05 (top entry).

**What was built:**

- `widgets/TopBar/WallpaperPicker.qml` — NEW. Second centered BarPopout
  (after Launcher), first GridView, first image-loading widget. Grid of
  pre-squared thumbs (missing-thumb cells fall back to a downscaled
  crop of the full image — deliberate deviation from the plan's "skip
  it"), applies on ALL outputs via awww with configurable transition,
  current-wallpaper highlight via `awww query` (which doubles as a
  daemon health check → warning row instead of silent no-op clicks),
  arrows/Enter/Escape, Random button, SUPER+W global shortcut
  (shell:wallpapers), IPC target `wallpapers`
  (toggle/set/get/list/random).
- File listing via sh/find Process (the plan's blessed fallback —
  FolderListModel remains unverified under QS 0.3; swapping later is
  contained to one Process block). Dirs passed as $1/$2, never
  interpolated.
- `core/Settings.qml` — `wallpapersPath`, `wallpapersThumbDir`,
  `wallpaperThumbSize` (120), `wallpaperGridColumns` (5),
  `wallpaperGridMaxRows` (3), `wallpaperTransitionType/Duration/Fps`
  (grow / 0.8 / 60).
- `widgets/TopBar/TopBar.qml` — instantiates it (second invisible
  centered anchor alongside Launcher's; they coexist fine).

**Known constraints / gotchas discovered:**

- hyprland.lua had NO awww-daemon autostart (the entire autostart
  section was commented out) — exactly the runtime bug the plan
  predicted. Autostart + bind lines in docs/INTEGRATION_NOTES.md.
- Session ended with THREE modules written offline and unrun — the
  live-test-first discipline for the next session was called out in
  the handoff, and held.


## 2026-07-04 — Bar restyle: floating inset bar, rounded corners, tray removed, popouts flush to the bar's ends

**Context:** Same-conversation follow-up to the launcher session below,
after the maintainer confirmed the launcher works live. Visual pass on
the bar plus one removal. ⚠ Written offline, not yet confirmed running.

**What was built / changed:**

- `themes/DefaultTheme.qml` / `core/Theme.qml` — new theme tokens
  `barMargin` (8) and `barRadius` (10). The bar now floats, inset from
  the screen's top/left/right edges, with rounded corners. Both tokens
  zero out cleanly to restore the old edge-to-edge square bar; nothing
  in the widgets requires them to be nonzero.
- `widgets/TopBar/TopBar.qml` — the PanelWindow is now transparent with
  the visible bar drawn as an inner rounded Rectangle (a window itself
  can't have rounded corners), inset via the window's `margins` block.
  Exclusive zone set explicitly to `barHeight + barMargin` rather than
  trusting auto-computation with margins in play. **System tray REMOVED
  from the bar** — `Tray {}`, its conditional Separator, and the
  Quickshell.Services.SystemTray import are gone from TopBar. Tray.qml
  and TrayItem.qml remain on disk, unreferenced; TopBar's header
  documents exactly what to re-add to bring the tray back.
- `widgets/TopBar/BarPopout.qml` — `flushToScreenEdge` RENAMED to
  `flushToBarEdge`. No behavior change: the anchor-rect extension was
  always relative to the bar's content margin, so with the bar now
  inset, the same math lands the popout flush at the bar's rounded end
  automatically. The rename just makes the property's name match what
  it actually guarantees. Callers updated: SystemMenu.qml, Clock.qml.
- Also this session: rechecked the 07-03 flush code the maintainer
  suspected they'd broken while pasting — it was intact and correct;
  no change needed.

**Explicitly NOT done yet:**

- The corner notch: a flush popout's squared top corner meets the bar's
  now-rounded bottom corner, leaving a small barRadius-sized sliver of
  wallpaper visible at the junction while that popout is open. Known,
  deliberately unaddressed pending the maintainer actually seeing it —
  cheap fixes are a smaller barRadius or stopping flush popouts just
  inside the curve; inverted-corner shapes (a curve cut INTO the
  popout to hug the bar's rounding) are the expensive fix.
- `Settings.barPosition` still unread; bar still hardcoded to top.

**Known constraints / gotchas discovered:**

- The stale-KB incident described in "Session workflow" above happened
  at the start of this work: the project copies of TopBar.qml and
  BarPopout.qml were the pre-launcher versions. The delivered files
  were rebuilt on top of the launcher-session versions instead.


## 2026-07-04 — App launcher: hotkeyed, centered popout, typo-tolerant search

**Context:** Replacing the previous `SUPER+R` app launcher — the last
piece of the old setup still running. Requirements: scrolls down out of the MIDDLE
of the bar, hotkeyable, shows nothing until typing starts, best-effort
typo tolerance without inventing anything nonstandard. **Confirmed
working live by the maintainer** ("works great") after the Lua bind fix
described below.

**What was built / changed:**

- `widgets/TopBar/Launcher.qml` — NEW. An invisible 1px-wide,
  bar-height anchor centered in the bar (1px, not zero — a zero-area
  anchor rect is degenerate under xdg-positioner rules); its BarPopout
  hangs centered below with the new "center" alignment. Apps come from
  Quickshell's built-in `DesktopEntries.applications.values` (`noDisplay`
  filtered). Empty query = empty results, by design. Ranked matcher:
  name-prefix (100) > word-prefix (90) > substring (80) > in-order
  subsequence (50, covers missed-key typos like "frfx") > bounded
  edit-distance-1 against the name's prefix (40, covers wrong-key and
  adjacent-swap typos, only for queries of 3+ chars). Ties alphabetical,
  results capped. Keyboard: Up/Down/Tab/Shift-Tab move selection, Enter
  launches, Escape closes; hover and keyboard share one selectedIndex.
  `Terminal=true` entries get wrapped in the configured terminal
  command; everything else goes through `entry.execute()`. Opened by
  Hyprland global shortcut (appid "shell", name "launcher") or IPC
  (`qs -c <config> ipc call launcher toggle`).
- `widgets/TopBar/BarPopout.qml` — new "center" alignment (a lone
  `Edges.Bottom` for both edges and gravity = attach bottom-center,
  grow straight down).
- `widgets/TopBar/TopBar.qml` — instantiates Launcher, centered.
- `core/Settings.qml` — added `launcherWidth` (480), `launcherMaxResults`
  (8), `launcherTerminalCommand` (`["kitty"]` — kitty runs a trailing
  command directly, no `-e` needed).

**The Hyprland Lua discovery (important machine context):**

- This machine's Hyprland config is **hyprland.lua, not hyprland.conf**
  — Hyprland deprecated hyprlang in favor of Lua config as of 0.55
  (April 2026). A copy of the lua config is now in project knowledge.
- The working bind for the launcher:
  `hl.bind(mainMod .. " + R", hl.dsp.global("shell:launcher"))` —
  `global` is a FUNCTION under the `hl.dsp` table returning a dispatcher
  closure, and its argument is one quoted "appid:name" string. The QML
  side (GlobalShortcut) is config-language-agnostic; only the bind
  syntax differs from the old `bind = SUPER, R, global, shell:launcher`.
- This retroactively explains the 2026-07-01 PROBLEMS_AND_FIXES.md entry
  where `Hyprland.dispatch("workspace 4")` failed through a "Lua shim" —
  Quickshell was sending old-style dispatch strings into a Lua-configured
  Hyprland. The abandoned click-to-switch-workspace feature is probably
  fixable now (Lua-form dispatch strings). ⚠ That PROBLEMS_AND_FIXES
  entry has NOT been updated with this resolution yet — worth doing
  next docs pass.

**Explicitly NOT done yet:**

- No frequency/recency ranking (no launch-count database) —
  deliberate scope cut.
- No multi-typo correction (edit distance > 1) — the "don't invent it"
  line; distance-1 covers common fat-fingers without false positives.
- Click-to-switch workspaces still removed (see Lua note above).


## 2026-07-03 

Wifi.qml bar display no longer shows the SSID — icon + signal % only; the popout already identifies the connected network.

BarPopout panel restyled to read as part of the bar: bar background color, bottom-only rounding, border removed. colorSurface retained in the theme for future non-bar popups.

## 2026-07-03 — The interactive bar: shared popout component, working audio/wifi/bluetooth controls, calendar, system tray

**Context:** "Complete the bar" session. A maintained upstream
Quickshell config was consulted at the time for feature scope and
verified API usage — NOT copied; every file below is this project's own
pattern and commenting style. (That external reference has since been
dropped from the project entirely — the project is self-contained now.)
Everything read-only in the bar became interactive, as menus that
scroll out of the bar. ⚠ Written offline against verified API
references — NOT yet run on the live machine. First-run bugs should be
expected and go in docs/PROBLEMS_AND_FIXES.md as found.

**What was built:**

- `widgets/TopBar/BarPopout.qml` — NEW. The dropdown-menu pattern
  (PopupWindow + reveal-clip animation + the open/visible manual sync
  that dodges the binding-destruction trap) extracted from SystemMenu
  into one reusable component, plus a new `alignment: "left"|"right"`
  property so right-side widgets open leftward into the screen. Every
  dropdown now declares one of these; the pattern has exactly one
  implementation to fix when it needs fixing.
- `widgets/TopBar/SystemMenu.qml` — refactored onto BarPopout. Same
  menu, ~100 lines of plumbing gone.
- `services/Audio.qml` — grew the control half: `sinks` (all PipeWire
  output devices, filter pattern verified against working upstream
  usage),
  `setSink()` (via `Pipewire.preferredDefaultAudioSink`),
  `incrementVolume()`/`decrementVolume()` (step from new
  `Settings.volumeStep`). PwObjectTracker now binds the whole sink list.
- `widgets/TopBar/Volume.qml` — interactive: scroll on the bar widget
  adjusts volume, middle-click mutes, left-click opens a popout with a
  hand-rolled themed slider, mute button, and output-device picker.
- `services/Network.qml` — grew the control half, driven by `nmcli` via
  Quickshell.Io Process (the standard approach in real-world configs):
  `setWifiEnabled()`, `rescan()`, `connectTo(ssid, password)` (tries the
  saved profile first, falls back to creating one), `forget()`, plus
  `connecting`/`lastError`/`pendingSsid` state for the UI. Also added
  `wifiNetworks` (visible networks, strongest first).
- `widgets/TopBar/Wifi.qml` — interactive: popout with wifi toggle,
  rescan, the network list (top 8 by signal), and a select-then-connect
  flow with an optional themed password field (empty = open network or
  saved profile). Failure text surfaces from the service.
- `widgets/TopBar/Bluetooth.qml` — interactive: popout with adapter
  toggle (`adapter.enabled`, verified writable) and paired-device list
  with click-to-connect/disconnect (`device.connected = !...`, verified
  against real-world use of the same Quickshell 0.3 module). Pairing
  NEW devices deliberately out of scope — see the file's DESIGN NOTES.
- `widgets/TopBar/Clock.qml` — left-click now opens a month calendar
  popout (QtQuick.Controls MonthGrid/DayOfWeekRow, themed delegates,
  prev/today/next, today highlighted). Resets to the current month on
  every open.
- `widgets/TopBar/Tray.qml` + `TrayItem.qml` — NEW system tray.
  Left-click activates, right-click opens the app's DBus menu via
  QsMenuAnchor (native-styled — the themed-menu upgrade path is
  documented in TrayItem's DESIGN NOTES). Collapses to zero width, with
  its separator, when no icons are registered.
- `core/Settings.qml` — added `volumeStep` (0.05).
- `widgets/TopBar/TopBar.qml` — Tray added to the right group.

**Explicitly NOT done (unchanged plans):**

- MPD — still deferred per the standing decision; NowPlaying untouched.
- Notification daemon, app launcher, wallpaper picker — still the next
  big modules on the replacement table; nothing removed from the live
  system yet.
- Mic/input device picker — Audio.qml documents where it goes when
  something needs it.
- Battery widget — desktop machine, no urgency.

**Known constraints / gotchas going in:**

- Nothing here has run yet. The nmcli command strings, the QsMenuAnchor
  tray menus, and the MonthGrid delegates are the three most likely
  first-run break points, in that order.
- Tray menus render in native platform style, not the theme — deliberate
  v1 tradeoff, documented in TrayItem.qml.


## 2026-07-02 — Fixed volume NaN, bluetooth count, layout tweaks; diagnosed wifi backend error

**Context:** First real run of the previous session's Volume/Wifi/Bluetooth
work, on the bottom bar (visible side-by-side with the setup it was
replacing — see the screenshot this session started from). Three things
were broken or wrong: volume showed "NaN%", wifi showed a startup
backend error and never connects, and bluetooth showed a
connected-device count of 5 with only a DualSense controller actually
connected. Also two cosmetic requests: value-before-icon ordering for
volume/wifi, and the filled/inverted bluetooth icon variant.

**What was fixed:**

- `services/Audio.qml` — rewrote `volume`/`muted` to use optional
  chaining with explicit fallbacks (`sink?.audio?.volume ?? 0`, matching
  the verified pattern used by a maintained real-world Quickshell
  config) instead of gating on a `sink.ready` check. That
  check was copied from a GitHub issue thread that turned out to be the
  bug report itself, not confirmed-good code — `sink.audio.volume` was
  coming back `undefined`, and `undefined * 100` is `NaN` in JS, which
  QML assigns into a `real` property with no error. Added a
  `Number.isFinite` guard as extra defense.
- `widgets/TopBar/Bluetooth.qml` — `connectedCount` now filters
  `Bluetooth.devices.values` on `.connected` explicitly rather than
  trusting Quickshell's own docs that the list is pre-filtered to
  connected devices only. Whatever the actual cause of the count being
  5 instead of 1, the filter makes the displayed number correct either
  way. Also switched the icon from U+F293 (nf-fa-bluetooth, outline) to
  U+F294 (nf-fa-bluetooth_b, filled/"inverted"), the maintainer's
  preferred variant.
- `widgets/TopBar/Volume.qml` / `widgets/TopBar/Wifi.qml` — reordered
  to value-then-icon (percentage/SSID first, glyph last), per
  maintainer preference. One-off change, not a new general ordering
  convention for the bar — Bluetooth stays icon-first.
- `services/Network.qml` — added `backendAvailable` (inferred from an
  empty `Networking.devices` list) so `Wifi.qml` can show "NetworkManager
  Off" instead of a generic "Disconnected" when the real problem is the
  backend never initializing, not ordinary connectivity loss.

**Diagnosed, not fixed in code (environment issue):**

- The `ERROR quickshell.network: Network will not work. Could not find
  an available backend.` startup error is expected behavior, not a bug —
  Quickshell's Networking module currently only supports the
  NetworkManager DBus backend, and per Quickshell's own module docs,
  both DBus and NetworkManager must be running for it to work at all. No
  other backend (e.g. IWD) has shipped as of 0.3.0. If NetworkManager
  isn't installed/running on this machine, that fully explains both the
  startup error and wifi never showing anything real. See
  `docs/PROBLEMS_AND_FIXES.md` for the fix (installing/enabling
  NetworkManager) — deliberately not applied automatically here since it
  changes what's managing the machine's networking, not just what the
  bar displays.

**Explicitly NOT done yet:**

- None of the three modules are clickable yet — still the plan from the
  previous session, one module at a time, once the display layer is
  fully confirmed working (which now depends on the NetworkManager
  question above for Wifi specifically).
- Haven't independently confirmed the Audio.qml fix resolves the NaN in
  practice (no live machine access this session) — flagged what to check
  if it doesn't (`wpctl status`, full `qs log` for pipewire-specific
  lines) in that file's DESIGN NOTES.
- Haven't confirmed whether `Bluetooth.devices` really does return
  unfiltered devices on this Quickshell build (doc vs. observed behavior
  mismatch) or whether something else caused the count of 5 — the
  `.connected` filter sidesteps needing to know which it was, but the
  underlying question is still open if it matters later.

**Known constraints / gotchas discovered:**

- Don't trust a snippet from a bug-report thread as a confirmed-good
  pattern just because it looks authoritative — the quickshell#54 issue
  whose code this project's original Audio.qml was based on was itself
  about pipewire property bugs; the `sink.ready` check in that snippet
  wasn't validated, it was part of what didn't work. Cross-check against
  an actual maintained shell's source when in doubt, not just the first
  plausible-looking example found.
- Quickshell's `Quickshell.Networking` module is backend-limited
  (NetworkManager-only) in a way that isn't obvious from the QML API
  surface alone — this only turned up by reading the module's own
  `module.md` source doc, not the per-type reference pages. Worth
  checking a module's top-level doc page, not just the types it exposes,
  when something that "should just work" doesn't.

---


## 2026-07-02 — Volume, Wifi, Bluetooth modules + clock formatting

**Context:** Bar only had SystemMenu/Workspaces/NowPlaying/Clock — no
volume, network, or bluetooth status yet. Built all three as read-only
display modules in one
pass; clickable interaction (mute toggle, wifi/bluetooth dropdowns,
volume slider) is deliberately deferred to future sessions, one module
at a time, once all three are confirmed showing correctly. Also fixed
two small clock formatting issues while in there.

**What was built:**

- `services/Audio.qml` — **new**, first real file in `services/`. A
  `pragma Singleton` wrapping PipeWire's default sink (`Quickshell.
  Services.Pipewire`), exposing `volume`/`muted` plus `setVolume()`/
  `toggleMute()`. Binds the sink via `PwObjectTracker` per the
  documented Quickshell requirement (untracked nodes read
  stale/undefined volume — quickshell-mirror/quickshell#54).
- `services/Network.qml` — **new**. A `pragma Singleton` wrapping
  `Quickshell.Networking`, exposing `wifiEnabled`, `wifiConnected`/
  `wifiSsid`/`wifiSignal`, and `wiredConnected` (tracked separately
  since this is a desktop, plausibly on ethernet day-to-day).
- `widgets/TopBar/Volume.qml` — **new**. Icon (Font Awesome
  volume_off/down/up, U+F026/F027/F028) + percentage, read-only.
- `widgets/TopBar/Wifi.qml` — **new**. Wired icon (U+EF09) when on
  ethernet, wifi icon (U+F1EB) + SSID + signal% when on wifi, dimmed
  "Disconnected"/"Wifi Off" text otherwise.
- `widgets/TopBar/Bluetooth.qml` — **new**. Bluetooth icon (U+F293) +
  connected-device count, dimmed when the adapter is off. Reads
  `Quickshell.Bluetooth` **directly** — no `services/Bluetooth.qml`
  wrapper (see below).
- `widgets/TopBar/TopBar.qml` — right side is now a `RowLayout`
  (`Volume` / `Separator` / `Wifi` / `Separator` / `Bluetooth` /
  `Separator` / `Clock`) instead of a lone right-anchored `Clock`.
- `core/Settings.qml` — `clockUse24Hour` default flipped `true` ->
  `false`. The 12-hour/AM-PM format string already existed in
  `Clock.qml` but was never the active default, so AM/PM never
  actually showed.
- `widgets/TopBar/Clock.qml` — date format `"ddd MMM d"` ->
  `"ddd, MMM d"` (comma after the weekday).

**Explicitly NOT done yet:**

- None of the three new modules are clickable — no mute toggle, no
  wifi network list, no bluetooth device list/pairing. Next sessions,
  one module at a time, using the SystemMenu dropdown pattern
  (`docs/ARCHITECTURE.md`) as the reference shape.
- No scroll-to-adjust volume, no OSD.
- `services/Network.qml`'s `wifiDevice`/`wiredDevice` pick the FIRST
  matching device — fine for this machine (one wifi adapter), would
  silently ignore additional adapters if that ever changes.

**Known constraints / gotchas discovered:**

- **`Quickshell.Networking` and `Quickshell.Bluetooth` are both
  first-party native modules as of 0.3** — `docs/services-README.md`'s
  original plan assumed hand-rolled D-Bus/NetworkManager/BlueZ
  integration would be needed for both. Verified against the current
  v0.3.0 type reference before writing any code. Same shape of mistake
  already caught once for Hyprland (see the 2026-07-01 Workspaces
  entry below) — worth internalizing as a pattern: check the
  `Quickshell.*` namespace before assuming a `services/` file needs to
  shell out or hand-roll a protocol.
- Because of the above, `services/Bluetooth.qml` was deliberately NOT
  created — `Bluetooth.qml` (the widget) reads `Quickshell.Bluetooth`
  directly, same call already made for Hyprland/Workspaces. Wrap it in
  a real service later only if bluetooth logic needs to be shared
  across more than one widget (e.g. a future pairing dropdown).
  `services/Network.qml` DID get built as a real wrapper, since it
  does genuine derived-data work (picking the right device, then the
  right network within it) that's worth centralizing before a future
  wifi dropdown needs the same logic — see that file's DESIGN NOTES.
- Font Awesome's volume glyph set only has three states (off/down/up,
  no "medium") and has no signal-strength-tiered wifi icons — both
  `Volume.qml` and `Wifi.qml` fall back to a number instead of a
  finer-grained icon for that reason.
- All new icon codepoints (volume x3, wired, wifi, bluetooth) were
  checked against the actual Nerd Fonts `glyphnames.json` before use,
  not recalled from memory — the PUA-guessing trap from the Arch icon
  precedent applies to every new glyph, not just the first one.

---


## 2026-07-01 — Reverted NowPlaying's hover tooltip

**Context:** Not wanted, after trying it. Click functionality (left
play-pause, middle previous, right next) stays as-is.

**What changed:**

- `widgets/TopBar/NowPlaying.qml` — hover tooltip and its supporting
  code (delay timer, position-tracking timer, fade popup) removed
  entirely.
- `themes/DefaultTheme.qml` / `core/Theme.qml` — `tooltipDelay` removed
  since nothing reads it anymore, rather than left as dead config.
- `docs/ARCHITECTURE.md` — tooltip-variant addendum to the "Dropdown
  menu pattern" section removed.

**Plan instead:** once MPD is wired up (separate future session), build
a proper click-driven controls popup (transport buttons, maybe a seek
bar) rather than tooltip-based metadata display. No point building
tooltip UI now and throwing it away then.

---

## 2026-07-01 — NowPlaying hover tooltip

**Context:** Follow-up on the researched-but-skipped list from
NowPlaying's initial build — implementing the hover tooltip specifically
(the other skipped items — scroll actions, per-player icons, marquee
text — stay skipped for now). MPD was also discussed as a bigger,
separate future project (no code today, see chat) — explicitly deferred
until after the current Quickshell setup is solid.

**What was built:**

- `widgets/TopBar/NowPlaying.qml` — hovering the now-playing text (after
  `Theme.tooltipDelay`, 500ms default) shows a small popup with the
  FULL (untruncated) title and artist, the album if the track has one,
  and a live position/duration readout while playing. Reuses the
  `PopupWindow`/`PopupAnchor` shell from the "Dropdown menu pattern,"
  but as a fade instead of a "scroll down" reveal, and without
  `grabFocus` — see the file's DESIGN NOTES and
  `docs/ARCHITECTURE.md`'s pattern section for exactly how and why it
  differs from SystemMenu's popup.
  - Position only ticks (via a manual `positionChanged()` call, per
    Quickshell's documented pattern for this) while the tooltip is
    actually visible AND something is playing — not continuously in the
    background.
- `themes/DefaultTheme.qml` / `core/Theme.qml` — added `tooltipDelay`
  (500ms), the shared hover-in delay for this and any future tooltip.

**Explicitly NOT done yet:**

- Scroll-to-seek, scroll-to-switch-player, per-player icons,
  marquee/scrolling text — still skipped, see NowPlaying.qml's DESIGN
  NOTES for the full researched list.
- MPD integration — confirmed feasible (see chat), deliberately deferred
  until the current Quickshell setup is further along.

**Known constraints / gotchas discovered:**

- Confirmed the tooltip variant of the popup pattern is genuinely
  simpler than the menu variant specifically BECAUSE it skips
  `grabFocus` — the "don't bind `visible` directly" trap from
  `docs/PROBLEMS_AND_FIXES.md` only applies when something external
  might also assign to that property. Worth remembering when deciding
  whether a given popup needs the careful manual-sync treatment or can
  just use a plain binding.

---

## 2026-07-01 — Workspace-end divider, NowPlaying (MPRIS) widget

**Context:** Two asks from a live visual pass on the bar: a single
divider after the workspace list (not between every number), and a
"now playing" MPRIS module — which, before building, meant researching
whether the more
ambitious ask (an MPD control popup, replacing the GUI player entirely)
was feasible. Answered separately in chat/`docs/PROBLEMS_AND_FIXES.md`
isn't the right place for that — no code resulted from it, just an
answer — but noting it here since it shaped what got built today: MPD
integration is a real, deeper, separate project (no built-in Quickshell
MPD support; would mean either raw-protocol talk over a Unix socket if
MPD's configured that way, or shelling out to `mpc`), scoped for later,
not folded into this session.

**What was built:**

- `widgets/TopBar/TopBar.qml` — added a single `Separator {}` right
  after `Workspaces {}` in the left `RowLayout` (not one between each
  workspace number — one marking the end of the list, matching the
  reference screenshot). Added `NowPlaying {}` after that.
- `widgets/TopBar/NowPlaying.qml` — new. Shows "Title — Artist" from
  the active MPRIS player via Quickshell's built-in
  `Quickshell.Services.Mpris` module (`Mpris.players`) — not PipeWire
  directly; PipeWire doesn't carry track metadata, MPRIS (a separate
  D-Bus interface) does. Same "check for a Quickshell built-in before
  writing a custom service" pattern as Workspaces/Clock — see
  `docs/PROBLEMS_AND_FIXES.md`.
  - **Ignore-list, not allow-list:** `Settings.nowPlayingIgnoredPlayers`
    (default `["firefox"]`) excludes browsers (any playing tab
    registers as an MPRIS player) while automatically picking up any
    other media app without needing the list updated.
  - **Active-player selection:** prefers whichever non-ignored player is
    actually `Playing`; falls back to the first non-ignored one found
    (e.g. paused) if none are; shows nothing if there are none.
  - **Click bindings:** left = play/pause, middle = previous, right =
    next — the maintainer's established muscle memory for this module.
  - **Truncation:** `Settings.nowPlayingMaxLength` (default 60) caps the
    displayed text with an ellipsis so one long tag can't stretch the
    bar indefinitely.
  - Collapses to zero width (not just invisible) when nothing qualifies,
    so the `RowLayout` closes up around it instead of leaving a gap.
- `core/Settings.qml` — added `nowPlayingIgnoredPlayers` and
  `nowPlayingMaxLength`.

**Explicitly NOT done yet (researched, deliberately skipped for scope —
see NowPlaying.qml's DESIGN NOTES):**

- Hover tooltip with fuller metadata (album, position/duration)
- Scroll-to-seek or scroll-to-switch-between-multiple-active-players
- Per-player icons, per-status icons beyond the single ▶/⏸ glyph
- Marquee/scrolling text for long titles (using truncation instead)
- MPD integration (see Context above — real, but a separate project)

**Known constraints / gotchas discovered:**

- Confirmed the "check Quickshell's built-ins first" lesson generalizes
  a third time: `Quickshell.Services.Mpris` already exists, same as
  `SystemClock` and `Quickshell.Hyprland` did for the previous two
  modules.
- MPRIS players expose a `dbusName` and a `desktopEntry`, neither of
  which is guaranteed to exactly equal an app's common name — matching
  against both (case-insensitive substring) is more robust than trusting
  either alone. Worth remembering if `nowPlayingIgnoredPlayers` ever
  needs a second entry and "firefox" doesn't match cleanly.

---

## 2026-07-01 — SystemMenu polish: sizing, icons, dividers, animated reveal, click-outside dismiss

**Context:** First-use feedback on SystemMenu after it landed: the popup
was too narrow (hardcoded 180px clipped "Restart Hyprland"), the options
had no icons or visual separation, opening just snapped into existence
instead of feeling like a dropdown, and clicking elsewhere on screen
didn't close it. All fixed, and the fixes are written to generalize to
Wifi/Bluetooth/Volume, not just patch SystemMenu specifically.

**What was built:**

- `widgets/TopBar/MenuButton.qml` — added an optional `icon` property
  (fixed-width column so rows stay aligned) and made `implicitWidth`
  content-driven instead of relying on a hardcoded popup width elsewhere.
- `widgets/TopBar/MenuDivider.qml` — new reusable horizontal line,
  the row-stacking counterpart to `Separator.qml`'s "|".
- `widgets/TopBar/SystemMenu.qml` — popup width/height now computed from
  `menuColumn`'s own implicit size (no more hardcoded 180px). Each
  option got an icon — standard Unicode symbols (⟳ / ↻ / ⏻), not Nerd
  Font PUA codepoints, since real assigned Unicode codepoints are a much
  safer bet for actually rendering. `MenuDivider` between each option.
  Added an animated "scroll down" open reveal via a clipping `Item` and
  a new `revealProgress` property. Added `grabFocus: true` so clicking
  elsewhere closes the menu — which required NOT binding `visible`
  directly to the open/closed state (see
  `docs/PROBLEMS_AND_FIXES.md` — binding it directly breaks permanently
  the first time an outside click dismisses the popup).
- `themes/DefaultTheme.qml` / `core/Theme.qml` — added
  `animationDuration` (180ms) and `animationEasing` (`Easing.OutCubic`),
  the shared timing for the reveal animation. Themable like everything
  else — a new theme file can make every dropdown menu's open animation
  faster/slower/different-feeling with one edit.
- `docs/ARCHITECTURE.md` — "Dropdown menu pattern" section rewritten
  with the sizing, animation, and dismiss-on-outside-click recipes
  spelled out, since Wifi/Bluetooth/Volume are meant to copy this shape.

**Explicitly NOT done yet:**

- Closing the menu doesn't animate (only opening does) — a deliberate,
  documented tradeoff of how `grabFocus` dismissal interacts with
  `visible`, not an oversight. See DESIGN NOTES in SystemMenu.qml.
- No confirmation dialog before Restart/Shut Down (carried over,
  unrelated to this pass).
- "Restart Hyprland" command still unverified (carried over).

**Known constraints / gotchas discovered:**

- Binding a `PopupWindow`'s `visible` directly to a widget's own
  open/closed property breaks permanently once `grabFocus` dismissal
  fires once (assigning a property removes its binding — standard QML,
  easy to forget in the moment). Fixed by syncing the two properties
  manually in both directions instead of a declarative binding. Worth
  remembering for every future dropdown menu, not just this one.
- Standard Unicode symbols (arrows, IEC power symbols) are a safer
  choice than Nerd Font PUA glyphs when a real Unicode codepoint exists
  for the concept — lower risk of an empty box, and doesn't depend on
  the Nerd Font patch specifically. Worth checking for a standard
  codepoint before reaching for a Nerd Font one going forward.

---

## 2026-07-01 — Arch icon power menu, workspace spacing, dropdown menu pattern established

**Context:** Third bar module, and the first one that isn't a passive
display — a click-to-open dropdown menu. Also addresses a visual nit
(workspace numbers too tightly packed) and
lays down a documented pattern for the Wifi/Bluetooth/Volume dropdowns
planned next.

**What was built:**

- `widgets/TopBar/SystemMenu.qml` — Arch Linux logo icon (Nerd Font
  glyph, U+F303 / `nf-linux-archlinux`, confirmed against a live
  reference before using it), leftmost in the bar. Click opens a
  dropdown with three options: Restart Hyprland, Restart, Shut Down.
  Restart/Shut Down run `systemctl reboot` / `systemctl poweroff` via
  `Quickshell.execDetached()`. **"Restart Hyprland" runs `hyprctl
  reload` as an unverified placeholder** — the actual Super+M keybind's
  command wasn't available to check against; flagged prominently in the
  file's DESIGN NOTES and needs confirming/correcting.
- `widgets/TopBar/MenuButton.qml` — reusable themed menu row (hover
  highlight, left-aligned label), used by SystemMenu's three options and
  intended for Wifi/Bluetooth/Volume's menus later.
- `widgets/TopBar/Workspaces.qml` — indicator spacing bumped from
  `Theme.spacingSmall` to `Theme.spacingLarge` (wider visual gap
  between workspace numbers).
- `widgets/TopBar/TopBar.qml` — SystemMenu and Workspaces are now
  grouped in one left-anchored `RowLayout` (icon, then workspace
  numbers, consistent gap) instead of Workspaces being anchored on its
  own with SystemMenu floating separately.
- `themes/DefaultTheme.qml` / `core/Theme.qml` — added `colorSurface`
  (popup background, a shade off `colorBackground`), `colorHover` (menu
  row hover highlight), and `radiusMedium` (corner radius for popups and
  menu buttons). First theme tokens added specifically for the dropdown
  menu pattern, not for a single one-off widget.
- `docs/ARCHITECTURE.md` — new "Dropdown menu pattern" section
  documenting the click-to-open + `PopupWindow`/`PopupAnchor` + themed
  `Rectangle` shape, as the reference for Wifi/Bluetooth/Volume.

**Explicitly NOT done yet:**

- No confirmation dialog before Restart/Shut Down — clicking either
  fires immediately. Worth adding if a misclick ever costs unsaved work;
  deliberately left out for now rather than adding unrequested friction.
- "Restart Hyprland" command is unverified — see the callout above.
- No bar on the second monitor still (unrelated, carried over from the
  Workspaces entry).
- Wifi/Bluetooth/Volume dropdowns don't exist yet — SystemMenu is the
  pattern reference for when they're built, not a stand-in for them.

**Known constraints / gotchas discovered:**

- `PopupWindow`'s `width`/`height` properties are deprecated in favor of
  `implicitWidth`/`implicitHeight` — using the deprecated ones logs a
  warning but still (currently) works; used the non-deprecated ones from
  the start here.
- `PopupAnchor.edges` (which point on the anchor item the popup attaches
  to) and `PopupAnchor.gravity` (which direction it expands from that
  point) are easy to conflate — both default to different corners
  (`Edges.Top | Edges.Left` and `Edges.Bottom | Edges.Right`
  respectively). Worth re-reading both docstrings carefully for any
  future popup, rather than assuming which one controls "which way does
  this menu open."

---

## 2026-07-01 — Separators, active-only workspaces, dropped click-to-switch, bigger text

**Context:** First real usability pass after seeing the bar running
live for the first time. Four related changes, all driven by direct
visual comparison against the setup it was replacing (a two-monitor
screenshot, not stored in the repo, was the basis for these changes).

**What was built:**

- `widgets/TopBar/Separator.qml` — new reusable "|" divider,
  separating every distinct piece of
  status info. Uses `Theme.colorMuted` so it visually recedes.
- `widgets/TopBar/Clock.qml` — restructured from one `Text` into a
  `RowLayout` of date / `Separator` / time, so the divider actually sits
  between them instead of a double-space.
- `widgets/TopBar/Workspaces.qml` — now shows only workspaces that
  currently exist (`Hyprland.workspaces.values`) instead of a fixed
  1..`workspaceCount` range with dimmed empty slots. With two monitors
  each showing one active workspace, this now correctly shows exactly
  "1 2" instead of "1 2 3 4 5" with three greyed-out placeholders.
- `widgets/TopBar/Workspaces.qml` — removed click-to-switch entirely
  (the `MouseArea` + `Hyprland.dispatch(...)` call). It only worked for
  the already-focused workspace; clicking any other one failed with a
  Hyprland IPC error (Lua dispatch syntax mismatch — full error text in
  `docs/PROBLEMS_AND_FIXES.md`). Workspace switching happens via
  Hyprland keybinds day-to-day, so this was dead weight, not a loss.
- `core/Settings.qml` — removed `workspaceCount` (nothing reads it
  anymore). Bumped `fontScale` from `1.0` to `1.4` — the bar's text
  read noticeably too small at 1.0.
- `themes/DefaultTheme.qml` / `core/Theme.qml` — `colorMuted` is now
  used by `Separator.qml` instead of the (now-removed) empty-workspace
  state it was originally added for. Same color, different consumer.

**Explicitly NOT done yet:**

- No separator between Workspaces and Clock themselves — they're still
  anchored to opposite corners of the bar with empty space between, not
  adjacent, so a divider there wouldn't read the same way it does
  between date/time. Revisit if the layout ever changes to cluster
  everything together (e.g. once Volume/Battery/Bluetooth exist and
  join Clock on the right).
- No bar on the second monitor yet — Workspaces already reflects
  multi-monitor state correctly (shows both monitors' active
  workspaces), but the bar itself is still single-monitor. Not being
  chased right now per direct instruction — noting it here so it isn't
  forgotten later.
- The underlying Hyprland dispatch error (Lua syntax mismatch) was
  never actually root-caused, just avoided by removing the feature that
  hit it. If click-to-switch is wanted again later, start there.

**Known constraints / gotchas discovered:**

- `Hyprland.workspaces.values` is reactive the same way
  `Hyprland.focusedWorkspace` is — binding a `Repeater`'s `model:`
  directly to it keeps the indicator list in sync as workspaces are
  created/destroyed, no manual refresh needed.

---

## 2026-07-01 — Second bar module: Workspaces

**Context:** First widget that needs live system data (which workspace
is focused/occupied/urgent) rather than just theme/settings values, so
also the first real test of the services-vs-widgets boundary described
in `docs/ARCHITECTURE.md`.

**What was built:**

- `widgets/TopBar/Workspaces.qml` — fixed row of numbered workspace
  indicators (1..`Settings.workspaceCount`), left-anchored. Click any
  number to switch to that workspace. Color state: focused (accent) >
  urgent (urgent color) > occupied (foreground) > empty (new
  `Theme.colorMuted`). Talks directly to Quickshell's built-in
  `Quickshell.Hyprland` module (`Hyprland.workspaces`,
  `Hyprland.focusedWorkspace`, `Hyprland.dispatch()`) — no custom
  service file. See `docs/PROBLEMS_AND_FIXES.md` for why.
- `core/Settings.qml` — added `workspaceCount` (default `5`).
- `themes/DefaultTheme.qml` / `core/Theme.qml` — added `colorMuted`
  (`#40474E`), forwarded the same way every other color is, for the
  empty-workspace state. First new color since the initial theme.
- `widgets/TopBar/TopBar.qml` — instantiates `Workspaces {}`,
  left-anchored, vertically centered, mirroring how `Clock` sits on the
  right.
- `services/README.md` — corrected the `Hyprland.qml` roadmap entry:
  it's not needed (yet), since `Quickshell.Hyprland` already provides
  what it would have wrapped. Left as a strikethrough note rather than
  deleted outright, so the reasoning stays visible instead of silently
  disappearing.

**Explicitly NOT done yet:**

- No workspace name labels (Hyprland supports named workspaces —
  `HyprlandWorkspace.name` — this only shows numeric IDs)
- No multi-monitor awareness — this shows one global set of workspace
  numbers, not per-monitor workspace state
- No drag-and-drop or scroll-to-switch, just click
- `Settings.workspaceCount` still has to be edited by hand, same
  limitation as every other setting so far

**Known constraints / gotchas discovered:**

- `HyprlandWorkspace.urgent` "becomes always falsed after the workspace
  is focused" per Quickshell's docs — so the focused/urgent color
  priority in `Workspaces.qml` is written defensively (focused checked
  first) but the two states shouldn't actually collide in practice.
- Confirmed the SystemClock lesson generalizes: check the `Quickshell.*`
  namespace for a purpose-built module before writing a custom
  `services/` file or shelling out to a CLI tool. Two out of two bar
  modules so far (Clock, Workspaces) turned out not to need one.

---

## 2026-07-01 — Font scaling + clock date/time order swap

**Context:** Two small follow-ups after the first Clock module landed:
whether font size should scale independently of theme, and a display
preference on the clock itself.

**What was built:**

- `core/Settings.qml` — added `fontScale` (default `1.0`), a multiplier
  applied on top of the active theme's base `fontSize`. Lives in
  Settings rather than Theme deliberately: text size preference should
  survive switching themes, not reset to whatever a given theme file
  happens to specify. See that file's DESIGN NOTES for the full
  reasoning.
- `core/Theme.qml` — `fontSize` is no longer a direct forward of
  `active.fontSize`. It's now `Math.round(active.fontSize *
  Settings.fontScale)`. Every widget still just reads `Theme.fontSize`
  as before — nothing outside these two files changed.
- `widgets/TopBar/Clock.qml` — flipped display order to date-then-time
  (`ddd MMM d  HH:mm` instead of `HH:mm  ddd MMM d`). Format strings
  themselves unchanged, just the concatenation order.

**Explicitly NOT done yet:**

- No in-shell way to change `fontScale` (or any setting) — still direct
  file edits only, same limitation as `clockUse24Hour`/`clockShowSeconds`.
- Only one theme exists, so "does fontScale survive a theme switch"
  hasn't actually been exercised yet, only designed for.

**Known constraints / gotchas discovered:**

- `Theme.qml` reads `Settings.fontScale` with no `import` statement —
  they're neighboring singletons in the same `core/` folder, and
  Quickshell auto-imports uppercase-named neighbors. Worth remembering
  as more cross-references show up between core/ files: same-folder
  singletons don't need `import qs.core` to see each other, only files
  *outside* `core/` do.

---

## 2026-07-01 — First bar module: Clock

**Context:** First real content in the bar — everything before this was
an empty themed panel. Also the first widget built entirely under the
post-rebuild conventions (singletons, `qs.*` imports), so it doubles as
a check that those conventions actually work end to end for something
real, not just the empty-bar milestone.

**What was built:**

- `widgets/TopBar/Clock.qml` — shows the current time and a short date
  (e.g. `14:07  Wed Jul 1`). Uses Quickshell's built-in `SystemClock`
  type rather than shelling out to the `date` command on a repeating
  `Timer` (the approach shown in Quickshell's own introductory tutorial,
  which itself moves past that approach — see
  `docs/PROBLEMS_AND_FIXES.md`). Reads `Theme` for styling and
  `Settings` for format, both via `import qs.core` — no properties
  passed in from `TopBar.qml`.
- `core/Settings.qml` — added `clockUse24Hour` (default `true`) and
  `clockShowSeconds` (default `false`). First properties in this file
  that anything actually reads.
- `widgets/TopBar/TopBar.qml` — instantiates `Clock {}`, right-anchored
  and vertically centered. No import needed for `Clock` since it's a
  neighboring file in the same folder.

**Explicitly NOT done yet:**

- Clock is not clickable (no calendar popup, no click-to-copy, etc.)
- `Settings.clockUse24Hour` / `clockShowSeconds` have to be edited by
  hand in `core/Settings.qml` — no in-shell settings UI exists yet for
  any setting, this or otherwise
- Timezone is whatever the system clock reports; no multi-timezone
  support

**Known constraints / gotchas discovered:**

- `SystemClock.precision` controls how often `date` actually updates,
  not just how the string is formatted — binding it to
  `Settings.clockShowSeconds` means toggling that setting also changes
  how much work Quickshell does per minute, not just what's on screen.
  Worth remembering when adding other time-driven widgets later (e.g. an
  idle timer) — reuse `SystemClock`'s `precision` control rather than
  polling more often than the display actually needs.

---

## 2026-07-01 — Structural rebuild: singletons, real ShellRoot, module imports, version correction

**Context:** A review of how the wider Quickshell community structures
configs turned up several places where this project's original design
(from earlier the same day) diverged from documented, idiomatic
Quickshell usage — not broken, but working against the grain in ways
likely to cause bugs or confusion later. Rebuilt from scratch rather than
patched in place, since the changes touch the core wiring pattern that
everything else depends on.

**What changed:**

- **Theme/Settings/Globals/Signals are now `pragma Singleton` types**
  instead of instances created once and manually passed down as
  `theme:`/`settings:` properties to every widget. Any file now reaches
  them via `import qs.core` and reads them directly (`Theme.colorBackground`,
  `Settings.barPosition`, etc). The old pattern was avoided originally
  due to a mistaken belief that singletons required extra qmldir setup —
  they don't, for local files in your own shell directory. See
  `docs/PROBLEMS_AND_FIXES.md`.
- **Fixed a `ShellRoot` naming collision.** Quickshell ships a real,
  built-in `ShellRoot` type meant to be the literal root object of
  `shell.qml`. The original `core/ShellRoot.qml` defined a project
  component *also* named `ShellRoot` (a plain `Item`), which shadowed the
  real type when imported — meaning `shell.qml` was never actually
  instantiating Quickshell's real root element, just a look-alike. Fixed
  by renaming the project file to `core/Shell.qml` (root type changed
  from `Item` to `Scope`, Quickshell's non-visual grouping element) and
  making `shell.qml`'s literal root object Quickshell's actual
  `ShellRoot`.
- **Switched all cross-folder imports to module-style** (`import
  qs.core`, `import qs.themes`, `import qs.widgets.TopBar`) instead of
  relative paths (`import "../themes"`, `import "core"`). Quickshell's
  own docs note module imports are more LSP-friendly, and relative-path
  imports are one of the things that can interact badly with singletons.
- **Corrected a version error.** Earlier notes referred to "Quickshell
  3.0" — this doesn't exist. Quickshell's actual versioning is 0.x; the
  current release as of this rebuild is 0.3.0 (2026-05-04). All
  references updated.

**Files touched:**

- `shell.qml` — root object is now Quickshell's real `ShellRoot`; loads
  `core/Shell.qml` via `import qs.core`.
- `core/ShellRoot.qml` → renamed to `core/Shell.qml`. No longer creates
  or wires Theme/Settings/Globals instances.
- `core/Theme.qml`, `core/Settings.qml`, `core/Globals.qml`,
  `core/Signals.qml` — all converted to `pragma Singleton`.
- `themes/DefaultTheme.qml` — no value changes, header updated for the
  new import path.
- `widgets/TopBar/TopBar.qml` — removed `property var theme` / `property
  var settings`; now reaches `Theme`/`Settings` via `import qs.core`.
- `docs/ARCHITECTURE.md` — theme pattern section, folder tree, and
  checklist rewritten to match.

**Explicitly NOT done yet (unchanged from before the rebuild — do not
assume these exist):**

- No Hyprland workspace/window integration (`services/Hyprland.qml`
  doesn't exist yet, despite the folder being reserved for it)
- No clock, no volume, no battery, no network, no bluetooth, no tray
- No notification daemon (the previous daemon is still running;
  nothing here has claimed `org.freedesktop.Notifications`)
- No app launcher (the previous launcher is still handling `SUPER+R`)
- No logout menu (the previous tool is still handling that)
- No wallpaper picker (the previous script-based picker is still
  active and untouched)
- `Settings.barPosition` is declared but still not actually read by
  `TopBar.qml` — the bar is hardcoded to the top edge regardless of that
  value. (This survived the rebuild unchanged — it was never wired up,
  singletons don't change that.)

**Known constraints / gotchas discovered during this rebuild:**

- Singletons are instantiated lazily, on first property access — not
  necessarily the moment the shell starts. If a future `services/` file
  needs to be "alive" from launch (e.g. running a background `Process`
  immediately) rather than only once a widget reads from it, something
  needs to deliberately touch one of its properties early to force
  instantiation. This wasn't a concern under the old manual-instantiation
  pattern.
- Quickshell's `qs.<path>` module import syntax resolves relative to the
  folder containing `shell.qml` — same root every file uses, regardless
  of where the importing file itself lives.

---

## 2026-07-01 — Project start

**Context:** Building a full Quickshell desktop shell from scratch on a
fresh Arch/Hyprland install, replacing an assortment of separate tools
(bar, launcher, wallpaper picker, logout menu, notification daemon) —
each of which stayed live on the machine until its Quickshell
replacement was confirmed working (the "standing migration rule"
referenced in later entries). The full pre-Quickshell history lives in
a prior chat conversation, not in this repo; the `#64727D` / `#5294e2`
color choices below carried over from that setup for visual continuity
during the transition.

**What was built:**

- Directory structure established:
  ```
  quickshell/
  ├── shell.qml
  ├── core/          (ShellRoot, Theme, Settings, Globals, Signals)
  ├── services/       (empty — reserved for D-Bus/system integrations)
  ├── widgets/
  │   └── TopBar/    (the only widget that exists so far)
  ├── themes/        (DefaultTheme.qml)
  ├── assets/        (empty — reserved for icons/images)
  ├── docs/          (this file, PROBLEMS_AND_FIXES.md, ARCHITECTURE.md)
  ├── notes/         (empty — scratch space, not part of the shipped shell)
  └── testing/       (empty — reserved for standalone test .qml files)
  ```

- `shell.qml` — minimal entry point, loads `ShellRoot`.
- `core/ShellRoot.qml` — creates one shared `Theme`, `Settings`, `Globals`
  instance and instantiates `TopBar`, passing theme/settings into it.
  **Superseded same-day — see the entry above.** This turned out to
  shadow Quickshell's own built-in `ShellRoot` type; the file was renamed
  to `core/Shell.qml` and the manual instance-passing was replaced with
  singletons.
- `core/Theme.qml` — the property interface widgets bind to
  (`theme.colorBackground`, etc). Deliberately does NOT contain actual
  color values — those live in `themes/DefaultTheme.qml`. See that file's
  header for why they're split. **Converted to a singleton same-day —
  see the entry above.**
- `core/Settings.qml` — user-configurable behavior (currently just
  `barPosition`, not yet wired up to actually do anything). **Converted
  to a singleton same-day.**
- `core/Globals.qml` — placeholder for shared runtime state (battery %,
  volume, etc). Empty for now — nothing populates it until `services/`
  files exist. **Converted to a singleton same-day.**
- `core/Signals.qml` — placeholder signal bus. **Not wired into
  ShellRoot** as of this entry — exists to reserve the pattern, not
  because anything uses it yet. **Converted to a singleton same-day**,
  which also means the original "step 1: add Signals{id:signals} to
  ShellRoot" activation instructions no longer apply.
- `themes/DefaultTheme.qml` — first theme. Grey background (`#64727D`),
  black foreground, blue accent (`#5294e2`), red urgent (`#f53c3c`).
  These three colors carried over from the desktop's existing scheme
  at the time, for visual continuity during the transition.
- `widgets/TopBar/TopBar.qml` — renders an empty, themed bar anchored to
  the top of the screen. No modules inside it yet (no clock, no
  workspaces). This was the first working milestone: confirm Quickshell
  renders correctly, end to end, before adding real content.

**Explicitly NOT done yet (do not assume these exist):**

- No Hyprland workspace/window integration (`services/Hyprland.qml`
  doesn't exist yet, despite the folder being reserved for it)
- No clock, no volume, no battery, no network, no bluetooth, no tray
- No notification daemon (the previous daemon is still running;
  nothing here has claimed `org.freedesktop.Notifications`)
- No app launcher (the previous launcher is still handling `SUPER+R`)
- No logout menu (the previous tool is still handling that)
- No wallpaper picker (the previous script-based picker is still
  active and untouched)
- `Settings.barPosition` is declared but not actually read by `TopBar.qml`
  yet — the bar is hardcoded to the top edge regardless of that value.

**Known constraints carried over from the old setup** (worth knowing
before rebuilding these as Quickshell modules — see the prior
conversation for the full debugging story on each):

- Wifi interface name is `wlan0`-shaped but not guaranteed — a prior
  script hardcoded it and that eventually caused churn (home PC, wifi
  network never changes, issues handled via terminal). If a Quickshell
  network module gets built later, don't assume `wlan0` — check first.
- Bluetooth: earlier menu attempts felt "janky" mainly because they
  had no live-refresh — the menu had to be closed and reopened to see
  updated scan results. This is a real Quickshell advantage worth
  using: a proper D-Bus-backed bluetooth module can listen for bluez
  signals and update live.
- The previous notification setup hardcoded its output to monitor 2 —
  when a Quickshell notification module gets built, decide
  deliberately whether to hardcode a monitor number again or make it
  configurable via `core/Settings.qml`.

---

## 2026-07-16 — Desktop clock center offsets + display controls (GPT-5.6 Thinking)

**Context:** Center-position X/Y offsets were ignored, and the desktop clock needed independent weather-icon/temperature visibility plus whole-widget scaling.

**What changed:**

- Centered placement now adds configured X/Y offsets and clamps the result to monitor bounds.
- Added persisted weather-icon, temperature, and 0.50x–2.50x overall-scale preferences.
- Added matching controls to the split Desktop Settings page.
- Time, date, weather icon, temperature, and spacing scale together.

<!--
  TEMPLATE FOR NEW ENTRIES — copy this below the line above when adding
  a new entry. Keep entries in reverse-chronological order (newest at
  the TOP, right after this comment block, above the 2026-07-01 entries.

## YYYY-MM-DD — Short title (model that wrote it, e.g. Fable 5)

**Context:** Why this work happened.

**What was built / changed:**

- ...

**Explicitly NOT done yet:**

- ...

**Known constraints / gotchas discovered:**

- ...
-->

## Desktop Clock Shadow Offset Rev 1 — 2026-07-16
- Added independent X/Y shadow offsets for desktop clock time, date, and temperature.
- Replaced fixed `Text.Raised` rendering with explicit shadow layers so offsets are controllable.
- Preserved the approved look with default offsets of 2px / 2px.
