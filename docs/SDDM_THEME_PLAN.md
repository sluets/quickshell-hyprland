=================================================================
FILE
=================================================================

docs/SDDM_THEME_PLAN.md

=================================================================
PURPOSE
=================================================================

Planning doc for a small side project: a custom SDDM login theme,
built from scratch in QML, the same way the Quickshell shell itself
was built (docs/PROJECT_README.md's philosophy — small hand-built
modules, heavily commented, no forked configs). This is a SEPARATE
codebase from the Quickshell shell — SDDM's greeter runs as its own
process, as the `sddm` user, before any session (and therefore
before Quickshell) starts. Nothing here shares a QML engine or a
singleton with `core/Theme.qml` — any "matching" is a hand-sync, not
shared code, until/unless Phase 5 below happens.

Not started yet. This is the plan to start FROM.

=================================================================
GOALS (v1 — what "done" looks like for the first pass)
=================================================================

1. A login screen with a clock + date, styled to look like it
   belongs to the same desktop as the Quickshell bar/clock — not a
   pixel-perfect port, just the same font, palette, and general
   restraint.
2. A background that matches whatever wallpaper is currently in use
   on the desktop — even if, for v1, that's a manual "set the
   background to this file" step rather than a live sync.
3. A login box (password field, user avatar, session/power buttons)
   that doesn't look like a stock/default theme — reuses the same
   surface/hover/accent color language as the rest of the shell.
4. A tiny STANDALONE settings tool to edit the theme's config
   (colors, background path, clock format) without hand-editing
   `theme.conf.user` — separate from the Quickshell settings window
   for now. Folding it in as a new tab is explicitly a LATER step,
   not part of v1.

=================================================================
OUT OF SCOPE FOR NOW (don't drift into these early)
=================================================================

- Live weather on the greeter. Technically possible (QML's
  `XMLHttpRequest` can hit a network API, and NetworkManager is
  normally up before SDDM starts) but nobody in the SDDM theme
  ecosystem seems to actually do this — no known-good pattern to
  copy. Revisit only after v1 is solid and daily-driven.
- Live wallpaper sync (desktop wallpaper change -> SDDM background
  updates automatically). Needs a privileged write into a
  root-owned directory (`/usr/share/sddm/themes/<name>/`) — real
  design work, not a quick hook. See Phase 3.
- Folding theme-color switching into the Quickshell settings window
  (`SettingsWindow.qml`) as a real tab with staged/Apply semantics.
  Good end state, wrong place to start.
- Multi-monitor greeter layout, animated backgrounds, a custom
  avatar picker, restyled session/keyboard-layout dropdowns — keep
  SDDM's default components for these in v1; reskin colors only.
- Supporting Qt5 / legacy SDDM. Same assumption as the rest of this
  project: current Arch, current Quickshell, current Qt6 — see
  `docs/PROJECT_README.md`'s "System context" section instead of
  reproducing it here.

=================================================================
WHERE THIS LIVES
=================================================================

A new, separate project directory — NOT inside
`~/.config/quickshell/`, since this isn't a Quickshell config.
Suggested: `~/dev/sddm-caelestia/` (or wherever your other
from-scratch projects live), with its own README and revision
history file mirroring this project's docs/ convention once it's
underway. Installed for real testing via:

    sudo cp -r ~/dev/sddm-caelestia /usr/share/sddm/themes/caelestia

Iteration during development should NOT require that install step —
`sddm-greeter-qt6 --test-mode --theme ~/dev/sddm-caelestia` runs
straight from the working directory.

=================================================================
PHASES
=================================================================

---- Phase 0 — Scaffolding ----

Goal: prove the test-mode loop works before writing anything real.

- Confirm deps installed: qt6-declarative, qt6-svg (pacman, not AUR
  — see this project's AUR-avoidance stance).
- Minimal skeleton: `metadata.desktop`, `theme.conf`, `Main.qml`
  that's just a solid-color Rectangle filling the screen.
- Confirm `sddm-greeter-qt6 --test-mode --theme <dir>` renders it.
  This is the whole phase — if this doesn't work, nothing past here
  will either, and it's much cheaper to find out now.

---- Phase 1 — Static visual parity ----

Goal: a login screen that looks like it belongs, using ONE
hand-picked wallpaper and ONE hand-copied palette — no syncing yet.

- Background: hardcode a path to a wallpaper you like (copy the
  file into the theme dir; don't reference `~/Pictures/Wallpapers`
  directly — the `sddm` user may not have read access there).
- Clock + date: same font family as `Theme.fontFamily`, same rough
  proportions as `widgets/TopBar/Clock.qml` / `DesktopClock.qml` —
  copied by hand, not imported (separate QML engine, see PURPOSE).
- Login box: restyle SDDM's password field + avatar + session
  picker using colors hand-copied from whichever theme file is your
  current favorite (e.g. `themes/HoneycombTheme.qml`'s
  colorSurface/colorAccent/colorMuted/radiusMedium values).
- Test via test-mode after EVERY piece, not at the end — same
  incremental-and-verify habit as the rest of this project.

---- Phase 2 — Standalone settings tool ----

Goal: a small GUI to edit the theme's own config, separate from the
Quickshell settings window.

- Likely shape: a standalone QML app (run via `qmlscene` or a tiny
  Quickshell config of its own — decide when we get here, both are
  plausible) with fields for: background path, clock format,
  handful of hex colors, font family/size.
- Open question to resolve when we start this phase: `theme.conf`
  lives under `/usr/share/sddm/themes/<name>/`, which is root-owned.
  The tool will need either a `pkexec`/`sudo` write step, or it
  writes to a staging file and shows the user the `sudo cp` command
  to run — no existing pattern in this project to lean on here
  (`ConfigManager.qml`'s writes are all to user-owned files), so
  this is genuinely new ground, not a copy-paste of something we've
  already solved.
- This tool edits ONLY the SDDM theme. It does not touch
  `core/Theme.qml`, `UserPrefs.qml`, or anything in the Quickshell
  config — fully separate config surface for now, per the v1 goals.

---- Phase 3 — Live wallpaper sync (stretch, post-v1) ----

Goal: changing the desktop wallpaper (via `WallpaperPicker.qml` /
`caelestia wallpaper`) updates the SDDM background too, automatically.

- Likely shape: a hook fired from wherever the wallpaper picker
  calls `awww` to actually set the wallpaper — copy the new file
  into the theme dir and rewrite `theme.conf.user`'s background key.
- Same root-ownership problem as Phase 2 — solve it once, reuse the
  answer here.

---- Phase 4 — Weather (experimental, post-v1) ----

Goal: mirror `DesktopClock.qml`'s weather display on the greeter.

- Explicitly experimental. First step if/when we get here: confirm
  network is actually up at greeter-load time on THIS machine's
  actual boot sequence (NetworkManager starting before SDDM is
  typical, but "typical" isn't "confirmed on your box") before
  writing any QML for it.

---- Phase 5 — Real sync with the Quickshell theme (stretch, post-v1) ----

Goal: switching themes in the Quickshell settings window pushes
colors to the SDDM theme too, closing the loop this plan explicitly
avoids for v1.

- Likely shape: a small script, run from `ConfigManager.applyChanges`
  or similar, that reads the active theme's palette and regenerates
  the SDDM theme's color file.
- THIS is the point where adding a tab to `SettingsWindow.qml` (per
  the original ask) makes sense — once there's a real, working,
  tested SDDM theme to point that tab at. Not before.

=================================================================
REVISION HISTORY
=================================================================

2026-07-13  Initial plan. Nothing built yet — start at Phase 0.
