# SONNET QUEUE — build plans for the Sonnet 5 era

Written 2026-07-09 by Fable 5, per the model-assigned roadmap in
docs/PROJECT_VISION.md. Each item below is a pre-made plan: decisions
locked, traps listed, APIs verified. Sonnet sessions: read
docs/AI-MAINTENANCE-GUIDE.md first (binding), build ONE item per
session, sign changelog entries "(Sonnet 5)", snapshot before config
changes, and if a plan contradicts what you find on disk — STOP and
flag it to the maintainer; do not improvise around it.

Established recipes referenced throughout: PowerScreen.qml (top-level
Overlay window: focus grab, Escape, reveal), SettingsWindow.qml
(pages, StepperRow/ToggleSettingRow, staged→Apply), BarPopout.qml
(bar dropdowns), ConfigManager.applyChanges (transaction), the
per-page token migration rule (notes/settings-manager-plan.md).

---

## Q1. Keybind cheat-sheet overlay  [API PRE-VERIFIED — recipe work now]

A fullscreen Overlay card (PowerScreen recipe exactly) listing every
live keybind. Toggle via GlobalShortcut appid "shell" name "binds"
(suggest SUPER+F1 in user/keybinds.lua) + IPC target `binds`.

- Data: Process → `hyprctl binds -j` on open. Output is a JSON array;
  fields (verified 2026-07-09 against Hyprland source bindings):
  `modmask` (int), `key`, `keycode`, `dispatcher`, `arg`,
  `description`, `has_description`, `submap`, `locked`, `mouse`,
  `repeat`, `release`, `catch_all`.
- Modmask decode (X11 bits): SHIFT=1, CAPS=2, CTRL=4, ALT=8,
  Mod2=16, Mod3=32, SUPER=64, Mod5=128. Verified: SUPER+SHIFT = 65.
  Helper: build "SUPER + SHIFT + E" strings from the bits.
- ⚠ Parse defensively: `hyprctl -j` has HISTORICALLY prefixed stray
  non-JSON lines in some versions — take stdout, find the first
  `[`, JSON.parse from there, and on parse failure show "couldn't
  read binds" rather than crashing.
- Display: two-column grid of "keys — action" rows; action =
  description if has_description, else dispatcher + (arg ? ": "+arg
  : ""); skip mouse binds and empty-submap noise as taste dictates.
  Refresh on every open (binds can change at runtime).
- NEVER read user/keybinds.lua for this — runtime query only (the
  never-parse-user-files rule).

## Q2. Snapshot/Restore UI page ("Backups", 4th settings page)

