# Bar Appearance and Popout Presentation — build plan

**Status:** Completed and live-tested (2026-08-01)
**Planned:** 2026-07-31
**Author:** Claude (Opus 5)

Read `docs/AI-MAINTENANCE-GUIDE.md` first — it is binding. Build ONE
phase per session. Snapshot before config changes. Sign changelog
entries. If a phase below contradicts what you find on disk, STOP and
flag it to the maintainer; do not improvise around it.

This plan was written from the knowledge-base copy of the source. Every
line number, property name, and API claim should be re-read on disk
before you rely on it.

---

## Completion record — 2026-08-01

All four phases were implemented and live-tested in order. The completed behavior is:

- **P1:** optional bar-height and corner-radius overrides, with `-1` theme-following sentinels, staged Apply behavior, and the locked `24–64 px` / `0–24 px` ranges. The custom bar-border path now clamps its drawn radius to the physical bar dimensions so large requested radii cannot produce overlapping arcs or a vertical end stroke.
- **P2:** independent bar and elevated-surface opacity controls. Popout opacity is also shared by attached and detached notification cards so matching shell surfaces stay visually consistent. Background alpha is applied at draw sites rather than inherited through container `opacity`.
- **P3:** documented Hyprland blur namespaces and layer-rule setup for the top bar and detached notifications. Attached `PopupWindow` menus require `blur_popups = true` on the `qs-bar` layer rule. A thin compositor seam can remain where an attached blurred popup overlaps the bar; it is accepted for now and tracked in `PROBLEMS_AND_FIXES.md`.
- **P4:** one global **Menus** setting with `Attached` and `Detached` modes. Detached menus retain their module anchor but use a positive gap, four rounded corners, a closed border, and no bar-gap registration. Attached remains the default.

Live testing covered both presentation modes, multiple left/right bar modules, opacity with and without blur, notification matching, radius extremes, and bar heights.

---

## Scope

Four related pieces, deliberately separated because they fail
differently:

| Phase | Work | Risk |
|---|---|---|
| P1 | Bar height + corner rounding settings | Low — boilerplate |
| P2 | Bar/popout translucency | Low, but touches every theme file |
| P3 | Hyprland blur layer rules | Config-only, hand-applied |
| P4 | Attached vs detached popout presentation | High — `BarPopout.qml` |

**Build order is P1 → P2 → P3 → P4, and it matters.** See "Build order"
at the bottom for why they must not be combined.

## Established recipes this plan leans on

- **`barPaddingTop/Side/Bottom` overrides (2026-07-12)** — the exact
  template for P1's override chain, including the `-1` sentinel
  convention and the fall-through to a theme token.
- **Bar border settings (2026-07-10)** — the template for the
  Appearance page controls, including the "toggling custom ON seeds
  the current effective value so nothing jumps" behavior.
- **`widgets/TopBar/Launcher.qml`** — the router template for P4. It is
  already an `Item` holding both a `BarPopout` and a
  `Common.CenteredSurface`, with `toggle()` picking between them and
  closing the other. Read it before writing anything in P4.
- **`widgets/Notifications/NotificationPopups.qml`** — the `Scope` +
  `presentationActive` variant of the same idea.
- **`ConfigManager.applyChanges`** — the staged transaction. Everything
  in P1 and P2 rides it.

## Settings ownership (unchanged, restated because P1/P2 add controls)

Per `docs/LAUNCHER_WALLPAPER_NOTIFICATION_PLAN.md`:

- persisted values + setters → `core/UserPrefs.qml`
- page-facing aliases and option models → `SettingsContext.qml`
- staging, diffs, discard, Apply orchestration → `SettingsTransaction.qml`
- visible controls → `widgets/Settings/pages/AppearancePage.qml`
- writes → `services/ConfigManager.qml`
- `SettingsWindow.qml` stays a lifecycle/hosting component only

Do not move any of these controls back into `SettingsWindow.qml`.

---

