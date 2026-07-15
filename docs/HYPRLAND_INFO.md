## Additional notes (verified via web search, 2026-07-06)

**Timing context:** Hyprland switched its config format to Lua in
v0.55. This happened after Claude's Jan-2026 training cutoff, so it's
not something a fresh Claude session will "know" by default — it has
to be verified, not assumed. If a future session says "hyprland.lua"
like it's unusual or a typo, point it here.

### The `hl` scripting API (what's actually available)

- `hl.config({...})` — sets config categories/variables (general,
  decoration, animations, etc.)
- `hl.monitor({...})` — monitor setup (output, mode, position, scale)
- `hl.bind(keys, dispatcher)` — keybindings; dispatchers live under
  `hl.dsp.*` (e.g. `hl.dsp.exec_cmd(cmd)`, `hl.dsp.global(name)` for
  global shortcuts IPC-style, `hl.dsp.window.float({...})`)
- `hl.on(eventName, callback)` — event callbacks (e.g.
  `hl.on("window.active", function(w) ... end)`,
  `hl.on("workspace.move_to_monitor", function(ws, m) ... end)`) —
  this is genuinely new capability hyprlang never had
- Full Lua stdlib is available — real scripting, not just declarative
  config. Also means: **arbitrary code execution if you source someone
  else's config file** — don't `require()` random configs you haven't
  read.
- Timers and async exec helpers also exist under `hl.*`

### Splitting config across files

`require("path.to.file")` (or `require("path/to/file")`, either
separator works) loads a sub-file as its own Lua scope — errors in one
required file don't kill the others. This is the mechanism our future
settings-GUI project should use (see below).

### Reload behavior + safety net

- Config reloads automatically the moment you save the file (no
  manual `hyprctl reload` needed, though it still works if you want
  it explicit)
- Fundamental Lua syntax errors → Hyprland refuses to reload, shows an
  error popup, keeps running your LAST GOOD config
- Runtime errors in one `require()`d file only kill that file's
  execution, not the whole config
- Emergency fallback keybinds exist even on a badly broken config:
  **SUPER+Q** (terminal), **SUPER+R** (run), **SUPER+M** (exit) — a
  genuine safety net against a config error locking you out entirely

### Relevant if we ever build the settings-menu project

**Proposed safe architecture (not yet built, just designed):** a
Quickshell-based settings GUI should NEVER parse or rewrite your actual
hand-written `hyprland.lua` directly — text-munging someone's live
compositor config is much higher-stakes than any of the widget work
we've done (a broken bar restarts `qs`; a broken Hyprland config can
affect the whole session). Instead: the GUI manages its OWN dedicated
file (e.g. `~/.config/hypr/gui-managed/monitors.lua`), and the real
`hyprland.lua` just has one line: `require("gui-managed.monitors")`.
The GUI only ever reads/writes a file it fully owns and controls the
format of. Live-apply (e.g. dragging a monitor into place) can also go
straight through Hyprland's IPC for instant feedback, with the managed
file updated separately for persistence across restarts — same
"apply now, persist separately" pattern as the wallpaper picker
(`awww img` now, thumbnail state separate).

**Existing community tooling worth knowing about** (found via search,
not verified hands-on): a Python library called `hyprland-config`
exists with `load_any()`/`serialize_any()` (format-dispatches on file
suffix, `.conf` vs `.lua`) and dedicated `load_lua()`/`serialize_lua()`
for the new format — could be worth investigating if we ever need
programmatic parsing of an EXISTING hand-written config (as opposed to
just generating our own managed file, which doesn't need a parser at
all). Also a Go-based `hyprlang2lua` CLI converter exists for migrating
old-format configs. Neither of these has been tried in this project —
noting them as leads, not endorsements.
