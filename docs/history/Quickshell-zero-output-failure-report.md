# Quickshell Zero-Output / Monitor Power-Off Failure Report

**Prepared:** 2026-07-20  
**Environment:** Arch Linux, Hyprland, Wayland, Qt 6, Quickshell, Mesa/Gallium  
**Primary symptom:** Quickshell remains alive but becomes unresponsive after all physical monitors are powered off for an extended period. One OpenGL worker thread and one Wayland event thread consume nearly one full CPU core combined.

---

## 1. Executive summary

When both physical monitors are powered off, Hyprland temporarily exposes no real outputs. Qt Wayland responds by creating a synthetic placeholder screen named `FALLBACK`.

Quickshell survives the initial transition and may continue working for a short period. After approximately two minutes in the zero-output state, it can enter a failure mode where:

- Quickshell IPC calls stop responding.
- Desktop notifications sent through `notify-send` time out.
- The Quickshell process remains alive.
- The main process is mostly sleeping rather than crashing.
- A Mesa/OpenGL worker thread named `qs:gl0` consumes about 50% CPU.
- A Qt Wayland event thread consumes about 40% CPU.
- Total CPU use is approximately one full logical core.
- The condition does not appear to recover on its own while the monitors remain off.
- Restarting Quickshell restores normal operation.

A first QML-side mitigation was applied to stop the top bar and desktop clock from creating layer-shell surfaces for the fake `FALLBACK` screen. This successfully removed repeated layer-shell warnings and null-screen errors, but the underlying Qt/Wayland/OpenGL failure still occurred after a prolonged zero-output period.

The evidence points to a failure in the interaction between Qt Wayland output handling, Qt Quick scenegraph rendering, Mesa/Gallium, and Quickshell surface lifecycle when no real display outputs exist.

---

## 2. User-visible behavior

The original symptom was not a clean crash.

When the problem occurs:

- Quickshell UI elements become nonresponsive or only partially responsive.
- Launcher, settings, power screen, and notification operations may stop working.
- Quickshell IPC calls block until timeout.
- The Quickshell process remains present in `ps`.
- The desktop itself and Hyprland remain operational.
- The problem is strongly associated with turning off all physical monitors.
- Brief DPMS off/on cycles may not reproduce it.
- Leaving all monitors physically powered off for longer reliably reproduces it.

This distinction matters: the process is alive, but its event/rendering path is effectively wedged.

---

## 3. Test environment and workload

The failure was reproduced using an automated Quickshell soak harness.

The harness:

- Kept the same Quickshell PID alive throughout the test.
- Repeatedly toggled launcher, settings, power screen, wallpaper picker, and notifications.
- Changed visual settings.
- Changed wallpaper settings and themes.
- Opened three Kitty test windows.
- Monitored Quickshell resource use.
- Declared Quickshell unresponsive after three consecutive operation timeouts.
- Captured process and thread state without restarting Quickshell.

The relevant failing run used:

```text
Duration requested: 10 minutes
Speed: 3x
Failure threshold: 3 consecutive failures
Quickshell PID: 160797
```

The run began at:

```text
2026-07-20 18:58:52 -04:00
```

The monitors entered the zero-output state at:

```text
2026-07-20 19:04:06 -04:00
```

The first harness timeout occurred at:

```text
2026-07-20 19:06:16 -04:00
```

The harness declared Quickshell unresponsive at:

```text
2026-07-20 19:06:33 -04:00
```

The process remained alive.

---

## 4. Reproduction procedure

### 4.1 Start Quickshell normally

```bash
pkill qs
qs &
```

### 4.2 Start the soak harness

```bash
cd ~/.config/quickshell/testing
./qs-soak-test.py --minutes 10 --speed 3
```

Optional:

```bash
sudo -v
```

This was intended to allow an automatic GDB backtrace, although the noninteractive GDB capture still failed because `sudo -n` did not retain authorization in the relevant context.

### 4.3 Turn off all physical monitors

Physically power off both monitors and leave them off.

A short off/on cycle may not trigger the failure. Leaving both displays off for approximately two minutes reproduced it.

### 4.4 Observe failure

The harness reports three consecutive timeouts, for example:

