# Launcher, Wallpaper Picker, and Notification Expansion Plan

**Status:** Planned / deferred  
**Created:** 2026-07-18  
**Author:** GPT  

## Purpose

This document captures the next planned customization block for the app launcher, wallpaper picker, and notification popups.

The goal is to make all three surfaces support more consistent placement and visual behavior without turning `SettingsWindow.qml` into an even larger monolith.

No implementation should begin until the Settings structure is split enough that these controls can live in dedicated pages or components.

---

## Requested features

### 1. Notification popups that can grow out of the top bar

Add an optional notification presentation mode that visually connects the popup to the top bar.

In this mode:

- The notification should appear to expand from the bar rather than float as a separate card.
- The top-bar border should flow around the notification surface.
- The visual treatment should match the existing connected behavior used by the app launcher and wallpaper picker.
- Existing detached corner-positioned notifications must remain available.

Suggested setting:

- `Notification presentation`
  - `Detached popup`
  - `Connected to bar`

The connected mode will likely need:

- A shared bar-popout border/background component.
- Knowledge of which monitor and bar instance spawned the notification.
- Configurable horizontal alignment or attachment point.
- Correct clipping and corner radii where the notification joins the bar.
- A fallback to detached mode when no suitable bar instance exists.

This should reuse the existing top-bar popout language rather than creating a third unrelated border implementation.

---

### 2. App launcher placement modes

The app launcher should support both its current bar-connected position and a floating screen-centered position.

Suggested settings:

- `Launcher placement`
  - `Attached to bar`
  - `Centered on screen`
- `Launcher horizontal offset`
- `Launcher vertical offset`

Behavior:

- Attached mode preserves the current launcher behavior and connected bar border.
- Centered mode creates a detached floating launcher centered on the selected/current monitor.
- Offsets apply after centering.
- The launcher should open on the monitor associated with the active bar or pointer, depending on the existing project convention.
- Search, keyboard navigation, closing behavior, and result selection must remain identical in both placement modes.

The placement logic should be separated from the launcher content so both modes render the same launcher body.

---

### 3. Wallpaper picker placement modes

The wallpaper picker should receive the same placement model as the launcher.

Suggested settings:

- `Wallpaper picker placement`
  - `Attached to bar`
  - `Centered on screen`
- `Wallpaper picker horizontal offset`
- `Wallpaper picker vertical offset`

Behavior:

- Attached mode preserves the existing bar-connected picker.
- Centered mode displays the same wallpaper grid in a detached floating window.
- Offsets apply after centering.
- The existing shared wallpaper-library path and `.thumbs` cache remain authoritative.
- Selection, shuffle, thumbnail loading, and wallpaper application behavior must not be duplicated between placement modes.

The picker body should be extracted from the current positioning shell before adding the second placement mode.

---

### 4. Launcher initial app visibility

The launcher currently opens empty and shows no application results until typing begins. This was intentional, but it should become configurable.

Suggested setting:

- `Show applications when launcher opens`
  - Off: preserve current blank-until-search behavior.
  - On: show an initial application list immediately.

The initial list should use the existing launcher model and filtering pipeline rather than a second application model.

Possible initial ordering:

1. Frequently used applications, if usage tracking is ever added.
2. Alphabetical applications.
3. Existing desktop-entry/model order as the simplest first implementation.

For the first version, alphabetical or existing model order is sufficient. Usage tracking should not be added as part of this feature unless separately approved.

The launcher must still reset the search field when opened unless a future setting explicitly changes that behavior.

---

## Shared placement model

The launcher and wallpaper picker should not each invent separate placement settings and geometry code.

Create a shared placement concept with values such as:

- `bar`
- `center`

And shared behavior for:

- Target monitor selection.
- Center calculation.
- X/Y offsets.
- Screen-edge clamping.
- Detached versus connected corner radii.
- Opening and closing animation origin.

A reusable component or helper could own the detached window geometry while the existing `BarPopout` path continues to own attached mode.

Do not force attached and centered modes into one giant component if that creates fragile conditional anchors. Prefer a shared content component hosted by two small presentation shells.

---

