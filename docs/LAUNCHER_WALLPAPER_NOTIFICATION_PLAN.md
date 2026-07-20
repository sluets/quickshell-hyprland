# Launcher, Wallpaper Picker, and Notification Expansion

**Status:** Implemented and live-tested through Rev 64
**Planned:** 2026-07-18
**Completed:** 2026-07-20
**Author:** GPT

## Purpose

This document began as the implementation plan for a shared customization block covering the app launcher, wallpaper picker, and notification popups. The work is now complete and this file records the approved architecture, behavior, and constraints.

The structural prerequisite was completed first: `SettingsWindow.qml` was reduced to a window host, page-facing state moved to `SettingsContext.qml`, staged Apply/Cancel state moved to `SettingsTransaction.qml`, and feature controls were placed in dedicated Settings pages.

## Final implementation

### App launcher — Revs 41–46

The launcher now supports two presentation modes while sharing one content implementation:

- **Attached to bar** — opens through the connected `BarPopout` presentation.
- **Centered on screen** — opens as a detached floating surface on the selected monitor.

Persisted and staged controls include:

- placement mode;
- horizontal and vertical offsets;
- show applications immediately when the launcher opens;
- favorites;
- launch-count ordering;
- hidden applications and maintenance controls.

The launcher model receives an explicit refresh when the shell starts so the initial application list does not remain empty until another model change occurs. Search, keyboard navigation, launching, favorites, usage tracking, and hidden-app filtering use the same shared content regardless of presentation mode.

The launcher row and maintenance-button radius fixes from Revs 44–45 are part of the approved baseline.

### Wallpaper picker — Revs 47–51

The wallpaper picker now uses the same attached/centered presentation model as the launcher:

- **Attached to bar** — connected `BarPopout` surface.
- **Centered on screen** — detached floating surface.
- X/Y offsets apply to the selected presentation.

The wallpaper body remains shared. Both modes use the same:

- configured wallpaper-library path;
- `.thumbs` cache;
- current-wallpaper marker;
- random/shuffle behavior;
- `awww` application path;
- transition configuration.

Wallpaper controls were consolidated into `widgets/Settings/pages/WallpaperPage.qml`. The old gear-menu wallpaper settings were removed; the gear now opens the full Settings window directly.

The approved transition list is intentionally limited to:

- Fade
- Wipe
- Wave
- Grow
- Random

### Notifications — Revs 52–64

Notifications now support two independent presentation modes:

- **Detached** — preserves the original corner-positioned floating cards and detached X/Y offsets.
- **On Bar** — attaches a notification stack to the active monitor's top bar using the shared connected-border language.

On-bar controls include:

- Left / Center / Right bar position;
- horizontal offset;
- optional attached card borders.

The bar exposes dedicated left, center, and right notification anchor items. `shell.qml` routes the notification surface to the focused bar and selected anchor.

The attached implementation is split into:

```text
widgets/Notifications/NotificationPopups.qml
widgets/Notifications/DetachedNotificationSurface.qml
widgets/Notifications/AttachedNotificationSurface.qml
widgets/Notifications/NotificationCards.qml
```

`NotificationPopups.qml` selects presentation. The two surfaces own geometry and window behavior. `NotificationCards.qml` owns shared card rendering and notification lifecycle behavior.

Approved animation behavior:

- New attached notifications reveal downward from the bar.
- Multiple notifications stack and expand the connected surface.
- Individual non-final cards fade and collapse upward before model removal.
- The final card retracts with the host surface into the bar.
- The bar-gap seam is released slightly before the host reaches zero height, allowing the bar border to rebuild underneath the final fillet instead of leaving visible empty frames.
- A new notification arriving during close cancels the close and keeps the surface active.

Attached card borders are optional. When disabled, the `BarPopout` owns the normal outer border. Critical notifications retain their urgent visual treatment.

## Settings ownership

These features follow the current Settings architecture:

- visible feature UI belongs in dedicated files under `widgets/Settings/pages/`;
- staged values, diffs, discard, and Apply orchestration belong in `SettingsTransaction.qml`;
- page-facing aliases and option models belong in `SettingsContext.qml`;
- persisted values and setters belong in `core/UserPrefs.qml`;
- writes are applied through `services/ConfigManager.qml`;
- `SettingsWindow.qml` remains a lifecycle and hosting component only.

Do not move these controls or transaction rules back into `SettingsWindow.qml`.

## Shared presentation rules

- Attached surfaces should reuse `widgets/TopBar/BarPopout.qml` and the bar-gap registration system rather than copying connected-border drawing code.
- Detached and attached shells should share the same feature content whenever practical.
- Placement logic must not duplicate application models, wallpaper scans, or notification models.
- Bar attachment must route to the correct monitor-specific `TopBar` instance.
- Edge-positioned notification popouts use a safe inset so both connection fillets can render; manual horizontal offset is applied after that baseline inset.
- Closing animations must coordinate popup visibility and bar-gap lifetime. Hiding the popup first and rebuilding the bar afterward produces exposed seam frames.

## Live-test status

The user confirmed:

- launcher attached and centered modes work;
- launcher initial application visibility, favorites, launch counts, and hidden-app controls work;
- wallpaper picker attached and centered modes work;
- wallpaper settings consolidation and transition cleanup work;
- detached notifications remain functional;
- attached notifications stack and grow the bar border correctly;
- Left / Center / Right attachment and horizontal offsets work;
- both connection fillets render at every position;
- optional attached card borders work;
- individual card exits and final host retraction work;
- the Rev 64 seam handoff substantially improves bar-border reconstruction during final retraction.

## Future extensions

The following are not part of this completed block:

- notification history;
- launcher width and maximum-result Settings controls;
- named launcher groups or folders;
- per-monitor independent placement preferences;
- wallpaper-driven dynamic color generation.

Any future work should build from the current live-tested files rather than the original plan-era implementations.
