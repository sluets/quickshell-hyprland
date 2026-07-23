# Quickshell testing tools

`qs-soak-test.py` is a visible, external torture-test harness for one running
Quickshell process. It exercises safe UI entry points, mutates visual
preferences, and records every action plus continuous process telemetry.

The harness never restarts Quickshell and never exposes UI Profile save,
overwrite, rename, delete, or restore operations through its `soak` IPC target.

This directory is also reserved for standalone `.qml` files used to try an
unfamiliar API or layout in isolation before wiring it into `widgets/`. Nothing
here is loaded by `shell.qml` unless a test feature is deliberately connected.
Two settings-menu reference images were added here on 2026-07-13.

## Stabilization restriction

Do not run another broad soak until the notification-state and notification-
surface lifecycle fixes in `docs/QUICKSHELL_MEMORY_STABILIZATION_PLAN.md` are
complete. A short harness/restoration check may exclude both implicated groups:

```bash
python testing/qs-soak-test.py --minutes 1 --speed 1 \
  --exclude-group notifications --exclude-group placement
```

## Controlled-test setup

Stop hypridle so an unrelated idle timeout or DPMS transition cannot contaminate
the run. How it was started determines which command applies:

```bash
systemctl --user stop hypridle.service
pkill -x hypridle
pgrep -a -x hypridle
```

Start the test Quickshell process with scene-graph diagnostics enabled. Prefix
the same command normally used to launch the shell:

```bash
QSG_INFO=1 qs
```

If Quickshell is launched by a wrapper or service, set `QSG_INFO=1` in that
launch environment instead. `baseline.txt` records whether the running process
actually inherited it.

The baseline also records the Quickshell version, the result of checking `ldd`
for jemalloc, hypridle state, initial RSS/RssAnon, thread-family counts, and file
descriptors. When a Quickshell crash report is available, independently check
its `Use jemalloc:` header.

## Notification-cap live check

Memory stabilization Phase 2 bounds the actual tracked collection at eight,
including critical and timeout-zero notifications. After reloading Quickshell,
clear any existing notifications:

```bash
qs ipc call notifs dismissAll
```

Send one long-lived normal, one critical, and one timeout-zero notification,
clearing after each. Every cleanup should report one dismissed notification:

```bash
notify-send -t 60000 "QS cap test" "normal"
qs ipc call notifs dismissAll

notify-send -u critical -t 60000 "QS cap test" "critical"
qs ipc call notifs dismissAll

notify-send -t 0 "QS cap test" "timeout zero"
qs ipc call notifs dismissAll
```

Then send twelve persistent notifications. Cleanup must report exactly eight,
proving the tracked objects—not only the visible delegates—were capped:

```bash
for i in {1..12}; do
    notify-send -t 0 "QS cap test $i" "persistent notification $i"
done
qs ipc call notifs dismissAll
```

Expected final result:

```text
ok: dismissed 8 notification(s)
```

After cleanup, running the command again must report zero. Watch the live QS
output throughout for repeated `modelData` or delegate teardown warnings.

The same IPC target exposes a read-only count for controlled telemetry:

```bash
qs ipc call notifs count
```

Expected with an empty collection: `ok: count=0`.

## Controlled notification cleanup

Memory stabilization Phase 4 automatically applies controlled cleanup to every
harness run that includes the notifications group. The harness records the
tracked count and full process-resource sample at four checkpoints:

1. before notification generation;
2. at the highest observed tracked count;
3. immediately after the final `dismissAll` IPC call;
4. after the cleanup wait (ten seconds by default).

The final count query completes before the final telemetry sample. No further
IPC or preference mutation occurs before the original preferences are restored
and verified. Runs that exclude the notifications group retain the existing
telemetry-only cleanup path.

Notification checkpoint data is written to `notification-checkpoints.csv`.
Both post-dismissal counts must be zero or the run fails. RSS is contextual;
judge cleanup using RssAnon, worker threads, file descriptors, bounded tracked
state, and behavior across fresh-process runs rather than requiring exact RSS
return to baseline.

## Notification-surface lifecycle live check

Memory stabilization Phase 3 keeps both presentation windows instantiated and
switches which host is active. With one persistent notification visible, change
**Settings -> Notifications -> Presentation** between Detached and Attached at
least ten times. At every switch, verify that exactly one popup is visible and
that the attached popup remains on the bar where its current session opened.

While an attached notification is visible, move focus between monitors. The
popup must not jump to the newly focused bar. Dismiss it, focus the other
monitor, and send a new notification; that new session must use the newly
focused bar.

Finally, repeat the presentation switch 25 times, dismiss all notifications,
wait ten seconds, and compare the QS process counters before and after:

```bash
qs_pid="$(pgrep -n -x qs)"
ps -o pid,rss,nlwp,cmd -p "$qs_pid"
for comm in QSGRenderThread 'qs:gl' 'qs:gdrv' 'qs:sh' WaylandEv; do
    printf '%-16s ' "$comm"
    grep -h "^$comm" /proc/"$qs_pid"/task/*/comm 2>/dev/null | wc -l
done
```

