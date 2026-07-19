# Settings Architecture and Split Map

_Last updated 2026-07-19 by GPT through Rev 25._

This document records the current ownership boundaries inside the Quickshell Settings application. It exists so future structural work does not accidentally mix presentation with persistence, regress Apply/Cancel, or rebuild from an older `SettingsWindow.qml` parent.

## Current structure

```text
widgets/Settings/
├── SettingsWindow.qml
├── SettingsTransaction.qml
├── components/
│   ├── SettingsPendingFooter.qml
│   └── reusable Settings controls...
└── pages/
    ├── AppearancePage.qml
    ├── DesktopPage.qml
    ├── HyprlandPage.qml
    ├── NotificationsPage.qml
    ├── SddmPage.qml
    └── UiProfilesPage.qml

scripts/
└── settings-profile.sh
```

## Ownership map through Rev 25

### `SettingsWindow.qml` — application shell

The window owns:

- `FloatingWindow` lifecycle and preferred dimensions;
- sidebar/navigation state;
- page hosting;
- shared popup hosting;
- instantiation of `SettingsTransaction`;
- connection of the transaction controller to pages and the pending footer;
- temporary compatibility aliases/functions preserving the pre-Rev-21 page API.

The window should not regain the full staged transaction. Rev 21 reduced it from 2,088 to 1,860 lines by moving that responsibility out. Rev 25 then removed the dormant Displays prototype and reduced the file again from 1,866 to 1,487 lines.

### `SettingsTransaction.qml` — staged transaction controller

The controller owns:

- all global `staged...` properties;
- all staged-or-live `shown...` effective values;
- pending-change derivation (`changes`);
- `discardStaged()` and reset behavior;
- validation and conversion helpers used during Apply;
- normal Settings Apply ordering and persistence;
- final Hyprland active-border resolution from the complete staged state.

This is now the first file to inspect when a control stages correctly but fails to appear in pending changes, fails to cancel, or fails to persist.

### Compatibility aliases in `SettingsWindow.qml`

Rev 21 deliberately kept old property and function names available from the window. Existing pages therefore continue to use their previous bindings without being rewritten simultaneously. This is migration scaffolding, not duplicated ownership: the controller remains authoritative.

Do not remove these aliases piecemeal. Converting pages to use the controller directly should be a separate revision, done from the latest approved parent, with a full multi-tab regression test.

### `SettingsPendingFooter.qml` — presentation only

The footer owns:

- pending-change heading and count;
- fixed three-line pending list;
- empty-state text;
- `ConfigManager` status/error/output display;
- Cancel and Apply button presentation;
- `cancelRequested()` and `applyRequested()` signals.

It does not own staged state, diff generation, persistence, or transaction ordering.

### Page files — controls and page presentation

Pages own page-specific layout, labels, controls, and interactions. They consume effective values and assign staged values through the current window compatibility API. A page must not write durable preferences directly merely because its control is visible there.

### SDDM page — separate privileged workflow

SDDM retains a separate Test/preview and root-owned install path. The normal desktop Settings transaction must not silently install SDDM files. Preserve the manual Apply model, temporary user-owned preview, digest checks, and privileged helper boundary.

### `UiProfilesPage.qml` — restore-point presentation and orchestration

The UI Profiles page owns only the user interaction around the current single `My Default` snapshot:

- save/overwrite and restore buttons;
- confirmation dialogs;
- status, timestamp, and saved-wallpaper display;
- launching the profile helper;
- discarding open staged values after a successful restore;
- explicitly requesting `UserPrefs.reloadFromDisk()` after the helper restores the JSON;
- waiting for `UserPrefs.preferencesReloaded()` before requesting the post-restore Hyprland reapply through the Settings-window compatibility API.

It does not copy files itself and does not own normal staged settings. Snapshot file operations belong to `scripts/settings-profile.sh`; normal Apply and the Hyprland generator remain owned by `SettingsTransaction`/`ConfigManager`.

### `scripts/settings-profile.sh` — user-owned snapshot I/O

