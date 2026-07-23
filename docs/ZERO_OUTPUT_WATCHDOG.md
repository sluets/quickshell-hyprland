# Zero-output failure & the external watchdog

Destination: `docs/ZERO_OUTPUT_WATCHDOG.md`
Companion files: `qs-output-watchdog.py` (quickshell root),
`testing/simulate-zero-output.sh`, `rev72-qswatchdog-guard-patch.md`
Source material: `history/Quickshell-zero-output-failure-report.md` (the full
soak-harness investigation, 2026-07-20) plus the web research below.

This doc exists so a future session doesn't have to re-derive any of
this. Read this before touching the watchdog, the Rev 71 screen guards,
or anything monitor-lifecycle-adjacent.

---

## 1. The failure, in one paragraph

Power off every physical monitor and leave them off. Hyprland removes
all wl_outputs; Qt Wayland logs `There are no outputs - creating
placeholder screen` and inserts a synthetic screen named `FALLBACK`.
Quickshell keeps working for roughly two minutes, then wedges: IPC calls
and `notify-send` time out, the process stays alive, a Mesa/Gallium
worker thread (`qs:gl0`) burns ~50% CPU and Qt's `WaylandEventThread`
~40%, and it never recovers on its own — only a restart fixes it. Fully
reproducible via the soak harness (`testing/qs-soak-test.py`) plus
physical power-off.

## 2. Why it happens (captured mechanism)

The 2026-07-22 physical-power-off autocapture closed the earlier evidence gap.
With `hyprctl monitors all` returning `[]`, Quickshell reached `80.7%`
combined target-thread CPU:

- `qs:gl0`: `43.8%`
- `WaylandEventThread`: `36.9%`

Three GDB snapshots taken about five seconds apart showed the same persistent
stacks:

- `QSGRenderThread` was stuck in
  `QRhi::endFrame -> QWaylandGLContext::swapBuffers -> Mesa dri_flush`.
- A Mesa `qs:gl0` worker was inside
  `wl_display_roundtrip_queue -> EGL Mesa -> Gallium`.
- The main Qt thread was blocked while processing a Wayland window
  configure/expose event.

This demonstrates a rendering-path wedge in the Qt Wayland / Qt Quick / Mesa
interaction while no real output exists. It does not identify which upstream
project owns the defect, but it rules out a QML loop and memory exhaustion as
the cause. All three captures were unchanged, so this was a persistent wedge,
not a momentary burst.

The Rev 71 guards still matter: they stop the bar and desktop clock from
binding to `FALLBACK` and remove real QML errors. They cannot repair the
lower-level swap/Wayland/Mesa path.

## 3. This is a known Qt Wayland failure class (research, 2026-07-20)

Whatever the precise mechanism, the failure class predates this shell
and is not fixable from QML. Closest public matches:

- **qutebrowser #5828** — under Sway, DPMS off → Qt logs `Creating a
  fake screen in order for Qt not to crash` → 100% CPU, window stops
  re-rendering and responding. Same fingerprint, different Qt app,
  different compositor. Strongly supports a shared Qt-Wayland-level failure CLASS; it does not
  prove this shell's exact failure has the identical cause.
- **QTBUG-98010** — documents the fake-screen state itself: when no
  outputs exist, the placeholder has 0x0 geometry, NaN DPI, no physical
  size. That degenerate geometry is exactly the kind of input that sends
  resize/reconfigure and frame-scheduling logic into loops.
- **quickshell-mirror #503** — lockscreen + monitor power-off crash on
  niri. Adjacent territory; upstream (outfoxxed) is aware of this class.
- **hyprwm/Hyprland #5752** — Hyprland destroys/recreates monitors that
  are slow to wake from deep power-save, causing client chaos on
  monitor-return. This is why the watchdog debounces the *return*
  direction too, not just the removal.

The QML fixes were still worth it: the Rev 71 guards (no bar/clock
instances on `FALLBACK`, null-safe screen access, focused-bar routing
tolerating a vanishing screen) fixed real defects and removed real log
spam. They stay. They just can't prevent a failure that lives below QML.

## 4. The two mitigation strategies

A wedged Quickshell cannot rescue itself — its event loop is the thing
that's stuck — so the mitigation must be an **external process**. The
watchdog implements two strategies behind one `--mode` flag; they share
all plumbing.

### `--mode restart` (default — production workaround)

After a sustained zero-output period (default 3 s), SIGTERM Quickshell
*before* the ~120 s wedge window closes, escalating to SIGKILL after 5 s
if ignored. When a real output has been back for three seconds, relaunch.
The short removal grace prioritizes stopping QS while it is still healthy;
the three-second return grace absorbs slow wake and cable renegotiation.

Cost: in-memory state is lost — open popouts, notification popups,
anything not persisted. All settings live in user-prefs.json /
ConfigManager and survive fine. When both monitors go off before bed,
losing an open launcher is irrelevant. Guaranteed to avoid the wedge,
which is why it's the default and the first thing to live-test.

### `--mode headless` (EXPERIMENTAL — earns promotion only through §7)

Shortly after real outputs hit zero (default 1 s — per-mode grace, since
creating an output is cheap to do and undo, unlike killing the shell),
run `hyprctl output create headless QSWATCHDOG` and VERIFY the output
actually appears in `monitors all` (a zero exit code proves nothing).
When a real monitor returns, remove it after the return debounce.

Be precise about what this does and doesn't do: **Qt creates its
placeholder the instant the last real output vanishes — headless mode
does not prevent that.** It *ends* the placeholder-only state within
about a second, keeping exposure at ~1/120th of the observed wedge
window, while Quickshell keeps running with all state intact and the
same PID. "Minimizes, not eliminates."

Also be precise about cost: cheap is not free. Output create/remove is
a monitor-layout transition — Hyprland may migrate workspaces to the
headless output and back, focus can move, and windows may react. The
return-side debounce covers the noisy-cable repeated-create/remove case.
These are exactly the things §7's acceptance criteria measure.

The Rev 72 guards exclude `QSWATCHDOG` by name (alongside `FALLBACK`),
so no per-monitor bar or desktop-clock surface is created on the
mitigation output. That is the specific, verified guarantee — NOT a
blanket "the shell renders nothing." Other global windows (launcher,
notifications, volume OSD, power screen, settings, wallpaper picker) are
NOT screen-guarded and could bind to Qt's current/default screen if
shown or created during an outage; whether any of them do is one of the
things §7's headless acceptance criteria exist to measure. The guard
landing first is still a hard prerequisite for testing this mode:
without it, invisible bars/clocks get created on the mitigation output,
re-entering the exact graphics lifecycle it exists to route around.

Failure handling: if creation is rejected, or the output never appears
within 3 s, any partial result is removed and the watchdog falls back to
stopping qs for that episode — a broken headless path degrades to
restart behavior, never to nothing. If the output vanishes mid-outage
(e.g. a Hyprland reload wiping runtime outputs), it is re-created. A
pre-existing QSWATCHDOG from a dead predecessor watchdog is adopted if
the outage is ongoing, removed if stale.

## 5. Watchdog design decisions (each earned by the report)

- **Event-driven, verify-on-event.** Subscribes to Hyprland's socket2
  and reacts to `monitoradded` / `monitorremoved` (all `monitor*`
  variants). Every event triggers a fresh `hyprctl -j monitors` read —
  events are treated as "something changed, go look", never as truth,
  because socket2 events can race actual state. A 15 s periodic
  re-verify backstops any missed event.
- **Debounced both directions, with per-mode removal grace.** The
  debounce is sized to the destructiveness of the action: restart mode
  waits 3 s (short enough to stop qs while healthy; the script refuses
  restart-mode `--zero-grace` ≥ 100), headless mode waits 1 s (create/remove is
  cheaply reversible, and every second shaved shortens placeholder
  exposure). Return side: 3 s for both, because of the Hyprland
  slow-wake destroy/recreate behavior (#5752) and the noisy-cable case.
  Grace values are validated: nothing below 0.5 s, no negatives.
- **Headless state is verified, adoption-aware, and self-healing.** The
  watchdog distinguishes an absent output from a named-but-unusable one
  and from an active one. A disabled or zero-geometry `QSWATCHDOG` is
  removed before creation or adoption because it gives Qt no usable
  screen while potentially blocking a replacement with the same name.
  A created output must become active in `monitors all` within 3 s or the
  attempt is cleaned up and the episode falls back to restart behavior.
  An active QSWATCHDOG at act time or startup-during-outage may be
  adopted in headless mode; one found with monitors back is removed as
  stale; one that vanishes or becomes unusable mid-outage is re-created.
  Removal is also verified against `monitors all`.
- **`hyprctl` failure ≠ zero outputs.** If `hyprctl` times out or
  errors, the evaluation is skipped. The watchdog must never kill the
  shell because of its own glitchy probe.
- **`FALLBACK` and `QSWATCHDOG` never count as real outputs.** Neither
  does a monitor with `disabled: true`.
- **Tracked-PID process management.** The watchdog captures the qs PID
  at startup and updates it after every relaunch; stop actions target
  that instance, verified against /proc/pid/comm before any signal. The
  pgrep fallback (only when the tracked PID is gone) matches EVERY user
  process named qs/quickshell and stops all of them — fine on this
  one-shell machine, stated plainly because a test config or SDDM
  preview process could someday match. The relaunch command lives in one
  place (`QS_COMMAND`, bare `qs` — correct for this machine per
  INTEGRATION_NOTES.md's no-`-c` setup).
- **Singleton via flock** in `$XDG_RUNTIME_DIR`; duplicate launches
  exit silently, so exec-once firing twice or a manual launch alongside
  it is harmless.
- **Restart-mode restraint:** only relaunches qs if the watchdog itself
  stopped it, so a deliberate `pkill qs` during development doesn't get
  fought by the watchdog. `--always-start` opts out (covers qs crashing
  on its own mid-outage).
- **Hyprland-restart handling:** socket2 EOF → old socket closed
  explicitly → reconnect → **immediate re-evaluate** (a compositor
  restart is precisely when monitor state is most likely to have changed
  under us). If Hyprland is really gone, exit — the new instance has a
  new `HYPRLAND_INSTANCE_SIGNATURE` and its own exec-once spawns a
  fresh watchdog.
- **Cleanup on exit leaves the world sane:** the headless output is
  removed ONLY if a real output exists — removing it mid-outage would
  re-enter the placeholder state, so it is deliberately left for a
  successor watchdog to adopt. qs is restarted if we stopped it and
  there's a screen to show it on.

## 6. Installation

The watchdog lives at the quickshell root as `qs-output-watchdog.py`
(chmod +x). It runs `qs` bare — matching this machine, where shell.qml
sits at the quickshell root and there is no `-c` flag (see
INTEGRATION_NOTES.md).

Autostart from `startup.lua`, alongside the existing entries:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
    hl.exec_cmd("kbuildsycoca6 --noincremental")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/quickshell/qs-output-watchdog.py")
end)
```

