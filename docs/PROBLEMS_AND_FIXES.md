# Problems and Fixes

## 2026-07-15 — Desktop clock live corner switching fixed; center offsets still do not apply

**Original symptom:** The desktop clock displayed correctly in the center, but choosing any corner either made it disappear or moved it once and then left it stuck there. The selected corner was still written correctly: after restarting Quickshell, the clock appeared in the saved location. Font and color changes continued updating live while position changes were stuck.

**Causes discovered:**
- Earlier revisions dynamically switched anchors on the clock content. Qt retained stale anchor relationships when the selected corner changed.
- A later attempt mixed a full-screen layer-shell `PanelWindow` with content-sized `implicitWidth`/`implicitHeight`, creating conflicting surface geometry. Right/bottom placement could collapse or clamp to the top-left corner.

**Working fix:** `widgets/Desktop/DesktopClock.qml` now keeps one full-screen, click-through Background-layer `PanelWindow`, does not advertise content-sized window dimensions, and positions the clock content with explicit `x`/`y` bindings calculated from the real screen dimensions. Live switching among center and all four corners now works without restarting Quickshell. Weather icons remain tinted from the same effective color as the clock text.

**Known remaining bug:** X/Y offsets currently do not affect the clock while the position is set to **Center**. Corner offsets work. This is intentionally deferred until after `SettingsWindow.qml` has been split into page files.

**Do not regress:**
- Do not restore dynamic anchor switching for clock placement.
- Do not set the full-screen clock `PanelWindow`'s `implicitWidth` or `implicitHeight` from the clock content.
- Keep the Wayland surface full-screen and move only the inner clock content.

---

## 2026-07-14 — Appearance border color and Hyprland active border are only partially linked during staged Apply

**Symptom:** The Appearance page can change the top-bar border color, and the
Hyprland page can change the compositor active-window border color, but changing
one does not immediately make the other match. Touching the second setting and
then reverting it may cause both to line up again.

**Cause:** The two pages stage separate values. The current Apply path resolves
part of the relationship from already-saved `UserPrefs`/theme values instead of
resolving both settings from the complete staged state in one transaction. That
creates an apply-order/synchronization problem. The individual color controls
are working; the coupling between them is not authoritative.

**Current status:** Deferred while `SettingsWindow.qml` is being split into page
files. This does not block the page extraction because all other Appearance
controls are working.

**Correct future rule:**
- If Hyprland **Use theme color** is enabled, it follows the effective
  Appearance border: theme gradient when Appearance uses theme color, custom
  solid color when Appearance uses a custom color.
- If Hyprland **Use theme color** is disabled, its custom active-border value is
  independent.

**Do not try again:** Do not keep adding page-local bindings between staged and
saved values. Fix this once in `SettingsStore.qml` or the centralized Apply
transaction, where both staged settings can be resolved together before writes.

---

## 2026-07-14 — Bar-popout seams, reverse close animation, and settings-window geometry

### Bar border gap was off by 1–3 pixels on content-anchored menus

**Symptom:** Launcher and Wallpaper Picker joined the bar cleanly, while
Volume, Wi-Fi, Bluetooth, Calendar, and Settings showed a tiny offset where
the popup fillet met the bar border. Changing the configured border width
did not correct it.

**Cause:** Right-side bar widgets are positioned by `RowLayout` and can land
on fractional coordinates. The Canvas gap used those fractional values, but
the Wayland popup surface was ultimately placed on whole pixels. The border
gap and popup therefore disagreed by a few pixels.

**Fix:** In `widgets/TopBar/BarPopout.qml`, round popup width/height, anchor
rectangle coordinates, and the values passed to the bar-gap API through the
same whole-pixel helper. The geometry on both sides of the seam must be
derived from the same rounded values.

### Popouts opened with animation but snapped closed

**Symptom:** Menus scrolled down from the bar but vanished immediately when
closed.

**Cause:** `PopupWindow.visible` was cleared as soon as the open state became
false, destroying the visible surface before a reverse reveal animation could
run. This was an implementation lifecycle issue, not a QML limitation.

**Fix:** Keep the popup visible while `revealProgress` animates back to zero,
release its input grab at the beginning of close, then hide the popup after
the animation finishes. Reveal timing was also slowed from roughly 180 ms to
about 250 ms.

### Redesigned Settings window showed double borders and clipped controls

**Symptom:** The new settings layout worked functionally, but thick Hyprland
borders exposed several visual defects: sidebar tabs painted into the border,
a second inner QML border competed with the compositor border, inner corners
were square, and full-width dropdowns extended underneath the custom
scrollbar.

**Cause:** The first redesign mixed client-side border/rounding assumptions
with Hyprland's server-side border and rounding. The page viewport also used
its full width while the scrollbar was painted over that same region.

**Fix:**
- Use a normal `FloatingWindow`; Hyprland is the only owner of the outer
  border, active gradient, and rounded window shape.
- Remove the competing QML outer border.
- Inset/round sidebar content so even an exaggerated 10 px compositor border
  does not overlap it.
- Reserve a permanent scrollbar gutter and cap dropdown buttons/panels to the
  page width before that gutter.
- Keep the sidebar, header, and Apply/Cancel area fixed while only the selected
  page scrolls.

**Regression rule:** test border geometry with an intentionally huge Hyprland
border. If it is clean at 10 px, ordinary border widths should also be clean.

---

This file exists so that dead ends discovered once don't get rediscovered
the hard way a second time — by you, by a future Claude with no memory of
this conversation, or by anyone else who ends up maintaining this project.

Every entry should answer: what were we trying to do, what went wrong,
what actually fixed it, and — most importantly — **what should someone
NOT try again**, because it looks like an obvious fix and isn't.

If you hit something confusing while working on this project and eventually
solve it, add an entry here before moving on, even if it feels minor. The
cost of writing it down is a few minutes. The cost of not writing it down
is re-debugging the same thing in six months with no memory of having
already solved it.

---

# PART 1 — new entries (newest first)


## 2026-07-13 A multi-line comment placed INSIDE the JsonAdapter block silently broke the ENTIRE UserPrefs singleton — every property and function read as `undefined` shell-wide. No syntax error, no log line, qmllint clean. Cost a multi-hour session. Exact trigger character never isolated; removing the comment fixed it.

**Trying to do:** Ship the wallpaper-transition feature — migrate
`wallpaperTransition{Type,Duration,Fps,Angle}` from Settings.qml into
UserPrefs.qml's JsonAdapter, add a new `wallpaperTransitionPos`, plus
public forwards and setters. Standard migration, same pattern as a
dozen prior ones.

**What went wrong:** After dropping the new files in, the shell came up
badly degraded — tiny fonts, no bar border, no popup corner fillets,
broken settings window, a notification that filled 25% of the screen.
The log was a wall of ~50 `Unable to assign [undefined]` warnings across
SettingsWindow, DesktopClock, Theme, and NotificationPopups — every file
that reads `UserPrefs.*`. But the shell still printed "Configuration
Loaded" and themes could still be changed.

**The long wrong path (what NOT to repeat):** Burned rounds on theories
that all turned out wrong, each of which *looked* right:
- Stale/mismatched files (diffed every shipped file against the live
  tree — all byte-identical, all correct).
- A missing `core/qmldir` (there never was one; this project uses
  automatic singleton resolution, not qmldir registration).
- The `sddm-rev0/` folder copied into the config tree (moving it out
  changed nothing).
- A stale `user-prefs.json` shape mismatch (deleting it entirely still
  broke — ruled out on-disk state completely).
- A `core/undefined/` nested backup folder (real clutter, real to
  delete, but NOT the cause).
- `property real wallpaperTransitionAngle: 45` — a bare int on a real
  property. Plausible (every other real default in the file uses `.0`),
  changed it to `45.0`, md5-confirmed on disk, STILL broke. Not it.
- Multi-line array literals in the setters (backup keeps arrays
  single-line). Collapsed them — still broke. Not it.
- The `%` modulo operator (appears nowhere in the working file).
  Removed it — still broke. Not it.

**What actually found it:** Bisection against a KNOWN-GOOD BACKUP of the
file. Built the working backup + one category of change at a time,
testing each with `qs 2>&1 | grep -c undefined` on the real machine:
- backup + adapter properties only  -> 0 (works)
- backup + adapter props + forwards -> 0 (works)
- backup + all of it (props+forwards+setters+COMMENTS) -> 57 (broken)
- same, setters present but their multi-line COMMENT block removed -> 0 (works)

The delta between the last two was ONLY a comment block. Removing the
comment that sat inside the adapter/function region fixed it, 57 -> 0,
with all features intact.

**What actually fixed it:** Remove the offending in-adapter/in-function
comment block. The proven-working `UserPrefs.qml` keeps the feature code
but drops those specific comments (documentation moved to plain-ASCII
comments ABOVE the blocks instead).

**What NOT to try again / the rule going forward:**
- Do NOT trust that "it's the same migration pattern as before" means
  the code is fine — the code WAS fine; a comment was the problem.
- Do NOT chase the JSON, the file paths, the qmldir, or type literals
  first. When EVERY property on ONE singleton is undefined shell-wide
  but there's no syntax/log error and qmllint is clean, suspect the
  Quickshell AHEAD-OF-TIME SINGLETON COMPILER choking on something —
  and bisect against a known-good copy immediately rather than theorize.
- Keep comments inside a JsonAdapter block or a function body SHORT and
  plain ASCII. Put long/rich documentation ABOVE the block in normal
  file scope (proven safe — the file header uses that style fine).

**Honest caveat:** the EXACT trigger character was never isolated. The
broken comment had backticks, double-quotes, and em-dashes — but OTHER
comments in the same adapter also have double-quotes and em-dashes and
work fine. So it is NOT simply "quotes/em-dashes break it." Something
more specific (a sequence?) remains unidentified. If you ever have the
patience to isolate it, add the finding here. Until then: keep in-block
comments minimal and ASCII, and always re-run `grep -c undefined` after
editing UserPrefs.qml.


