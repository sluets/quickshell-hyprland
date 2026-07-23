# Settings app / ConfigManager — v1 plan (written 2026-07-09, not yet built)

Scratch notes for a FUTURE session, written by Claude (Fable 5) for
Claude, at the maintainer's request — same purpose as the (since
deleted) wallpaper-picker plan that preceded that build. This is a
rewrite of the maintainer's own design document, keeping its philosophy
intact and revising the technology and scope decisions per a review
discussed and accepted in the same session this was written. Nothing
here is code yet. Lives in `notes/` — read it, resolve the "Ask at
session start" items, then build **Phase 1 only**.

> **STATUS 2026-07-09 (Fable 5): Phase 1 is BUILT (offline) — see
> services/ConfigManager.qml and shell.qml's `config` IpcHandler. The
> six sh scripts were extracted and tested against a sandbox tree
> (all success criteria passed: original-backup idempotency,
> snapshot, mangle→restore byte-identical, daily dedupe, prune
> retention with manual survival). The QML wiring is NOT yet run
> live — do that before starting Phase 2. Live test procedure: the
> IPC comments in shell.qml, plus success criteria below.**

> **STATUS UPDATE, later 2026-07-09 (Fable 5): Phase 1 LIVE-CONFIRMED
> (all success criteria green — see REVISION_HISTORY). Phase 2 then
> BUILT same session (offline, live test pending):
> widgets/Settings/SettingsWindow.qml (Appearance page, staged
> changes, pending-diff panel, Apply/Cancel), the rebuilt
> core/Theme.qml themes map (the 07-05 deferred item — retried with a
> different pattern), fontScale migrated Settings→UserPrefs, and
> ConfigManager.applyChanges (auto snapshot → writes). Open questions
> RESOLVED as the leans: in-process window, one JSON file
> (user-prefs.json IS the settings store), themeName = type name
> (legacy "Honeycomb" falls back + self-corrects on first Apply).
> hyprland.lua is now in the KB — Q4 satisfied, Phase 3 designable.
> PHASE 2 LIVE-CONFIRMED same day: theme switching + Apply/restore
> loop working on the machine. LATER same day: the Notifications
> settings page (a Phase-5 category, pulled forward per the
> maintainer's THOUGHTS.txt wishlist — the plan explicitly allows
> category order to follow maintainer demand), page tabs in the
> window, and daily-snapshot-on-open wired. Next session starts at
> Phase 3 — which is BLOCKED AGAIN on hyprland.lua: it fell out of
> the KB in the re-sync (external files don't survive
> flatten-and-replace). Permanent fix documented in the README: keep
> a copy at notes/hyprland.lua inside the repo.**

> **PHASE 3 BUILT (offline), later 2026-07-09 (Fable 5):** hyprland.lua
> re-synced AND banked at notes/hyprland.lua. The real config split
> byte-faithfully into notes/hypr-restructure/ (requires-only root,
> generated/appearance+monitors, user/look+startup+rules+keybinds);
> by-hand migration procedure at docs/HYPR_RESTRUCTURE.md; Lua
> generation chained into the Apply transaction (fixed-shape template,
> graceful skip pre-restructure); Hyprland settings page (gaps in/out,
> border, rounding — defaults match the live config exactly). Two
> live-config findings fixed in the split: shell:power had NO keybind
> (now SUPER+Escape), SUPER+M's fallback dispatch was a no-op.
> Remaining: maintainer runs the restructure and live-confirms.
> ALSO: docs/PROJECT_VISION.md and docs/AI-MAINTENANCE-GUIDE.md now
> exist — the project's aim is public release as an AI-maintainable
> Hyprland DE; this plan is a component of that larger vision.**

The maintainer's original design doc covered the full long-term vision
(every settings category, setup wizard, DBus service, plugin system).
That vision is preserved below as the long-term map — but v1 is
deliberately much smaller, and the build order matters more than the
feature list.

---

## Philosophy (unchanged from the maintainer's doc — this part is right)