```text
FAIL setting desktopClockShowWeatherIcon=1:
TimeoutExpired(['qs', 'ipc', 'call', 'soak', 'set',
'desktopClockShowWeatherIcon', '1'], 8.0)

FAIL notification burst:
TimeoutExpired(['notify-send', ...], 8.0)

FAIL notification:
TimeoutExpired(['notify-send', ...], 8.0)

QS_UNRESPONSIVE 3 consecutive failures
```

---

## 5. Runtime log evidence

### 5.1 Qt reports zero real outputs

The critical runtime log line is:

```text
2026-07-20 19:04:06.055 INFO qt.qpa.wayland:
There are no outputs - creating placeholder screen
```

This is the point at which both physical displays are no longer available to Qt.

### 5.2 Placeholder output later disappears

When the monitors return, Quickshell logs:

```text
2026-07-20 19:08:08.850 WARN quickshell.hyprland.ipc:
Got removal for monitor "FALLBACK" which was not previously tracked.
```

This confirms that Qt inserted a synthetic fallback monitor during the zero-output period.

---

## 6. Earlier pre-mitigation errors

Before the first QML-side mitigation, the runtime log showed additional errors immediately after Qt created the placeholder screen.

### 6.1 Layer-shell surfaces attached to a non-real screen

Repeated warnings:

```text
Layershell screen does not correspond to a real screen.
Letting the compositor pick.
```

These occurred repeatedly while the placeholder screen was active.

### 6.2 Desktop clock dereferenced a null screen

The desktop clock logged:

```text
@widgets/Desktop/DesktopClock.qml[269:17]:
TypeError: Cannot read property 'height' of null

@widgets/Desktop/DesktopClock.qml[261:17]:
TypeError: Cannot read property 'width' of null
```

This showed that screen-bound QML assumed a valid real screen still existed while the output list was being torn down.

---

## 7. First mitigation applied

A targeted revision was made to:

- Exclude the Qt `FALLBACK` screen from top-bar screen enumeration.
- Exclude screens with null names or invalid dimensions.
- Exclude the placeholder from desktop-clock instances.
- Make desktop-clock width and height access null-safe.
- Make focused-bar routing tolerate a disappearing screen.

Files changed:

```text
shell.qml
widgets/Desktop/DesktopClock.qml
```

### 7.1 Result of the mitigation

The mitigation worked as intended for the QML-level symptoms.

In the next failing run:

- No repeated layer-shell placeholder warnings appeared.
- No desktop-clock null width/height errors appeared.
- Thread count dropped substantially compared with the earlier failure.
- The top bar and desktop-clock surfaces were no longer being created for `FALLBACK`.

However:

- Quickshell still became unresponsive after approximately two minutes with no real output.
- The same OpenGL and Wayland CPU spin occurred.
- IPC and notifications still timed out.

Therefore, the QML errors were real bugs, but they were not the root cause of the prolonged zero-output hang.

---

## 8. Failure chronology from the post-mitigation run

### 8.1 Normal operation before monitor shutdown

From 18:58:52 through 19:04:06, the soak harness completed hundreds of actions successfully.

Examples included:

- launcher toggles
- settings toggles
- power screen toggles
- wallpaper picker toggles
- theme changes
- wallpaper changes
- notification bursts
- desktop clock setting changes
- notification layout changes

### 8.2 Zero-output transition

At:

```text
19:04:06
```

Qt reported:

```text
There are no outputs - creating placeholder screen
```

### 8.3 Continued operation after output loss

Quickshell continued servicing actions for roughly two minutes after the output loss.

The last successful harness actions occurred at approximately:

```text
19:06:07
```

### 8.4 First timeout

At:

```text
19:06:16
```

A Quickshell IPC settings call timed out after eight seconds.

### 8.5 Notification timeouts

At:

```text
19:06:24
19:06:33
```

Two `notify-send` operations timed out.

### 8.6 Automated failure declaration

At:

```text
19:06:33
```

The harness stopped actions and captured diagnostics.

---

## 9. Process-level evidence

The Quickshell process did not crash.

At failure:

```text
State: sleeping
PID: 160797
Threads: 27
VmRSS: 445396 kB
VmHWM: 546712 kB
VmSwap: 0 kB
```