## 2026-07-12 Font-family picker: a hardcoded list of "nice" family names silently rendered NOTHING when picked, because `Qt.fontFamilies()` reports families under different exact strings than `fc-list` shows. Two separate exact-match guards (list filter + setter validation) each hid the bug in a different way.

**Trying to do:** Trim the font-family dropdown from the raw
`Qt.fontFamilies()` dump (150-300+ entries, unusable) down to a
sensible short list of popular Nerd Fonts, and have picking one
actually change the shell font.

**What went wrong (three symptoms, one root cause):**
1. First trim filtered a hardcoded curated list against
   `Qt.fontFamilies()` with `.includes()` on the raw return — matched
   NOTHING (list-property, not a real JS array; `.includes()` no-ops).
   Only "(Theme Default)" showed.
2. Switched to `.slice().indexOf()` (real array) — now matched exactly
   ONE family, **CaskaydiaCove**, and dropped the other nine even
   though `fc-list` confirmed all ten installed.
3. Removed the list filter (showed the hardcoded 10 directly). Picking
   a font staged + showed in pending + Apply cleared it… then snapped
   straight back to "theme default", visibly unchanged.

**Root cause:** The exact strings I hardcoded ("JetBrainsMono Nerd
Font", etc.) are NOT the strings Qt reports for those families on this
machine — only CaskaydiaCove (the theme's own default) happened to
match verbatim (symptom 2 was the loud clue). So:
- The list filter hid every non-matching name.
- `UserPrefs.setFontFamilyOverride` had a MATCHING guard
  (`if v === "" || Qt.fontFamilies().indexOf(v) !== -1`) that rejected
  every real pick — Apply ran, ConfigManager called the setter, the
  setter silently no-op'd, so only "" ever persisted (symptom 3).
- Even with both guards removed, setting `font.family` to a string Qt
  can't resolve just falls back to the default font at render — so the
  font "didn't change" even though the value persisted.

**What actually fixed it:** DERIVE the list from `Qt.fontFamilies()`
at runtime and show the VERBATIM Qt strings (filtered to families
ending in "Nerd Font" for the base variant, popular picks floated
top). Every offered name is therefore already a valid Qt family, so a
pick is guaranteed to resolve and render. Setter guard removed too
(the picker is now the only gate on what's offerable).

**Do NOT try again:**
- Do NOT hardcode font family names and assume they match
  `Qt.fontFamilies()`. `fc-list` family names and Qt's reported family
  strings can differ; hardcoded names may render as a silent fallback.
  Always offer strings that came OUT of `Qt.fontFamilies()`.
- Do NOT call array methods (`.includes`, `.map`, `.filter`) on the
  RAW `Qt.fontFamilies()` return — it's a list-property, same caveat
  as `Quickshell.screens` (see monitorOptions). `.slice()` first.
- Do NOT re-add an exact-match validation guard in the setter. If the
  picker offers real Qt strings, the guard is redundant; if it offers
  anything else, the guard silently eats the write and Apply looks
  broken for no visible reason.


## 2026-07-12 A singleton reading ANOTHER singleton (ConfigManager → Theme) broke COLD-start init ordering — every `ConfigManager.*` read came back `undefined` all session ("Working (undefined)", permanently-dead Apply). Hot-reload masked it; a `color`-typed param was a red herring that cost a round.

**Trying to do:** Nothing new — the active-border gradient work (same
day, see entries below) had shipped and worked. Then: dumped the files
in, `qs` hot-reloaded, everything worked. Killed `qs`, cold-started,
and the settings window broke — status line stuck on **"Working
(undefined)…"**, **Apply never clickable** no matter what was staged,
while **Cancel and the pending-changes list kept working**.

**What went wrong:** The split is the tell — Cancel
(`root.discardStaged()`) and pending changes (`root.changes`) are
pure-QML; the status line and Apply's `enabled_` both gate on
`ConfigManager.busy`. So the fault was isolated to ConfigManager:
- `ConfigManager.busy !== ""` → `undefined !== ""` → `true` →
  `"Working (" + undefined + ")…"` = **"Working (undefined)…"**
- `root.changes.length > 0 && ConfigManager.busy === ""` →
  `... && (undefined === "")` → **always false** → Apply disabled.

A one-line diagnostic in `open()` settled it:
`console.log("...", ConfigManager, ConfigManager.busy, typeof ...)`
printed `ConfigManager= ConfigManager  busy=[ undefined ]
typeofBusy= undefined`. So the singleton OBJECT resolved, but **every
property read `undefined`** — the signature of a lazy singleton whose
init failed and got cached. A bisect confirmed it: reverting ONLY
`ConfigManager.qml` to its pre-session original made the exact same
diagnostic print `busy=[ ] typeofBusy= string` and settings worked.

Root cause: the session's border-color work had ConfigManager read
`Theme` directly inside `_performStagedWrites`
(`_qColorToHyprHex(Theme.colorAccent)` etc.). Even though that read is
in a function BODY, it added ConfigManager → Theme → UserPrefs to
ConfigManager's dependency graph. On COLD start, `shell.qml`'s
force-instantiation read (`readonly property bool _configManagerLoaded:
ConfigManager.ready`, the intentional "wake the singleton at boot"
line) fired before that chain resolved; the lazy init failed and QML
cached the failure, so `ConfigManager.ready` — and every other
property — read `undefined` for the whole session. Hot-reload masked
it because the singleton was already initialized in memory from the
previous (working) state; only a cold process exposes the ordering.

**THE RED HERRING (cost a full round):** the same helper was first
written `_qColorToHyprHex(c: color)`, and the first fix attempt blamed
that `color`-typed PARAM (plausible: value-type annotations resolve at
compile time). Dropping the annotation changed nothing — the failure
persisted identically. The lesson: **a plausible mechanism that
matches the symptom is not a confirmed cause.** The thing that actually
localized it was DATA (the diagnostic print + the revert bisect), not
more inspection. Should have reached for that first instead of
reasoning from the code.

**What fixed it:** ConfigManager must NOT read `Theme`. The
theme-derived colors are now resolved in `SettingsWindow` (which
safely depends on Theme — it's a normal instantiated component, not a
lazy singleton with a boot-time force-read) and pushed into
ConfigManager through four plain properties
(`hyprActiveBorderThemeHex` / `Hex2` / `Angle` / `Grad`) via live
`Binding`s. ConfigManager's dependency graph is now identical to its
proven-good original (`qs.core`/UserPrefs only). Live `Binding`s (not a
one-shot copy at apply time) are what keep theme SWITCHING correct: the
regen runs async after the snapshot Process exits, by which point
`Theme.colorAccent` reflects the new theme and the Binding has already
propagated it, so the border bakes the new color. Custom-color
resolution needs no Theme and stayed inline (`_hexToHyprHex`).

**Don't try this instead (looks right, isn't):**
- Do NOT let a `pragma Singleton` read another singleton that sits
  behind a boot-time force-instantiation read, even from a function
  body — the dependency-graph entry is created regardless of where the
  reference textually sits, and it can reorder cold init. If a
  singleton needs a value from another singleton, have a
  non-singleton caller push it in (properties + Bindings), or pass it
  as a function argument.
- Do NOT "fix" the symptom in the settings window by guarding
  `ConfigManager.busy` against `undefined`. That masks a total
  singleton-init failure behind a UI pretending the backend is alive.
  The `busy === ""` checks are correct and predate this session.
- Do NOT trust "it works on hot-reload." Singleton init order only
  runs on a cold process. After ANY change touching a singleton's
  dependencies, `pkill qs; qs` and verify before trusting it.
- When a singleton's object resolves but all its properties are
  `undefined`, stop inspecting and get DATA: a one-line
  `console.log(typeof singleton.prop)` at a read site, plus a
  revert-one-file bisect, localizes it in one cold-start each. That
  pair would have found this immediately; inference chased a red
  herring for a round first.


## 2026-07-12 A settings page referencing a singleton that was never written throws `ReferenceError`s the moment its `pages` entry exists — not just when the tab is clicked

**Trying to do:** Nothing, initially — this surfaced from live shell
logs the maintainer pasted after an unrelated request, showing a
stream of warnings on every settings-window open:

```
WARN scene: @widgets/Settings/SettingsWindow.qml[1982:-1]: ReferenceError: DisplayManager is not defined
WARN scene: @widgets/Settings/SettingsWindow.qml[691:-1]: ReferenceError: DisplayManager is not defined
WARN scene: @widgets/Settings/SettingsWindow.qml[2187:-1]: TypeError: Cannot read property 'length' of undefined
```

**What went wrong:** `SettingsWindow.qml`'s `pages` array included
`"Displays"`, and the Displays page's UI plus several supporting
functions (`stageDisplay`, `shownDispMode/Scale/Disabled`,
`displayChanges`, `applyDisplays`) all referenced a `DisplayManager`
singleton — but `services/DisplayManager.qml` was never actually
written. Confirmed the maintainer's report: **it never worked**, since
whenever that page was added. The `length of undefined` warning was
the least obvious of the three: the Apply/Cancel button's `enabled_`
reads `root.displayChanges.length`, and `displayChanges` is a
`readonly property var` whose binding body opens with
`const mons = DisplayManager.monitors;` — an undefined reference deep
inside a computed property, evaluated whenever ANY of its dependencies
change, not only when the Displays tab is actually open. This is the
same "silent until USE" failure class documented in the 2026-07-09
gear-menu entry below — a QML binding that references something
undefined doesn't crash the shell, it just spams one WARN per
re-evaluation and returns `undefined`.

**What fixed it:** Removed `"Displays"` from the `pages` array (so the
tab and its Repeater delegate never render) and wrapped the entire
page UI block plus the five DisplayManager-dependent functions in
`/* ... */` block comments, rather than deleting them — the logic
looks correct and complete, it's just waiting on a service that
doesn't exist. Two stand-in fallbacks
(`readonly property var displayChanges: []` and
`function applyDisplays(): void {}`) were left in place outside the
comment in case anything else still binds to those names.

**Don't try this instead (looks right, isn't):**
- Don't assume a tab existing in a settings window's page list means
  its backing service exists — `pages` is just a list of strings; QML
  happily lets a `visible: currentPage === "X"` block sit there
  broken until someone actually looks at the logs. A structure audit
  (files exist, are instantiated) doesn't catch this; only a
  by-USE check (or reading the actual log output) does.
- Don't try to silence these warnings by guarding every
  `DisplayManager.foo` call with an existence check
  (`typeof DisplayManager !== "undefined"`) — that hides the symptom
  per call site and multiplies the places a future fix has to touch.
  Cutting the page off at the one root (`pages` array) plus a single
  block comment is one change, not a dozen.
- **To bring this back:** write `services/DisplayManager.qml` first,
  exposing (at minimum, based on the still-intact caller code):
  `monitors` (list), `refreshing` (bool), `lastError` (string),
  `refresh()`, `apply(cfgs)`, `fmtScale(v)`, `parseMode(modeString)`,
  `validScalesFor(w, h, currentScale)`. Then un-comment the two blocks
  in `SettingsWindow.qml` and re-add `"Displays"` to `pages` — all
  three together, not piecemeal (partial restoration reintroduces this
  exact bug for whichever piece is still missing).

## 2026-07-12 Bar padding at `0` still left a visible gap under the bar — Hyprland's own `gaps_out` reserves screen-edge space independently of the shell's `exclusiveZone`

**Trying to do:** After adding per-edge bar padding (top/side/bottom,
same session), the maintainer set bottom padding to `0` expecting the
bar to sit flush against whatever tiled below it. Screenshot showed a
persistent gap anyway.

**What went wrong:** Two separate systems both reserve space under the
bar, and only one of them was configurable from the shell:
`TopBar.qml`'s `exclusiveZone` (Quickshell/Wayland — how much the
*shell* reserves) and Hyprland's own `general.gaps_out` (how much
*Hyprland* insets every tiled window from every screen edge,
independently of any compositor client's exclusive zone). Zeroing the
shell's contribution left Hyprland's `gaps_out` fully in effect,
which read as "padding did nothing."