- **The shell reads configuration. The Settings application writes
  configuration.** The settings app is not part of the shell; its sole
  responsibility is safely managing the desktop's configuration.
- **One source of truth** for any given setting. Never two files that
  can disagree (this project has already been bitten by exactly that —
  see PROBLEMS_AND_FIXES 2026-07-05, the thumbnail-dir mismatch).
- **Generated vs user-owned, clearly split.** The manager only ever
  writes files it fully owns and controls the format of. It NEVER
  parses or rewrites hand-written config.
- **Every change is previewable, reversible, validated, recoverable.**
  Snapshot before write, health-check after, auto-restore on failure.
- **Guiding principle: the desktop should be impossible to
  accidentally break through the Settings application.** This is the
  institutionalized version of a lesson this project learned the hard
  way — the 2026-07-05 settings-menu attempt regressed core/Theme.qml
  with no snapshot and no rollback, cost 1.5 hours, and the root cause
  was never found. The transaction system exists so that failure mode
  is structurally impossible, not just avoided by care.

---

## Decisions LOCKED for v1 (changes from the original doc, with reasons)

### 1. ConfigManager is a QML singleton, not C++

The original doc specified a C++ backend. Rejected for v1:

- Everything v1 needs — read/write JSON, copy directories, run
  `hyprctl`/`luac`, generate a Lua file from string templates — is
  already done in this project in QML with debugged, documented
  patterns. `core/UserPrefs.qml` is a working miniature of the whole
  architecture (FileView + JsonAdapter + mkdir-on-first-run +
  single-mutation-path setters).
- C++ means cmake/ninja, a compile step, and a second language in a
  project whose stated identity (root README, "Why this exists") is
  that every line is readable and fixable by the maintainer.
- The doc's own justifications for C++ (DBus service, plugin system)
  are listed as FUTURE additions. Don't scaffold for them.

**When C++ earns its place later:** a real `qs-configd` DBus service,
a CLI that must work while the shell is dead, or measured performance
problems. By then the API surface will be proven in QML and porting is
a translation job, not a design job.

**Structural rule that keeps the door open:** ConfigManager is
UI-agnostic. No settings page ever touches a file or runs a command —
pages call ConfigManager functions only (`setThemeName()`,
`createSnapshot()`, `applyPending()`, ...). Same API shape as the
original doc, different implementation language.

### 2. "Validation" is a health check, not semantic verification

The original doc's transaction step "validate configuration" was the
hand-waviest box in its diagram. What's actually implementable:

