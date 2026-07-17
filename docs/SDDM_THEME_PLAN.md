# SDDM theme project — current design and status

## Purpose

The project provides a custom Qt 6 SDDM login theme that visually matches the Quickshell desktop while remaining independent from the Quickshell runtime. SDDM runs before login as the `sddm` user, so it cannot import Quickshell singletons or directly consume the live desktop state.

The editable SDDM source is stored at:

```text
~/.config/quickshell/sddm-project/
```

A compatibility symlink keeps the established script path working:

```text
~/.config/sddm-project -> ~/.config/quickshell/sddm-project
```

See `docs/SDDM_BACKUP_AND_TRANSFER.md` for backup, migration, deployment, and rollback instructions.

## Approved visual design

The current approved login screen has:

- the active wallpaper filling the screen
- a 12-hour clock and date in the upper-left corner
- a centered login panel
- a subtle clock shadow for readability
- no decorative accent line under the clock
- Honeycomb-derived colors and restrained surfaces
- session selection, password authentication, suspend, reboot, and shutdown controls

Clock and login positions include X/Y offset values so a later Settings revision can expose positioning controls without restructuring `Main.qml`.

## Synchronization policy

SDDM synchronization is deliberately manual.

Changing the live desktop theme or wallpaper does not write anything under `/usr/share` or `/etc`. The user may change wallpapers repeatedly without invoking privilege escalation or touching root-owned files.

The Settings page provides:

- **Include current theme**
- **Include current wallpaper**
- **Apply to SDDM**

The apply operation builds a user-owned staged snapshot, compares it with the installed snapshot, and invokes the privileged helper only when installation work is required. An identical snapshot results in no root-owned files being rewritten.

## Architecture

### User-owned source and staging

```text
~/.config/quickshell/sddm-project/
├── Main.qml
├── metadata.desktop
├── theme.conf
├── theme.conf.user
├── assets/
├── snapshot/
└── scripts/
```

Quickshell integration:

```text
~/.config/quickshell/widgets/Settings/pages/SddmPage.qml
~/.config/quickshell/scripts/apply-sddm-current.py
```

### Root-owned deployment outputs

```text
/usr/local/libexec/quickshell-sddm-installer
/usr/share/sddm/themes/quickshell-custom/
/etc/sddm.conf.d/quickshell-theme.conf
```

Only the narrow installer helper writes the installed theme directory. Activation is a separate explicit operation.

### Snapshot flow

```text
Quickshell Settings
    -> user selects theme/wallpaper inputs
    -> apply-sddm-current.py updates the staged snapshot
    -> snapshot generator validates and hashes output
    -> privileged installer compares source and installed digests
    -> identical: skip every write
    -> changed: back up previous installed snapshot and install new copy
```

Wallpaper files are copied into the SDDM theme rather than referenced from the user's wallpaper directory. This avoids greeter-time home-directory permissions and availability problems.

## Completed phases

### Phase 0 — test-mode scaffolding: complete

- Confirmed Qt 6 SDDM test mode works.
- Established the standalone development loop.

### Phase 1 — static visual theme: complete

- Built and iterated the approved login screen.
- Replaced the initial procedural SVG with a local PNG wallpaper.
- Changed the clock to 12-hour time.
- Moved clock to upper-left and login panel to center.
- Added configurable position offsets.
- Removed the unwanted accent bar and retained a stronger soft shadow.
- Confirmed successful real logout/login cycles.

### Phase 2 — generated snapshot contract: complete

- Kept `theme.conf` as safe defaults.
- Added generated override data through `theme.conf.user`.
- Added user-space generation, validation, and deterministic hashing.
- Proved appearance can be regenerated without rewriting `Main.qml`.

### Phase 3 — safe installation and activation: complete

- Added dry-run support and fake-root testing under `/tmp`.
- Verified first install and identical-snapshot write skipping.
- Installed the helper under `/usr/local/libexec`.
- Installed and tested the exact root-owned theme copy.
- Added explicit activation/deactivation scripts.
- Activated the theme and confirmed repeated real logins.

Emergency rollback:

```bash
sudo rm -f /etc/sddm.conf.d/quickshell-theme.conf
sudo systemctl restart sddm
```

### Phase 4 — Quickshell Settings integration: complete

- Added a dedicated SDDM Settings page.
- Added manual theme/wallpaper selection and Apply behavior.
- Added status and error reporting.
- Confirmed the Settings-generated root-installed theme renders successfully.

## Remaining optional work

These are enhancements, not requirements for the working system:

- expose clock and login X/Y offsets in Settings
- expose clock format despite the current preference for 12-hour time
- expose additional SDDM-only typography and panel sizing controls
- add a preview/status display for the last installed digest and wallpaper
- add a clearly labeled deactivate/rollback button to Settings
- improve multi-monitor behavior if real use reveals a problem
- investigate greeter weather only as an experimental feature

Automatic live wallpaper synchronization remains intentionally rejected unless the user explicitly changes the design decision. Manual Apply prevents unnecessary privileged writes during frequent wallpaper changes.

## Revision history

- **2026-07-13:** Initial planning document.
- **2026-07-16:** Phases 0-4 completed; custom theme activated and tested through real login cycles; manual Quickshell Settings integration approved; Git-backed source and transfer workflow documented.