## P1 — Bar height and corner rounding

### Decisions LOCKED

**Two new overrides, `-1` sentinel, same shape as `barBorderWidthOverride`:**

```
UserPrefs:  barHeightOverride: -1     barRadiusOverride: -1
Theme:      barHeight  = override >= 0 ? override : active.barHeight
            barRadius  = override >= 0 ? override : active.barRadius
```

`Theme.barHeight` and `Theme.barRadius` are currently direct forwards of
`active.*`. After this they join `fontSize`, `barBorderWidth`, and the
`barPadding*` trio as documented exceptions. **Add the same style of
explanatory comment those carry** — the file's convention is that every
non-forward explains itself in place.

**Clamps:** height `24`–`64`, radius `0`–`24`.

Height floor is 24, not 20. At the shipped `fontScale` of 1.4 the bar's
text needs roughly 26px before it clips, and a floor that lets the user
silently clip their own bar is a support burden. 24 is tight but
survivable; below that, the answer is "lower your font scale first."

**Controls:** two `StepperRow`s in the existing Bar Layout card on
`AppearancePage.qml`, each behind a "Custom" toggle that seeds the
current effective value on enable — copy the `barBorderWidthOverride`
toggle behavior verbatim so nothing jumps when you turn it on.

**No live preview.** These stage and land on Apply like everything else.
Live-previewing bar height would make Hyprland reflow every tiled window
on every stepper click. This is a designed exclusion, not an oversight.

### Traps

⚠ **`barRadius` is not cosmetic.** `Theme.barBorderFillet` resolves to
`active.barRadius` whenever a theme leaves `barBorderFilletRadius` at
`-1` — which every shipped theme does. So the radius stepper silently
reshapes:

- `BarPopout._fL` / `_fR`, which set the popout **window width** (the
  fillet flanks), and therefore the anchor-rect compensation math
- `AttachedNotificationSurface.safeEdgeInset`, which is literally
  `Theme.barBorderFillet + Theme.barRadius - Theme.spacingMedium` — so
  barRadius enters that expression twice
- every connected popout's border `Canvas` path

This is the correct behavior (the joint should match the corners) but it
means the radius stepper is a geometry control, not a paint control.

⚠ **Canvas repaint.** `BarPopout`'s border `Canvas` does not repaint on
its own; the file forces repaints through explicit property change
handlers. Grep for `requestPaint()` and confirm `Theme.barRadius` /
`Theme.barBorderFillet` are in that set. If they are not, add them, or
the outline will not update until some unrelated geometry event.

⚠ **`Theme.barHeight` has non-bar consumers.** `Launcher.qml` sets
`height: Theme.barHeight` on its anchor `Item`. Grep for every reader
before assuming the change is contained to the bar.

⚠ **Exclusive zone.** Bar height drives the layer-shell exclusive zone.
Changing it on Apply makes Hyprland reflow every tiled window. That is
expected and reactive through the singleton binding — no restart needed
— but it is a visibly heavier operation than a padding tweak. Do not be
alarmed by the reflow; do be alarmed if windows end up overlapping the
bar, which would mean the exclusive zone is bound to a stale value
rather than `Theme.barHeight`.

### Live-test matrix

Radius `0` · radius `24` with a narrow popout (Volume is the narrowest)
· notifications at `left` and at `right` alignment, where
`safeEdgeInset` moves · height `24` and `64` · border width `0` and `2`
at both radius extremes.

Screenshots: `sleep 3 && grim /tmp/shot.png`. Screenshot keybinds close
open popouts — that is `HyprlandFocusGrab`'s outside-focus dismiss
working as designed, not a bug.

### Files

`core/UserPrefs.qml`, `core/Theme.qml`, `SettingsContext.qml`,
`SettingsTransaction.qml`, `widgets/Settings/pages/AppearancePage.qml`,
`services/ConfigManager.qml` (two switch cases).

---

## P2 — Translucency

### Decisions LOCKED