**What fixed it:** Let bottom padding go negative (down to `-100px`)
so it can cancel out `gaps_out` from the shell side, without touching
the separate Hyprland gaps setting. This surfaced a smaller trap of
its own: the padding override system already used `-1` to mean "no
override, follow the theme" (same convention as
`barBorderWidthOverride`), and once real negative values became legal
for Bottom, `-1` was no longer distinguishable from an intentional
"-1px" choice. Fixed by giving Bottom a dedicated far-out-of-range
sentinel (`UserPrefs.barPaddingBottomOffSentinel = -9999`) instead of
reusing `-1`; Top/Side were left on `-1` since they were never asked
to go negative. Also had to clamp `TopBar.qml`'s
`exclusiveZone` to a minimum of 0 — Wayland's exclusive zone protocol
doesn't accept negative values, and a large enough negative bottom
padding could otherwise produce one.

**Don't try this instead (looks right, isn't):**
- Don't assume "the shell's own padding is 0" means "there's no gap" —
  check whether the compositor itself is also reserving space on that
  edge (`gaps_out`, `gaps_in`, or similar) before concluding the
  shell-side value is wrong.
- Don't reuse an existing "-1 = off" sentinel for a control once real
  negative values become valid input for it — audit every place that
  sentinel is checked (`>= 0`, `< 0`) when widening a range; a stray
  `>= 0` check left over from before still silently mis-reads a real
  `-1` as "off." (Caught here in the toggle's ON/OFF logic and the
  StepperRows' `visible` bindings, both of which originally checked
  `shownBarPaddingBottomOverride >= 0`.)

## 2026-07-12 Hyprland active-window border color went stale on theme switch — it's baked into a generated file as a static string, not a live binding

**Trying to do:** Added a Hyprland active-border-color control (theme
color or custom hex, mirroring the bar border) to the Hyprland
settings page. Maintainer confirmed the custom-color path worked, but
reported that switching themes left the border on the OLD theme's
accent color — it only updated after manually toggling "use theme
color" off, changing something, and toggling it back on.

**What went wrong:** Unlike the shell's own bar border (a live QML
binding — `Theme.colorAccent` changes, the Canvas repaints
immediately), the Hyprland border color is written into
`generated/appearance.lua` as a plain resolved string
(`rgba(RRGGBBAA)`) at the moment `ConfigManager`'s hypr-regen script
runs. That regen is gated behind an internal `_hyprDirty` flag, set by
the Hyprland-page prefs (gaps, border size, rounding) and, once added,
the border color prefs themselves — but NOT by a plain theme switch.
So switching themes updated `Theme.colorAccent` correctly in the
shell's own UI, while the already-generated Hyprland file kept
whatever color was baked in at the last regen — visually "stale until
something else happens to trigger a regen."

**What fixed it:** The `themeName` case in `_performStagedWrites`'s
switch now also sets `_hyprDirty = true`, but only when
`UserPrefs.hyprActiveBorderUseThemeColor` is on (no point regenerating
an unrelated file for a maintainer using a custom, theme-independent
color). Property bindings in QML resolve synchronously, so by the time
the post-loop `if (_hyprDirty)` block runs — after every case in the
switch has executed, regardless of the order changes were listed in —
`Theme.colorAccent` already reflects the new theme.

**Don't try this instead (looks right, isn't):**
- Don't assume a value read from a live QML singleton (`Theme.*`) stays
  live once it's written into a generated file on disk by an external
  process (bash, in this case). The generated file is a snapshot at
  write time; anything that can change the source value needs an
  explicit trigger to re-snapshot, even if that trigger doesn't look
  related to the file's own settings page at first glance (theme
  switching happens on the Appearance page; the file it invalidates is
  owned by the Hyprland page).
- When adding a new "derived from theme" value anywhere in this
  project, check whether ANYTHING regenerates a file from it, and if
  so, whether a theme switch is in that thing's dirty-trigger list —
  it's an easy case to miss because "theme switch" doesn't obviously
  look like a Hyprland-page event.

## 2026-07-11 Inline regex LITERAL with `{n}` quantifiers silently misparses in a QML property binding — hex validation returned backwards, and typed custom colors "never persisted" for five debugging rounds

**Trying to do:** Let the user type a custom hex color (e.g. `#00ff00`)
into the bar-border / desktop-clock color fields in the settings window
and have it stick. Symptom the maintainer reported: preset-swatch picks
always persisted, but hand-TYPED colors never reached disk —
user-prefs.json kept its old value no matter what.

**What went wrong (the real cause, found last):** In
`widgets/Settings/SettingsWindow.qml`, the HexColorRow field's validity
check was written as a property binding with the regex INLINE:

```qml
readonly property bool hexValid:
    /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(text)
```

In a QML **property-binding expression**, a regex literal that contains
`{6}` / `{8}` brace-quantifiers gets misparsed — the `{`/`}` collide with
QML's own block/object-literal braces, so the expression the engine
actually evaluates is NOT the regex you wrote. Live per-keystroke logging
proved it returned the exact OPPOSITE of the truth:

```
text=""        valid=true    ← empty string marked VALID
text="#00ff00" valid=false   ← a perfect 6-digit hex marked INVALID
```

Because `onTextEdited` only stages `if (valid)`, every complete color the
user typed was rejected at the door and never staged; the only thing that
ever passed was the empty seed, so an empty/garbage value (or nothing) got
committed. Staging, ConfigManager, and UserPrefs were all working
correctly the whole time — the value was being thrown away one step
before staging.

**Why swatches worked but typing didn't (the red herring that cost time):**
Swatch picks are validated ONLY by `UserPrefs._validHex`, which uses the
IDENTICAL regex but inside a **function body**, where it parses correctly.
Typed values were gated by the broken **binding**. So two code paths that
looked like "the same regex" were not running the same code, and the one
that failed was invisible until per-keystroke logging exposed it. Four
earlier fix attempts (write/reload race, activeFocus resync guard,
lastStagedByMe, select-all-on-focus) all assumed the value was being LOST
downstream and were chasing a phantom; the real bug was upstream validity.

**What fixed it:** Drive validity from a function that builds the pattern
from a STRING via `new RegExp(...)` — no literal slashes or braces for the
QML binding parser to choke on. This is the SAME safe form `shell.qml`
already uses (`new RegExp(p).test(s.name)`):

```qml
function hexValidText(t) {
    return new RegExp("^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$").test(t);
}
```

`onTextEdited` calls `hexValidText(text)` directly (fresh, no dependence on
signal ordering); the `hexValid` bool property is recomputed in
`onTextChanged` for the readers that need it (field/swatch/border color).
Verified in a JS engine: accepts `#00ff00` / `#c678dd` / 8-digit
`#AARRGGBB`, rejects `#c678d` (5) / `#1234567` (7) / empty. Confirmed live:
typing `#00ff00`, `#00ff01`, `#011111` each staged and committed exactly.

**Don't try this instead (looks right, isn't):**
- Do NOT put a regex LITERAL with `{n}` quantifiers directly in a QML
  property-binding expression (`property bool x: /.../.test(...)`). It can
  silently evaluate to something other than your regex. Build it from a
  string with `new RegExp("...")`, OR move the `.test()` into a function
  body (both parse correctly). When in doubt, log the actual boolean on
  real input before trusting it.
- Do NOT assume two call sites share behavior just because they contain the
  same regex text — a regex in a function body and the same regex in a
  binding are NOT equivalent under the QML parser. If one path works and a
  "identical" one doesn't, suspect the CONTEXT, not the pattern.
- Do NOT keep fixing staging/persistence/timing when a value "doesn't
  save." First confirm the value is even VALID at the input gate. One
  `console.log` of `(text, isValid)` per keystroke would have found this in
  round one instead of round five.

