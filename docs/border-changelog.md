# Paste into docs/REVISION_HISTORY.md (top)

## 2026-07-10 (Fable 5) — bar border side-project

- Border around the whole bar that CONTINUES around any open popout
  (bluetooth, wifi, volume, wallpaper, launcher, clock, settings — all
  eight, since they share BarPopout). Bar strokes a rounded border via
  Canvas with a gap in its bottom edge where the open popout hangs;
  the popout draws its left/bottom/right sides inside the reveal clip,
  so the border grows with the slide-out.
- New theme tokens `barBorderWidth`/`barBorderColor` (both themes +
  Theme.qml forward). Width default -1 = follows UserPrefs.hyprBorderSize
  LIVE — the bar border tracks the Border Size slider on the Hyprland
  settings page. 0 disables. Color defaults to each theme's accent.
  Hyprland's active-window border is generated separately by the settings
  system; it may follow the effective bar-border color when configured to use
  the theme, but it also supports an independent custom value.
- TopBar contents wrapped in `barRoot` (marker + gap API); BarPopout
  registers/clears its gap on open/close. Gap math mirrors the
  anchor-rect math — change together.
- Offline-tested: segment complement + gap-x math against real bar
  geometry. Live-untested; expected first-run rough edges: seam
  alignment at flush-edge popouts near the bar's rounded corners.

## Same-day extension — fillets + gradients

- Fillet joints where popouts meet the bar (the mockup): popout window
  widened by Theme.barBorderFillet per side, transparent flanks hold
  quarter arcs curving the bar's bottom border into the panel's sides;
  anchor-rect compensation keeps the panel exactly where it was. Flush
  popouts (settings/system menu) skip the fillet on their flush side.
  Token barBorderFilletRadius: -1 = follow barRadius, 0 = square joint.
- Gradient borders: barBorderColor2 (transparent = solid) +
  barBorderGradientAngle (0 = left→right, 90 = top→bottom, clockwise).
  The popout draws the bar's gradient line translated into its own
  coordinates, so color flows through the seam unbroken. Match your
  Hyprland col.active_border by using the same two colors and nudging
  the angle by eye.
- HoneycombTheme barBorderColor changed white → teal #35e0b4 (white
  border on white wallpaper: the invisible-feature incident).
- Offline-verified: border path endpoint continuity in all four flank
  configurations (both/left-only/right-only/none), gap tangency,
  anchor compensation. Known live caveats: f-wide click-dead strips
  beside an open menu (input-mask polish item), and reveal-animation
  interaction with the fillet arcs is untested.

## 2026-07-14 live fixes — pixel alignment and reverse close animation

- Content-anchored popouts could disagree with the TopBar Canvas gap by 1–3 px
  because RowLayout produced fractional coordinates while Wayland positioned
  the popup surface on whole pixels. `BarPopout.qml` now rounds popup size,
  anchor geometry, and gap geometry through the same helper.
- Closing no longer snaps. The popup surface stays alive while the reveal clip
  animates upward, then becomes invisible when the reverse animation finishes.
- Open/close timing slowed to approximately 250 ms.
- Live-confirmed on Launcher, Wallpaper Picker, Volume, Wi-Fi, Bluetooth,
  Calendar, and Settings popouts.

## 2026-07-16 fix — staged bar/Hyprland border colors synchronized

- The previous bug was an asynchronous Apply race, not a page-splitting issue.
  Settings cleared staged values while ConfigManager was still taking its
  safety snapshot, so the later Hyprland regeneration could see old saved data.
- Settings now resolves the final Appearance border and selected theme before
  Apply begins, then passes an immutable border snapshot through ConfigManager's
  transaction.
- When Hyprland “Use theme color” is enabled, it follows the effective Appearance
  border in the same Apply, including theme gradients, custom solid colors, and
  theme changes. When disabled, its independent custom value remains untouched
  by Appearance changes.