The helper currently supports `save`, `restore`, and `status` for one profile at:

```text
~/.local/state/quickshell/ui-profiles/my-default/
├── user-prefs.json
└── wallpaper.txt
```

`save` copies the complete persisted preference JSON and records the current `awww` wallpaper path. `restore` atomically replaces the live preference JSON and restores the wallpaper when the referenced file exists. It performs no Hyprland generation and no privileged SDDM work.

### Post-restore Hyprland side effect — Rev 24

Replacing `user-prefs.json` updates persisted values, but Hyprland also depends on the separately generated `appearance.lua`. After restore, `UiProfilesPage` waits briefly for `UserPrefs` to reload, then calls `SettingsWindow.reapplyCurrentHyprland()`, which delegates to `SettingsTransaction.reapplyCurrentHyprland()`. The controller submits the restored Hyprland values through the normal `ConfigManager.applyChanges()` generator path.

Do not reimplement this with fake slider changes, direct writes from the page, or a second Hyprland generator in the profile script.

## Transaction flow

For a normal Settings change:

1. A page writes a `staged...` value through the compatibility API.
2. `SettingsTransaction` computes the effective `shown...` value, so the control reflects the staged state immediately.
3. The controller compares staged and live values and generates `changes`.
4. `SettingsPendingFooter` renders that list but does not alter it.
5. Cancel calls the controller's discard path, clearing staged values and restoring live values.
6. Apply resolves all final values from the complete staged state, validates/converts them, and commits them through the existing persistence/configuration path.
7. Successful Apply clears staged state and therefore clears the pending list.


## UI Profiles restore flow

1. The user confirms **Restore My Default**.
2. `UiProfilesPage` runs `settings-profile.sh restore`.
3. The helper atomically replaces the live `user-prefs.json` and asks `awww` to restore the saved wallpaper when available.
4. The page clears any values staged in the currently open Settings transaction.
5. After a short delay, the page requests `reapplyCurrentHyprland()`.
6. `SettingsTransaction` reads the reloaded `UserPrefs` values and submits the Hyprland subset through `ConfigManager.applyChanges()`.
7. The existing generator rebuilds the compositor appearance output and Hyprland reloads through the normal path.

The delay is intentional: firing the reapply in the same event as the file replacement can read the previous in-memory singleton values.

## Hyprland border-color rule

The final compositor border must be resolved centrally from the complete transaction:

- when Hyprland **Use theme color** is enabled, it follows the effective Appearance border selection;
- when Appearance uses the theme border, use the theme gradient;
- when Appearance uses a custom border, use that custom solid color;
- when Hyprland **Use theme color** is disabled, use its independent custom active-border value.

Do not reintroduce page-local bindings or saved-value reads during Apply. The controller must calculate one immutable final border snapshot before persistence so write order cannot change the result.

## Fixed-height pending footer

The pending panel intentionally keeps fixed geometry while changes are staged and unstaged. Do not make the footer height depend on `changes.length`, hide the panel when empty, or move it into a scrolling page. Those patterns previously caused the page viewport and Apply/Cancel controls to move while editing.

## Rev 21–25 live-test record

The user confirmed:

- staged settings appeared correctly as pending;
- Cancel restored staged controls correctly;
- a broad selection of settings was applied successfully;
- no obvious visual or behavioral regression appeared.

For UI Profiles Rev 22–24, the user deliberately pushed most UI controls to extreme values, applied them, and restored the saved default successfully. Wallpaper and Hyprland output restored correctly after the Rev 24 reapply fix. Rev 25 replaced the fixed restore delay with an explicit reload handshake; another broad test changed and restored a large set of UI/Hyprland values with no warnings or regressions.

This was broad, aggressive live testing, not an exhaustive test of every possible combination. A future isolated failure does not automatically invalidate the split; use the tracing checklist below.

## Troubleshooting a single setting after Rev 21

Check the setting in this order inside `SettingsTransaction.qml`:

1. **Stage declaration:** Does the matching `staged...` property exist with the correct type/default sentinel?
2. **Effective value:** Does its `shown...` expression correctly choose staged versus live state?
3. **Pending diff:** Does `changes` include the setting with correct comparison and labels?
4. **Cancel:** Does `discardStaged()` return it to the unstaged sentinel/value?
5. **Apply:** Does `apply()` validate, convert, and persist the final value?
6. **Compatibility bridge:** Does `SettingsWindow.qml` expose the exact property/function name the page expects?

Common symptom mapping:

- Control changes, but no pending row: check step 3.
- Pending row appears, but Cancel does not restore: check steps 2 and 4.
- Pending and Cancel work, but Apply does nothing: check step 5 and `ConfigManager.busy/lastError`.
- Only one page breaks after alias cleanup: check step 6 and restore the alias until a dedicated page-migration revision.
- Border result depends on staging order: centralized final-border resolution has been bypassed or regressed.
- Profile restores saved values but Hyprland visuals do not change: verify `UserPrefs.reloadFromDisk()` is called, `preferencesReloaded` is received while `awaitingProfileReload` is true, `SettingsWindow.reapplyCurrentHyprland()` delegates correctly, `ConfigManager.busy` is empty, and `SettingsTransaction.reapplyCurrentHyprland()` submits the restored values.
- Profile settings restore but wallpaper does not: inspect `wallpaper.txt`, confirm the path still exists, and test `awww img` independently. Missing wallpaper files are non-fatal by design.
- UI Profiles logs an undefined QColor warning: verify all color tokens exist in `core/Theme.qml`; Rev 23 replaced the invalid `Theme.colorBorder` reference.


## Rev 25 profile-reload handshake

UI Profiles must not use a guessed delay after replacing `user-prefs.json`. The required sequence is:

1. the helper atomically restores the preference file;
2. the page discards any open staged values and marks itself as awaiting reload;
3. the page calls `UserPrefs.reloadFromDisk()`;
4. `UserPrefs` reloads its `FileView` and emits `preferencesReloaded()` on the next Qt event-loop turn;
5. only the waiting UI Profiles page consumes that signal and calls `reapplyCurrentHyprland()`.

Keep the `awaitingProfileReload` guard. `preferencesReloaded` is a singleton-wide signal and must not trigger Hyprland regeneration for unrelated reload requests.

## Displays status after Rev 25

Displays remains a future feature. The incomplete, block-commented prototype and dummy transaction plumbing were removed from `SettingsWindow.qml`. Do not paste that dead implementation back into the window. A future Displays page must begin with a real `services/DisplayManager.qml` (or an equivalent current Hyprland-backed service), then add staged/apply behavior as a separately tested feature revision.

## Full regression checklist for future Settings structural work

Stage at least one obvious setting on every normal Settings tab, then verify:

1. every staged change appears in the footer;
2. controls immediately display their effective staged values;
3. nothing touches disk before Apply;
4. Cancel returns every staged control to its live value;
5. stage the same values again and Apply them;
6. all tabs commit in one transaction;
7. pending rows clear after successful Apply;
8. status/busy/error text remains visible;
9. footer geometry stays fixed while staging and scrolling;
10. Apply remains disabled while `ConfigManager` is busy;
11. custom and theme-derived Hyprland border paths both resolve correctly;
12. closing Settings with uncommitted changes still follows the intended discard behavior.

SDDM requires its own Test mode and, for installed behavior, its explicit privileged Apply/reboot path. It is not part of the quick normal-transaction smoke test.

## Recommended next structural work

Do not immediately combine another large Settings split with new launcher, wallpaper-picker, or notification features. Rev 21 should be committed as a checkpoint first.

Possible later cleanup:

- migrate pages from window compatibility aliases to an explicit transaction-controller reference;
- remove aliases only after every consumer is converted and tested;
- extract additional large presentation-only sections from `SettingsWindow.qml` where ownership is unambiguous;
- keep behavior changes separate from structural changes.