This rules out:

- process termination
- out-of-memory kill
- swap exhaustion
- a simple runaway memory allocation as the immediate cause

Memory usage was elevated but not extreme.

The soak summary reported:

```text
Start RSS: 416.7 MiB
Peak RSS: 516.0 MiB
End RSS: 435.0 MiB
PID remained alive: True
```

The end RSS was lower than the peak, which is inconsistent with memory exhaustion being the reason for failure.

---

## 10. CPU and thread evidence

The most important diagnostic capture was `top -H`.

At failure:

```text
qs:gl0             ~49.7% CPU
WaylandEventThread ~39.8% CPU
```

Combined, these threads consumed close to one full logical CPU core.

The main Quickshell thread showed:

```text
0.0% CPU
futex_do_wait
```

Most other threads were sleeping.

This means:

- the main QML/application thread was not the CPU consumer;
- the active work was concentrated in the graphics and Wayland event path;
- the process was not globally busy;
- the shell became unresponsive even though the hottest work occurred outside the main application thread.

### 10.1 Relevant thread names

The process included:

```text
QSGRenderThread
qs:traceq0
qs:gdrv0
qs:gl0
WaylandEventThread
QQmlThread
QQuickPixmapReader
```

The hot `qs:gl0` name comes from Mesa/Gallium graphics worker infrastructure.

The hot Wayland thread is part of Qt Wayland client event handling.

---

## 11. GDB evidence

### 11.1 Original post-spike capture

A manual GDB backtrace from the earlier failure was successfully collected after the hottest CPU spike had subsided.

At capture time:

- The main Quickshell thread was waiting normally in Qt's event loop.
- Wayland event threads were blocked in `poll()`.
- Qt Quick render threads were waiting on condition variables.
- Mesa/Gallium worker threads were sleeping in condition waits.
- No permanent mutex deadlock was visible.
- No single crashing function was visible.

This suggests the failure is not a classic permanent deadlock.

A more likely pattern is:

1. all outputs disappear;
2. Qt inserts a placeholder output;
3. Qt Quick / Wayland / graphics state enters a high-CPU event or rendering loop;
4. Quickshell IPC and notification handling stop making progress;
5. the active spin may eventually subside;
6. the shell remains functionally wedged.

The automatic GDB attempt failed with:

```text
sudo: a password is required
```

Therefore, that original attempt did not capture a stack at the exact hottest
instant. The later capture below closed this gap.

### 11.2 Active-wedge capture, 2026-07-22

The later physical-power-off autocapture successfully attached during the
active failure. At trigger time:

```text
hyprctl monitors all: []
qs:gl0:               43.8%
WaylandEventThread:   36.9%
combined:             80.7%
RSS:                  ~409 MiB
```

Three GDB snapshots taken about five seconds apart showed the same persistent
stacks:

- `QSGRenderThread` was stuck in
  `QRhi::endFrame -> QWaylandGLContext::swapBuffers -> Mesa dri_flush`.
- A Mesa `qs:gl0` worker was inside
  `wl_display_roundtrip_queue -> EGL Mesa -> Gallium`.
- The main Qt thread was blocked while processing a Wayland window
  configure/expose event.

The repeated, unchanged stacks prove that the process was persistently wedged
in the Qt Wayland / Qt Quick / Mesa rendering path. Memory remained stable, so
the failure was not caused by runaway allocation.

---

## 12. What has been ruled out

The evidence substantially weakens or rules out the following explanations.

### 12.1 Ordinary idle behavior

This is not normal idle resource use. Nearly one logical core was consumed by the graphics and Wayland threads.

### 12.2 A simple QML JavaScript infinite loop

The main application/QML thread was not the active CPU consumer.

### 12.3 Memory exhaustion

RSS remained under approximately 550 MiB and dropped from its peak before the diagnostic snapshot.

### 12.4 Process crash

The Quickshell PID remained alive.

### 12.5 Whole-system failure

Hyprland and the operating system remained alive. The problem was localized to Quickshell and its Qt/Wayland rendering path.

### 12.6 Only the desktop clock

The desktop clock had genuine null-screen bugs, but after those were fixed, the underlying zero-output hang remained.