- List: call ConfigManager.list() in onCurrentPageChanged (async —
  bind rows to ConfigManager.snapshots; it may populate a beat
  later, that's fine). One row per snapshot: name + a Restore
  button.
- Restore is LIVE, not staged — it IS the undo mechanism; do not
  wrap it in the Apply transaction. Guard with arm-then-fire: first
  click turns the button into "Click again to restore" (colorUrgent),
  second click within ~3s fires ConfigManager.restoreSnapshot(name);
  a Timer disarms.
- "Take Snapshot" button → createSnapshot("from settings", "manual").
  No text input (no text-field pattern exists outside Launcher;
  don't invent one for this).
- ⚠ The Original Backup gets an INFO ROW ONLY (date + "see
  docs/BACKUPS.md to restore manually"). Do NOT build one-click
  Original restore: it would copy whole config dirs over the RUNNING
  shell's own QML files — undefined behavior, deliberately excluded.
  This is a designed exclusion, not an oversight.
- No delete-snapshot UI in v1 (terminal `rm -rf` documented in
  BACKUPS.md is fine). Say so in the page footer text.

## Q3. Power screen v2 — Lock / Suspend

- Add to PowerScreen's row: Lock → `loginctl lock-session` fallback
  `hyprlock` (Process; check `command -v hyprlock` result and hide
  the button if absent — same graceful-degradation as icons), and
  Suspend → `systemctl suspend`.
- HIBERNATE IS EXCLUDED unless the maintainer confirms swap is
  configured for it — ask, don't assume.
- Icons: extend the assets/icons/power/ set (lock-black/white,
  suspend-black/white) with the same status-based hide; note the
  set is still unsourced anyway.
- Card may need width for 5 buttons — cardScale stays; adjust
  spacing/layout, not the scale knob.

## Q4. Notification history — bell widget + popout

The state layer services/Notifs.qml was PRE-DESIGNED for (see its
DESIGN NOTES): per-notification QtObject copies with a popup flag.

- Notifs.qml grows: `history` ListModel (or var array + signal),
  appended on every received notification with {appName, summary,
  body, image/appIcon resolution, timeMs: Date.now()}; capped at
  Settings.notifHistoryMax (new token, 50). Existing popup flow
  UNTOUCHED — history is an append-only mirror, dismissing a popup
  does not remove history.
- Bar widget: bell glyph + count of items since last opened; opens a
  BarPopout listing newest-first rows (icon, summary, relative time
  via a coarse "Xm ago" from timeMs), "Clear All" MenuButton at
  bottom.
- ⚠ Trap: do NOT hold references to the live Notification objects in
  history (they're invalidated on dismiss/expiry) — copy the fields.
  That's the entire reason the NotifData-copy design exists.

## Q5. Notifications page additions (timeout / max visible / position later)

- Migrate `notifDefaultTimeout` and `notifMaxVisible` from
  Settings.qml → UserPrefs (per-page rule: the page takes ownership;
  REMOVE from Settings + grep consumers — the silent-undefined trap
  has shipped twice, see AI-MAINTENANCE-GUIDE).
- Steppers: Timeout (1–30 s, store ms ×1000, display seconds), Max
  Visible (1–10). ConfigManager switch cases + staged plumbing per
  the existing pattern.
- Position (corner selection) is EXCLUDED for now — the popup window
  geometry is anchored top-right in code; making it corner-agnostic
  is a Fable-return item.

## Q6. Launcher settings page

- Migrate `launcherWidth` and `launcherMaxResults` → UserPrefs;
  steppers (width 400–900 step 50; results 4–12). Terminal command
  stays a Settings.qml hand-edit token (needs text input — excluded).

## Q7. Audio settings page

- ONLY: volume scroll step (new UserPrefs token, default matching
  Volume.qml's current hardcoded step — read the file) and OSD
  duration (migrate the Settings OSD timeout token). Sink switching
  STAYS in the bar popout — transient/durable split; do not
  duplicate it in the window.

## Q8. Animations toggle (small)

- Add `hyprAnimationsEnabled` (bool, default true) → UserPrefs +
  ConfigManager case + a ToggleSettingRow on the Hyprland page; the
  hyprGenScript template gains `animations = { enabled = $anim },`
  inside hl.config. ⚠ Requires removing `animations { enabled }`
  from user/look.lua (ownership transfer of ONE key) — maintainer
  does that edit by hand, per the rules; the plan is to ASK first.
  Full animation/curve editing is PARKED for Fable.

## Q9. More themes

Recipe in docs/ARCHITECTURE.md ("Adding a new theme"): copy a
themes/ file, change values, one child instance + one map line in
core/Theme.qml. Appears in the picker automatically. Zero risk.

---

## Parked for Fable's return (do NOT attempt)

- Displays page / monitors generation (needs the apply-with-
  revert-timer pattern — designed but unbuilt; black-screen risk)
- Notification position/corner support
- Full animations/curves editing (ownership migration design)
- Workspaces click-to-switch investigation (Lua dispatch strings)
- Wallpaper-driven color scheme
- Anything requiring a NEW pattern rather than an existing recipe —
  if an item turns out to need one mid-build, stop, document where
  you stopped, and leave it for review.