**Alpha goes in the background `Rectangle`'s color. Never `opacity:`.**

QML's `opacity` multiplies down onto every child. Set it on the
`PanelWindow` or any wrapping `Item` and the bar's text, icons, and
workspace indicators go translucent with it. In `TopBar.qml`:

```qml
Rectangle {
    anchors.fill: parent
    radius: Theme.barRadius
    antialiasing: true
    color: Qt.alpha(Theme.colorBackground, Theme.barOpacity)
}
```

`antialiasing: true` matters more than usual here — a translucent
rounded corner with no border to hide behind shows stair-stepping that a
solid fill does not.

Confirm the `PanelWindow` itself carries `color: "transparent"`. It
almost certainly does already, since the floating `barMargin` gap would
otherwise paint an opaque block, but verify rather than assume.

**Two tokens, not one — and this is the important decision.**

`BarPopout`'s panel `Rectangle` uses `Theme.colorBackground`, the *same*
color the bar's background uses. So applying alpha to the Theme color
itself would make popouts translucent at the bar's value automatically,
and bar-plus-popout would flatten into one uniform sheet exactly where
they overlap — destroying the elevation the connected-border language
depends on.

Therefore: **do not put alpha on the Theme color.** Apply it at the two
draw sites, with two independent tokens:

```
Theme.barOpacity      → TopBar.qml's background Rectangle
Theme.popoutOpacity   → BarPopout.qml's panel Rectangle
```

Defaults: both `1.0`, so P2 ships as a visual no-op and only moves when
the user opts in. Suggested user-facing pairing is bar `0.75` with
popout `0.95`, but that is taste, not a default.

**Do not alpha the borders.** The bar's border `Canvas` and the popout's
border `Canvas` both draw with `Theme.barBorderColor`. A solid outline
around a translucent fill is what makes the shape still read as one
object; a translucent outline over a busy wallpaper disappears.

**Theme token contract.** Every file in `themes/` must gain
`property real barOpacity: 1.0` and `property real popoutOpacity: 1.0`.

⚠ This is P2's single biggest mechanical risk. `DefaultTheme.qml`'s own
header states the rule: a theme file must define the FULL property
contract, and a missing property forwards as silent `undefined`. Miss
one theme file and that theme's bar renders at `undefined` alpha with no
error. Count the files in `themes/`, add the properties, then count
again against `core/Theme.qml`'s theme map.

**UserPrefs overrides:** `barOpacityOverride: -1`,
`popoutOpacityOverride: -1`, resolved in `Theme.qml` the same way as P1.
Note the sentinel works here because valid opacity is `0.0`–`1.0` and a
real value is never negative — same reasoning as `barBorderWidthOverride`,
*not* the `-9999` case `barPaddingBottomOverride` needed.

**Controls:** two sliders on the Appearance page. Sliders, not steppers —
opacity is a continuous feel judgment, unlike px values.

### Traps

⚠ **Readability without blur.** Below roughly `0.6` on a busy wallpaper,
bar text becomes genuinely hard to read. P3 is the answer. Ship P2 with
a `1.0` default so nobody lands in a bad state before P3 exists.

⚠ **Gradient continuation.** `BarPopout` translates the bar's border
gradient into its own window coordinates via `_barX` / `_barW` / `_barH`
so colors flow through the seam. Alpha on the *fills* does not touch
this. If you find yourself editing that math during P2, you have gone
off-plan — stop.

⚠ **Do not alpha `colorSurface`.** It is the elevated-popup color used
by other surfaces; it is not in P2's scope and changing it will move
things this plan has not audited.

### Files

`themes/*.qml` (all of them), `core/Theme.qml`, `core/UserPrefs.qml`,
`widgets/TopBar/TopBar.qml`, `widgets/TopBar/BarPopout.qml`,
`SettingsContext.qml`, `SettingsTransaction.qml`, `AppearancePage.qml`,
`services/ConfigManager.qml`.