**General rule for future settings work:** every new validated input
(numbers with min/max, hex, names, paths) gets its validator as a FUNCTION,
never an inline-literal binding — and gets a one-line sanity check against a
known-good and known-bad value before wiring it to staging. The whole
HexColorRow validator pattern is now the reference; copy it, don't
re-invent an inline `.test()`.

## 2026-07-09 The gear menu silently didn't exist — SettingsMenu.qml was never instantiated (manual-restore casualty #3)

**Trying to do:** Run the ConfigManager Phase-1 "money test," which
uses the gear menu's toggles as the visible readout of
user-prefs.json. Maintainer: "there is no gear menu in the bar."

**What went wrong:** SettingsMenu.qml existed in widgets/TopBar/ but
nothing instantiated it — TopBar.qml's module rows had no
`SettingsMenu {}`. Cause: the 07-05 manual flat-file restore (after
the settings-menu incident) brought back a PRE-07-05 TopBar.qml whose
revision history ends at 07-04, from before the gear menu was added.
The menu had been dark ever since, and nothing ever errored: an
uninstantiated QML file is completely silent, and "a menu is missing
from the bar" looks like nothing. Third confirmed casualty of that
one restore, after the NotificationPopups misplacement and the
duplicate themes folder (both found 07-09 by structure audit — this
one was only findable by USE).

**What fixed it:** One line: `SettingsMenu {}` added to the right
RowLayout in TopBar.qml (far right, after Clock, with a Separator).

**Don't try this instead (looks right, isn't):** Don't assume a
feature documented as built is actually WIRED after any manual file
surgery — the changelog says what was built, not what's currently
instantiated. After restoring files by hand, diff the restored tree
against a known-good one AND click every documented feature once. A
structure audit catches misplaced/duplicated files; only usage
catches a correctly-placed file that nothing references.

## 2026-07-09 Verified: JsonAdapter fed garbage keeps in-memory values (one WARN, no reset, UI unaffected)

**Trying to do:** Phase-1 restore test — deliberately corrupt
user-prefs.json (`echo 'GARBAGE{{{' > ...`) with the shell live and
FileView watching, to learn what actually happens before trusting the
restore path. This behavior was previously undocumented and unknown.

**What happened (the finding):** exactly one WARN — `QML JsonAdapter:
Failed to deserialize json: illegal number` — and NOTHING else.
In-memory values retained, no reset to defaults, SettingsMenu toggles
kept working, clocks unaffected. The shell runs on last-known-good
until valid JSON appears (a ConfigManager restore, or any toggle
write, which serializes good state right over the garbage).

**Worth knowing (both directions):** this makes the prefs file
self-healing — but it also means a malformed HAND-EDIT is silently
clobbered by the next toggle write. Recorded in UserPrefs.qml's
DESIGN NOTES. Also confirms FileView's watch survives the file being
replaced by `cp -a` (restore) and rewritten by shell redirection
(the mangle): both were picked up live, same inode or not.

> **RESOLVED 2026-07-09 (Fable 5):** the deferred Theme.qml half of the
> 2026-07-05 partial-revert finding below is CLOSED. Runtime theme
> switching was rebuilt (named-children instances + parenthesized map
> — never inline instantiation in an object literal, the prime suspect
> for the original breakage) and live-confirmed working. See
> REVISION_HISTORY's Phase 2 entries and core/Theme.qml's notes.

## 2026-07-05 Wallpaper picker "lag" was full-size images silently loading instead of thumbnails — root cause found, prior investigation below was chasing a phantom

**Trying to do:** Fix grey-box pop-in and (during one bad experiment)
single-digit-fps scrolling in the wallpaper picker on a 1000+ collection.

**Root cause:** `Settings.wallpapersThumbDir` defaulted to `".thumbs"`
(hidden folder), but the thumbnail-generation script's `THUMB_DIR` was
hardcoded to `"$HOME/Pictures/Wallpapers/thumbs"` (no dot) — the two
never agreed. Every single lookup silently missed — the picker's own
deliberate "no matching thumb? fall back to the full image" behavior
then engaged for EVERY wallpaper, meaning the picker was decoding
full-size, multi-megapixel originals for every cell the entire time,
not the small pre-squared thumbnails the design assumes. That fully
explains both symptoms: grey pop-in is just normal decode latency for
a large image; the fps collapse during the async-off experiment is
what forcing that same large-image decode onto the main thread looks
like.

**What fixed it:** Match `Settings.wallpapersThumbDir` to whatever your
actual thumbnail folder is really called (or vice versa — just make the
two agree; this project settled on renaming the folder AND the script's
`THUMB_DIR` to `.thumbs`, matching Settings). Also worth a `ls` check
any time thumbnail generation and the Settings path are maintained as
two separate things, since nothing errors when they drift apart — the
fallback exists precisely so a missing thumb never breaks the picker,
which also means a *systematic* mismatch degrades silently instead of
loudly.

**Don't try this instead (looks right, isn't):** Don't chase decode
performance, `GridView` recycling behavior, `cacheBuffer` tuning, or a
custom caching layer for lag like this before confirming actual
thumbnails (not originals) are what's loading. Check the warn/debug log
for `Invalid image provider` or simply eyeball what folder the loaded
paths point at — a symptom that "shouldn't be this slow for a small
thumbnail" is a strong hint the thing loading ISN'T a small thumbnail.

**Superseded:** an earlier version of this entry documented a same-night
investigation (preload pools, a "Grid decoding" diagnostic counter,
shuffle-freeze workarounds, a partial `cacheBuffer: 0` test) that
concluded the lag was "inherent to GridView's own cacheBuffer/reuseItems
scroll-recycling." That investigation almost certainly ran against this
same masked bug the whole time (the thumb-dir mismatch predates it) and
its specific findings — including the decode-counter result — should
NOT be treated as reliable evidence about GridView, Qt's image cache, or
delegate construction cost. None of that theorizing has been reproduced
under correctly-matched thumbnails. If a genuine performance issue shows
up again after confirming real thumbnails ARE loading, that's a fresh
investigation, not a continuation of the old one.

## 2026-07-05 Settings menu built ahead of the Theme.qml revert — Appearance section and clock toggles are silently dead (FOUND, NOT YET FIXED — deliberately deferred)

**Trying to do:** A routine "once over" of re-uploaded project files
after an unrelated feature request (wallpaper thumbnail caching),
requested explicitly by the maintainer after re-syncing project
knowledge.

**What went wrong:** The prior session's settings-menu attempt (theme
switching, wallpaper caching toggle, clock display toggles) regressed
`core/Theme.qml` to everything-undefined and got reverted to backup
mid-session, per the maintainer's own account ("reverted back to the
last revision, but with the small changes we made at the start of the
chat"). That revert was **partial**: `core/Theme.qml` itself went back
to the safe pre-session shape (hardcoded `property var active:
HoneycombTheme {}`, no `themes` map, no `themeNames`) — but
`widgets/TopBar/SettingsMenu.qml`, `core/UserPrefs.qml`, and the
`Settings.qml` removal of `clockUse24Hour`/`clockShowSeconds` were ALL
kept, because they were built earlier in that same session, before the
theme-switching work specifically broke. Nobody reconciled the two
halves. Concretely, right now:

- `SettingsMenu.qml`'s "Appearance" section binds a `Repeater` to
  `Theme.themeNames` — which doesn't exist on the current `Theme.qml`.
  Not a crash (a `Repeater` on an `undefined` model just renders zero
  rows) — the Appearance header shows with nothing under it.
- `widgets/TopBar/Clock.qml` still reads `Settings.clockUse24Hour` /
  `Settings.clockShowSeconds` — properties that were REMOVED from
  `Settings.qml` (moved to `UserPrefs.qml`, per that file's own
  REVISION HISTORY). Not a crash either — `Settings.clockUse24Hour`
  just evaluates to `undefined` (falsy), so the clock silently always
  renders 12-hour, no-seconds, regardless of what
  `UserPrefs.clockUse24Hour`/`clockShowSeconds` actually hold. The
  SettingsMenu toggles for these write to `UserPrefs` correctly and
  persist to disk correctly — they just have zero visible effect,
  because the ONE file that should read them never got updated to the
  new location.
- `UserPrefs.wallpaperCachingEnabled` existed with a working persisted
  toggle in `SettingsMenu.qml` ("Cache Thumbnails") but nothing read it
  — `WallpaperPicker.qml` never referenced `UserPrefs` at all. (This
  specific piece IS now fixed — see the entry below. The Appearance/
  Clock pieces are NOT.)

**What fixed it:** Nothing yet, by the maintainer's explicit choice —
asked to defer `Theme.qml`/`SettingsMenu.qml`/`Clock.qml` work to a
later session ("that can be a later thing") after the Theme.qml
regression from the prior session. Documenting this now so it isn't
silently rediscovered as a fresh bug later, and so a future session
knows the Appearance section and clock toggles are known-nonfunctional
rather than something to re-diagnose from scratch.

**Don't try this instead (looks right, isn't):** Don't assume that
because the shell loads cleanly with no errors or warnings, every
UI control in it actually does something — this class of bug (a
`Repeater` on an undefined model, a stale property reference that
resolves to `undefined`) fails completely silently in QML. When
reconciling a partial revert (some files rolled back, others kept),
explicitly cross-check every file that was kept for references to
whatever got rolled back, rather than trusting that "it loads fine" is
enough validation. If/when this gets fixed properly: `Theme.qml` needs
the `themes` map + `themeNames` restored (carefully, ideally by
comparing against what actually broke last time rather than
re-attempting the same change), and `Clock.qml` needs its two
`Settings.clock*` references swapped to `UserPrefs.clock*`.

## 2026-07-05 Wallpaper picker never actually cached anything, despite a working toggle for it