The worker-family counts must not continue growing across repeated batches.
RSS is recorded for context but is not expected to return byte-for-byte.

## Preference safety

Before its first setter IPC call, each run saves the exact starting
`user-prefs.json`. On every normal, failed, interrupted, or unresponsive exit,
the harness then performs teardown in this order:

1. stop random action generation;
2. close temporary test windows;
3. for notification-enabled runs, call `dismissAll` and record the immediate
   count/resource checkpoint;
4. sample through the cleanup wait;
5. complete the final count query and collect the final telemetry sample;
6. stop all test IPC activity;
7. restore the starting preferences;
8. wait two seconds and verify the live file byte-for-byte.

A failed verification fails the run and leaves `starting-user-prefs.json` in
the run directory for manual recovery. If the file did not exist at startup,
the run records that state and verifies that it remains absent after cleanup.

`--no-restore-prefs` deliberately disables restoration for debugging. It prints
a warning and still preserves the starting copy. Do not use it for normal runs.

## Running the harness

Memory-stabilization Phase 5 has two isolated modes. A notification-only soak
generates single notifications and bursts without changing preferences,
switching presentation, opening test windows, or toggling unrelated UI:

```bash
python testing/qs-soak-test.py --minutes 15 --speed 2 --notification-only
```

The no-action baseline records process telemetry without test windows, IPC,
notifications, or preference mutations:

```bash
python testing/qs-soak-test.py --minutes 30 --no-actions
```

`--notification-only` and `--no-actions` are mutually exclusive. A no-action
run also disables controlled notification tracking and cleanup so the baseline
is not contaminated by count or dismissal IPC calls.

Once broad soaks are allowed again, a five-minute run is:

```bash
python testing/qs-soak-test.py --minutes 5
```

Long run:

```bash
python testing/qs-soak-test.py --hours 8
```

No duration means run until stopped:

```bash
python testing/qs-soak-test.py
```

Controls in the harness terminal:

- `p` then Enter: pause/resume
- `q` then Enter: stop cleanly
- `Ctrl+C`: stop cleanly

Use `--no-test-windows` to avoid opening three temporary kitty windows. The
default cleanup wait is ten seconds and can be changed with `--cleanup-wait`.

Exclude notifications, placement mutations, or both without editing the script:

```bash
python testing/qs-soak-test.py --minutes 5 --exclude-group notifications
python testing/qs-soak-test.py --minutes 5 --exclude-group placement
python testing/qs-soak-test.py --minutes 5 \
  --exclude-group notifications --exclude-group placement
```

The notifications group covers notification generation and notification
settings. The placement group covers launcher, wallpaper-picker, notification,
and desktop-clock placement/offset mutations. Notification placement settings
belong to both groups, so excluding either group removes them.

## Logs and telemetry

Each run writes to:

```text
~/.local/state/quickshell/soak-tests/YYYY-MM-DD_HH-MM-SS/
```

Important files:

- `actions.log` — timestamped actions, failures, teardown, and restore result
- `resources.csv` — five-second RSS, RssAnon, CPU, system memory, total threads,
  `QSGRenderThread`, `qs:gl*`, `qs:gdrv*`, `qs:sh*`, `WaylandEvent*`, and FD count
- `notification-checkpoints.csv` — notification count and matching process
  resources before generation, at peak count, after dismissal, and after cleanup
- `baseline.txt` — Phase 0 environment and initial process measurements
- `starting-user-prefs.json` — exact emergency recovery copy when prefs existed
- `starting-user-prefs.absent` — marker when prefs did not exist at startup
- `run.json` — arguments, PID, and start time
- `summary.txt` — run totals, start/peak/end resources, and restore verification

Linux truncates `/proc/PID/task/*/comm` to 15 characters. The harness therefore
matches Mesa and Wayland worker names by the prefixes `qs:gl`, `qs:gdrv`,
`qs:sh`, and `WaylandEv`; `QSGRenderThread` fits exactly.

The harness stops instead of restarting Quickshell if the original PID exits.

## Automatic unresponsive capture

By default, three consecutive failed actions stop new test activity, leave the
original QS process running, and capture process state plus an all-thread GDB
backtrace when available.

Install GDB and refresh the sudo credential immediately before the test:

```bash
sudo pacman -S --needed gdb
sudo -v
python testing/qs-soak-test.py --minutes 30 --speed 3
```

Change the failure threshold with `--failure-threshold 5`. Use
`--no-auto-backtrace` to collect the non-GDB diagnostics without attaching GDB.
Diagnostic files can include:

- `unresponsive-trigger.txt`
- `process-state.txt`
- `thread-top.txt`
- `thread-proc-state.txt`
- `proc-status.txt`, `proc-sched.txt`, `proc-limits.txt`, and `proc-wchan.txt`
- `open-files.txt`
- `quickshell-backtrace.txt`

After capture, keep the entire run directory and do not restart QS until the
harness reports that automatic diagnostics were captured.

— GPT
