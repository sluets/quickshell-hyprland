# Settings Architecture and Split Map

_Last updated 2026-07-18 by GPT for Rev 21._

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
    └── SddmPage.qml
```

## Ownership map after Rev 21

### `SettingsWindow.qml` — application shell

The window owns:

- `FloatingWindow` lifecycle and preferred dimensions;
- sidebar/navigation state;
- page hosting;
- shared popup hosting;
- instantiation of `SettingsTransaction`;
- connection of the transaction controller to pages and the pending footer;
- temporary compatibility aliases/functions preserving the pre-Rev-21 page API.

The window should not regain the full staged transaction. Rev 21 reduced it from 2,088 to 1,860 lines by moving that responsibility out.

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

## Transaction flow

For a normal Settings change:

1. A page writes a `staged...` value through the compatibility API.
2. `SettingsTransaction` computes the effective `shown...` value, so the control reflects the staged state immediately.
3. The controller compares staged and live values and generates `changes`.
4. `SettingsPendingFooter` renders that list but does not alter it.
5. Cancel calls the controller's discard path, clearing staged values and restoring live values.
6. Apply resolves all final values from the complete staged state, validates/converts them, and commits them through the existing persistence/configuration path.
7. Successful Apply clears staged state and therefore clears the pending list.

## Hyprland border-color rule

The final compositor border must be resolved centrally from the complete transaction:

- when Hyprland **Use theme color** is enabled, it follows the effective Appearance border selection;
- when Appearance uses the theme border, use the theme gradient;
- when Appearance uses a custom border, use that custom solid color;
- when Hyprland **Use theme color** is disabled, use its independent custom active-border value.

Do not reintroduce page-local bindings or saved-value reads during Apply. The controller must calculate one immutable final border snapshot before persistence so write order cannot change the result.

## Fixed-height pending footer

The pending panel intentionally keeps fixed geometry while changes are staged and unstaged. Do not make the footer height depend on `changes.length`, hide the panel when empty, or move it into a scrolling page. Those patterns previously caused the page viewport and Apply/Cancel controls to move while editing.

## Rev 21 live-test record

The user confirmed:

- staged settings appeared correctly as pending;
- Cancel restored staged controls correctly;
- a broad selection of settings was applied successfully;
- no obvious visual or behavioral regression appeared.

This was a broad smoke test, not an exhaustive test of every setting. A future isolated failure does not automatically invalidate the split; use the tracing checklist below.

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
