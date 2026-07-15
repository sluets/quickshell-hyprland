# quickshell-config

A personal Hyprland desktop shell built with [Quickshell](https://quickshell.org),
built from scratch module by module.

**Status: daily-drivable.** As of this file's last update (2026-07-09)
the shell has: a floating per-monitor bar (workspaces, now-playing,
volume/wifi/bluetooth popouts, clock+calendar, settings menu), a
centered power screen, a hotkeyed app launcher, a wallpaper picker, a
volume OSD, its own notification daemon, a desktop clock with weather,
and a settings window (theme + font scale, transactional Apply) backed
by a snapshot/restore engine (docs/BACKUPS.md). See `docs/REVISION_HISTORY.md` for exactly what's built and
what isn't, since this line goes stale fast and shouldn't be trusted
over that file.

## Why this exists

This project intentionally avoids pulling in a pre-built Quickshell
config (several good ones exist in the community) and instead builds
each module from scratch, one at a time, heavily commented. That's a
deliberate tradeoff: slower than adopting an existing config, but every
line here is something the maintainer(s) can actually read, understand,
and fix without depending on someone else's abandoned repo or
undocumented design decisions. See `docs/ARCHITECTURE.md` for the
reasoning behind specific structural choices.

## System context

Built and tested on:

- Arch Linux, Hyprland (Wayland) — note the Hyprland config on this
  machine is **hyprland.lua** (Hyprland deprecated hyprlang for Lua
  config in 0.55, April 2026); all bind/autostart examples in the docs
  use the Lua forms
- AMD Ryzen 7800X3D, 32GB DDR5-6000 CL30, AMD RX 9070 XT
- Quickshell 0.3.0 (released 2026-05-04 — see quickshell.org/changelog
  if you need to confirm the version installed locally with
  `quickshell --version`)

Package installs in this project prefer official `pacman` repositories
over the AUR wherever possible, given the [AUR malware incident of June
2026](https://archlinux.org) affecting hundreds of packages via
compromised orphaned packages and `.install` hook payloads. Widely-used,
actively-maintained AUR packages are treated as acceptable when no
official-repo equivalent exists (e.g. `yay` itself).

External runtime dependencies beyond Quickshell itself: `awww` +
`awww-daemon` (wallpaper daemon; started by the compositor via
hyprland.lua, NOT a systemd unit), NetworkManager (Quickshell's only
network backend), PipeWire. The shell's own notification daemon owns
`org.freedesktop.Notifications` — do not install/run another
notification daemon alongside it (see `services/Notifs.qml`'s DESIGN
NOTES on D-Bus name ownership).

## Getting started

```bash
sudo pacman -S quickshell awww networkmanager
git clone <this-repo> ~/.config/quickshell
qs
```

You should see a floating bar appear across the top of your screen.
If you see nothing, or an error, start with `docs/PROBLEMS_AND_FIXES.md`.

Note: with shell.qml directly in `~/.config/quickshell/` (this repo's
layout), there is no config name — IPC calls are plain
`qs ipc call <target> <function>`, with no `-c` flag.

## Project structure

See `docs/ARCHITECTURE.md` for the full breakdown of every folder and
file, why the project is organized this way, and a checklist for adding
new widgets/themes.

Quick summary:

- `shell.qml` — the config root Quickshell loads. A `Scope` that
  instantiates one bar per monitor (via `Variants` over
  `Quickshell.screens`) plus the single-instance widgets (volume OSD,
  notification popups, power screen, desktop clock), and registers all
  global shortcuts and IPC handlers in one place.
- `core/` — shell-wide singletons any file can reach via
  `import qs.core`: `Theme.qml`, `Settings.qml`, `UserPrefs.qml`
  (persisted, UI-toggleable prefs), `Globals.qml`, `Signals.qml`.
- `services/` — system integrations: `Audio.qml` (PipeWire),
  `Network.qml` (NetworkManager/nmcli), `Notifs.qml` (the notification
  daemon — owns the D-Bus name), `BluetoothAgent.qml` (BlueZ pairing
  agent), `Weather.qml` (Open-Meteo, for the desktop clock)
- `widgets/` — visual components: `TopBar/` (the bar and everything
  that hangs off it, including the launcher, wallpaper picker, and
  settings menu), `OSD/` (volume OSD), `Notifications/` (notification
  popup cards), `PowerMenu/` (the centered power screen),
  `Desktop/` (the on-wallpaper clock/weather readout)
- `themes/` — actual color/font/size data files (`DefaultTheme.qml`,
  `HoneycombTheme.qml`)
- `assets/` — icons and images (weather + power icon SVGs live under
  `assets/icons/`)
- `docs/` — revision history, problems-and-fixes log, architecture
  notes, Hyprland/Lua notes, and INTEGRATION_NOTES.md (hyprland.lua
  bind/autostart lines live there)
- `notes/` — scratch space, not part of the running shell
- `testing/` — standalone test files, for trying things in isolation
- `scripts/` — maintenance tooling for this repo itself, not loaded by
  the running shell. Currently just `flatten-for-kb.sh` — see "Working
  with Claude" below.

## Working with Claude / updating the knowledge base

This project has been developed collaboratively with Claude, inside a
Claude Project with this repo's files uploaded to its knowledge base so
Claude has full context across sessions.

**The problem this solves:** Claude Projects' knowledge base is a flat
list of files — it does not preserve folder structure. This repo has
real nested folders (`core/`, `widgets/TopBar/`, `themes/`, etc.), and
several files share a name across folders (`README.md` exists at the
repo root and inside `services/`, `assets/`, `notes/`, and `testing/`).
Uploading the repo as-is would either lose the folder context entirely
or silently collide on those shared filenames.

**The fix:** `scripts/flatten-for-kb.sh` walks the whole repo and copies
every file into one flat folder, renaming only the files that actually
collide (using the parent folder as a prefix — e.g. `services/README.md`
becomes `services-README.md`). Files with unique names keep them as-is.
Re-running it wipes and rebuilds the flattened output each time, so it's
always an exact mirror of the current repo, never a stale accumulation.

**Files that live OUTSIDE this repo get lost on every re-sync** —
learned twice with hyprland.lua (manually added to the KB, wiped by
the next flatten-and-replace cycle, twice). The fix: keep an
up-to-date copy of any external file Claude needs INSIDE the repo —
`notes/hyprland.lua` is the designated spot for the compositor config
(`cp ~/.config/hypr/hyprland.lua ~/.config/quickshell/notes/` before
running the flatten) — so the flatten carries it forever. notes/ is
never loaded by the shell, so a stale copy there can't break anything;
it just needs refreshing when the real one changes meaningfully.

**Note the KB itself is NOT self-cleaning:** the script wipes its own
output folder, but uploading to the Claude Project only ADDS/replaces
files — anything renamed or deleted in the repo leaves a stale copy in
the KB until it's manually removed there. (This has actually bitten:
see REVISION_HISTORY 2026-07-09 — a duplicated theme folder and a
misplaced widget rode along in the KB for days.) When files get renamed
or removed, delete their old KB entries as part of the re-upload.

**Workflow, end of a session:**

```bash
./scripts/flatten-for-kb.sh
```

This produces `~/quickshell-project` (or pass a different destination as
the second argument). Select everything in that folder and upload it to
the Claude Project's knowledge base, replacing the previous version, so
the next session starts with current context.

**If you're picking this project up from GitHub in a brand new Claude
chat** (no existing Project/knowledge base) — clone the repo, run the
same script, and hand the flattened output to Claude directly (upload
the files, or paste key ones inline) along with a pointer to this
section and to `docs/REVISION_HISTORY.md`. That combination — the actual
current files plus the project's own account of how it got here — is
enough for a fresh Claude instance to pick up where a previous session
left off, including *why* things are built the way they are, not just
*what* exists. From there you can keep modifying the project however
you'd like, with or without continuing to sync a knowledge base.

## Documentation

- **`docs/PROJECT_VISION.md`** — where this project is going: a
  public, AI-maintainable Hyprland desktop environment
- **`docs/AI-MAINTENANCE-GUIDE.md`** — START HERE if you are an AI
  model maintaining this project
- **`docs/ARCHITECTURE.md`** — how the project is organized and why,
  including a checklist for adding new widgets or themes
- **`docs/REVISION_HISTORY.md`** — project-wide changelog (individual
  files also keep their own short local revision history in their
  headers, for changes scoped to just that file)
- **`docs/HYPR_RESTRUCTURE.md`** — the one-time by-hand procedure that
  splits hyprland.lua into manager-owned generated/ and untouchable
  user/ files (ready-made split at notes/hypr-restructure/)
- **`docs/BACKUPS.md`** — user guide for the snapshot/backup commands
  (take, list, restore, prune — and manual recovery without the tool)
- **`docs/PROBLEMS_AND_FIXES.md`** — a running log of non-obvious
  problems hit during development and their actual fixes, so they don't
  get rediscovered the hard way twice

## File header convention

Every `.qml` file in this project answers four questions at the top,
plus dependency/revision info:

- What does it do?
- Why does it exist?
- Who depends on it?
- What breaks if it's removed?

See any existing file (e.g. `shell.qml`) for the exact template.

## Shared state pattern

`Theme`, `Settings`, `UserPrefs`, `Globals`, and `Signals` are all
Quickshell singletons (`pragma Singleton`), living in `core/`. Any file
that needs one adds `import qs.core` and reads it directly — e.g.
`Theme.colorBackground`. There's no instance to create and nothing to
pass in when instantiating a widget. See `docs/ARCHITECTURE.md` for the
full explanation and `docs/PROBLEMS_AND_FIXES.md` for why this replaced
an earlier manual-wiring approach.

The `Settings` vs `UserPrefs` split: `Settings` is hand-edit-the-file
tuning knobs with no UI; `UserPrefs` is the small set of preferences
that have live toggles in the gear-icon SettingsMenu and persist to
disk between sessions.

## Hotkeys and IPC

Global shortcuts register under appid `shell` and are bound in
hyprland.lua via `hl.bind(mainMod .. " + <key>",
hl.dsp.global("shell:<name>"))`:

| Keys | Global | Opens |
|---|---|---|
| SUPER+R | `shell:launcher` | App launcher |
| SUPER+W | `shell:wallpapers` | Wallpaper picker |
| SUPER+P | `shell:power` | Power screen |

IPC targets (no `-c` flag on this machine — see Getting started):

```
qs ipc call launcher toggle
qs ipc call wallpapers toggle | set <path> | get | list | random
qs ipc call power toggle
qs ipc call settings toggle
qs ipc call config snapshot <label> | list | restore <name> | prune | status
```
