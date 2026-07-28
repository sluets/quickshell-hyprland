# Shell Visual Polish Plan

_Canonical implementation plan — replaces `SETTINGS_POLISH_PLAN.md` and `SHELL_DESIGN_SYSTEM.md`._

_Created 2026-07-26. This document changes how the shell looks, not how it works. Existing architecture, transaction, geometry, performance, and workflow invariants remain authoritative._

---

## 1. Goal

The shell is functionally complete. The remaining work is a visual-polish pass that gives Settings and the rest of the Quickshell desktop a consistent hierarchy without destabilizing working behavior.

The guiding rule is:

> Stop drawing full-strength lines around everything. Start placing things on deliberate visual layers.

This is one shared design system applied across Settings, Music, popouts, Launcher, notifications, Clipboard, Calculator, and the remaining shell surfaces. It is not a collection of unrelated redesigns.

---

## 2. Diagnosis

The current UI is capable and structurally sound, but many surfaces still read as functional forms or developer-default panels because the same habits repeat throughout the project:

1. **No grouping surface.** Related controls often sit directly on the window background and are separated only by labels or spacing.
2. **Weak typographic hierarchy.** Labels, values, and explanations often carry equal visual weight.
3. **Border-heavy styling.** Full-opacity muted borders are used as decoration rather than to communicate focus, error, or floating boundaries.
4. **Uniform density.** Bar-scale spacing tokens are reused in full settings pages and application windows, producing one flat rhythm.
5. **Improvised active-state language.** Selection, staged changes, current track, and active tabs do not yet share a coherent visual grammar.
6. **Duplicated local styles.** Several surfaces solve the same visual problem independently instead of sharing primitives.

The existing Music library and queue panes already demonstrate the better direction: rounded surface containers, title/subtitle hierarchy, and clear internal structure. The polish pass should generalize that success.

---

## 3. Non-negotiable invariants

Aesthetic changes must not violate any of the following:

- Settings stable geometry:
  - fixed card width
  - top-anchored content
  - fixed-height pending footer
  - no layout movement when staging or unstaging values
- Existing Settings transaction model:
  - staged values
  - Apply/Discard behavior
  - page-facing compatibility through `SettingsContext`
- Dropdown overlay positioning and anchor geometry
- Whole-row click behavior for toggle rows
- Long-list performance:
  - `ListView`
  - `reuseItems`
  - no delegate inflation that harms the 10,000–20,000-track Music case
- Launcher churn-avoidance and keyboard navigation
- Empty-input-region click-through behavior for OSD and desktop furniture
- Existing Hyprland/compositor borders
- SDDM preview/install workflow behavior
- The disabled-not-deleted compact Music popout

This is a reskin and component-consolidation project, not an architectural rewrite.

---

## 4. Shell-wide design system

### 4.1 Elevation ladder

Define one derived elevation ladder in `core/Theme.qml` and use it everywhere:

```qml
// Level 0: window, page, and popout ground
readonly property color colorGround: active.colorBackground

// Level 1: grouped surfaces and cards
readonly property color colorCard: active.colorSurface

// Level 2: interactive controls
readonly property color colorControl:
    Qt.tint(active.colorSurface, Qt.alpha(active.colorForeground, 0.06))

// Level 3 already exists
// Theme.colorHover: hover, selected, and transient emphasis

readonly property color colorDivider:
    Qt.alpha(active.colorMuted, 0.18)

readonly property color colorCardBorder:
    Qt.alpha(active.colorMuted, 0.25)

readonly property int radiusLarge:
    Math.round(radiusMedium * 1.8)

readonly property int spacingXLarge:
    spacingLarge + spacingMedium
```

Every visible rectangle should have a clear level:

- **Level 0 — `colorGround`**: page/window background
- **Level 1 — `colorCard`**: cards, list panes, grouped panels
- **Level 2 — `colorControl`**: buttons, fields, dropdowns, steppers, segmented controls
- **Level 3 — `colorHover`**: hover and selected states

Widgets must read the shared `Theme.*` forwards rather than computing local `Qt.lighter()` or alpha variants inline.

No required token is added to every theme file. A specific theme may define an optional override only when the derived ladder genuinely fails during the final theme sweep.

### 4.2 Border policy

Borders communicate meaning rather than decorate every surface:

- Default card/control state: **no border**
- `colorCardBorder`: floating surfaces that need an edge against arbitrary content
- `colorAccent`, 1px: focus, open dropdown, or active editing
- `colorUrgent`, 1px: invalid input or destructive confirmation
- Existing Hyprland/compositor window borders remain unchanged

A full-opacity `border.color: Theme.colorMuted` becomes a conversion candidate unless it is a documented floating-edge case.

