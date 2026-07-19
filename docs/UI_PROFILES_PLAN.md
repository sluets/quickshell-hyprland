# UI Profiles Plan and Current Status

_Last updated 2026-07-19 by GPT through Rev 25._

## Purpose

UI Profiles exists first as a development safety net: save the user's current known-good desktop configuration, aggressively test Settings, then restore that baseline in a few clicks. It may later grow into named custom UI profiles, but Phase 1 must remain simple and trustworthy.

## Current implemented phase: My Default

The **UI Profiles** tab currently supports:

- **Set Current as My Default**;
- **Overwrite My Default**;
- **Restore My Default**;
- complete persisted `UserPrefs` capture;
- current wallpaper-path capture and restoration;
- saved timestamp/wallpaper display;
- confirmation before overwrite or restore;
- staged-change discard after restore;
- automatic Hyprland regeneration/reapply after restore.

The user broadly live-tested the feature by pushing most UI settings to extreme values, applying them, and restoring the saved default. Rev 24 fixed the first discovered integration gap: restored Hyprland values now regenerate their separate appearance output without requiring a slider to be moved. Rev 25 removed the fixed 250 ms reload guess and replaced it with explicit `UserPrefs` reload confirmation. A second broad test completed with no warnings and full UI, wallpaper, and Hyprland restoration.

## Files and ownership

```text
widgets/Settings/pages/UiProfilesPage.qml
    UI, confirmations, helper processes, status, restore orchestration

scripts/settings-profile.sh
    save / restore / status file operations and wallpaper handling

widgets/Settings/SettingsTransaction.qml
    reapplyCurrentHyprland() bridge into the normal generator path

widgets/Settings/SettingsContext.qml
    page-facing restore/reapply bridge and shared Settings facade

widgets/Settings/SettingsWindow.qml
    window host and minimal externally required wrapper

core/UserPrefs.qml
    explicit reloadFromDisk() entry point and preferencesReloaded() signal
```

## Snapshot storage

```text
~/.local/state/quickshell/ui-profiles/my-default/
├── user-prefs.json
└── wallpaper.txt
```

The wallpaper itself is not copied. Restoration succeeds for settings even when the saved wallpaper path is missing, while reporting that condition to the user.

## Restore sequence

1. Replace the live preference JSON using a temporary file and atomic rename.
2. Restore the saved wallpaper when the path still exists.
3. Discard any values staged in the open Settings window.
4. Mark the page as awaiting profile reload and call `UserPrefs.reloadFromDisk()`.
5. `UserPrefs` reloads its `FileView` and emits `preferencesReloaded()` on the next Qt event-loop turn.
6. The waiting page receives that signal and submits the restored Hyprland subset through the normal `ConfigManager` apply/generator path.

## Hard boundaries

- Do not write SDDM files or run privileged installation from UI Profiles.
- Do not duplicate the Hyprland generator in the profile script.
- Do not replace the explicit reload handshake with a fixed timer.
- Do not automatically overwrite `My Default`; only the user may replace it.
- Do not copy wallpaper image libraries into profile storage.
- Do not expand Phase 1 into a profile manager while restore reliability is still being validated.

## Future expansion

Later phases may add:

- **Save As** with named profiles;
- profile cards/listing;
- rename, duplicate, and delete;
- optional wallpaper inclusion per profile;
- import/export;
- a separately managed **Previous Apply** rollback point;
- selective profile categories.

A profile should represent more than a color theme: font, scale, bar layout, notifications, desktop widgets, wallpaper, and Hyprland visual settings may all be included. That is why the feature is named **UI Profiles**, not merely Custom Themes.

## Regression checklist

1. Save a known-good default.
2. Confirm status shows a timestamp and wallpaper.
3. Change obvious settings across multiple tabs and Apply.
4. Change Hyprland gaps, border, rounding, and border-color modes.
5. Change wallpaper.
6. Restore My Default.
7. Verify general UI, wallpaper, and Hyprland visuals all return without touching another control.
8. Verify no normal settings remain staged.
9. Verify a missing saved wallpaper does not block settings restoration.
10. Verify SDDM is untouched.
11. Verify restore performs no timer-based wait and still reapplies Hyprland after `preferencesReloaded`.

## Rev 29 architecture note

UI Profiles remains a page-level feature. New profile functionality belongs in `UiProfilesPage.qml`, dedicated profile components, `settings-profile.sh`, or a future profile service. Do not add named-profile management, profile cards, import/export, or snapshot I/O to `SettingsWindow.qml`. Page-facing calls should go through `SettingsContext.qml`; normal Hyprland regeneration must continue to use `SettingsTransaction.qml`.
