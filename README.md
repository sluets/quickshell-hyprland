# Quickshell Hyprland Desktop

## Built with AI, designed to stay maintainable

This project was built collaboratively with AI—primarily Claude and OpenAI's GPT models—through an iterative process of describing features, generating code, testing the result on a real Arch/Hyprland system, and feeding the failures and edge cases back into the next revision. It was not written as a one-off generated demo and abandoned. It has been repeatedly tested, repaired, reorganized, documented, and used as a real desktop shell.

That development model is intentional. The repository is structured and documented so another person can clone it, place the full project into a ChatGPT or Claude project, and ask the AI to help install it, explain it, modify it, or repair it when future Quickshell, Hyprland, Qt, Arch, or SDDM updates break something. The goal is not to require every user to become a QML expert before they can make the desktop their own.

The codebase, documentation, revision history, setup notes, troubleshooting records, and project structure together provide enough context for an AI assistant to work from the actual current system instead of guessing from isolated snippets. For the best results, give the assistant the complete repository or a current ZIP, describe the desired change, test the generated files, and keep Git checkpoints before major updates.

AI-generated changes should still be treated like any other code change: inspect them when possible, apply only the changed files, test in the temporary preview paths first, and keep a clean Git commit available for rollback. The project is designed to make that workflow practical even for users who are more comfortable testing and describing behavior than writing QML or Python from scratch.

