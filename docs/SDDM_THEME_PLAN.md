# SDDM theme project — current design and status

<!-- GPT: updated 2026-07-18 after the major SDDM customization block -->

## Purpose

This project provides a standalone Qt 6 SDDM login theme that matches the Quickshell desktop without depending on the Quickshell runtime at login time. SDDM runs before the user session as the `sddm` user, so the login theme cannot import Quickshell singletons or directly read the live desktop state.

Editable source:

```text
~/.config/quickshell/sddm-project/
```

Compatibility symlink used by the scripts:

```text
~/.config/sddm-project -> ~/.config/quickshell/sddm-project
```

See `docs/SDDM_BACKUP_AND_TRANSFER.md` for installation, migration, recovery, and machine-specific monitor setup.

## Approved visual design

The current login screen supports:

- wallpaper filling each screen
- upper-left time and optional date
- centered login panel
- independently configurable clock/date colors
- adjustable clock shadow color, opacity, and X/Y offsets
- selected-theme or custom font
- session selection, password authentication, suspend, reboot, and shutdown

## Current Settings controls

### Theme and font

- **Include current theme**
- when disabled, choose any Quickshell theme from the same theme list used by Appearance
- **Use theme font**
- when disabled, choose a custom installed Nerd Font from the same font list used by Appearance
- alternate SDDM theme/font choices do not change the active desktop theme or font

### Wallpaper

- **Use current wallpaper**
- when disabled, choose from the shared wallpaper library
- thumbnail grid reuses `<wallpaper-library>/.thumbs`
- full image is used when a matching thumbnail is unavailable
- custom absolute wallpaper path is supported
- the original image path is saved; thumbnail paths are UI-only
- wallpaper filenames are intentionally hidden in the grid

The shared wallpaper library path is persisted in `UserPrefs.wallpapersPath` and is also used by the main Quickshell wallpaper picker. The default is:

```text
~/Pictures/Wallpapers
```

### Clock

The Clock section is split into nested sections:

- **Position & scale**
  - overall clock scale: 50–200%
  - clock X/Y offsets
- **Date**
  - show/hide date
  - independent date scale
  - adjustable time/date spacing
- **Colors**
  - follow selected SDDM theme colors, or
  - custom time, date, and shadow colors
- **Shadow**
  - opacity/strength
  - independent X/Y offsets

Time and date use the same root clock value and update together. The date renderer has a safe fallback if a configured Qt date format resolves to an empty string.

### Login panel

- panel X/Y offsets
- panel scale
- panel width
- panel spacing
- custom greeting/login text

### Preview and deployment

- **Test SDDM Theme**
- **Apply to SDDM**
- Reset controls for numeric layout/appearance values
- collapsible sections to keep the large control set manageable

## Preview versus Apply

### Test SDDM Theme

The Test button previews the current unsaved SDDM controls without touching root-owned files:

1. Copies the user-owned SDDM project to a temporary directory under `/tmp`.
2. Applies the selected theme, font, wallpaper, layout, date, color, shadow, and login-panel settings to that temporary copy.
3. Regenerates `theme.conf.user` and its deterministic digest.
4. Launches `sddm-greeter-qt6 --test-mode` or the `sddm-greeter` fallback.
5. Deletes the temporary copy after the greeter exits.

Preview does not invoke `pkexec`, does not write to `/usr/share`, and does not alter the real snapshot contract.

The test window runs inside Hyprland, so its monitor arrangement follows Hyprland rather than the real pre-login X11 arrangement.

### Apply to SDDM

Apply is deliberately manual. It updates the user-owned snapshot and invokes the narrow privileged installer only when needed.

The installer compares deterministic digests. If the installed theme is already identical, it reports that it is up to date and performs no root-owned rewrite.

Changing desktop or SDDM settings never updates `/usr/share` until **Apply to SDDM** is pressed.

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
~/.config/quickshell/widgets/Settings/components/CollapsibleSection.qml
~/.config/quickshell/scripts/apply-sddm-current.py
```

### Root-owned deployment outputs

```text
/usr/local/libexec/quickshell-sddm-installer
/usr/share/sddm/themes/quickshell-custom/
/etc/sddm.conf.d/quickshell-theme.conf
```

The Git-backed project source is authoritative. Root-owned files are generated deployment outputs and should never be copied back into Git.

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

Wallpaper files are copied into the generated theme instead of being referenced directly from the user's wallpaper directory. This avoids greeter-time home-directory access and permission problems.

## Completed phases

- **Phase 0:** Qt 6 test-mode scaffolding
- **Phase 1:** static visual theme
- **Phase 2:** generated snapshot contract and deterministic hashing
- **Phase 3:** safe installation, activation, deactivation, and rollback
- **Phase 4:** Quickshell Settings integration
- **Phase 5:** advanced visual customization
  - alternate theme and font
  - shared-library wallpaper selector with `.thumbs`
  - full clock/date controls
  - custom colors and shadows
  - login-panel sizing and spacing
  - non-root unsaved preview

## Real SDDM monitor layout

The real greeter runs under X11 on the current machine and executes:

```text
/usr/share/sddm/scripts/Xsetup
```

Confirmed connector mapping:

```text
DisplayPort-1 = physical left monitor
DisplayPort-0 = physical right/main monitor
```

Working machine-specific layout:

```sh
#!/bin/sh

/usr/bin/xrandr \
    --output DisplayPort-1 --mode 2560x1440 --rate 143.97 --pos 0x0 \
    --output DisplayPort-0 --primary --mode 2560x1440 --rate 143.97 --pos 2560x0
```

This is machine-specific system display configuration. Do not hard-code these connector names into the portable SDDM theme installer.

## Remaining optional work

The major customization block is complete. Future SDDM work is optional and should not begin until the current project has been backed up, committed, pushed, and verified clean.

Possible later work:

- installed digest/status detail in the Settings UI
- clearly labeled deactivate and rollback buttons in Settings
- safer optional machine-specific monitor-layout UI
- greeter weather only as an experiment

Automatic live wallpaper synchronization remains intentionally rejected. Manual Apply avoids privileged writes while cycling wallpapers.

## Revision history

- **2026-07-13:** Initial planning document.
- **2026-07-16:** Phases 0–4 completed and activated.
- **2026-07-18:** Added temporary preview, resettable offsets, clock scaling, and X11 monitor-layout documentation. (GPT)
- **2026-07-18:** Completed the major customization block: alternate themes/fonts, shared-library wallpaper thumbnails, date display, custom clock colors and shadows, login-panel sizing, and the final Settings UX cleanup. (GPT)