Do NOT add this line until §7 step 6 is reached — manual foreground
runs come first. To trial headless mode later, append `--mode
headless` to that
command string. Logs go to stdout (Hyprland's journal for exec-once
processes — `journalctl --user -t Hyprland` or wherever this machine's
session logs land); relaunched-qs output additionally goes to
`$XDG_RUNTIME_DIR/qs-output-watchdog-relaunch.log`.

Manual run for testing (foreground, verbose):

```sh
~/.config/quickshell/qs-output-watchdog.py --verbose
```

## 7. Testing — restart first, headless earns promotion

`testing/simulate-zero-output.sh [SECONDS]` disables every active real
output via `hyprctl keyword monitor "<name>, disable"`, waits, then
re-enables (plus `hyprctl reload` belt-and-braces, reapplying monitors
from hyprland.lua). Disabling removes the wl_output like a physical DP
disconnect, so it drives the same Qt code path. Screens go black for the
duration — the script recovers itself; emergency recovery from a TTY is
`hyprctl reload`.

Nothing gets installed as an autostart daemon until restart mode has
proven boring in manual foreground runs. Order:

1. **Apply Rev 72 first** (QSWATCHDOG guards in shell.qml +
   DesktopClock.qml — see rev72-qswatchdog-guard-patch.md), including
   its step-3/4 manual create/remove smoke test. This is a prerequisite
   for headless testing and harmless for restart testing.