---

## P3 — Hyprland blur

Nothing in Quickshell can blur what is behind a layer surface. Blur is
the compositor's job and reaches the shell only through layer rules.

### The rules

```
layerrule = blur, <namespace>
layerrule = ignorezero, <namespace>
layerrule = ignorealpha 0.2, <namespace>
```

`ignorezero` is **mandatory**, not optional polish. Without it Hyprland
blurs the fully transparent region of the panel window too — including
the `barMargin` gap around the floating bar — producing a blurred
rectangle noticeably larger than the bar itself. `ignorealpha` sets a
threshold below which pixels are skipped, which matters for the popout's
transparent fillet flanks.

### Namespaces

Quickshell layer surfaces share a default namespace, so a single rule
set hits the bar, popouts, OSD, notifications, launcher and overlays at
once. If blur should be selective — and it should, the volume OSD
almost certainly does not want it — each window needs its own namespace:
`qs-bar`, `qs-popout`, `qs-osd`, `qs-notif`, `qs-launcher`, `qs-overlay`.

⚠ **VERIFY BEFORE BUILDING.** The per-window namespace is set through a
`WlrLayershell` attached property on the `PanelWindow`. This plan was
written from memory against a pre-0.3 recollection of the API. Check the
Quickshell 0.3 documentation for the current form before writing it, and
if it has changed, update this section rather than working around it.

Also consider `layerrule = noanim, <popout namespace>` if Hyprland's
layer animation visibly fights `BarPopout`'s reveal animation. Test
before adding it — it may be fine.

### Ownership

⚠ Layer rules belong in `user/look.lua` or `user/rules.lua`, which are
**hand-written and ConfigManager must never touch them**. v1 of this
phase is documentation only: the maintainer pastes the lines in.

A blur toggle in the settings window would require transferring those
keys into `generated/appearance.lua`, which is the same ownership-
transfer situation as the parked animations-enabled item. **Ask the
maintainer first; do not do it unprompted.**

---

## P4 — Attached vs detached popouts

### Decisions LOCKED

**Detached means "floats below its module", not "centered on screen."**

Centered is right for the launcher and wallpaper picker, which feel
modal. It is wrong for a volume slider: a control that appears in the
middle of the screen when you clicked something in the corner is
disorienting, and it severs the visual link between the module and its
menu.

**Therefore this is a mode flag inside `BarPopout`, not a second surface
file.**

```qml
property bool detached: false
```

When `detached` is true:

- `_updateGap()` early-returns before registering anything
- `_fL` / `_fR` evaluate to `0` (no fillet flanks, so no window widening
  and no anchor-rect compensation)
- the panel keeps its radius on all four corners — remove the small
  `Rectangle` that squares off the top two
- the anchor rect's negative overlap into the bar is replaced with a
  positive vertical gap of `Theme.spacingMedium`
- the border `Canvas` draws a closed rounded rect instead of the
  open-topped fillet path

**Why not copy the notification split.** `NotificationPopups.qml` splits
into two surface files because notifications genuinely change *position*
between modes — screen corner versus bar anchor. Module popouts do not:
same anchor item, same alignment, same x math, only different connective
tissue. Splitting them would duplicate the anchor-rect ↔ `_updateGap`
mirror pair, which is the single most fragile invariant in the file and
the one its own comments repeatedly warn must "change together." One
copy of that math, with a flag, is strictly safer than two copies.

**One global pref, not per-module:** `UserPrefs.popoutPresentation`,
values `"attached"` | `"detached"`. Per-module choice is scope creep and
would produce a settings page nobody wants to read.

**Explicitly untouched:** `launcherPlacement`, the wallpaper picker's
placement pref, and `notifPresentation` all keep their own independent
settings. This key does not read or write them.

### Traps

⚠ **Skip gap registration; do not register-then-clear.** If
`_updateGap()` registers a gap and something clears it later, there is a
window of frames where the bar's border has a notch with nothing
attached to it. Early-return at the top of the function.