### 4.3 Typography and descriptions

Use three levels where useful:

- Page title: existing heading treatment
- Row label: normal foreground text
- Description/supporting text: approximately `0.8 × fontSize`, muted

Descriptions are **selective**, not mandatory.

Add a description when:

- the label is ambiguous
- the setting has an important consequence
- two similar controls need distinction
- a restart, reload, or external action is required

Do not add descriptions that merely restate an obvious label.

### 4.4 Section headers

Use explicit uppercase section labels rather than simulated small caps:

```text
APPEARANCE
NOTIFICATIONS
BORDERS
```

Treatment:

- muted color
- restrained letter spacing
- minimum readable font-size floor
- large separation from the previous section
- small separation from the card it owns

### 4.5 Active versus staged states

Do not make active selection and unapplied edits visually identical.

Use these meanings:

- **Full-height 3px accent bar**: current/selected/active item
  - active Settings sidebar page
  - current Music track
  - selected artist/album
  - active tab
- **Short edited gutter marker plus accent label tint**: staged Settings value
  - marker stays inside permanently reserved left padding
  - no text prefix
  - no control or label movement

This gives the shell one coherent active-state language while preserving a distinct “changed but not yet applied” state.

### 4.6 Animation policy

- No layout animations in Settings or other stable-geometry surfaces
- Color and hover transitions only
- Use existing duration/easing tokens
- No `DropShadow` or layer-backed shadow effects during this project

The elevation ladder must provide hierarchy without introducing rendering instability.

---

## 5. Shared primitives

The rollout should leave fewer bespoke styles than it started with.

### 5.1 Settings primitives

All Settings-specific components remain in `widgets/Settings/components/`.

#### `SettingsCard.qml` — new

- Level-1 rounded grouping surface
- `radiusLarge`
- horizontal card padding
- optional low-opacity card border only if theme testing proves necessary
- inset dividers between visible rows
- conditional rows must not leave orphan dividers

#### `SettingsRowBase.qml` — new, deliberately thin

Own only the truly shared anatomy:

- left label column
- optional description
- reserved staged-marker gutter
- right-side control slot
- minimum row height
- hover policy

It must not become a rigid universal layout engine. Toggle, Stepper, Option Picker, Hex Color, and specialized rows retain ownership of their control geometry and any exceptional sizing.

#### `SettingsSectionHeader.qml` — new

- uppercase muted section label
- standardized section spacing

#### Existing rows — restyle, contracts unchanged

- `ToggleSettingRow.qml`
- `StepperRow.qml`
- `OptionPickerRow.qml`
- `HexColorRow.qml`
- `CollapsibleSection.qml`

Add optional `description` support where appropriate, but preserve signals, value bindings, staging behavior, and footprints.

### 5.2 Cross-shell primitives

Promote components to a shared/common location only when a second real consumer appears.

Expected reusable primitives:

- elevation tokens
- segmented control
- title/subtitle row
- quiet Level-2 button
- accent progress bar
- section header

Do not create speculative abstractions before reuse exists.

---

## 6. Settings visual specification

### 6.1 Card pattern

Each logical group becomes:

```text
APPEARANCE
┌────────────────────────────────────────┐
│ Theme                              [▾] │
│   Choose the palette used by the shell │
│ ────────────────────────────────────── │
│ Font family                        [▾] │
│ ────────────────────────────────────── │
│ Font scale                      − 1.0 +│
└────────────────────────────────────────┘
```

Card rules:

- fill: `Theme.colorCard`
- radius: `Theme.radiusLarge`
- default border: none
- divider: `Theme.colorDivider`
- gap between cards: `Theme.spacingXLarge`

### 6.2 Row anatomy

A standard row contains:

- label and optional description on the left
- natural-width control on the right
- reserved left gutter for staged marker
- minimum height near `fontSize * 2.6`

Only whole-row-interactive rows receive full hover treatment and a pointing cursor.

### 6.3 Control treatment

#### Dropdowns

- closed: Level-2 fill, no border
- hover: `colorHover`
- open: accent border, existing squared bottom corners preserved
- overlay list keeps a reduced floating-edge border
- geometry and anchor mapping must remain unchanged

#### Steppers

Use one unified pill:

```text
[ − ]   value   [ + ]
```

- Level-2 group fill
- hover only on minus/plus cells
- existing footprint retained

#### Segmented controls

- Level-2 group background
- selected segment uses Level-3 fill and accent text or active indicator
- shared later with Music tabs and Launcher chips

#### Hex fields

- Level-2 fill
- no default border
- accent border on focus
- urgent border on invalid input

#### Toggle switches

Keep existing behavior and geometry. Only adjust surrounding row/card colors if required.