**⚠ SUPERSEDED — see the top entry in this file** ("Wallpaper picker
'lag' was full-size images silently loading instead of thumbnails").
The fix below looked complete and tested fine in isolation, but was
never actually the cause of the real 1000+-collection lag reported
later — that turned out to be a thumbnail-folder path mismatch. Read
the top entry for what actually happened.

**Trying to do:** Add a "cache thumbnails" option to the wallpaper
picker per the original ask (a 1000+ wallpaper collection was slow to
re-populate on every open).

**What went wrong:** Discovered while wiring this up: `UserPrefs.qml`
already had a persisted `wallpaperCachingEnabled` property, and
`SettingsMenu.qml` already had a working "Cache Thumbnails" toggle
that correctly read/wrote it — both left over from the same
partially-reverted prior session as the entry above. But
`WallpaperPicker.qml` never referenced `UserPrefs` at all, so flipping
that toggle did precisely nothing.

**What fixed it:** `WallpaperPicker.qml`'s `rescan()` now checks
`UserPrefs.wallpaperCachingEnabled`: if it's on and a listing already
exists, skip the folder scan (`listProc`) entirely on reopen — only
the cheap current-wallpaper query re-runs. Since the popout window is
never destroyed on close (only hidden — see BarPopout.qml's DESIGN
NOTES), not replacing the `wallpapers` array means the GridView's
already-decoded thumbnail Images just stay alive, so reopening is
instant. Added a second checkbox in the picker's own header, next to
Shuffle, driving the SAME `UserPrefs` property (not a separate
setting) — so the gear-icon menu and the picker's own header are two
entry points to one real setting now, instead of one working and one
dead.

**Don't try this instead (looks right, isn't):** Don't assume a
toggle that reads/writes cleanly to a persisted property is
"working" — check whether anything downstream actually consumes that
property's value. `SettingsMenu.qml`'s checkbox looked completely
correct in isolation (correct read, correct write, persists across
restart) while doing absolutely nothing, because the consumer side was
simply never built.

## 2026-07-05 Bluetooth pairing silently rejected — "Authentication attempt without agent"

**Trying to do:** Add discovery + pairing to the Bluetooth popout (scan
for new devices, click to pair) — connect/disconnect of already-paired
devices already worked fine.

**What went wrong:** Scanning worked immediately — new devices showed
up in the popout. Clicking to pair a controller just sat on
"(pairing…)" and never completed, with no error surfaced in the UI.
`journalctl -u bluetooth -f` during a pairing attempt showed the real
cause: `Authentication attempt without agent` /
`profiles/input/server.c:auth_callback() Access denied:
org.bluez.Error.Rejected`. BlueZ requires SOME agent to be registered
before it will authorize ANY new pairing — even PIN-less "Just Works"
pairing still needs something to approve the authorization request —
and nothing in this project had ever registered one. Already-paired
devices were unaffected because BlueZ already has a stored trust
relationship for those and doesn't need a fresh authorization decision
just to reconnect.

**What fixed it:** New `services/BluetoothAgent.qml` — keeps a
`bluetoothctl` process alive for the whole shell session purely to run
`agent NoInputNoOutput` + `default-agent` once at startup, registering
it as BlueZ's default agent. Restarts itself (2s timer) if the process
ever dies, so the agent stays registered even across a bluetoothd
restart. Forced to instantiate at shell startup via a throwaway
property reference from `widgets/TopBar/Bluetooth.qml` (same trick
`services/Notifs.qml` uses via `NotificationPopups.qml` — a `pragma
Singleton` type only gets created the first time something references
it).

**Don't try this instead (looks right, isn't):** Don't assume
`bluetoothctl` (or a GUI equivalent like blueman-applet) is always
running somewhere in the background — this is a from-scratch shell
with nothing like that running unless something in this project
explicitly starts it. If a Bluetooth feature added later ever needs to
accept an INCOMING pairing request (rather than initiate one, like
this popout does) or needs actual PIN entry, this NoInputNoOutput agent
won't be enough — that's a genuinely bigger feature (properly
implementing `org.bluez.Agent1`'s PIN-handling methods) and is out of
scope here on purpose, matching the reference project's own scope
decision to not build a pairing-agent UI either.

## 2026-07-05 `Timer is not a type` — forgot `import QtQuick` twice in the same session

**Trying to do:** Add a background `Timer` to a `pragma Singleton`
service file — first in `services/Network.qml`, then again later the
same session in the new `services/BluetoothAgent.qml`.

**What went wrong:** Both files only imported `Quickshell` and
`Quickshell.Networking`/`Quickshell.Io` — `Timer` is a QtQuick type,
not a Quickshell one, and without `import QtQuick` the whole shell
failed to load with a cascading error chain (`Timer is not a type` ->
the file that used it -> everything that imports that file ->
`shell.qml` itself, reported as e.g. `Type TopBar unavailable`). Hit
this exact mistake twice in one session, in two different new files.

**What fixed it:** Add `import QtQuick` to any `pragma Singleton`
service file that uses `Timer`, `Component.onCompleted`, or any other
QtQuick-provided basic — `Quickshell`, `Quickshell.Io`, and
`Quickshell.Networking` don't pull those in for free.

**Don't try this instead (looks right, isn't):** Don't assume a new
service file's imports are "probably fine" just because similar
existing files in this project happen to work without `import
QtQuick` — check whether THIS file actually uses anything QtQuick-only
before skipping the import. `services/Network.qml`'s original version
never needed it because it had no Timer; the moment one was added, the
missing import became a real bug immediately and loudly (a load-time
error, not a silent one — at least this class of mistake fails fast
and unambiguously, unlike the Wifi list bug below).

## 2026-07-05 Wifi popout showed connection status fine but the network list stayed empty — no errors, no warnings

**Trying to do:** Build out the originally-requested full wifi
scan-and-connect experience (toggle, rescan, click-to-connect).

**What went wrong:** Toggle on/off and connection status worked
immediately — confirmed live. But clicking Rescan did nothing; the
network list stayed empty. `nmcli device wifi list` run directly in a
terminal showed every nearby network correctly, and `qs` printed zero
warnings or errors on rescan — nothing crashing, the list just never
populated. The bug was in `Networking.wifiDevice.networks.values`
(Quickshell's own built-in `Quickshell.Networking` module) — it never
got populated with scan results in this Quickshell version, silently.

**What fixed it:** Stopped relying on `Networking.wifiDevice.networks`
for the network list entirely. `services/Network.qml` now parses
`nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list` directly
(terse output, colon-escaped, deduped by SSID, strongest signal wins).
Cross-checked against a maintained real-world Quickshell config before
writing this — it does the exact same thing, parsing nmcli output
rather than trusting that particular Quickshell API for the scan list.
Connection
status/toggle (`wifiEnabled`, `wifiConnected`, `wifiSsid`, etc.) still
come from `Networking` — those were never broken, only the per-network
scan list was.

**Don't try this instead (looks right, isn't):** Don't trust
`Quickshell.Networking`'s per-device `.networks` list to reflect live
scan results just because the module's OTHER properties (enabled
state, active connection) work fine — reading connection status and
reading scan results appear to be handled differently under the hood,
and one working doesn't mean the other does. If a Quickshell
Networking property looks silently stuck (no error, just
empty/stale), check whether the proven-working reference config still
relies on that specific property before assuming it's trustworthy —
here it didn't, and parsing nmcli directly was the actual fix.

**Related, same file:** `rescan()`/`refreshList()` are deliberately
on-demand only — the network list refreshes when the Wifi popout opens
(a cheap non-forcing `nmcli ... list`) or when Rescan is clicked
(forcing `--rescan yes`). An earlier draft of this fix included a
15-second background timer polling nmcli constantly; removed the same
session as unnecessary — there's no reason to run nmcli while the menu
is closed, same principle later applied to Bluetooth discovery above.

## 2026-07-05 Keyboard selection invisible in the wallpaper grid — the project's first live-caught bug

**Trying to do:** Show which grid cell is selected while arrowing
around the wallpaper picker with the keyboard.

**What went wrong:** The selection indicator existed and worked — a
`Theme.colorHover` FILL on the current cell — but the thumbnail image
covers all but a few pixels of each cell, so the fill only peeked
through a ~4px gap around the image edge. Over busy wallpaper
thumbnails that's functionally invisible. Clicking worked fine (you
aim with the cursor), but keyboard navigation was flying blind.

**What fixed it:** Selection is now a 2px accent BORDER around the
cell (reads over any image content), and the "this is the active
wallpaper" marker — which had been using the accent border — moved to
a small corner badge dot ringed in the background color. Two states,
visually distinct even when overlapping.

**Don't try this instead (looks right, isn't):** Don't indicate
state on image-covered cells with a background fill, ever — it
renders BEHIND the content that covers the cell. This applies to any
future image grid (notification images, a wallpaper category view):
state indicators for image cells must be borders, overlays, or badges
drawn ON TOP. Also don't bother tuning the fill color brighter — the
geometry is the problem, not the contrast.

## 2026-07-05 `qs -c <config-name>` errors, and this machine needs no -c at all

**Trying to do:** Run the documented IPC test command
`qs -c <config-name> ipc call wallpapers toggle`.

**What went wrong:** Two stacked issues. First, the literal
placeholder was typed in — bash parsed `<config-name>` as input
redirection from a file named `config-name` ("No such file or
directory"). Second, once past that: this machine has no config name
AT ALL — shell.qml sits directly in `~/.config/quickshell/`, not in a
named subfolder, so there's nothing valid to pass to `-c`.

**What fixed it:** On this machine, plain `qs ipc call <target> <fn>`
with no `-c` flag. All IPC examples in the docs should be read that
way here.

**Don't try this instead (looks right, isn't):** Don't create a
subfolder and move the shell into it just to have a config name for
`-c` — the no-name layout is valid and everything works without it.
And when any doc shows `<angle-bracket>` placeholders, they're never
typed literally; the brackets are the notation, not the syntax.

## 2026-07-05 `systemctl start awww` — "Unit awww.service not found"

**Trying to do:** Start the wallpaper daemon after installing awww.