## Settings organization

These controls should not be added directly to the remaining 2,000+ line body of `SettingsWindow.qml`.

Recommended pages:

### Launcher page

- Placement mode.
- X/Y offsets.
- Show applications on open.
- Future launcher width and maximum-result settings.

Suggested file:

```text
widgets/Settings/pages/LauncherPage.qml
```

### Wallpaper page or Appearance subsection

The wallpaper-library path is currently part of Appearance. The picker-specific placement controls could either:

- Remain in a dedicated `WallpaperPage.qml`, or
- Live in a smaller extracted `WallpaperSettingsSection.qml` hosted by Appearance.

A dedicated page is preferable if more wallpaper controls are expected.

Suggested file:

```text
widgets/Settings/pages/WallpaperPage.qml
```

### Notifications page

Extend the existing:

```text
widgets/Settings/pages/NotificationsPage.qml
```

Add:

- Detached versus connected presentation.
- Attachment/alignment controls only when connected mode is selected.
- Preserve the existing corner and offset settings for detached mode.

---

## Estimated code growth

The features themselves are not enormous, but they touch several presentation layers.

Rough estimate:

| Area | Estimated added lines |
|---|---:|
| Shared placement/helper components | 150–300 |
| Launcher placement and initial-list behavior | 150–300 |
| Wallpaper picker dual presentation | 200–400 |
| Connected notification presentation | 250–500 |
| Settings controls and persistence | 250–450 |
| Tests, comments, and compatibility handling | 100–250 |
| **Likely total** | **1,100–2,200** |

This does not mean `SettingsWindow.qml` should grow by that amount. With proper page extraction, most settings growth should land in dedicated page files and shared components.

Without cleanup first, the Settings window could absorb another 300–600 lines of staging, Apply/Cancel plumbing, loaders, and controls. That would make future work substantially riskier.

---

## Required structural work before implementation

Before building this feature block:

1. Finish extracting remaining page-specific controls and staged values from `SettingsWindow.qml`.
2. Create `LauncherPage.qml` before adding launcher controls.
3. Decide whether wallpaper controls become `WallpaperPage.qml` or a dedicated Appearance component.
4. Keep notification controls in `NotificationsPage.qml` and move any remaining notification state there.
5. Extract reusable popup content from `Launcher.qml` and `WallpaperPicker.qml` before adding centered presentation shells.
6. Reuse or extend `BarPopout.qml` for connected notification visuals rather than copying its border logic.
7. Add persisted properties to `UserPrefs.qml` and staging support through the normal Settings Apply/Cancel path.
8. Implement and test one surface at a time.

Recommended implementation order:

1. Launcher initial-app visibility toggle.
2. Shared detached placement helper.
3. Centered launcher mode.
4. Centered wallpaper picker mode.
5. Connected notification mode.

The notification work is last because it has the most interaction with monitor selection, timing, stacking, and bar geometry.

---

## Acceptance criteria

### Launcher

- Can switch between attached and centered placement.
- Centered placement honors X/Y offsets.
- Existing keyboard navigation and search behavior remain unchanged.
- Initial application visibility can be enabled or disabled.
- No duplicate desktop-entry model is introduced.

### Wallpaper picker

- Can switch between attached and centered placement.
- Centered placement honors X/Y offsets.
- Uses the same wallpaper library and `.thumbs` cache in both modes.
- No duplicate wallpaper scanning or application logic is introduced.

### Notifications

- Detached mode remains fully functional.
- Connected mode visually grows from the bar.
- Border/background connection matches launcher and wallpaper picker styling.
- Multiple notifications stack correctly.
- Notifications remain usable when the bar is hidden, missing, or on another monitor.

### Settings

- New controls live in dedicated pages/components.
- Apply/Cancel behavior remains consistent.
- `SettingsWindow.qml` does not materially grow as a result of this feature block.

---

## Decision

**Split the Settings structure further before implementing this block.**

The requested features are reasonable and fit the project, but adding them directly to the current Settings monolith would create avoidable bloat. The correct next step is targeted structural extraction—not a full rewrite—followed by incremental implementation and live testing.