### 6.4 Sidebar and header

Sidebar:

- Nerd Font icon per page
- slightly taller items
- restrained gap between items
- active item uses Level-1 pill plus full-height accent bar
- active text remains accent and bold

Page header:

- title
- one-line muted page description
- `spacingLarge` before first section

Pending footer:

- fixed reserved height unchanged
- Level-1 surface strip
- top divider
- Apply: filled accent button
- Discard/Cancel: quiet Level-2 button
- pending-count indicator may use a small accent dot

---

## 7. Surface-by-surface application

### 7.1 Settings

Settings is the first implementation target because it creates the shared tokens and primitives.

### 7.2 Music

Music is the first non-Settings proof and the highest-value daily-driver surface.

#### Now-playing card

Wrap Music panel and spectrum into one Level-1 player-head card:

- artwork clipped by radius, no full muted border
- metadata and transport share one grouped hierarchy
- spectrum belongs to the same card

#### Transport

- previous/play/next/shuffle/repeat in a Level-2 grouped pill
- play/pause may use a filled accent treatment as the dominant action
- preserve existing press-scale feedback

#### Progress

- Level-2 track
- accent fill
- slightly thicker
- hover-revealed handle
- do **not** add elapsed/total labels unless explicitly requested later

#### Tabs

- Library / All Songs / Queue use the shared segmented-control primitive
- Refresh/Clear become quiet Level-2 buttons, not reused tab components

#### Lists

- keep existing Level-1 panes
- current track uses the active accent bar
- selected artist/album uses the same active motif
- column separators use `colorDivider`
- no delegate item-count increase for visual polish

#### Search

- Level-2 fill
- no border until focus

### 7.3 Bar popouts

Applies to Wi-Fi, Bluetooth, System Menu, Volume, Clock Tools, and Music indicator.

- preserve `BarPopout` outer frame
- internal rows use ladder colors
- Device rows gain title/subtitle hierarchy
- section separators use `colorDivider`
- whole-row interactions remain intact

### 7.4 Launcher

- Level-2 search field with accent focus
- selected result uses Level-3 fill plus active accent bar
- result rows use title/subtitle anatomy where `.desktop` metadata provides it
- category/favorite chips adopt segmented-control language
- model churn and keyboard navigation remain untouched

### 7.5 Notifications

Notification popups float over arbitrary content, so they retain a reduced `colorCardBorder` edge.

- normal notifications use quiet floating-edge border
- urgent notifications earn the urgent border
- action buttons become Level-2 controls
- existing app-name/body hierarchy remains

### 7.6 Clipboard and Calculator

- Clipboard rows adopt title/subtitle anatomy and active selection language
- Calculator display becomes a Level-1 card
- keypad buttons become Level-2 controls
- existing calculator and unit-converter behavior remains unchanged

### 7.7 Power Screen and OSD

- Power buttons use Level-2 fills
- destructive confirmation uses urgent-border meaning
- Volume OSD receives color-only ladder treatment
- no geometry or click-through changes
- Desktop Clock remains exempt as wallpaper furniture

---

## 8. Implementation phases

Every phase begins from a clean Git state and ends with a regression checkpoint. Do not queue unrelated features during this work.

### Phase 0 — baseline capture

Before code changes, capture consistent screenshots using one theme and fixed window sizes:

- Settings Notifications
- Settings Appearance
- Music Library
- one bar popout
- Launcher
- Calculator

These are the visual comparison baseline.

### Phase 1 — tokens, primitives, and Notifications proof

Implement:

- derived Theme tokens
- `SettingsCard`
- thin `SettingsRowBase`
- `SettingsSectionHeader`
- Toggle row restyle
- Stepper row restyle
- Notifications page conversion

Exit criteria:

- staging moves zero pixels
- edited marker uses reserved gutter
- all existing Notifications behavior works
- conditional rows leave no orphan dividers
- card/control/ground hierarchy is visible in several themes

Stop and use this page before continuing.

### Phase 2 — risky controls and Appearance

Implement:

- dropdown restyle
- overlay-list polish
- HexColorRow restyle
- segmented OptionPickerRow
- Appearance page conversion

Exit criteria:

- overlays align at font scale 1.0 and one non-default scale
- dropdown open/close geometry is unchanged
- custom theme editor remains fully functional
- no Settings transaction regressions

### Phase 3 — Music proof

Apply the design system to Music before converting every remaining Settings page.

Purpose:

- prove that primitives and tokens generalize outside Settings
- correct abstractions before mechanical rollout

Exit criteria:

- no music-library performance regression
- transport, seek, tabs, queue, album art, CAVA, keyboard controls, and notifications still work
- no new process/socket churn

