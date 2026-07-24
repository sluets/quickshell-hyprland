## Current tested baseline (verified 2026-07-23)

The project is now developed and live-tested on **Hyprland 0.56.0**
with Lua configuration. Hyprland switched its config format to Lua in
v0.55, after the model training cutoffs used during much of this
project, so current compositor behavior must be verified against the
installed version and current official documentation rather than
assumed from memory.

Animation notes for 0.56:

- `hl.animation()` requires either `bezier = "name"` or
  `spring = "name"`; a generic `curve` field is not accepted.
- animation `speed` is duration in deciseconds (`1.0` = 100 ms), so
  lower values are faster;
- the old `spring = "easy"` window-entry values that felt acceptable
  before the upgrade became visibly sluggish on 0.56;
- the managed Smooth/window-style presets therefore use the existing
  `quick` Bézier with shorter durations, while Bouncy deliberately
  remains spring-based.

If a future session treats `hyprland.lua`, `hyprctl eval`, or the Lua
animation API as unusual, outdated, or a typo, point it here and verify
against the current Hyprland wiki first.

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

### Current managed/user Settings architecture

The Settings system now follows the safe architecture that was originally proposed here: it never rewrites the owner's hand-written compositor file wholesale. Quickshell generates and owns dedicated files under the managed Hyprland tree, while user-owned Lua files remain separate. Ordinary Apply uses one normal `hyprctl reload`; `full-reset` is explicitly unsafe for repeated Settings changes.

See:

- `SETTINGS_ARCHITECTURE.md`;
- `PROBLEMS_AND_FIXES.md`;
- `history/HYPR_RESTRUCTURE.md` for the completed one-time migration procedure.

External parser/converter projects mentioned in older research were never adopted and are not project dependencies.