A complete custom desktop shell for Arch Linux and Hyprland, built with
[Quickshell](https://quickshell.org).

This project replaces the usual collection of separate desktop utilities with
one integrated shell. The bar, launcher, notifications, wallpaper tools,
desktop widgets, power controls, settings interface, and SDDM theme are all
part of the same system and share the same themes, preferences, and design
language.

The project is fully functioning and used as a real desktop environment rather
than a demonstration config.

## Features

### Desktop shell

- Floating multi-monitor top bar
- Hyprland workspace controls
- Application launcher with attached or centered presentation, offsets, favorites, usage ordering, and hidden-app controls
- Power and session menu
- Volume control and volume OSD
- Wi-Fi scanning, status, and connection controls
- Bluetooth status, device controls, and pairing support
- Split date/calendar and time-tools popouts
- Media playback information and controls
- Quickshell-native calculator opened from the launcher, with favorites, usage ranking, keyboard input, and session history
- Timer, stopwatch, alarm, interval notifications, and selectable alert sounds
- Clipboard persistence/history with bounded entries, delete/clear actions, and image thumbnails
- Native Quickshell notification daemon with detached or bar-attached stacked cards
- Desktop clock, date, weather, and temperature display
- Per-monitor behavior where appropriate

### Appearance and wallpapers

- Multiple built-in QML themes
- Theme selection without restarting the shell
- Configurable font family and font scaling
- Shared wallpaper-library directory
- Wallpaper picker with attached or centered presentation and cached `.thumbs` previews
- Wallpaper transitions through `awww`
- Configurable bar spacing, borders, sizing, and related appearance options
- Persisted Settings window dimensions for different displays and workspaces

### Settings and configuration

- Full graphical Settings window
- Transactional Apply and Cancel workflow
- Persistent user preferences through `UserPrefs.qml`
- Draggable scrollbars and resizable floating window behavior
- Hyprland integration settings
- Desktop clock and weather settings
- Theme, launcher, wallpaper, and notification presentation controls
- Backup, restore, and configuration snapshot tooling

### SDDM integration

The project includes a matching SDDM login theme and a complete management
workflow from inside the Quickshell Settings window.

SDDM features include:

- Temporary no-root test preview
- Apply and rollback tooling
- Hash-aware installation that skips identical writes
- Current or independently selected Quickshell theme
- Theme font or independently selected custom font
- Current wallpaper or separately selected wallpaper
- Thumbnail wallpaper selector using the shared `.thumbs` cache
- Custom wallpaper path support
- Adjustable clock and login-panel positions
- Clock and date scaling
- Optional date display and adjustable spacing
- Theme-driven or custom time, date, and shadow colors
- Adjustable clock shadow strength and X/Y offsets
- Login-panel width, scaling, spacing, and custom text
- Snapshot-based generated theme state

The SDDM greeter is tested under X11. Machine-specific monitor ordering and
refresh-rate configuration belongs in `/usr/share/sddm/scripts/Xsetup` and is
kept separate from the portable theme installer.

## System context

The project is developed and tested on:

- Arch Linux
- Hyprland 0.55.4 or newer using Lua configuration
- Quickshell
- Wayland
- AMD graphics
- PipeWire
- NetworkManager
- `awww` and `awww-daemon`

The shell owns `org.freedesktop.Notifications`, so another notification daemon
should not run alongside it.

Package installation prefers official Arch repositories where practical.

## Installation

Clone the repository into the default Quickshell configuration location:

```bash
git clone https://github.com/sluets/quickshell-hyprland ~/.config/quickshell
```

Install the primary runtime dependencies:

```bash
sudo pacman -S quickshell networkmanager pipewire libnotify wl-clipboard wl-clip-persist cliphist
```

Install `awww` using the appropriate package source for your system, then make
sure `awww-daemon` starts with Hyprland.

Clipboard persistence/history also requires three long-running session processes. See `docs/CLIPBOARD_SETUP.md` before testing the clipboard popout.

Launch the shell:

```bash
qs
```

For a fresh installation, read these first:

- `docs/SETUP_GUIDE.md`
- `docs/HYPRLAND_WINDOW_RULES.md`
- `docs/PROBLEMS_AND_FIXES.md`
- `sddm-project/README.md`

## Hyprland integration

This project targets Hyprland's Lua configuration format. Examples and window
rules in the documentation use Lua rather than legacy `.conf` syntax.

The Settings window should normally be floated and centered, but its size
should not be hardcoded in the Hyprland rule because the preferred width and
height are managed by Quickshell.

Example:

```lua
hl.window_rule({
    name = "quickshell-settings",
    match = {
        class = "org.quickshell",
        title = "Quickshell Settings",
    },

    float = true,
    center = true,
})
```

See `docs/HYPRLAND_WINDOW_RULES.md` for the complete current rules.

## Project structure

```text
shell.qml                  Main Quickshell entry point
core/                      Shared singletons and global settings
services/                  Audio, network, notifications, weather, clock tools, clipboard history, and helpers
widgets/                   Bar, launcher, settings, desktop widgets, OSDs, menus
themes/                    QML theme definitions
assets/                    Runtime icons, weather assets, and alert sounds
scripts/                   Maintenance and apply helpers
sddm-project/              SDDM source theme, snapshots, and installer tooling
docs/                      Setup, architecture, changelog, fixes, and plans
testing/                   Standalone test files
notes/                     Active non-runtime scratch notes and reference material
```

### Important shared singletons

The project uses Quickshell singletons in `core/` for shell-wide state:

- `Theme.qml` — active theme and theme discovery
- `Settings.qml` — static internal tuning values
- `UserPrefs.qml` — persisted user-controlled preferences
- `Globals.qml` — shared runtime state
- `Signals.qml` — cross-component signals

Files import them with:

```qml
import qs.core
```

This avoids manually passing the same state through every component.

## Running and controlling the shell

With `shell.qml` directly inside `~/.config/quickshell`, IPC commands do not
need a config-name argument.

Common commands:

```bash
qs ipc call launcher toggle
qs ipc call wallpapers toggle
qs ipc call wallpapers set /path/to/image.png
qs ipc call wallpapers get
qs ipc call wallpapers list
qs ipc call wallpapers random
qs ipc call power toggle
qs ipc call settings toggle
qs ipc call calculator toggle
qs ipc call config status
qs ipc call config snapshot my-backup
qs ipc call config list
qs ipc call config restore snapshot-name
qs ipc call config prune
```

Typical Hyprland shortcuts:

| Shortcut | Action |
|---|---|
| `SUPER + R` | Application launcher |
| `SUPER + W` | Wallpaper picker |
| `SUPER + P` | Power menu |

The exact bindings belong in the user's Hyprland Lua configuration.

## Wallpaper library

The wallpaper picker and SDDM wallpaper selector use one shared wallpaper
library path configured from the Appearance page.

Thumbnail previews are stored in:

```text
<wallpaper-library>/.thumbs/
```

The selected wallpaper always stores the original image path. Thumbnail files
are only used for the user interface.

Thumbnails can be generated manually with:

```bash
./scripts/make-square-thumbs.sh "/path/to/wallpapers"
```

## SDDM workflow

The SDDM page provides two separate operations:

### Test SDDM Theme

Creates a temporary user-owned preview from the currently selected, including
unsaved, Settings values. It does not invoke `pkexec` and does not write to
`/usr/share`.

### Apply to SDDM

Generates the snapshot, installs the theme through the system helper, and
updates the real SDDM theme. Root access is used only for the system-owned
installation step.

Before changing system SDDM files, read:

- `sddm-project/README.md`
- `docs/SDDM_THEME_PLAN.md`
- `docs/SDDM_BACKUP_AND_TRANSFER.md`

## Backups

The project includes configuration snapshots and rollback support, but a full
machine backup should also preserve:

- `~/.config/quickshell`
- The wallpaper library and its `.thumbs` directory
- Hyprland Lua configuration and related scripts
- `/usr/share/sddm/scripts/Xsetup` if it contains machine-specific monitor setup
- `~/.ssh`, including private keys, public keys, `config`, and `known_hosts`

See `docs/BACKUPS.md` and `docs/SDDM_BACKUP_AND_TRANSFER.md` for details.

## Documentation

- `docs/SETUP_GUIDE.md` — installation and first-run setup
- `docs/PROJECT_VISION.md` — long-term direction
- `docs/ARCHITECTURE.md` — code organization and design decisions
- `docs/REVISION_HISTORY.md` — detailed project changelog
- `docs/PROBLEMS_AND_FIXES.md` — known issues and verified solutions
- `docs/HYPRLAND_WINDOW_RULES.md` — required and recommended Lua rules
- `docs/BACKUPS.md` — snapshot and restore workflow
- `docs/FEATURE_BACKLOG.md` — canonical future-work list
- `docs/SMALL_ADDITIONS_BACKLOG.md` — focused small-utility ideas
- `docs/CLIPBOARD_SETUP.md` — required clipboard backend setup
- `docs/MUSIC_PLAYER_PLAN.md` — approved phased MPD player plan
- `sddm-project/README.md` — SDDM theme management and installation

## Development approach

The shell is developed feature by feature, with live testing after each change.
Large changes are checkpointed by updating documentation, refreshing the full
project archive, and committing a clean Git state before unrelated work begins.

The codebase is intentionally documented and split into focused files so it can
be maintained with ordinary code review, direct experimentation, or AI-assisted
development without depending on one specific tool or model.

## License

No license has been declared yet. Until one is added, treat the repository as
all rights reserved by its owner.
