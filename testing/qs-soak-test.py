#!/usr/bin/env python3
"""Visible Quickshell soak/torture test. GPT.

One uninterrupted QS process is required. The harness never restarts QS and
never touches UI Profiles. Stop cleanly with Ctrl+C or type q + Enter.
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import random
import select
import shutil
import signal
import subprocess
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Callable

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
PREFS = STATE / "quickshell/user-prefs.json"
OUTROOT = STATE / "quickshell/soak-tests"
THEME_DIR = Path(__file__).resolve().parents[1] / "themes"


def now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def run(cmd: list[str], timeout: float = 8.0) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, timeout=timeout, check=False)


def qs_pid() -> int | None:
    for name in ("qs", "quickshell"):
        cp = run(["pgrep", "-n", "-x", name], 2)
        if cp.returncode == 0 and cp.stdout.strip().isdigit():
            return int(cp.stdout.strip())
    cp = run(["pgrep", "-n", "-f", r"(^|/)qs( |$)|quickshell.*shell.qml"], 2)
    return int(cp.stdout.strip()) if cp.returncode == 0 and cp.stdout.strip().isdigit() else None


def proc_rss_kib(pid: int) -> int:
    try:
        for line in Path(f"/proc/{pid}/status").read_text().splitlines():
            if line.startswith("VmRSS:"):
                return int(line.split()[1])
    except OSError:
        pass
    return 0


def proc_ticks(pid: int) -> int:
    try:
        fields = Path(f"/proc/{pid}/stat").read_text().split()
        return int(fields[13]) + int(fields[14])
    except (OSError, ValueError, IndexError):
        return 0


def mem_available_kib() -> int:
    try:
        for line in Path("/proc/meminfo").read_text().splitlines():
            if line.startswith("MemAvailable:"):
                return int(line.split()[1])
    except OSError:
        pass
    return 0


def ipc(target: str, method: str, *args: object) -> tuple[bool, str]:
    cp = run(["qs", "ipc", "call", target, method, *map(str, args)])
    text = cp.stdout.strip().replace("\n", " | ")
    return cp.returncode == 0 and "ERROR" not in text.upper(), text


@dataclass
class Harness:
    pid: int
    outdir: Path
    min_delay: float
    max_delay: float
    launch_windows: bool
    stop: bool = False
    paused: bool = False
    actions: int = 0
    failures: int = 0
    consecutive_failures: int = 0
    failure_threshold: int = 3
    auto_backtrace: bool = True
    unresponsive: bool = False

    def __post_init__(self) -> None:
        self.action_file = (self.outdir / "actions.log").open("a", buffering=1)
        self.resource_file = (self.outdir / "resources.csv").open("w", newline="", buffering=1)
        self.resource_csv = csv.writer(self.resource_file)
        self.resource_csv.writerow(["timestamp", "elapsed_s", "pid", "rss_mib", "cpu_percent", "mem_available_mib"])
        self.start = time.monotonic()
        self.last_sample = self.start
        self.last_ticks = proc_ticks(self.pid)
        self.clock_ticks = os.sysconf(os.sysconf_names["SC_CLK_TCK"])
        self.peak_rss = 0
        self.start_rss = proc_rss_kib(self.pid)
        self.test_windows: list[subprocess.Popen[bytes]] = []

    def log(self, kind: str, message: str) -> None:
        line = f"{now()} {kind:<7} {message}"
        print(line, flush=True)
        self.action_file.write(line + "\n")

    def action(self, name: str, fn: Callable[[], tuple[bool, str]]) -> None:
        self.actions += 1
        try:
            ok, detail = fn()
        except Exception as exc:  # keep harness alive, but make failure loud
            ok, detail = False, repr(exc)
        if ok:
            self.consecutive_failures = 0
        else:
            self.failures += 1
            self.consecutive_failures += 1
        self.log("ACTION" if ok else "FAIL", f"{name}: {detail or 'ok'}")
        if not ok and self.consecutive_failures >= self.failure_threshold and not self.unresponsive:
            self.unresponsive = True
            self.capture_diagnostics(name, detail)

    def _write_command(self, filename: str, cmd: list[str], timeout: float = 20.0) -> None:
        path = self.outdir / filename
        try:
            cp = run(cmd, timeout)
            path.write_text(
                f"$ {' '.join(cmd)}\nreturncode={cp.returncode}\n\n{cp.stdout}"
            )
        except subprocess.TimeoutExpired as exc:
            output = exc.stdout or ""
            if isinstance(output, bytes):
                output = output.decode(errors="replace")
            path.write_text(
                f"$ {' '.join(cmd)}\nTIMEOUT after {timeout:.1f}s\n\n{output}"
            )
        except Exception as exc:
            path.write_text(f"$ {' '.join(cmd)}\nFAILED: {exc!r}\n")

    def capture_diagnostics(self, action_name: str, detail: str) -> None:
        self.log(
            "QS_UNRESPONSIVE",
            f"{self.consecutive_failures} consecutive failures; last={action_name}: {detail or 'no detail'}",
        )
        (self.outdir / "unresponsive-trigger.txt").write_text(
            f"timestamp: {now()}\n"
            f"pid: {self.pid}\n"
            f"consecutive_failures: {self.consecutive_failures}\n"
            f"last_action: {action_name}\n"
            f"last_detail: {detail}\n"
        )
        self.sample()
        self._write_command(
            "process-state.txt",
            ["ps", "-L", "-p", str(self.pid), "-o",
             "pid,tid,ppid,stat,psr,pcpu,pmem,rss,vsz,etime,wchan:32,comm"],
        )
        self._write_command(
            "thread-top.txt",
            ["top", "-b", "-H", "-n", "1", "-p", str(self.pid)],
        )
        self._write_command(
            "open-files.txt", ["ls", "-l", f"/proc/{self.pid}/fd"],
        )
        for source, target in (
            (f"/proc/{self.pid}/status", "proc-status.txt"),
            (f"/proc/{self.pid}/sched", "proc-sched.txt"),
            (f"/proc/{self.pid}/limits", "proc-limits.txt"),
            (f"/proc/{self.pid}/wchan", "proc-wchan.txt"),
        ):
            try:
                (self.outdir / target).write_text(Path(source).read_text())
            except OSError as exc:
                (self.outdir / target).write_text(f"Unable to read {source}: {exc}\n")

        task_dir = Path(f"/proc/{self.pid}/task")
        with (self.outdir / "thread-proc-state.txt").open("w") as fh:
            try:
                tids = sorted(task_dir.iterdir(), key=lambda item: int(item.name))
            except OSError as exc:
                fh.write(f"Unable to enumerate threads: {exc}\n")
                tids = []
            for tid_dir in tids:
                fh.write(f"\n===== TID {tid_dir.name} =====\n")
                for leaf in ("comm", "wchan", "stack", "stat"):
                    fh.write(f"--- {leaf} ---\n")
                    try:
                        fh.write((tid_dir / leaf).read_text())
                    except OSError as exc:
                        fh.write(f"Unable to read: {exc}\n")

        if not self.auto_backtrace:
            self.log("INFO", "automatic GDB backtrace disabled")
            return
        if shutil.which("gdb") is None:
            (self.outdir / "quickshell-backtrace.txt").write_text(
                "gdb is not installed. Install it with: sudo pacman -S --needed gdb\n"
            )
            self.log("WARN", "gdb not installed; saved non-GDB diagnostics")
            return

        gdb_args = [
            "gdb", "-q", "-batch",
            "-ex", "set pagination off",
            "-ex", "set print thread-events off",
            "-ex", "thread apply all bt full",
            "-p", str(self.pid),
        ]
        if shutil.which("sudo") is not None:
            cmd = ["sudo", "-n", *gdb_args]
        else:
            cmd = gdb_args
        self._write_command("quickshell-backtrace.txt", cmd, timeout=60.0)
        self.log("INFO", "automatic diagnostics captured; QS was left running")

    def sample(self) -> None:
        current = time.monotonic()
        dt = max(0.001, current - self.last_sample)
        ticks = proc_ticks(self.pid)
        cpu = max(0.0, (ticks - self.last_ticks) / self.clock_ticks / dt * 100.0)
        rss = proc_rss_kib(self.pid)
        self.peak_rss = max(self.peak_rss, rss)
        self.resource_csv.writerow([
            now(), f"{current-self.start:.1f}", self.pid,
            f"{rss/1024:.1f}", f"{cpu:.2f}", f"{mem_available_kib()/1024:.1f}",
        ])
        self.last_sample, self.last_ticks = current, ticks

    def create_windows(self) -> None:
        if not self.launch_windows or shutil.which("kitty") is None:
            return
        for idx in range(1, 4):
            title = f"QS Soak Test {idx}"
            proc = subprocess.Popen([
                "kitty", "--class", f"qs-soak-{idx}", "--title", title,
                "sh", "-c", f"printf '\\n  {title}\\n\\n  Safe to close. The harness will continue.\\n'; exec sleep 86400",
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.test_windows.append(proc)
            time.sleep(0.4)
        self.log("INFO", f"opened {len(self.test_windows)} kitty test windows")

    def cleanup_windows(self) -> None:
        for proc in self.test_windows:
            if proc.poll() is None:
                proc.terminate()
        self.test_windows.clear()

    def write_summary(self, reason: str) -> None:
        end_rss = proc_rss_kib(self.pid)
        duration = time.monotonic() - self.start
        text = (
            f"Quickshell soak-test summary\n"
            f"Started: {datetime.fromtimestamp(time.time()-duration).astimezone().isoformat(timespec='seconds')}\n"
            f"Ended: {now()}\n"
            f"Duration seconds: {duration:.1f}\n"
            f"Stop reason: {reason}\n"
            f"QS PID: {self.pid}\n"
            f"Actions: {self.actions}\n"
            f"Failures: {self.failures}\n"
            f"Start RSS MiB: {self.start_rss/1024:.1f}\n"
            f"Peak RSS MiB: {self.peak_rss/1024:.1f}\n"
            f"End RSS MiB: {end_rss/1024:.1f}\n"
            f"PID remained alive: {Path(f'/proc/{self.pid}').exists()}\n"
        )
        (self.outdir / "summary.txt").write_text(text)
        print("\n" + text)


def setting_action() -> tuple[str, Callable[[], tuple[bool, str]]]:
    choices: list[tuple[str, object]] = [
        ("fontScale", random.choice([0.9, 1.0, 1.1, 1.25, 1.4])),
        ("clockUse24Hour", random.choice([0, 1])),
        ("clockShowSeconds", random.choice([0, 1])),
        ("launcherPlacement", random.choice(["attached", "centered"])),
        ("launcherOffsetX", random.randrange(-120, 121, 20)),
        ("launcherOffsetY", random.randrange(-80, 121, 20)),
        ("launcherShowAppsOnOpen", random.choice([0, 1])),
        ("wallpaperPickerPlacement", random.choice(["attached", "centered"])),
        ("wallpaperPickerOffsetX", random.randrange(-120, 121, 20)),
        ("wallpaperPickerOffsetY", random.randrange(-80, 121, 20)),
        ("wallpaperTransitionType", random.choice(["fade", "wipe", "wave", "grow", "random"])),
        ("wallpaperTransitionDuration", random.choice([0.3, 0.6, 1.0, 1.5, 2.0])),
        ("notifPresentation", random.choice(["bar", "detached"])),
        ("notifBarPosition", random.choice(["left", "center", "right"])),
        ("notifBarOffsetX", random.randrange(-100, 101, 20)),
        ("notifBarShowCardBorders", random.choice([0, 1])),
        ("notifShowAppName", random.choice([0, 1])),
        ("notifIconSize", random.choice([24, 32, 40, 48, 64])),
        ("notifBodyLines", random.randint(1, 6)),
        ("notifFontScale", random.choice([0.8, 0.9, 1.0, 1.15, 1.3])),
        ("notifCorner", random.choice(["top-left", "top-right", "bottom-left", "bottom-right"])),
        ("notifOffsetX", random.randrange(-60, 161, 20)),
        ("notifOffsetY", random.randrange(-60, 161, 20)),
        ("desktopClockEnabled", random.choice([0, 1])),
        ("desktopClockCorner", random.choice(["top-left", "top-right", "bottom-left", "bottom-right", "centered"])),
        ("desktopClockOffsetX", random.randrange(-60, 161, 20)),
        ("desktopClockOffsetY", random.randrange(-60, 161, 20)),
        ("desktopClockScale", random.choice([0.7, 0.9, 1.0, 1.2, 1.5])),
        ("desktopClockShadowEnabled", random.choice([0, 1])),
        ("desktopClockShadowStrength", random.choice([0, 20, 40, 60, 80, 100])),
        ("desktopClockShadowOffsetX", random.randint(-8, 8)),
        ("desktopClockShadowOffsetY", random.randint(-8, 8)),
        ("desktopClockShowWeatherIcon", random.choice([0, 1])),
        ("desktopClockShowTemperature", random.choice([0, 1])),
        ("barBorderWidthOverride", random.choice([-1, 0, 1, 2, 3, 4])),
        ("barPaddingTopOverride", random.choice([-1, 0, 2, 4, 8, 12, 18])),
        ("barPaddingSideOverride", random.choice([-1, 0, 4, 8, 16, 24, 40])),
        ("barPaddingBottomOverride", random.choice([-9999, -8, -4, 0, 4, 8, 16])),
        ("barBorderUseThemeColor", random.choice([0, 1])),
        ("barBorderCustomColor", random.choice(["#ff6b6b", "#7aa2f7", "#9ece6a", "#e0af68", "#bb9af7"])),
    ]
    if THEME_DIR.is_dir():
        themes = [p.stem for p in THEME_DIR.glob("*.qml") if p.stem != "qmldir"]
        if themes:
            choices.append(("themeName", random.choice(themes)))
    key, value = random.choice(choices)
    return f"setting {key}={value}", lambda: ipc("soak", "set", key, value)


def notification(burst: bool = False, speed: float = 2.0) -> tuple[bool, str]:
    count = random.randint(3, 7) if burst else 1
    urgency = random.choice(["low", "normal", "critical"])
    timeout = random.choice([1800, 2500, 3500, 5000])
    for i in range(count):
        cp = run([
            "notify-send", "-u", urgency, "-t", str(timeout),
            "QS soak test", f"Random notification {i+1}/{count} at {now()}",
        ])
        if cp.returncode != 0:
            return False, cp.stdout.strip()
        if burst:
            time.sleep(random.uniform(0.05, 0.22) / max(0.1, speed))
    return True, f"{count} {urgency} notification(s), timeout={timeout}ms"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Visible Quickshell soak test")
    group = p.add_mutually_exclusive_group()
    group.add_argument("--minutes", type=float)
    group.add_argument("--hours", type=float)
    p.add_argument("--seed", type=int, help="repeatable random sequence")
    p.add_argument("--min-delay", type=float, default=0.8,
                   help="base minimum delay before applying --speed")
    p.add_argument("--max-delay", type=float, default=3.5,
                   help="base maximum delay before applying --speed")
    p.add_argument("--speed", type=float, default=2.0,
                   help="action-rate multiplier; 1 is original pace, 2 is default, 4 is aggressive")
    p.add_argument("--no-test-windows", action="store_true")
    p.add_argument("--failure-threshold", type=int, default=3,
                   help="consecutive failed actions before capturing diagnostics and stopping")
    p.add_argument("--no-auto-backtrace", action="store_true",
                   help="capture process diagnostics but skip the automatic GDB attach")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    if args.seed is not None:
        random.seed(args.seed)
    if args.failure_threshold < 1:
        print("--failure-threshold must be at least 1.", file=sys.stderr)
        return 2
    if args.speed <= 0:
        print("--speed must be greater than zero.", file=sys.stderr)
        return 2
    effective_min_delay = args.min_delay / args.speed
    effective_max_delay = args.max_delay / args.speed
    if effective_min_delay > effective_max_delay:
        print("--min-delay cannot exceed --max-delay.", file=sys.stderr)
        return 2
    if shutil.which("qs") is None or shutil.which("notify-send") is None:
        print("Missing required command: qs and notify-send are required.", file=sys.stderr)
        return 2
    pid = qs_pid()
    if pid is None:
        print("No running Quickshell process found. Start qs first.", file=sys.stderr)
        return 2
    ok, detail = ipc("soak", "set", "clockShowSeconds", "1")
    if not ok:
        print("The soak IPC handler is unavailable. Install the supplied shell.qml and restart qs.")
        print(detail)
        return 2

    stamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    outdir = OUTROOT / stamp
    outdir.mkdir(parents=True, exist_ok=False)
    if PREFS.exists():
        shutil.copy2(PREFS, outdir / "starting-user-prefs.json")
    (outdir / "run.json").write_text(json.dumps(vars(args) | {"pid": pid, "started": now()}, indent=2))

    h = Harness(
        pid, outdir, effective_min_delay, effective_max_delay, not args.no_test_windows,
        failure_threshold=args.failure_threshold,
        auto_backtrace=not args.no_auto_backtrace,
    )
    duration = None
    if args.minutes is not None:
        duration = args.minutes * 60
    elif args.hours is not None:
        duration = args.hours * 3600

    h.log("INFO", f"started; PID={pid}; logs={outdir}")
    h.log("INFO", "controls: Ctrl+C or q+Enter stop; p+Enter pauses/resumes")
    h.log("INFO", "UI Profiles are not exposed to this harness")
    h.log("INFO", f"speed={args.speed:g}x; effective delay={effective_min_delay:.2f}-{effective_max_delay:.2f}s")
    h.log("INFO", f"auto-diagnostics after {args.failure_threshold} consecutive failures")
    if h.auto_backtrace:
        h.log("INFO", "for automatic GDB capture, run sudo -v before starting the test")
    h.create_windows()

    actions: list[tuple[str, Callable[[], tuple[bool, str]]]] = [
        ("launcher toggle", lambda: ipc("launcher", "toggle")),
        ("wallpaper picker toggle", lambda: ipc("wallpapers", "toggle")),
        ("random wallpaper", lambda: ipc("wallpapers", "random")),
        ("settings toggle", lambda: ipc("settings", "toggle")),
        ("power screen toggle", lambda: ipc("power", "toggle")),
        ("notification", lambda: notification(False, args.speed)),
        ("notification burst", lambda: notification(True, args.speed)),
    ]
    reason = "duration reached"
    next_sample = time.monotonic()
    try:
        while True:
            if not Path(f"/proc/{pid}").exists():
                reason = "QS process exited"
                h.log("CRASH", reason)
                break
            elapsed = time.monotonic() - h.start
            if duration is not None and elapsed >= duration:
                break
            if sys.stdin.isatty() and select.select([sys.stdin], [], [], 0)[0]:
                cmd = sys.stdin.readline().strip().lower()
                if cmd == "q":
                    reason = "user requested"
                    break
                if cmd == "p":
                    h.paused = not h.paused
                    h.log("INFO", "paused" if h.paused else "resumed")
            if time.monotonic() >= next_sample:
                h.sample()
                next_sample = time.monotonic() + 5.0
            if h.paused:
                time.sleep(0.2)
                continue
            if random.random() < 0.48:
                name, fn = setting_action()
            else:
                name, fn = random.choice(actions)
            h.action(name, fn)
            if h.unresponsive:
                reason = f"QS unresponsive after {h.consecutive_failures} consecutive failures"
                break
            time.sleep(random.uniform(h.min_delay, h.max_delay))
    except KeyboardInterrupt:
        reason = "Ctrl+C"
    finally:
        h.sample()
        h.cleanup_windows()
        h.write_summary(reason)
        h.action_file.close()
        h.resource_file.close()
        print(f"Logs: {outdir}")
    return 1 if reason == "QS process exited" else 0


if __name__ == "__main__":
    raise SystemExit(main())
