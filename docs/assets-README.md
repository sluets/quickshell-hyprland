# assets/

Reserved for static files the shell needs at runtime — custom icons,
images, fonts not already available system-wide.

No longer empty as of 2026-07-13:

- `icons/weather/` — 7 SVGs (clear/partly-cloudy/cloudy/fog/rain/snow/
  thunderstorm) read by `widgets/Desktop/DesktopClock.qml` via
  `services/Weather.qml`'s condition mapping. Flat fill + soft dark
  halo (no stroke, to avoid seam artifacts from overlapping shapes) —
  see the icons themselves for the exact technique if adding more.
- `icons/power/` — 6 SVGs (restart/restarthyprland/shutdown, each in
  -black and -white) read by `widgets/PowerMenu/PowerScreen.qml`.
  Black/white variant is picked automatically by luminance of the
  active theme's `colorSurface`, not a setting — see that file's
  DESIGN NOTES.

Both sets degrade gracefully if a file is missing (weather icon: the
row just doesn't show; power icon: falls back to the old ⟳ ↻ ⏻
glyphs) — see each consuming file's own DESIGN NOTES rather than
assuming a missing file breaks anything.

Adding a new icon set for a future widget: follow the same pattern —
consuming QML checks `Image.status` and hides/falls back rather than
erroring, so the widget can be built and tested before the assets
exist, same as both sets above were.