**What went wrong:** awww ships no systemd unit — it's a plain
daemon binary, not a service. systemctl can only start things that
have unit files. (Secondary lesson in the same command: session-level
things belong to `systemctl --user`; bare `systemctl` talks to the
system manager, which would've been wrong even if a unit existed.)

**What fixed it:** `awww-daemon &` to start it by hand; the permanent
answer is the compositor autostart in hyprland.lua
(`hl.on("hyprland.start", ...)` → `hl.exec_cmd("awww-daemon")`), which
also restores the last wallpaper from awww's cache on every login.

**Don't try this instead (looks right, isn't):** Don't write a custom
user unit for awww-daemon just to make systemctl work — the compositor
hook is the right lifecycle (it should live and die with the Wayland
session). Diagnostic habit worth keeping: when systemctl says "unit
not found," check `pacman -Ql <package> | grep service` to see whether
a unit even exists before assuming a typo.

## 2026-07-05 Literal `{core,services,widgets...}` directories in the config root

**Trying to do:** (Historical — discovered during a structure audit,
created at some earlier setup step.) Create the project folder tree
with `mkdir -p ~/.config/quickshell/{core,services,...}`.

**What went wrong:** The command was run under a shell that doesn't do
brace expansion (plain `sh`, or quoted braces) — so instead of many
directories, it created ONE directory literally named
`{core,services,widgets` with a child named the rest of the pattern.
They sat invisible in the config root until a `find` listing exposed
them. Harmless (empty, not loaded by anything) but confusing in any
listing.

**What fixed it:** `rmdir` on both, quoted paths (rmdir is the safe
tool — refuses to remove anything non-empty).

**Don't try this instead (looks right, isn't):** Don't `rm -rf` glob
patterns containing braces to clean this up — quoting mistakes there
can match real folders. And when scripting mkdir for other machines,
either spell paths out or use explicit loops; brace expansion is a
bash/zsh-ism, not POSIX.

## 2026-07-05 Wallpaper picker showed nothing — path token case mismatch

**Trying to do:** First live open of the wallpaper picker.

**What went wrong:** `Settings.wallpapersPath` shipped with the
guessed default `~/Pictures/Wallpapers`; the real folder on this
machine is lowercase `~/Pictures/wallpapers`. Linux paths are
case-sensitive, the scan's errors are deliberately suppressed
(`2>/dev/null` — missing dirs are an expected state), so the symptom
is just the "No wallpapers found in ..." empty state showing the
wrong-case path.

**What fixed it:** One-line Settings change to the lowercase path —
exactly the fix the token design intended. (Same session the thumbs
dir became `.thumbs`, also one line.)

**Don't try this instead (looks right, isn't):** Don't debug the scan
Process or the find command when the picker shows the empty state —
the empty-state text PRINTS the exact directory being scanned;
read it and check that path exists (`ls -d <path>`) before touching
any QML. General lesson for every future path-shaped Settings token:
defaults are guesses until confirmed against the live machine, and
guessed paths should surface themselves in their failure state (this
one did, which is what made it a 30-second fix).

## 2026-07-04 Current-wallpaper highlight would never match on symlinked dirs (caught before it ever ran)

**Trying to do:** Highlight the currently-displayed wallpaper in the
picker grid by comparing scanned paths against `awww query` output.

**What went wrong:** Nothing yet — this was caught reading swww's
source during the offline verification pass. The awww/swww client
CANONICALIZES image paths before sending them to the daemon
(`img_path.canonicalize()`), so `query` reports symlink-RESOLVED
paths. The picker's `find` scan reported paths as-found under the
configured dir. On a symlinked wallpapers dir (stow-managed dotfiles)
the string comparison would silently never match: no highlight, no
error, nothing obviously broken.

**What fixed it:** The scan pipes wallpaper paths through `realpath`
(coreutils), so both sides of the comparison are canonical.

**Don't try this instead (looks right, isn't):** Don't compare paths
from two different sources as strings without canonicalizing both —
"the same file" has many spellings (symlinks, `..`, double slashes).
And the meta-lesson: when integrating an external tool, reading its
source for the exact output format is cheap and catches bug classes
that testing on ONE machine layout never would have (this machine's
dir isn't symlinked — the bug would've shipped dormant).

## 2026-07-04 A killed notification daemon can resurrect itself via D-Bus activation — killall alone can't hand off the name

**Trying to do:** Free the org.freedesktop.Notifications D-Bus name so
the shell's new NotificationServer could register (only one process
can own the name; another daemon was running at the time).

**What went wrong:** Preemptively documented rather than suffered:
many notification daemons ship a D-Bus activation file, so after
killing one, the next notify from ANY app summons it back before the
shell can grab the name. A plain kill looks sufficient and isn't.

**What fixed it:** Kill the other daemon and reload the shell in the
same breath (shell registers first), with `systemctl --user mask
<daemon>.service` as the option for longer test windows. In the end
the other daemon was uninstalled outright (2026-07-05) and the shell's
daemon worked on the first try; uninstalling removes both the
autostart and the activation file, which is the clean permanent
switchover. The shell has been the machine's only notification daemon
since.

**Don't try this instead (looks right, isn't):** Don't conclude the
shell's NotificationServer is broken because notifications still
render in another daemon's style after killing it — check who owns
the name before debugging QML. And if the shell shows NO
notifications while another daemon is installed, that's this, not a
code bug: Quickshell logs the failed registration but nothing
surfaces in the UI.

---

## 2026-07-03 — Shell failed to launch: "Connections is not a type" in services/Audio.qml

Symptoms: qs refused to load entirely, with a cascade of "Type X
unavailable" errors bottoming out at
`services/Audio.qml: Connections is not a type`.

Cause: the 2026-07-03 Audio rewrite added a `Connections` block (to
rebuild the sink list on Pipewire node changes) without adding
`import QtQuick` — Connections is a QtQuick type, and the file's
original import list never included QtQuick because it never needed it
before. One unresolvable type makes the whole file fail to load, which
takes down every file that depends on it, up to shell.qml itself.

Fix: added `import QtQuick` to services/Audio.qml.

Lesson: when adding a new QML type to a file, check the type's module
against the file's existing imports — a file's import list only covers
what it used YESTERDAY. Also note the error cascade pattern: the real
problem is always the DEEPEST "caused by" line, not the top one.

## 2026-07-03 — Every Audio/Network function threw "not a function"; volume % and backendAvailable read wrong

Symptoms: volume % broken, wifi showed "NetworkManager Off", and every
popout action logged `TypeError: Property 'x' of object Audio/Network is
not a function`. Bluetooth unaffected.

Cause: the 2026-07-03 rewrites of services/Audio.qml and
services/Network.qml dropped the `pragma Singleton` line. It was lost
because the originals were read starting from the first `import` line,
which cut off the pragma above it — the rewrite faithfully reproduced
everything that was visible. Without the pragma, `import qs.services`
resolves Audio/Network as component types, not singleton instances:
properties read as garbage and functions aren't callable, with no load
error.

Fix: `pragma Singleton` restored as line 1 of both files.

Lesson: a Quickshell singleton needs BOTH the `Singleton {}` root type
AND `pragma Singleton` — the root type alone loads without complaint
and fails only at the call site. Also: when reading files to reproduce
them, read from line 1, not from the first import.


## Format for new entries

```
## [Date] Short description of the problem

**Trying to do:** ...

**What went wrong:** ...

**What fixed it:** ...

**Don't try this instead (looks right, isn't):** ...
```

---

## 2026-07-02 — Wifi widget permanently shows "Could not find an available backend"

**Trying to do:** Get `widgets/TopBar/Wifi.qml` / `services/Network.qml`
showing real wifi status, after `qs` logged `ERROR quickshell.network:
Network will not work. Could not find an available backend.` at startup
and the widget never showed anything but "Wifi Off"/"Disconnected."

**What went wrong:** Nothing in this project's QML — the error is
Quickshell itself failing to find a working network backend at launch.
`Networking.devices` stays permanently empty in this state, which is why
the widget had nothing real to show no matter what the QML did.

**What fixed it:** Read `Quickshell.Networking`'s own module doc (not
just the per-type reference pages — see the second gotcha in this
project's 2026-07-02 entry below), which states plainly: "For now, the
only backend available is the NetworkManager DBus interface. Both DBus
and NetworkManager must be running to use it." If NetworkManager isn't
installed or isn't running, this error is expected, not a Quickshell or
project bug.

Check:
```bash
systemctl status NetworkManager
```
If it's inactive or not installed:
```bash
sudo pacman -S networkmanager
sudo systemctl enable --now NetworkManager
```
NetworkManager coexisting with a home PC that "never roams" (see
`docs/services-README.md`'s old note on the removed `wifi-menu.sh`) is
fine — running it doesn't force any auto-connect/roaming behavior, it's
just the connection manager Quickshell's Networking module is able to
talk to. If NetworkManager is already running and this error still
shows, that's a genuinely different problem worth its own investigation
(check `NM.service` logs, confirm `dbus` itself is up) — don't assume
this fix covers every cause of the same error message.

**Don't try this instead (looks right, isn't):** Don't assume this is a
Quickshell version issue or a bug in `services/Network.qml`'s device-
picking logic and start rewriting that file — the symptom (empty device
list, generic "Disconnected") is identical whether the code is perfect
or badly wrong, because there's nothing for either version of the code
to find. Confirm the backend is actually running FIRST, before touching
any QML. As of Quickshell 0.3.0, there is no IWD/systemd-networkd
backend to switch to instead — NetworkManager is currently the only
option, full stop.

---

## 2026-07-02 — Volume showed "NaN%" despite Audio.qml looking correct

**Trying to do:** Show the current PipeWire sink's volume as a
percentage in `widgets/TopBar/Volume.qml`, reading from
`services/Audio.qml`.

**What went wrong:** The bar displayed "NaN%" instead of a real number.
`services/Audio.qml`'s `volume` property was gated behind a computed
`ready` check (`sink !== null && sink.ready && sink.audio !== null`)
that itself evaluated `true`, so the gate wasn't the problem on its
face — but `sink.audio.volume` was still coming back `undefined` at the
point it got read. `undefined * 100` is `NaN` in JavaScript, and QML
assigns that into a `real` property with no error or warning at all —
it just silently displays as "NaN" wherever the property gets used in a
string.