2. **Baseline (no watchdog), 150 s** — confirm the simulation reproduces
   the wedge the way physical power-off did, soak harness running.
3. **Restart mode, foreground + `--verbose`, blip test (5 s)** — expect
   ZERO_PENDING → "false alarm", no action.
4. **Restart mode, 150 s** — expect stop at ~3 s, clean SIGTERM (no
   SIGKILL escalation in the log), relaunch ~3 s after re-enable, soak
   harness recovers (its timeouts during the stopped window are
   expected).
5. **Restart mode, one real physical power-off** — the simulation is
   close but not identical (a physically-off monitor also drops
   DDC/hotplug and renegotiates slowly on wake).
6. **Restart mode, physical power-off and return — PASSED 2026-07-22.**
   Quickshell was stopped before the wedge and relaunched after a real monitor
   returned. Exactly one `qs` process and one watchdog process remained.
   Restart mode is the validated production workaround.
7. **Only then: headless mode, 150 s + soak harness.** Acceptance
   criteria, all of them:
   - qs PID unchanged across the whole outage;
   - IPC keeps responding throughout (harness keeps passing);
   - no `placeholder screen` line after ~1 s into the outage, and no
     sustained qs:gl0 / WaylandEventThread CPU spike at any point;
   - zero bar/clock instances created on QSWATCHDOG (qs log clean);
   - after monitors return: workspaces and application windows back on
     their original monitors, no delayed jank from the removal;
   - repeat once with a real physical power-off.
   Any failure → headless stays experimental, restart stays the
   default, and the result gets recorded here either way.

## 8. Upstream reporting

Section 18 of the failure report is the starting issue body. Include the newer
autocapture evidence and stacks from §2. File
against **Quickshell first** (quickshell-mirror on GitHub) and let
outfoxxed route it toward Qt Wayland — he's responsive and #503 shows
the class is on his radar. Reference qutebrowser #5828 and QTBUG-98010
as prior art showing the fake-screen + CPU-spin pattern predates
Quickshell entirely.

The previous missing in-spin stack is no longer a blocker. The
`quickshell-zero-output-capture-2026-07-22-220817.tar.gz` archive contains
three stable GDB snapshots plus monitor state, process memory, thread CPU,
maps, versions, and trigger metadata.

## 9. Operational notes / gotchas

- The watchdog manages processes named `qs` or `quickshell`
  (`pgrep -x`). If the launch method ever changes (wrapper script,
  systemd unit), update `QS_PROC_NAMES` in the script.
- Restart mode + development workflow: killing qs by hand while
  monitors are off is fine (the watchdog only restarts what it
  stopped), but remember the watchdog will still stop a *manually
  relaunched* qs if you're mid-outage past the debounce.
- If the watchdog ever exits mid-mitigation in restart mode with
  monitors still off, qs stays down until relaunched by hand — the
  cleanup path logs exactly this case.
- The name `QSWATCHDOG` is load-bearing in TWO places: the watchdog's
  `--headless-name` and the Rev 72 `isRealScreen()` guards in
  shell.qml + DesktopClock.qml. Change one, change all three.