- **JSON side:** parse-check + range/type sanity on known keys. Easy.
- **Lua side (pre-write, optional):** `luac -p` syntax check IF luac
  is installed (verify at session start; don't hard-depend on it).
- **Post-apply health check (the real safety):** Hyprland still
  answering (`hyprctl version` exits 0)? `qs` process still alive?
  If yes → commit. If no → restore the snapshot taken at step 1.

Do NOT attempt semantic validation ("does this monitor mode exist") —
that's a research project. Snapshot + health check + instant rollback
delivers the actual guarantee ("never left broken") without pretending
to verify things that can't be verified short of trying them.

**Hyprland already provides half this safety net** (verified,
docs/HYPRLAND_INFO.md 2026-07-06): the Lua config auto-reloads on
save, a syntax error makes Hyprland REFUSE the reload and keep running
the last good config (with an error popup), a runtime error in one
`require()`d file kills only that file, and SUPER+Q/R/M emergency
binds survive even a badly broken config. So a syntactically broken
generated module can't take the session down — the transaction
system's rollback mainly protects against *semantically* wrong-but-
valid config (bad monitor mode, unreadable colors) and against
breaking the SHELL's own JSON.

### 3. Tokens migrate to JSON per-page, not big-bang

The original doc implies all user-editable settings move to JSON. The
end state is right; the migration path is the risk. `core/Settings.qml`
holds 40+ tokens as QML literals, and converting the theme/settings
layer wholesale is the exact class of change that caused the 07-05
Theme.qml regression.

**Rule: a token moves from Settings.qml to ConfigManager's JSON only
when a settings page takes ownership of it.** Settings.qml remains the
permanent home of anything with no UI (it's documented as
hand-edit-the-file knobs — that stays true for the long tail). Each
migration is one page's worth, individually testable, individually
snapshottable.

### 4. v1 scope: three things, in order

1. **The snapshot/restore engine** — built and trusted FIRST, before
   anything writes a config. Includes the one-time Original Backup.
2. **The Appearance page** — because building it IS the fix for the
   standing deferred item (the dead theme picker / Theme.qml `themes`
   map, PROBLEMS_AND_FIXES 2026-07-05). Two birds.
3. **The transaction loop + preview-diff-before-Apply screen** — cheap
   once all changes flow through one API, and it's the UX heart of the
   original doc. Keep it.

Everything else in the original doc's category list is the long-term
map (preserved below), built one category per session, same as the bar
was.

### 5. Cut from v1 entirely

- **Setup wizard / software detection** — one known machine, Quickshell
  only (maintainer's own annotation on the original doc). The Original
  Backup concept survives; it's created on the snapshot engine's first
  run instead of by a wizard.
- **DBus service, plugin system** — future, per the doc itself.
- **Wallpaper settings** — the picker already owns this (maintainer's
  annotation: "we have a wallpaper changer for this already, ignore").
- **Wi-Fi/Bluetooth pages** — the bar popouts already own everything
  TRANSIENT (connect, toggle, scan). The maintainer's annotation
  ("maybe we split this into menus and settings") resolves to: the
  settings app only ever gets what's DURABLE (e.g. "auto-connect
  behavior", if anything). On a single-user desktop that never roams,
  these categories may legitimately earn zero pages. Decide when
  reached, not now.

---

## Architecture (revised)

```
        Settings UI (QML pages)
                 │  function calls only — pages never touch files
                 ▼
        ConfigManager (QML singleton, UI-agnostic)
                 │
    ┌────────────┼────────────────┬──────────────────┐
    ▼            ▼                ▼                  ▼
settings.json  generated Lua   snapshots         commands
(FileView +    (~/.config/     (~/.local/state/  hyprctl / luac -p /
 JsonAdapter)   hypr/generated) qs-settings/)     systemctl / cp -r
    │            │
    ▼            ▼
 Quickshell    Hyprland (auto-reloads on save;
 (live reload   rejects broken syntax itself)
  via FileView
  watchChanges)
```

### The transaction (every Apply)

```
1. createSnapshot("auto: before <summary>")
2. write settings.json (and/or regenerate the relevant generated/*.lua)
3. [if Lua changed and luac available] luac -p each generated file
4. save — Hyprland auto-reloads on its own; shell picks up JSON via
   FileView watch
5. health check: hyprctl version exit 0? qs alive?
6. pass → commit (keep snapshot in the daily/auto pool)
   fail → restore snapshot, surface the error in the UI
```

### Hyprland file split (one-time, by-hand restructure — its own phase)

Per the architecture already proposed and verified-safe in
docs/HYPRLAND_INFO.md:

```
hypr/
  hyprland.lua          ← user-owned. Gains require() lines, NOTHING else
                          is ever done to it programmatically. The
                          restructure itself is done BY HAND, with the
                          Original Backup already taken.
  generated/            ← manager-owned. Regenerated whole-file from
    appearance.lua         JSON; never hand-edited (header comment in
    monitors.lua           each generated file says so and names the
    ...                    JSON source).
  user/                 ← user-owned. Never touched by the manager.
    keybinds.lua           (Current keybinds/autostart content moves
    startup.lua            here during the restructure.)
    rules.lua
```

Generation target is the `hl.config({...})` / `hl.monitor({...})` API
(HYPRLAND_INFO has the surface). Generating our own file needs NO Lua
parser — string templates from JSON. (The community `hyprland-config`
Python lib noted in HYPRLAND_INFO is only relevant if we ever need to
READ a hand-written config, which this design never does.)

Live-apply pattern where instant feedback matters (monitor dragging,
gap sliders): apply now via `hyprctl` IPC, persist separately to the
generated file — same "apply now, persist separately" split the
wallpaper picker already uses (`awww img` now, state separately).

### Snapshots

- **Location:** `~/.local/state/quickshell-settings/` (XDG state dir —
  config dirs are for config, state dirs are for this). Layout:
  `original/`, `snapshots/<ISO-timestamp>[-label]/`.
- **Original Backup:** first run only — full copy of
  `~/.config/quickshell/` AND `~/.config/hypr/`. Never modified, never
  expired, restorable as "factory reset to pre-manager state."
- **Daily:** on first settings-app open of the day. Keep 30, prune
  older automatically.
- **Manual:** named by the user ("Before Blur Experiment"). Never
  auto-expired.
- **Auto (transaction):** taken by every Apply; these can share the
  daily pool's retention.
- **What's IN a snapshot** (besides the Original): the managed set
  only — settings.json, prefs.json, `hypr/generated/`. Restoring never
  touches user-owned files (unless the user explicitly picks the
  Original / full restore).
- Implementation is `cp -r` / `rm -rf` via Process — no library, no
  cleverness. The engine gets a `testing/` harness before anything
  trusts it.

---

## Build order (each phase ≈ one session, live-confirmed before the next)

**Phase 1 — Snapshot/restore engine, standalone.**
ConfigManager.qml exists with ONLY: `createSnapshot(label)`,
`listSnapshots()`, `restoreSnapshot(id)`, `pruneDailies()`, Original
Backup on first run. No UI beyond maybe IPC calls for testing
(`qs ipc call config snapshot <label>`). Confirmed by actually
restoring one and diffing. Nothing writes config yet — the safety net
goes up before the trapeze act.

**Phase 2 — Appearance page + the transaction loop + theme fix.**
The settings window (see runtime question below) with ONE page. Theme
picker backed by a rebuilt Theme.qml `themes` map reading
`UserPrefs.themeName` — this closes the standing deferred item. This
is a REPEAT of the change that broke Theme.qml on 07-05: this time
with a Phase-1 snapshot taken first, one edit at a time, live confirm
between. Also on this page: fontScale. The preview-diff / Apply /
Cancel flow ships here, because even two settings exercise it fully.

**Phase 3 — Hyprland restructure (by hand) + first generated module.**
Take a manual snapshot; restructure hyprland.lua into
user/ + generated/ requires BY HAND with the maintainer at the wheel;
confirm reload; then build the Hyprland page (gaps, borders — the
simple `hl.config` numbers first) generating `generated/appearance.lua`
through the full transaction loop.

**Phase 4 — Panels page.** Bar height, position (finally wiring the
never-read `Settings.barPosition`, which has been declared-but-unused
since 2026-07-01), spacing, widget visibility. These tokens migrate
from Settings.qml to JSON as this page takes ownership (per the
per-page migration rule).

**Phase 5+ — one category per session from the long-term map**, in
whatever order the maintainer actually wants next. Candidates from the
original doc: Notifications (timeout/position/max — tokens already
exist in Settings.qml), Launcher (width/results — likewise), Audio
(volume step, default device — service functions already exist),
Displays (monitors → generated/monitors.lua + live-apply via hyprctl),
Power, Applications (terminal/browser defaults —
`Settings.launcherTerminalCommand` already wants this),
Advanced (restore-point browser, generated-config viewer, logs).

---

## Ask at session start (open questions, with leans)

1. **Runtime model: in-process window, or separate `qs -c settings`
   process?** LEAN: in-process for v1 — a toggled top-level window
   like PowerScreen (IPC target `settings`, maybe a gear-menu entry),
   because it gets Theme for free and adds no process lifecycle. The
   philosophy's separation is preserved where it matters: ConfigManager
   stays UI-agnostic and shell code never imports it. Extraction to
   its own process is mechanical later, once JSON is the shared truth.
   Counterpoint to note: a shell crash takes the settings app with it
   — acceptable, since recovery is file-based anyway.

2. **UserPrefs convergence.** UserPrefs.qml already IS a small
   settings.json (FileView+JsonAdapter, four keys). Does ConfigManager
   grow its own second JSON file, or does prefs.json become/absorb
   settings.json? LEAN: converge — one file, one source of truth (the
   doc's own principle; two overlapping JSON files is how this project
   got the thumbnail-dir bug). Mechanically: ConfigManager takes over
   the file; UserPrefs either becomes the shell-side read surface of
   it or retires. Decide with the maintainer before Phase 2 touches it.

3. **Exact file locations.** settings.json inside
   `~/.config/quickshell/` next to prefs.json, or a neutral
   `~/.config/quickshell-settings/`? Snapshot dir as proposed
   (`~/.local/state/...`)? Maintainer's call; nothing downstream
   depends on the answer.

4. **Confirm the LIVE hyprland.lua structure before Phase 3.** The
   docs describe it (Lua, autostart section, bind lines) but the file
   itself is not in project knowledge — get a current copy pasted in
   before designing the restructure. Do not assume.

5. **Theme-name format.** user-prefs.json currently stores
   `"themeName": "Honeycomb"` while the theme file/type is
   `HoneycombTheme` — nothing reads the key yet (Theme.qml hardcoded),
   so it's harmless today, but Phase 2's themes map must pick ONE
   format (LEAN: the type name, "HoneycombTheme", so the map key is
   the file/type name and display strings are derived) and migrate the
   stored value if needed.

6. **Is `luac` installed?** (`luac -v`) — determines whether step 3 of
   the transaction exists or is skipped. Either is fine; Hyprland's
   own reject-on-syntax-error covers the gap.

---

## Patterns to reuse (all already debugged in this project)

- **FileView + JsonAdapter** — core/UserPrefs.qml is the reference
  implementation, including: adapter properties become JSON keys,
  `watchChanges` for live pickup of external edits, the
  directory-must-exist-before-first-write gotcha and its
  `mkdir -p`-in-Component.onCompleted fix.
- **Process for shell commands** — args as list, never interpolated
  into a string (WallpaperPicker's find/realpath calls are the model).
- **Singleton service + thin UI** — ConfigManager follows
  services/-style discipline (pragma Singleton AND Singleton root
  type, both — PROBLEMS_AND_FIXES 2026-07-03) even if it lives
  elsewhere; pages are dumb.
- **"Apply now, persist separately"** — wallpaper picker precedent,
  reuse for hyprctl live-apply.
- **Top-level window mechanics** — PowerScreen has the full recipe:
  HyprlandFocusGrab (imperative active push, never bound), Escape
  handling, click-outside, Overlay layer.
- **SettingsMenu's building blocks** — ToggleRow/ToggleSwitch/
  SectionLabel already exist for page content.

## Known traps (from this project's own history — don't relearn these)

- Stale property references fail SILENTLY in QML (undefined, not an
  error) — after any token migration, grep every consumer of the old
  name. Both clocks shipped this exact bug twice (PROBLEMS_AND_FIXES
  2026-07-05; fixed 2026-07-09).
- A partial revert leaves half-wired features that "load fine" —
  cross-check kept files against rolled-back ones explicitly.
- Two files/paths that must agree WILL drift if maintained separately
  (thumbnail-dir bug) — this is the whole argument for one JSON source
  of truth, and for the manager owning both sides of every pair.
- Don't trust that a plausible-looking snippet works — verify against
  Quickshell docs/source or a maintained real-world config
  (PROBLEMS_AND_FIXES 2026-07-02, the sink.ready lesson).

## Success criteria

- Phase 1: a deliberately mangled settings.json is restored to working
  by one function call; Original Backup verified restorable.
- Phase 2: switching themes from the gear UI visibly reskins the shell
  live, survives a shell restart, and a mid-apply failure demonstrably
  auto-restores. The 07-05 deferred item is closed.
- Phase 3: `hyprland.lua` is never programmatically written, ever;
  deleting `generated/` entirely leaves a session that still boots
  (degraded looks, nothing broken).
- Always: the maintainer can stop caring about manual pre-work backups
  because the tool's own snapshots are more reliable than the habit.