**What fixed it:** Rewrote the property using optional chaining with an
explicit numeric fallback at every step, instead of trusting a single
upstream `ready`-style flag to mean every downstream property is
populated:
```qml
readonly property real volume: {
    const v = sink?.audio?.volume ?? 0;
    return Number.isFinite(v) ? v : 0;
}
```
This is the same pattern a real, maintained Quickshell shell in the
wild uses for its own audio service — confirmed by reading actual
working source rather than assuming. The `Number.isFinite` check is
intentionally redundant with the `?? 0`: if PipeWire ever reports a
genuinely non-finite volume for some node (e.g. one with zero audio
channels, where an "average across channels" computes as `0/0`), this
still catches it before it reaches the display.

**Don't try this instead (looks right, isn't):** Don't trust a
`sink.ready`-style check as sufficient just because it's non-null and
evaluates `true` — a `PwNode` reporting itself "ready" doesn't
guarantee every nested property under `.audio` is actually populated
yet, and there's no error to signal the gap, just a silent `NaN`. Also:
don't copy a QML snippet from a GitHub issue thread and treat it as a
verified-good pattern just because it's the top search result — the
`sink.ready` check this project's original `Audio.qml` used came from
quickshell-mirror/quickshell#54, which is the bug report itself, not a
working example. If the fix above still doesn't resolve it on the
actual machine, that points below Quickshell (PipeWire/WirePlumber
routing) — check `wpctl status` and `wpctl get-volume
@DEFAULT_AUDIO_SINK@` against what the bar shows, and grep the full `qs
log` output (not just what's visible in a terminal screenshot) for
`quickshell.service.pipewire` lines before assuming the QML is still
wrong.

---

## 2026-07-02 — Bluetooth connected-device count didn't match reality

**Trying to do:** Show a count of currently-connected bluetooth devices
in `widgets/TopBar/Bluetooth.qml`, using `Bluetooth.devices.values.length`
directly per Quickshell's own doc description of that property ("a list
of all connected bluetooth devices across all adapters").

**What went wrong:** With exactly one bluetooth device actually
connected (a DualSense controller), the bar showed a count of 5.

**What fixed it:** Stopped trusting the doc's "already filtered to
connected" claim and filtered explicitly instead:
```qml
readonly property int connectedCount: Bluetooth.devices.values.filter(d => d.connected).length
```
This produces the correct count regardless of whether the root cause
was a doc/implementation mismatch, some quirk of how this particular
DualSense controller registers over BlueZ, or something else entirely —
the underlying "why" was never actually confirmed, just worked around
robustly.

**Don't try this instead (looks right, isn't):** Don't assume a
Quickshell type's own doc description of a property's contents is
accurate without checking, especially for anything list-shaped where
"already filtered" is doing a lot of work in one sentence. When a count
or list looks wrong, filtering explicitly on the specific condition you
actually care about is cheap insurance — even if the doc turns out to
have been right all along, the explicit filter costs almost nothing and
removes an assumption from the code.

---

## 2026-07-01 — Binding PopupWindow.visible directly breaks after the first outside-click dismiss

**Trying to do:** Make SystemMenu's dropdown close when clicking
somewhere else on screen (another window, the desktop, etc.), using
`PopupWindow`'s `grabFocus: true` property.

**What went wrong:** The obvious-looking implementation was:

```qml
property bool menuOpen: false
PopupWindow {
    visible: menuOpen   // looks fine!
    grabFocus: true
}
```

This works exactly once. `grabFocus: true` makes Quickshell itself set
`visible = false` when the user clicks outside the popup — an
imperative assignment. In QML, imperatively assigning to a property
that currently holds a declarative binding (`visible: menuOpen`)
permanently destroys that binding. So the first time an outside click
closes the menu, the connection between `menuOpen` and `visible` is
gone for good — clicking the icon again still flips `menuOpen`, but
nothing is listening to it anymore, and the popup stays stuck closed
(or, depending on timing, falls out of sync in some other confusing
way).

**What fixed it:** Never declare `visible: menuOpen` as a binding at
all. Instead, sync the two properties manually, in both directions:

```qml
property bool menuOpen: false
onMenuOpenChanged: menuPopup.visible = menuOpen

PopupWindow {
    id: menuPopup
    grabFocus: true
    onVisibleChanged: {
        if (root.menuOpen !== visible) root.menuOpen = visible
    }
}
```

Since neither side is ever a declarative binding, there's nothing for
`grabFocus`'s imperative dismissal to break. `menuOpen` stays the single
source of truth for our own logic (used for icon coloring, animation
target, etc.), and `visible` mirrors it — except when `grabFocus` moves
it first, in which case the `onVisibleChanged` handler catches that and
syncs `menuOpen` back down.

**Don't try this instead (looks right, isn't):** Don't bind any property
declaratively (`someProp: otherProp`) if something else in the system —
a built-in mechanism like `grabFocus`, a C++-side behavior, anything
outside direct control — might also assign to that same property
imperatively. The binding will work fine right up until the first
external assignment, then silently stop working with no error, which
is a nastier failure mode than if it had never bound at all. This
applies beyond popups: any Quickshell property documented as being
"set" by some automatic behavior (dismissal, animation completion,
focus changes) is a candidate for this same trap.

---

## 2026-07-01 — Nerd Font icon codepoints and unverified system commands both fail silently

**Trying to do:** Add an Arch Linux icon to SystemMenu.qml, and give it
a "Restart Hyprland" action matching an existing Super+M keybind.

**What went wrong:** Neither of these has a fast feedback loop.
- **Icons:** Nerd Font glyphs live in the Unicode Private Use Area — if
  you guess a codepoint and get it wrong, there's no error. It just
  renders as an empty box (or nothing, or a totally different icon than
  intended), and you won't know without actually looking at it rendered
  in the target font.
- **System commands:** "Restart Hyprland" could mean `hyprctl reload`
  (safe, just reloads config), fully restarting the Hyprland process
  (kills every open app), or a custom script bound to Super+M — and
  there was no way to check which one was actually intended without
  access to the real `hyprland.conf`.

**What fixed it:**
- For the icon: looked up the actual codepoint (U+F303 for
  `nf-linux-archlinux`) against a live source before using it, rather
  than recalling one from memory.
- For the command: picked the safest option that couldn't cause damage
  if wrong (`hyprctl reload` — reloads config, doesn't close anything or
  log out) and flagged it loudly in the code (a ⚠ comment in
  SystemMenu.qml's DESIGN NOTES) and in `docs/REVISION_HISTORY.md`,
  rather than silently guessing and moving on.

**Don't try this instead (looks right, isn't):** Don't guess a Nerd Font
PUA codepoint from memory and assume it's right because it "looks
plausible" — verify it against the actual font's glyph list or a
current reference before shipping it. Don't guess at what an existing
keybind does when the guess could be destructive (logging out, killing
processes, deleting data) — pick the least-destructive interpretation
that still does *something* useful, and flag the guess clearly enough
that it won't quietly become "how it's always worked."

---

## 2026-07-01 — Hyprland.dispatch() failed on workspaces other than the focused one

**Trying to do:** Make workspace indicators in `widgets/TopBar/Workspaces.qml`
clickable, switching to that workspace via `Hyprland.dispatch("workspace "
+ workspaceId)`.

**What went wrong:** Clicking the currently-focused workspace's own
indicator worked (a no-op, switching to where you already are). Clicking
any other workspace number failed, logging errors like:

```
WARN quickshell.hyprland.ipc: Dispatch request "workspace 4" failed with
error "error: [string \"return hl.dispatch(workspace 4)\"]:1: ')'
expected near '4'\n \xE2\x86\x92 Note: dispatch in lua is a shorthand for
hl.dispatch(...), your syntax might need to be updated."
```

Same shape of error for every workspace number tried (3, 4, 5 all
failed the same way). This points at a mismatch between how Quickshell
sends the dispatch string and how this Hyprland version's IPC layer
expects to receive it — Hyprland appears to be interpreting the dispatch
call through a Lua shim and choking on the argument, not on anything
specific to workspace numbers or to this project's code.

**What fixed it:** Didn't chase the root cause — removed click-to-switch
entirely instead (the `MouseArea` and the `dispatch()` call). Workspace
switching happens via Hyprland keybinds in normal use, so the broken
feature wasn't worth debugging further right now.

**Don't try this instead (looks right, isn't):** Don't assume this is a
Quickshell bug or a project-code bug just because the error is logged as
`quickshell.hyprland.ipc:` — the error text itself is coming from
Hyprland's own dispatch layer (the Lua shim), relayed through
Quickshell's log. If this gets revisited later: check the installed
Hyprland version's release notes around dispatch/IPC/Lua config changes
first, and check whether `Hyprland.dispatch()`'s expected argument
format changed in a recent Quickshell release, before assuming the fix
is in this project's QML.


> **RESOLVED (retro-note added 2026-07-05; explanation found
> 2026-07-04):** the machine's Hyprland config is **hyprland.lua**
> (Hyprland deprecated hyprlang for Lua config in 0.55, April 2026).
> The failures above were old-style dispatch strings being sent into a
> Lua-configured Hyprland. The launcher/wallpaper-picker global
> shortcuts work through `hl.bind(... hl.dsp.global("appid:name"))` on
> the Lua side, and Quickshell-side dispatching wants Lua-form
> dispatch strings when the compositor is Lua-configured. The
> abandoned click-to-switch-workspace feature in Workspaces.qml is
> therefore probably fixable now.

---

## 2026-07-01 — Almost built a custom Hyprland service that already exists

**Trying to do:** Build a workspace indicator for TopBar — needs to know
which workspaces exist, which is focused, and be able to switch on click.