### Phase 4 — remaining Settings and chrome

Convert:

- Wallpaper
- Desktop
- Music settings
- Launcher settings
- Hyprland
- UI Profiles
- SDDM collapsible sections
- Custom Theme
- sidebar
- page descriptions
- pending footer
- titlebar spacing

### Phase 5 — shell surfaces

Convert independently, one surface per checkpoint where practical:

1. Bar popouts
2. Launcher
3. Notifications
4. Clipboard
5. Calculator and Unit Converter
6. Power Screen
7. Volume OSD color pass

### Phase 6 — theme sweep and cleanup

Cycle every built-in theme plus Custom Theme through:

- Settings Appearance
- Settings Notifications
- Music
- one popout
- Launcher

For each theme verify:

- ground/card/control/hover remain distinguishable
- foreground and muted text remain readable
- card border is only used where justified
- accent and urgent states retain meaning

Add optional per-theme derived-token overrides only for confirmed failures.

Then:

- remove obsolete local style calculations
- grep for remaining full-opacity `Theme.colorMuted` borders
- document legitimate exceptions
- update screenshots and project docs

---

## 8.1 Settings implementation checkpoint — 2026-07-28

Settings Phase 4 is implemented and approved through redesign Rev 27. The canonical target is the final Settings/Music mockup stored under `testing/shell-visual-polish-target.png`; Settings uses that image as a structural and visual reference rather than attempting pixel-for-pixel reproduction.

Completed Settings decisions:

- fixed-width, left-anchored content column instead of fullscreen form stretching
- rounded navigation card and per-section cards on every page
- joined `− | value | +` steppers on a shared form grid
- compact dropdowns, aligned toggles, and restrained helper tooltips
- generic page subtitles and redundant always-visible notes removed
- permanent pending-changes panel replaced by a compact action bar and Apply review dialog
- custom Settings titlebar and close button removed; normal compositor shortcut/window controls close the window
- Hyprland animation styles converted to dropdowns
- Custom animation mode writes typed window, open, close, workspace, layer, and fade speeds directly into complete Lua declarations
- the final dropdown wheel fix lives in `SettingsOverlays.qml`, because Theme, Font family, and Wallpaper transition are overlay-owned menus rather than `DropdownSettingRow` instances

The failed dropdown experiments from Revs 22–26 were removed before approval. Do not retain dead modal-popup, parent-walk, or `objectName` scroll-lock plumbing in `DropdownSettingRow.qml`.

Deferred from this checkpoint:

- final SDDM-specific visual review at home
- full font-scale and built-in-theme sweep
- Music window implementation
- remaining shell surfaces in Phase 5

---

## 9. Regression checklist

### Settings

- staging any value moves zero pixels
- Apply/Discard works on every page
- footer height is identical before and after polish
- conditional rows hide without orphan dividers
- dropdown overlays align at default and non-default font scale
- descriptions wrap without moving controls unpredictably
- Custom Theme color picker and Hyprland border syncing still work

### Music

- 10,000–20,000-track list performance remains acceptable
- delegates remain reusable
- play/pause, seek, random, repeat, queue, search, and album selection work
- album-art cache remains stable
- CAVA lifecycle remains source-aware
- no recurring MPD socket warnings

### Launcher

- keyboard navigation unchanged
- result-model churn unchanged
- selection remains visible at all scales

### Popouts and notifications

- floating edges remain legible over arbitrary wallpaper/app content
- action hit targets remain unchanged
- no clipped overlays or menus

### Whole shell

- every visible rectangle can name its elevation level
- no full-opacity muted border remains except a documented floating-edge case
- active and staged states are visually distinct
- no new shadow/rendering effects
- no layout-animation regressions

---

## 10. Documentation and workflow rules

- This file is the canonical visual-polish plan.
- Delete:
  - `SETTINGS_POLISH_PLAN.md`
  - `SHELL_DESIGN_SYSTEM.md`
- Do not maintain parallel polish plans after this merge.
- Update this document after each completed phase with:
  - commit/checkpoint reference
  - files changed
  - screenshots captured
  - regressions found and resolved
  - any deferred visual decisions
- User remains responsible for commit and push.
- Assistant handoffs contain changed files only, preserving destination paths.

---

## 11. Completion definition

The polish project is complete when:

- Settings no longer reads as one flat form
- Music and Launcher clearly share the same visual language
- common controls use shared primitives instead of local copies
- borders communicate focus, urgency, or floating edges rather than decorate every rectangle
- all themes preserve readable elevation and control contrast
- existing functionality, performance, and stable geometry remain intact

At that point, future visual work should be driven by specific daily-use friction rather than another broad redesign.
