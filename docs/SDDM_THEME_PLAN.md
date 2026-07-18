# SDDM theme project — current design and status

<!-- GPT: updated 2026-07-18 -->

## Purpose

The project provides a custom Qt 6 SDDM login theme that visually matches the Quickshell desktop while remaining independent from the Quickshell runtime. SDDM runs before login as the `sddm` user, so it cannot import Quickshell singletons or directly consume the live desktop state.

The editable source lives at:

```text
~/.config/quickshell/sddm-project/
```

Compatibility symlink used by the scripts:

```text
~/.config/sddm-project -> ~/.config/quickshell/sddm-project
```

See `docs/SDDM_BACKUP_AND_TRANSFER.md` for installation, migration, recovery, and machine-specific monitor setup.

## Approved visual design

The current login screen has:

- the selected wallpaper filling each screen
- a 12-hour clock and date in the upper-left
- a centered login panel
- a soft clock shadow
- no accent line below the clock
- Honeycomb-derived colors and restrained surfaces
- session selection, password authentication, suspend, reboot, and shutdown

## Settings controls

The SDDM page currently supports:

- **Include current theme**
- **Include current wallpaper**
- clock scale from 50% to 200% in 10% steps
- clock horizontal and vertical offsets in 10 px steps
- login-panel horizontal and vertical offsets in 10 px steps
- individual Reset buttons for scale and every offset
- **Test SDDM Theme**
- **Apply to SDDM**

Positive X moves right. Positive Y moves down. Offsets are clamped to `-4096` through `4096`; clock scale is clamped to `50` through `200` percent.

The offset controls use fixed label/value columns so all rows remain aligned.

## Preview versus Apply

### Test SDDM Theme

The Test button previews the current unsaved SDDM controls without touching root-owned files:

1. Copies the user-owned SDDM project to a temporary directory under `/tmp`.
2. Applies the currently selected theme, wallpaper, offsets, and clock scale to that temporary copy.
3. Regenerates its `theme.conf.user` and digest.
4. Launches `sddm-greeter-qt6 --test-mode` (or `sddm-greeter` as a fallback).
5. Deletes the temporary copy after the greeter exits.

The preview does not run `pkexec`, does not write to `/usr/share`, and does not alter the source snapshot contract.

The test window runs inside the current Hyprland session, so its monitor arrangement follows Hyprland rather than the real pre-login X11 arrangement.

### Apply to SDDM

Apply is deliberately manual. It updates the user-owned snapshot and invokes the narrow privileged installer only when needed.

Changing the desktop theme, wallpaper, or SDDM controls does not write anything under `/usr/share` until Apply is pressed. The installer compares deterministic digests and skips installation when the root-owned copy is already identical.

Layout-only changes can be applied with both theme and wallpaper unchecked.

## Architecture

### User-owned source and integration

```text
~/.config/quickshell/sddm-project/
├── Main.qml
├── metadata.desktop
├── theme.conf
├── theme.conf.user
├── assets/
├── snapshot/
└── scripts/

~/.config/quickshell/widgets/Settings/pages/SddmPage.qml
~/.config/quickshell/widgets/Settings/components/StepperRow.qml
~/.config/quickshell/scripts/apply-sddm-current.py
```

### Root-owned deployment outputs

```text
/usr/local/libexec/quickshell-sddm-installer
/usr/share/sddm/themes/quickshell-custom/
/etc/sddm.conf.d/quickshell-theme.conf
```

The project source is authoritative. Root-owned files are generated deployment outputs and should not be committed back into Git.

### Snapshot flow

```text
Quickshell Settings
    -> build user-owned snapshot contract
    -> validate and generate theme.conf.user
    -> calculate deterministic digest
    -> privileged installer compares installed digest
    -> identical: skip writes
    -> changed: back up prior installed snapshot and install new copy
```

Wallpaper files are copied into the theme rather than referenced from the user's wallpaper directory. This avoids greeter-time home-directory access problems.

## Completed phases

### Phase 0 — test-mode scaffolding: complete

- Confirmed Qt 6 SDDM test mode.
- Established the standalone development loop.

### Phase 1 — static visual theme: complete

- Built and approved the login screen.
- Added a local wallpaper, 12-hour clock, upper-left clock, centered login panel, and soft shadow.
- Confirmed real logout/login cycles.

### Phase 2 — generated snapshot contract: complete

- Kept `theme.conf` as safe defaults.
- Added generated overrides through `theme.conf.user`.
- Added validation and deterministic hashing.

### Phase 3 — safe installation and activation: complete

- Added fake-root and dry-run testing.
- Added hash-aware installation and write skipping.
- Added explicit activation, deactivation, and rollback scripts.
- Confirmed the root-installed theme through repeated real logins.

### Phase 4 — Quickshell Settings integration: complete

- Added the dedicated Settings page.
- Added manual theme/wallpaper selection and status reporting.
- Added temporary non-root preview.
- Added clock/login offsets and Reset controls.
- Added clock scaling.

## Real SDDM monitor layout

The real greeter runs under X11 on the current machine and executes:

```text
/usr/share/sddm/scripts/Xsetup
```

Its connector names are not the same as Hyprland/Xwayland names. The confirmed SDDM/Xorg connectors are:

```text
DisplayPort-1 = physical left monitor
DisplayPort-0 = physical right/main monitor
```

The working machine-specific layout is:

```sh
#!/bin/sh

/usr/bin/xrandr \
    --output DisplayPort-1 --mode 2560x1440 --rate 143.97 --pos 0x0 \
    --output DisplayPort-0 --primary --mode 2560x1440 --rate 143.97 --pos 2560x0
```

This belongs to system display configuration, not the portable theme. Do not hard-code this machine's connector names into the general SDDM theme installer.

## Remaining optional work

- login-panel width and scale controls
- additional SDDM-only typography controls
- display of the last installed digest and wallpaper
- clearly labeled deactivate/rollback controls in Settings
- optional machine-specific monitor-layout UI only if it can be made safe
- greeter weather only as an experiment

Automatic live wallpaper synchronization remains intentionally rejected. Manual Apply prevents repeated privileged writes while cycling wallpapers.

## Revision history

- **2026-07-13:** Initial planning document.
- **2026-07-16:** Phases 0–4 completed and activated.
- **2026-07-18:** Documented temporary unsaved preview, resettable clock/login offsets, clock scaling, aligned controls, and the confirmed X11 dual-monitor setup. (GPT)