**What went wrong:** `services/README.md`'s roadmap (written before any
service existed) assumed this would need a hand-rolled `Hyprland.qml`
service parsing `hyprctl`'s JSON output or talking to Hyprland's IPC
socket directly, same shape as the planned Audio/Battery/Network
services. Started down that path before checking whether Quickshell
already had something better — same mistake pattern as the clock
(see the `SystemClock` entry above), just not caught before writing this
one down.

**What fixed it:** Quickshell ships a first-party `Quickshell.Hyprland`
module. `import Quickshell.Hyprland` gives you a reactive `Hyprland`
singleton with `.workspaces`, `.focusedWorkspace`, `.monitors`, and a
`.dispatch()` method for sending commands — no IPC socket code, no JSON
parsing, no process spawning. `widgets/TopBar/Workspaces.qml` uses it
directly.

**Don't try this instead (looks right, isn't):** Before writing anything
in `services/` that talks to a specific piece of software (Hyprland,
PipeWire, NetworkManager, etc.), check whether Quickshell already ships
a purpose-built module for it under the `Quickshell.*` namespace — the
type reference's left sidebar lists them. Two of two "planned services"
so far (clock, Hyprland) turned out to already be covered. Worth
checking Audio/Battery/Network/Bluetooth against the same list before
building those, rather than assuming `services/README.md`'s original
roadmap is still accurate — it was written without knowing what
Quickshell already provides.

---

## 2026-07-01 — Almost built the clock by shelling out to `date`

**Trying to do:** Build the first TopBar module: a clock.

**What went wrong:** Nothing went wrong exactly, but the obvious
approach — copy the pattern from Quickshell's own introductory tutorial,
which spawns the `date` command via a `Process` on a repeating `Timer`
— would have worked while quietly being the wrong tool for the job.
That tutorial pattern exists to teach `Process`/`Timer`/property-binding
concepts, not as the recommended way to build a real clock; the same
tutorial page goes on to introduce `SystemClock` specifically as the
better replacement for it.

**What fixed it:** Used Quickshell's built-in `SystemClock` type
instead. It exposes a reactive `date` property with no process spawning,
and its `precision` property (`Hours`/`Minutes`/`Seconds`) controls how
often it actually updates — so a clock that doesn't show seconds isn't
doing per-second work in the background. `widgets/TopBar/Clock.qml`
binds `precision` to `Settings.clockShowSeconds` so that setting
controls both what's displayed and how often it's recalculated.

**Don't try this instead (looks right, isn't):** Don't reach for
`Process { command: ["date"] }` + `Timer` for a clock just because it's
the first pattern shown in the docs' walkthrough. Skim ahead in whatever
tutorial you're following — Quickshell's own docs frequently teach a
naive version of something first, then introduce the real built-in type
for it a section later. Check the type reference sidebar for a
purpose-built type before writing a `Process` for something
system-level; there's a decent chance one already exists (as it does
here, and likely does for things like battery/volume/network too, worth
checking before building those services from scratch).

---

## 2026-07-01 — Manually wired Theme/Settings/Globals instead of using singletons

**Trying to do:** Give every widget access to shared state (colors,
fonts, sizes, user settings, runtime data) without each widget having its
own copy or hardcoding values.

**What went wrong:** The original design deliberately avoided
`pragma Singleton`, based on a belief that singleton registration
"requires a qmldir file and has version-specific quirks" not worth
debugging blind. Instead, one `Theme`/`Settings`/`Globals` instance was
created in the core wiring file and manually passed down as a `theme:` /
`settings:` property to every widget that needed it. This worked, but
had a silent failure mode: forgetting to pass `theme: theme` into a
newly-instantiated widget produced no error — the widget would just
render with QML default styling (often white-on-white, or the wrong
size), and the fix wasn't obvious unless you already knew to check for
a missing property pass-through.

**What fixed it:** Checked current Quickshell docs and real-world
configs. Making a type a singleton is just `pragma Singleton` at the top
of the file plus making `Singleton` the root type — no qmldir needed for
a plain file living in your own shell directory (that requirement, if it
ever existed, applies to packaging types as reusable QML *modules* for
distribution, not to referencing your own local files). Converted
`core/Theme.qml`, `core/Settings.qml`, `core/Globals.qml`, and
`core/Signals.qml` to singletons. Every file that needs shared state now
just does `import qs.core` and reads `Theme.colorBackground` etc.
directly — nothing to instantiate, nothing to pass in, nothing to forget.

**Don't try this instead (looks right, isn't):** Don't reach for manual
instantiate-and-pass-down "to be safe" or "to avoid singleton weirdness"
in a Quickshell config. It feels more explicit and therefore safer, but
it actually introduces more surface area for silent bugs (every new
widget instantiation site is a place to forget a property) than the
singleton pattern it was avoiding. If a genuine singleton limitation
shows up later (e.g. something version-specific that actually bites),
write it down here with the specific Quickshell version and error
message — "quirks" without either wasn't a real constraint, just an
unverified assumption carried over from before checking.

---

## 2026-07-01 — Project's own root component shadowed Quickshell's built-in ShellRoot type

**Trying to do:** Have a small, stable `shell.qml` entry point that
delegates all real setup to another file, per the project's own "keep
shell.qml under ~30 lines" convention.

**What went wrong:** Quickshell ships a real, built-in `ShellRoot` QML
type meant to be the literal root object of `shell.qml`. The project
defined its own component — a plain `Item` — and also named it
`ShellRoot`, in `core/ShellRoot.qml`. Because a locally-imported type
with the same name shadows a module type, `shell.qml`'s `import "core"`
followed by `ShellRoot { ... }` resolved to the *project's* Item, not
Quickshell's actual root element. It ran fine (an Item works as a
container), but the project was never actually using Quickshell's real
root type, and the name collision made this very easy to miss — anyone
reading Quickshell's own docs or examples (which all assume `ShellRoot`
means the built-in type) would be misled about what this project's
`shell.qml` was actually doing.

**What fixed it:** Renamed `core/ShellRoot.qml` to `core/Shell.qml` (and
changed its root type from `Item` to `Scope`, Quickshell's non-visual
grouping element — a better semantic fit for a file that draws nothing
itself). `shell.qml` now instantiates the real `ShellRoot` type directly
(`import Quickshell`) and loads `Shell {}` inside it.

**Don't try this instead (looks right, isn't):** Don't name a
project-defined component the same as a built-in Quickshell/QtQuick type
just because it conceptually plays a similar role. It'll often work
(shadowing is legal QML), which is exactly what makes it dangerous —
there's no error to notice, just a permanent source of confusion between
"the docs' ShellRoot" and "this project's ShellRoot." If in doubt, check
the Quickshell type reference for whether a name is already taken before
reusing it for a project file.

---

## 2026-07-01 — Incorrect Quickshell version recorded in project notes

**Trying to do:** Keep a note of which Quickshell version this project
targets, for compatibility and for knowing which docs apply.

**What went wrong:** A scratch note (carried over from an earlier
conversation, not verified against the actual project) recorded the
version as "Quickshell 3.0, updated March 2026." Quickshell doesn't use
that versioning scheme at all — it's on 0.x. There is no "3.0."

**What fixed it:** Checked the actual project changelog/releases. Current
version as of this fix is 0.3.0, released 2026-05-04. Updated all
references.

**Don't try this instead (looks right, isn't):** Don't trust a carried-
over scratch note as the source of truth for a fast-moving project's
version, especially one written in an earlier, separate conversation with
no way to verify it at the time. Check `quickshell --version` on the
actual machine, or the project's real changelog page, when it matters
(e.g. before relying on a version-gated feature).

---

## 2026-07-01 — No entries yet

Project just started. This file is set up and ready, but nothing has gone
wrong yet worth recording. One general lesson carried in from prior
theming work in other systems: when something is parsed without error
but doesn't visually do what you expect, don't assume you misconfigured
it — verify with a debug/dump tool before spending hours adjusting
values that are being silently ignored.

<!--
  TEMPLATE — copy below this line for new entries, newest at the top
  (right after this comment, above any entries that follow it).

## YYYY-MM-DD Short description

**Trying to do:**

**What went wrong:**

**What fixed it:**

**Don't try this instead (looks right, isn't):**

-->

## 2026-07-17 — Settings window size appeared inconsistent because Hyprland alternated between floating and tiling it

**Symptoms:** Changing `SettingsWindow.qml` `implicitHeight` had no visible effect in some launches. On an empty workspace the window expanded beneath the top bar and clipped near the bottom. With one existing client it appeared centered and floating. With multiple tiled clients it joined the tiling layout and could hide the Cancel/Apply footer until manually resized.

**Diagnosis:** `hyprctl clients` showed identical stable metadata in both states (`class: org.quickshell`, `title: Quickshell Settings`). The only meaningful difference was `floating: 1` versus `floating: 0`. QML implicit dimensions are size requests; Hyprland owns geometry once the surface is tiled.

**Fix:** Add an exact compositor rule in Hyprland `rules.lua`:

```lua
hl.window_rule({
    name = "quickshell-settings",
    match = {
        class = "org.quickshell",
        title = "Quickshell Settings",
    },
    float = true,
    center = true,
    size = "1440 820",
})
```

The final size was selected to fit a 1920x1080 laptop at 1.5x font scale while remaining comfortable on a 2560x1440 desktop.

**Lesson:** Do not keep tuning QML `implicitWidth`/`implicitHeight` when a window sometimes tiles. Compare `hyprctl clients` output first and fix compositor state with a precise window rule.

## 2026-07-17 — Hyprland Lua exit keybind broke after an update

**Symptoms:** `Super+M` stopped exiting the compositor. `hyprshutdown` was missing, and `hyprctl dispatch exit` returned a Lua dispatcher syntax error.

**Fix:** Replace the shell fallback with the native Lua dispatcher:

```lua
hl.bind(mainMod .. " + M", hl.dsp.exit())
```

Terminal test:

```bash
hyprctl dispatch 'hl.dsp.exit()'
```
