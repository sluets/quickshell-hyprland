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

### Current managed/user Settings architecture

The Settings system now follows the safe architecture that was originally proposed here: it never rewrites the owner's hand-written compositor file wholesale. Quickshell generates and owns dedicated files under the managed Hyprland tree, while user-owned Lua files remain separate. Ordinary Apply uses one normal `hyprctl reload`; `full-reset` is explicitly unsafe for repeated Settings changes.

See:

- `SETTINGS_ARCHITECTURE.md`;
- `PROBLEMS_AND_FIXES.md`;
- `history/HYPR_RESTRUCTURE.md` for the completed one-time migration procedure.

External parser/converter projects mentioned in older research were never adopted and are not project dependencies.