### 12.7 Only the top bar

The top bar was also guarded against the placeholder screen, yet the failure still occurred.

### 12.8 Hypridle or system suspend

The problem is reproducible by physically powering off displays while leaving the machine awake. Suspend is not required.

---

## 13. Current technical interpretation

The most likely failure class is:

> Quickshell remains connected to a Qt Wayland session with zero real outputs. Qt creates a placeholder screen. During the prolonged placeholder-only state, the Qt Quick scenegraph and/or Mesa rendering path interacts badly with Wayland output handling. A graphics worker and a Wayland event thread consume nearly one full core, and Quickshell stops servicing IPC and notification requests.

Possible layers involved:

- Qt 6 Wayland client output tracking
- Qt Quick scenegraph output/surface lifecycle
- Quickshell layer-shell and window lifecycle
- Mesa/Gallium graphics context handling
- Hyprland output removal/reappearance behavior

The active-wedge backtraces identify the failing path but do not assign sole
ownership to one upstream project. The defect may belong to Qt Wayland, Qt
Quick, Mesa, Quickshell, or their interaction.

---

## 14. Why brief DPMS cycles may pass

Short DPMS off/on cycles did not consistently trigger the problem.

This suggests the failure may require one or more of:

- remaining in the zero-output state for long enough;
- delayed cleanup of graphics surfaces or contexts;
- a later timer, animation, wallpaper update, notification, or IPC action;
- a race between output teardown and subsequent rendering activity;
- a stale placeholder-bound graphics context;
- a delayed event-queue or buffer-state inconsistency.

The post-mitigation test remained responsive for approximately two minutes after outputs disappeared before the first timeout.

---

## 15. Operational impact

If the user turns off both monitors before going to sleep while leaving the PC running, Quickshell may:

- consume close to one full logical CPU core for an extended period;
- waste power;
- generate unnecessary heat;
- become unresponsive before the monitors are turned back on;
- require a Quickshell restart afterward.

The machine may appear idle from a whole-system perspective because it has many cores, but Quickshell itself is not idle.

---

## 16. Current mitigation options

### 16.1 Keep the Rev 71 QML guards

The screen guards should remain because they fixed real defects:

- no fake-screen bar instances;
- no fake-screen desktop-clock instances;
- no null width/height access;
- no repeated layer-shell placeholder warnings from those surfaces.

### 16.2 External output watchdog

The most reliable workaround is an external process, independent of Quickshell:

1. poll or subscribe to Hyprland monitor state;
2. when no real outputs remain, stop Quickshell;
3. continue monitoring outside Quickshell;
4. when a real output returns, start Quickshell again.

This avoids leaving Qt Quick and Quickshell alive for an extended placeholder-only period.

The watchdog must not run inside Quickshell because Quickshell cannot rescue itself after its IPC/event path becomes unresponsive.

### 16.3 Avoid turning off all monitors

Leaving one real output logically present avoids entering the placeholder-only state, but this is not always practical.

### 16.4 Restart Quickshell after monitors return

Manual recovery:

```bash
pkill qs
qs &
```

This is a workaround, not a fix.

---

## 17. Suggested upstream bug-report title

**Quickshell becomes unresponsive and Qt Wayland / Mesa threads consume one CPU core after all outputs disappear**

Alternative:

**All monitors powered off: Qt creates FALLBACK screen, Quickshell IPC hangs, qs:gl0 and WaylandEventThread spin**

---

## 18. Suggested upstream issue body

### Description

When all physical monitors are powered off under Hyprland, Qt Wayland reports that no outputs exist and creates a placeholder screen. Quickshell initially survives, but after approximately two minutes it stops responding to IPC and notification requests.

The Quickshell process remains alive. At failure, a Mesa/Gallium `qs:gl0` thread consumes about 50% CPU and a Qt `WaylandEventThread` consumes about 40% CPU. The main Quickshell thread is sleeping in a futex wait.

### Reproduction

1. Start Quickshell.
2. Start a workload that periodically opens/toggles Quickshell windows and sends notifications.
3. Physically power off all monitors.
4. Leave them off for at least two minutes.
5. Observe that `qs ipc` and `notify-send` eventually time out.
6. Check `top -H -p $(pgrep -n qs)`.

