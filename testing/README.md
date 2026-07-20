# testing/

7-13-2026

user added 2 pictures to reference for settings menu changes.

Reserved for standalone `.qml` files used to try something in isolation
— e.g. testing a new `Process` call, a new layout idea, or an unfamiliar
Quickshell API — before wiring it into the real widget tree in
`widgets/`. Nothing in this folder is loaded by `shell.qml` unless a test
feature is deliberately wired into the live shell.

## Quickshell Soak Test

`qs-soak-test.py` is a visible, external torture-test harness for the running
shell. It keeps one Quickshell PID alive, repeatedly exercises safe UI entry
points, mutates harmless visual preferences, and records resource use and every
action.

It **does not restart Quickshell**, and the `soak` IPC handler deliberately has
no UI Profile save, overwrite, rename, delete, or restore functions. Restore the
saved default UI profile manually after a test to return the desktop to normal.

### First five-minute run

From the Quickshell project directory:

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

Controls in the terminal running the harness:

- `p` then Enter: pause/resume
- `q` then Enter: stop cleanly
- `Ctrl+C`: stop cleanly

Use `--no-test-windows` to avoid opening three temporary kitty windows.

### Logs

Each run writes to:

```text
~/.local/state/quickshell/soak-tests/YYYY-MM-DD_HH-MM-SS/
```

Files:

- `actions.log` — timestamped action and failure log
- `resources.csv` — QS RSS, CPU, and system available memory every five seconds
- `starting-user-prefs.json` — emergency copy of the prefs file at test start
- `run.json` — command settings, PID, and start time
- `summary.txt` — duration, stop reason, actions, failures, and RSS summary

The harness stops instead of restarting Quickshell if the original PID exits.

— GPT

## Automatic unresponsive capture

The harness now treats repeated command failures as a diagnostic trigger. By
default, three consecutive failed actions cause it to:

- log `QS_UNRESPONSIVE`
- stop issuing new torture-test actions
- leave the original QS process running
- capture per-thread CPU, memory, wait-channel, `/proc`, and file-descriptor state
- attempt an all-thread GDB backtrace
- end the run with `QS unresponsive after 3 consecutive failures`

Install GDB and refresh the sudo credential immediately before the test so the
automatic attach can run without an interactive password prompt:

```bash
sudo pacman -S --needed gdb
sudo -v
python testing/qs-soak-test.py --minutes 30 --speed 3
```

The failure threshold can be changed:

```bash
python testing/qs-soak-test.py --minutes 30 --speed 3 --failure-threshold 5
```

Use `--no-auto-backtrace` to save the non-GDB diagnostics without attaching
GDB. Automatic diagnostic files are written into the normal run directory and
include:

- `unresponsive-trigger.txt`
- `process-state.txt`
- `thread-top.txt`
- `thread-proc-state.txt`
- `proc-status.txt`, `proc-sched.txt`, `proc-limits.txt`, and `proc-wchan.txt`
- `open-files.txt`
- `quickshell-backtrace.txt`

After the capture finishes, upload the entire run directory. Do not restart QS
until the harness reports that automatic diagnostics were captured.

— GPT