⚠ **Switching the pref while a popout is open.** Lock: close all
popouts on pref change. The precedent and the reason are already in
`AttachedNotificationSurface._hideImmediately` — *"Presentation changes
and invalid anchors must stop exposure immediately; otherwise detached
and attached windows can overlap during retraction."* Same failure mode
applies here.

⚠ **The bar-bottom overlap must go.** The anchor rect currently reduces
its height by one border width so the popup overlaps the bar's bottom
`bw` pixels — that is the 2026-07-10 fix for fillet arcs being clipped
at the window's top edge. In detached mode there are no fillet arcs, so
the overlap is not just unnecessary, it would pull the detached panel up
into the bar. Replace it with a positive gap. The change-together rule
with `_updateGap` still applies even though that function early-returns
— keep both branches readable side by side.

⚠ **Do not delete the bar-gap machinery.** `setPopoutGap` /
`clearPopoutGap` / `_findBarHost` / the `isBarBorderHost` marker are all
still used by `AttachedNotificationSurface` regardless of this pref.

⚠ **Never declaratively bind properties Quickshell's C++ writes.**
`BarPopout`'s header states this as a general rule for the whole file
after it was hit twice — `visible` and `HyprlandFocusGrab.active` both.
Push from signal handlers instead. This applies to anything you add.

⚠ **Focus grab semantics are unchanged.** Outside-click dismissal works
identically in both modes. Do not touch `dismissOnOutsideClick`.

⚠ **Detached popouts are still layer surfaces** and can be caught by
Hyprland layer rules — see P3.

### Migration

The five modules that instantiate `BarPopout` directly — `Volume`,
`Wifi`, `Bluetooth`, `Clock`, `SystemMenu` — each gain one line binding
`detached` to the pref. That is the whole per-module change. If a module
needs more than that, stop and document why.

### Designed exclusions

- No per-module presentation choice
- No centered mode for module popouts
- No detached mode for notifications (they already have their own)
- No drag-to-reposition
- No per-popout offsets (the launcher's X/Y offset pattern is not
  extended here)

---

## Build order

**P1 → P2 → P3 → P4.**

⚠ **Do not combine P1 and P4 in one session.** P1 makes bar radius
user-adjustable, which reshapes fillet geometry. P4 makes fillet
geometry conditional. Debugging a geometry bug when both the value and
the branch are new is substantially harder than debugging either alone.
Land P1, live-test it at both radius extremes, *then* start P4.

P2 is safe to interleave with anything because it touches fills only —
but it wants its own session anyway, because the theme-file sweep is
tedious and easy to get wrong when tired.

P3 is config-only and hand-applied by the maintainer; it can happen any
time after P2, and should happen before anyone judges whether P2 looks
good.

---

## Parked

- Linking `radiusMedium` (internal card/button rounding) to `barRadius`,
  with an opt-in "match internal rounding" toggle
- Per-monitor bar height and radius (the per-monitor override file
  pattern exists but is not extended here)
- A blur toggle in the settings window (needs the ownership transfer
  described in P3 — ask first)
- Live preview for bar height
- Input-mask polish on the fillet flanks (pre-existing known cost: two
  fillet-width strips beside an open menu accept clicks and do nothing)

---

## Open questions for the maintainer

1. **Height floor.** This plan locks 24. If you would rather have 20
   with a warning row when the computed text height exceeds the bar,
   say so before P1 starts — retrofitting the warning is more work than
   building it in.
2. **Blur namespaces.** Split per window type, or one namespace for
   everything? Splitting is more work up front and much more flexible
   later.
3. **Opacity defaults.** This plan ships both tokens at `1.0` on every
   theme, so nothing changes until you opt in. The alternative is
   letting each theme express an opinion (Rose Pine at `0.85`, Honeycomb
   at `1.0`). Cheap either way, but it should be decided once rather
   than drifting per theme.