### Expected behavior

Quickshell should remain idle and recover when outputs return, or cleanly suspend/destroy screen-bound surfaces while no real outputs exist.

### Actual behavior

Qt creates a placeholder screen. Quickshell later stops servicing IPC. One OpenGL worker and one Wayland event thread consume almost one logical CPU core combined.

### Relevant log

```text
qt.qpa.wayland:
There are no outputs - creating placeholder screen

quickshell.hyprland.ipc:
Got removal for monitor "FALLBACK" which was not previously tracked.
```

### CPU at failure

```text
qs:gl0             ~49.7%
WaylandEventThread ~39.8%
```

### Process state

```text
PID alive: yes
Main thread: sleeping / futex_do_wait
RSS: ~435 MiB
Threads: 27
Swap: 0
```

### Additional findings

Before adding QML guards, screen-bound layer-shell surfaces attempted to use the placeholder screen and DesktopClock dereferenced a null screen. Those bugs were fixed locally. The warnings disappeared, but the underlying prolonged zero-output hang remained.

Later active-wedge GDB captures showed `QSGRenderThread` in
`QRhi::endFrame -> QWaylandGLContext::swapBuffers -> Mesa dri_flush` and a
Mesa `qs:gl0` worker in an EGL-triggered `wl_display_roundtrip_queue`. Three
captures remained unchanged, while RSS stayed near `409 MiB`.

---

## 19. Recommended additional diagnostics for upstream developers

For a deeper upstream investigation:

1. Use the three existing active-wedge GDB captures as the primary evidence.
2. Install debug symbols for:
   - Quickshell
   - Qt 6 Core
   - Qt 6 Gui
   - Qt 6 Quick
   - Qt 6 Wayland Client
   - Mesa/Gallium
3. Capture:
   ```bash
   sudo gdb -q -p "$(pgrep -n qs)"
   ```
4. In GDB:
   ```gdb
   set pagination off
   thread apply all bt full
   ```
5. Record repeated samples of the two hot threads to identify whether they spin in:
   - Wayland event dispatch
   - EGL swap/buffer handling
   - Qt Quick render loop
   - Mesa fence waits
   - output destruction callbacks
6. Compare behavior under:
   - software rendering;
   - a different Qt Quick render loop;
   - one monitor vs two monitors;
   - DPMS off vs physical power-off;
   - one output remaining active;
   - another Wayland compositor.

---

## 20. Evidence files

Relevant files collected during the investigation:

```text
quickshell-monitor-off-runtime.log
actions(9).log
summary(9).txt
thread-top(1).txt
process-state(1).txt
thread-proc-state(1).txt
proc-status(1).txt
proc-sched(1).txt
proc-wchan(1).txt
open-files(1).txt
quickshell-backtrace(1).txt
resources(9).csv
run(1).json
unresponsive-trigger(1).txt
quickshell-zero-output-capture-2026-07-22-220817.tar.gz
```

Earlier failing-run evidence:

```text
quickshell-dpms-runtime.log
quickshell-dpms-runtime.qslog
quickshell-dpms-backtrace.txt
actions(8).log
summary(8).txt
thread-top.txt
process-state.txt
thread-proc-state.txt
resources(8).csv
```

---

## 21. Final conclusion

The investigation has established a repeatable and measurable zero-output failure:

- all real outputs disappear;
- Qt creates `FALLBACK`;
- Quickshell survives initially;
- after a delay, Qt Wayland and Mesa/OpenGL threads become highly active;
- IPC and notifications stop responding;
- Quickshell remains alive but functionally wedged.
- active GDB captures place the wedge in Qt Quick frame completion,
  `QWaylandGLContext::swapBuffers`, Mesa flushing, and a Wayland roundtrip.

The initial QML bugs around fake-screen handling were real and have been mitigated, but they were not sufficient to prevent the deeper failure.

Until the underlying Qt/Quickshell/Wayland/Mesa interaction is fixed upstream,
the validated production workaround is the external restart watchdog. Its
current default stops Quickshell after three seconds of sustained zero real
outputs and relaunches it after a real output remains available for three
seconds.
