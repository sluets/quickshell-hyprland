# Settings Architecture and Split Map

_Last updated 2026-07-19 by GPT through Rev 29._

This is the authoritative ownership map for Settings. New work must follow it from the first revision so `SettingsWindow.qml` never becomes a monolith again.

## Current structure

```text
widgets/Settings/
├── SettingsWindow.qml
├── SettingsContext.qml
├── SettingsTransaction.qml
├── components/
│   ├── SettingsView.qml
│   ├── SettingsOverlays.qml
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

## Ownership map through Rev 29

### `SettingsWindow.qml` — window host only

Owns only:

- `FloatingWindow` creation and preferred geometry;
- open/show/close/toggle lifecycle;
- Escape handling;
- native window movement;
- creation-size tracking and the daily snapshot trigger;
- mounting `SettingsContext` and `SettingsView`;
- a very small number of externally required compatibility wrappers.

It must not own page UI, staged settings, pending diffs, dropdown implementations, color pickers, or feature-specific system integration. Rev 29 reduced it to 495 lines.

### `SettingsContext.qml` — page-facing facade

Owns:

- the `SettingsTransaction` instance;
- staged compatibility aliases and `shown...` forwards consumed by pages;
- pending-change exposure and Apply/Cancel coordination;
- current page and page models;
- shared option models such as fonts, corners, transitions, and monitors;
- dropdown open state and shared color-picker state;
- forwards for window close/move and UI Profiles Hyprland reapply.

The context is the compatibility boundary between pages/components and the underlying transaction/window. New pages should receive this context rather than reaching into the window host.

### `SettingsTransaction.qml` — staged state and commit logic

Owns:

- every normal `staged...` property;
- every staged-or-live `shown...` value;
- the computed pending-change list;
- discard/reset behavior;
- validation and conversion;
- Apply ordering and persistence;
- final Hyprland border resolution;
- the normal post-profile-restore Hyprland reapply path.

### `SettingsView.qml` — visible Settings shell

Owns:

- titlebar and close button;
- sidebar navigation and headings;
- page viewport and all page instances;
- scrolling and draggable scrollbar;
- pending footer placement;
- overlay mounting.

It receives the window host and `SettingsContext`; it does not own persistence.

### `SettingsOverlays.qml` — shared popup layer

Owns the theme, font, and wallpaper-transition dropdowns, click-outside dismiss surfaces, shared preset color picker, and popup positioning/clamping. It stays mounted at the card/view level so popups are not clipped by page content.

### `SettingsPendingFooter.qml` — presentation only

Renders pending changes, status/error/output text, and Apply/Cancel controls. It emits requests but never computes or persists settings.

### Page files — one feature/page per file

Pages own labels, controls, and page-specific presentation. They stage values through `SettingsContext`. A page must not directly write durable preferences or grow system scripts inline.

### SDDM — separate privileged transaction

SDDM remains outside the normal desktop Apply transaction. Preserve Test mode, snapshot generation, digest checks, explicit privileged Apply, and reboot verification.

### UI Profiles

`UiProfilesPage.qml` owns confirmation/status/orchestration. `scripts/settings-profile.sh` owns snapshot file operations. `UserPrefs.reloadFromDisk()` and `preferencesReloaded()` provide the restore handshake. Only after reload confirmation does the page request `SettingsTransaction.reapplyCurrentHyprland()` through the context/window bridge. No fixed timer is allowed.

## Normal transaction flow

1. A page stages a value through `SettingsContext`.
2. `SettingsTransaction` exposes the effective `shown...` value.
3. The transaction rebuilds the pending diff.
4. `SettingsPendingFooter` displays it.
5. Cancel calls `discardStaged()`.
6. Apply resolves the complete staged state, validates it, persists it, and clears staging after success.

## UI Profiles restore flow

1. `settings-profile.sh restore` atomically replaces `user-prefs.json` and restores the wallpaper when available.
2. Open staged values are discarded.
3. `UserPrefs.reloadFromDisk()` is called.
4. `UserPrefs.preferencesReloaded()` confirms the reload on the next Qt event-loop turn.
5. The guarded waiting page requests Hyprland reapply through the normal transaction/generator path.

## Permanent development rules

1. **Window host stays small.** New features may add only minimal mounting/wiring to `SettingsWindow.qml`.
2. **New tab = new page file.** Start with `pages/<Feature>Page.qml`; never prototype a full tab inside the window.
3. **Shared visible UI goes in `components/`.** Dropdowns, dialogs, cards, footers, and reusable controls do not belong in the host.
4. **Staging belongs in `SettingsTransaction.qml`.** Add staged value, shown value, pending diff, discard, validation, and Apply together.
5. **Page-facing API belongs in `SettingsContext.qml`.** Add aliases/models/forwards there, not to the window.
6. **System/file operations use scripts or services.** Do not bury large shell/file logic inside page QML.
7. **No block-commented feature corpses.** Deferred features get a short note and a planning document, not hundreds of disabled lines.
8. **Keep structure and behavior revisions separate where practical.** Large moves get a focused regression pass before adding behavior.
9. **Update this document in the same feature block.** Do not allow changelog or ownership drift.
10. **Use the newest approved parent.** Never rebuild Settings work from an older archived monolith.

## Required regression test after Settings structural work

- launch with no parser errors or warnings;
- visit every page;
- test dropdowns and color pickers;
- stage several values across multiple pages and verify pending rows;
- Cancel and verify full reversion;
- stage again, Apply, and verify persistence;
- close with pending changes and verify intended discard behavior;
- restore `My Default` and verify UI, wallpaper, and Hyprland output;
- test SDDM separately through its own workflow.

## Troubleshooting a single setting

Trace in this order:

1. staged property in `SettingsTransaction.qml`;
2. matching `shown...` expression;
3. pending-diff entry;
4. discard assignment;
5. Apply validation/conversion/persistence;
6. `SettingsContext` alias or forward;
7. page binding/control.

Symptom guide:

- changes visually but no pending row: diff entry;
- pending works but Cancel fails: shown/discard path;
- Cancel works but Apply fails: Apply path or `ConfigManager`;
- one page cannot resolve a name: context alias/forward;
- restored values exist but Hyprland does not change: reload handshake or reapply bridge;
- popup does not resolve: explicit sibling import and qualified component type.