- Headless leftovers: `hyprctl output remove QSWATCHDOG` removes a
  stray one manually; the watchdog also self-cleans at next startup.
- The restart-mode `--zero-grace` ceiling (< 100 s) is load-bearing.
  The entire safety argument of restart mode is "act while qs is
  still healthy enough to honor SIGTERM." Headless mode has no
  ceiling but a 0.5 s floor, like all grace values.

---

## REVISION HISTORY

- 2026-07-23  v2.3, post-live validation (GPT). Corrected the documented
  restart grace from the obsolete 12 seconds to the implemented 3 seconds.
  Recorded the physical zero-output GDB capture and the successful watchdog
  stop/relaunch test. Restart mode is now the validated production workaround;
  headless mode remains experimental.
- 2026-07-20  v2.2, final pre-live GPT review. The watchdog now
  distinguishes the named headless output as absent, invalid, or active.
  Disabled and zero-geometry `QSWATCHDOG` entries are removed before
  creation or adoption instead of being ignored, closing the remaining
  duplicate-name/stale-output edge case. Headless removal is now verified
  against `monitors all`. No architectural changes; v2.1 remains the
  parent and restart mode remains the first live-test target.
- 2026-07-20  v2.1, second GPT review. Watchdog: mode-aware stale-headless
  reconciliation (restart mode never adopts a stray output or jumps to
  MITIGATED — it runs its normal stop-qs and reaps the stray only after a
  real output returns; this closes the "restart silently becomes partial
  headless and orphans QSWATCHDOG" bug); adoption/verification now require
  an ACTIVE output with valid geometry, not merely a matching name (a
  disabled QSWATCHDOG gives Qt no screen); socket var initialized before
  the try. Doc: the "shell renders nothing / zero screen-bound surfaces"
  claim narrowed to the specific verified guarantee (no bar/clock on
  QSWATCHDOG) with the un-guarded global windows named as a headless-test
  unknown; remaining frame-callback/retry and qutebrowser statements
  softened from fact to inference.
- 2026-07-20  v2, from the joint Claude/GPT review. Watchdog: per-mode
  zero-grace (12 s restart / 1 s headless), verified headless creation
  with partial-result cleanup and restart fallback, stale-output
  adoption + mid-outage re-creation, tracked-PID process management
  with documented pgrep fallback, centralized QS_COMMAND, explicit
  socket close + immediate re-evaluate on reconnect, grace validation,
  outage-aware exit cleanup. Doc: §2 reframed as a working hypothesis
  (no in-spike backtrace exists yet); §4 corrected — headless mode
  MINIMIZES placeholder exposure (~1 s), it does not prevent Qt
  creating the placeholder, and output create/remove is a real
  monitor-layout transition, not free; §7 rewritten to GPT's testing
  order (restart proves itself manually, then overnight, then autostart;
  headless earns promotion through explicit acceptance criteria).
  New companion: rev72-qswatchdog-guard-patch.md (isRealScreen excludes
  QSWATCHDOG in shell.qml + DesktopClock.qml — hard prerequisite for
  headless testing). All watchdog state-machine paths re-tested offline
  incl. the new verification/adoption/fallback/recreation paths. STILL
  not run against live Hyprland — §7 is the next session's
  live-test-first obligation, starting at step 1.
- 2026-07-20  Initial version. Consolidates the zero-output failure
  report, the upstream research (qutebrowser #5828, QTBUG-98010,
  quickshell-mirror #503, Hyprland #5752), the mechanism analysis
  (frame-callback starvation → GUI-thread futex block → IPC death),
  and the design of qs-output-watchdog.py (restart + headless modes,
  dual debounce, socket2-driven) plus simulate-zero-output.sh. State
  machine offline-tested (mocked outputs: debounce absorption, both
  mode paths, flap during return, hyprctl-failure no-op). NOT yet run
  against live Hyprland — the §7 test matrix is the next session's
  live-test-first obligation.
