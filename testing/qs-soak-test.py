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
KNOWN_EXCLUSION_GROUPS = frozenset(("notifications", "placement"))


class HarnessSetupError(Exception):
    pass


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


def proc_status_kib(pid: int) -> tuple[int, int]:
    rss = 0
    rss_anon = 0
    try:
        for line in Path(f"/proc/{pid}/status").read_text().splitlines():
            if line.startswith("VmRSS:"):
                rss = int(line.split()[1])
            elif line.startswith("RssAnon:"):
                rss_anon = int(line.split()[1])
    except (OSError, ValueError, IndexError):
        pass
    return rss, rss_anon


def proc_thread_counts(pid: int) -> tuple[int, int, int, int, int, int]:
    total = qsg = qs_gl = qs_gdrv = qs_sh = wayland = 0
    try:
        tasks = list(Path(f"/proc/{pid}/task").iterdir())
    except OSError:
        return total, qsg, qs_gl, qs_gdrv, qs_sh, wayland
    for task in tasks:
        try:
            name = (task / "comm").read_text().strip()
        except OSError:
            continue
        total += 1
        if name == "QSGRenderThread":
            qsg += 1
        if name.startswith("qs:gl"):
            qs_gl += 1
        if name.startswith("qs:gdrv"):
            qs_gdrv += 1
        if name.startswith("qs:sh"):
            qs_sh += 1
        if name.startswith("WaylandEv"):
            wayland += 1
    return total, qsg, qs_gl, qs_gdrv, qs_sh, wayland


def proc_fd_count(pid: int) -> int:
    try:
        return sum(1 for _ in Path(f"/proc/{pid}/fd").iterdir())
    except OSError:
        return 0


@dataclass(frozen=True)
class ProcSample:
    rss_kib: int
    rss_anon_kib: int
    threads: int
    qsg_render_threads: int
    qs_gl_threads: int
    qs_gdrv_threads: int
    qs_sh_threads: int
    wayland_event_threads: int
    fd_count: int


@dataclass(frozen=True)
class NotificationCheckpoint:
    timestamp: str
    count: int | None
    proc: ProcSample
    detail: str


def read_proc_sample(pid: int) -> ProcSample:
    rss, rss_anon = proc_status_kib(pid)
    threads, qsg, qs_gl, qs_gdrv, qs_sh, wayland = proc_thread_counts(pid)
    return ProcSample(
        rss, rss_anon, threads, qsg, qs_gl, qs_gdrv, qs_sh, wayland,
        proc_fd_count(pid),
    )


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


def wait_uninterruptibly(seconds: float) -> None:
    deadline = time.monotonic() + max(0.0, seconds)
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return
        try:
            time.sleep(remaining)
        except KeyboardInterrupt:
            print("Final cleanup and preference verification are still in progress.", flush=True)


@dataclass(frozen=True)
class PreferenceSnapshot:
    live_path: Path
    backup_path: Path
    existed: bool
    content: bytes | None

    @classmethod
    def capture(cls, live_path: Path, outdir: Path) -> "PreferenceSnapshot":
        existed = live_path.exists()
        content = live_path.read_bytes() if existed else None
        backup_path = outdir / "starting-user-prefs.json"
        if content is not None:
            backup_path.write_bytes(content)
        else:
            (outdir / "starting-user-prefs.absent").write_text(
                f"{live_path} did not exist when the soak test started.\n"
            )
        return cls(live_path, backup_path, existed, content)

    def restore_and_verify(self, verify_delay: float = 2.0) -> tuple[bool, str]:
        try:
            if self.existed:
                assert self.content is not None
                self.live_path.parent.mkdir(parents=True, exist_ok=True)
                # Write the watched path itself so JsonAdapter receives the
                # external-file change and reloads the restored values. // GPT
                with self.live_path.open("wb") as fh:
                    fh.write(self.content)
                    fh.flush()
                    os.fsync(fh.fileno())
            else:
                self.live_path.unlink(missing_ok=True)
        except Exception as exc:
            return False, f"restore write failed: {exc!r}"

        wait_uninterruptibly(verify_delay)
        try:
            if self.existed:
                actual = self.live_path.read_bytes()
                if actual != self.content:
                    return False, "live preferences changed during the two-second verification window"
            elif self.live_path.exists():
                return False, "preferences were absent at test start but were recreated during verification"
        except OSError as exc:
            return False, f"restore verification failed: {exc!r}"
        return True, "starting preferences restored and verified byte-for-byte"


@dataclass
class Harness:
    pid: int
    outdir: Path
    min_delay: float
    max_delay: float
    launch_windows: bool
    track_notifications: bool
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
        self.resource_csv.writerow([
            "timestamp", "elapsed_s", "pid", "rss_mib", "rss_anon_mib",
            "cpu_percent", "mem_available_mib", "threads",
            "qsg_render_threads", "qs_gl_threads", "qs_gdrv_threads",
            "qs_sh_threads", "wayland_event_threads", "fd_count",
        ])
        self.start = time.monotonic()
        self.last_sample = self.start
        self.last_ticks = proc_ticks(self.pid)
        self.clock_ticks = os.sysconf(os.sysconf_names["SC_CLK_TCK"])
        self.peak_rss = 0
        self.peak_rss_anon = 0
        self.initial_proc = read_proc_sample(self.pid)
        self.last_proc = self.initial_proc
        self.test_windows: list[subprocess.Popen[bytes]] = []
        self.notification_checkpoints: dict[str, NotificationCheckpoint] = {}
        self.peak_notification_count = -1

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
        proc = read_proc_sample(self.pid)
        self.peak_rss = max(self.peak_rss, proc.rss_kib)
        self.peak_rss_anon = max(self.peak_rss_anon, proc.rss_anon_kib)
        self.resource_csv.writerow([
            now(), f"{current-self.start:.1f}", self.pid,
            f"{proc.rss_kib/1024:.1f}", f"{proc.rss_anon_kib/1024:.1f}",
            f"{cpu:.2f}", f"{mem_available_kib()/1024:.1f}", proc.threads,
            proc.qsg_render_threads, proc.qs_gl_threads, proc.qs_gdrv_threads,
            proc.qs_sh_threads, proc.wayland_event_threads, proc.fd_count,
        ])
        self.last_proc = proc
        self.last_sample, self.last_ticks = current, ticks

    def write_baseline(self) -> None:
        qs_path = shutil.which("qs") or "qs"
        project_root = Path(__file__).resolve().parents[1]
        try:
            git_commit = run(["git", "-C", str(project_root), "rev-parse", "HEAD"], 4).stdout.strip()
            git_changes = run(
                ["git", "-C", str(project_root), "status", "--porcelain"], 4
            ).stdout.strip()
            git_state = "clean" if not git_changes else "modified"
        except Exception as exc:
            git_commit = f"unable to query: {exc!r}"
            git_state = "unknown"
        try:
            qs_version = run([qs_path, "--version"], 4).stdout.strip()
        except Exception as exc:
            qs_version = f"unable to query: {exc!r}"
        try:
            ldd_output = run(["ldd", qs_path], 8).stdout
            jemalloc_lines = [line.strip() for line in ldd_output.splitlines()
                              if "jemalloc" in line.lower()]
            jemalloc = "yes: " + " | ".join(jemalloc_lines) if jemalloc_lines else "not shown by ldd"
        except Exception as exc:
            jemalloc = f"unable to query: {exc!r}"
        try:
            process_env = Path(f"/proc/{self.pid}/environ").read_bytes().split(b"\0")
            qsg_info = next((item.decode(errors="replace") for item in process_env
                             if item.startswith(b"QSG_INFO=")), "not set")
        except OSError as exc:
            qsg_info = f"unable to query: {exc}"
        hypridle = run(["pgrep", "-a", "-x", "hypridle"], 2)
        hypridle_state = hypridle.stdout.strip() if hypridle.returncode == 0 else "not running"
        p = self.initial_proc
        (self.outdir / "baseline.txt").write_text(
            f"Captured: {now()}\n"
            f"Git commit: {git_commit or 'no output'}\n"
            f"Git working tree: {git_state}\n"
            f"QS PID: {self.pid}\n"
            f"QS version: {qs_version or 'no output'}\n"
            f"Jemalloc (ldd): {jemalloc}\n"
            f"QSG_INFO: {qsg_info}\n"
            f"Hypridle: {hypridle_state}\n"
            f"RSS MiB: {p.rss_kib/1024:.1f}\n"
            f"RssAnon MiB: {p.rss_anon_kib/1024:.1f}\n"
            f"Threads: {p.threads}\n"
            f"QSGRenderThread: {p.qsg_render_threads}\n"
            f"qs:gl*: {p.qs_gl_threads}\n"
            f"qs:gdrv*: {p.qs_gdrv_threads}\n"
            f"qs:sh*: {p.qs_sh_threads}\n"
            f"WaylandEvent*: {p.wayland_event_threads}\n"
            f"File descriptors: {p.fd_count}\n"
        )

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
                try:
                    proc.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait(timeout=2)
        self.test_windows.clear()

    def cleanup_wait(self, seconds: float) -> None:
        deadline = time.monotonic() + max(0.0, seconds)
        while time.monotonic() < deadline:
            self.sample()
            remaining = deadline - time.monotonic()
            wait_uninterruptibly(min(5.0, max(0.0, remaining)))

    def notification_count(self) -> tuple[bool, int | None, str]:
        ok, detail = ipc("notifs", "count")
        prefix = "ok: count="
        if not ok or not detail.startswith(prefix):
            return False, None, detail or "no response"
        try:
            return True, int(detail[len(prefix):]), detail
        except ValueError:
            return False, None, f"invalid count response: {detail}"

    def capture_notification_checkpoint(self, label: str) -> bool:
        count_ok, count, detail = self.notification_count()
        # Complete the IPC query before telemetry so the after-cleanup row is
        # the final process sample before preference restoration. // GPT
        self.sample()
        self.notification_checkpoints[label] = NotificationCheckpoint(
            now(), count, self.last_proc, detail,
        )
        return count_ok

    def begin_notification_tracking(self) -> tuple[bool, str]:
        if not self.capture_notification_checkpoint("before-notifications"):
            detail = self.notification_checkpoints["before-notifications"].detail
            return False, detail
        checkpoint = self.notification_checkpoints["before-notifications"]
        assert checkpoint.count is not None
        self.peak_notification_count = checkpoint.count
        self.notification_checkpoints["peak-notification-count"] = checkpoint
        return True, f"tracked count={checkpoint.count}"

    def notification_action(self, burst: bool, speed: float) -> tuple[bool, str]:
        ok, detail = notification(burst, speed)
        if not ok:
            return False, detail
        count_ok, count, count_detail = self.notification_count()
        if not count_ok or count is None:
            return False, f"{detail}; count query failed: {count_detail}"
        if count > self.peak_notification_count:
            self.sample()
            self.peak_notification_count = count
            self.notification_checkpoints["peak-notification-count"] = NotificationCheckpoint(
                now(), count, self.last_proc, count_detail,
            )
        return True, f"{detail}; tracked count={count}"

    def cleanup_notifications(self, seconds: float) -> bool:
        dismiss_ok, dismiss_detail = ipc("notifs", "dismissAll")
        self.log("CLEANUP" if dismiss_ok else "FAIL", f"notification cleanup: {dismiss_detail}")

        immediate_ok = self.capture_notification_checkpoint("immediately-after-dismissal")
        immediate = self.notification_checkpoints["immediately-after-dismissal"]
        self.log(
            "INFO" if immediate_ok else "FAIL",
            f"notification count immediately after dismissal: {immediate.detail}",
        )

        self.log("INFO", f"cleanup sampling for {seconds:g} seconds")
        self.cleanup_wait(seconds)

        final_ok = self.capture_notification_checkpoint("after-cleanup-wait")
        final = self.notification_checkpoints["after-cleanup-wait"]
        self.log(
            "INFO" if final_ok else "FAIL",
            f"notification count after cleanup wait: {final.detail}",
        )

        counts_zero = immediate.count == 0 and final.count == 0
        if not counts_zero:
            self.log(
                "FAIL",
                "notification cleanup left tracked state: "
                f"immediate={immediate.count}, after-wait={final.count}",
            )
        return dismiss_ok and immediate_ok and final_ok and counts_zero

    def write_notification_checkpoints(self) -> None:
        if not self.track_notifications:
            return
        order = (
            "before-notifications",
            "peak-notification-count",
            "immediately-after-dismissal",
            "after-cleanup-wait",
        )
        path = self.outdir / "notification-checkpoints.csv"
        with path.open("w", newline="") as fh:
            writer = csv.writer(fh)
            writer.writerow([
                "checkpoint", "timestamp", "tracked_count", "rss_mib",
                "rss_anon_mib", "threads", "qsg_render_threads",
                "qs_gl_threads", "qs_gdrv_threads", "qs_sh_threads",
                "wayland_event_threads", "fd_count", "count_response",
            ])
            for label in order:
                checkpoint = self.notification_checkpoints.get(label)
                if checkpoint is None:
                    continue
                p = checkpoint.proc
                writer.writerow([
                    label, checkpoint.timestamp,
                    "" if checkpoint.count is None else checkpoint.count,
                    f"{p.rss_kib/1024:.1f}", f"{p.rss_anon_kib/1024:.1f}",
                    p.threads, p.qsg_render_threads, p.qs_gl_threads,
                    p.qs_gdrv_threads, p.qs_sh_threads,
                    p.wayland_event_threads, p.fd_count, checkpoint.detail,
                ])

    def write_summary(self, reason: str, restore_status: str) -> None:
        duration = time.monotonic() - self.start
        start = self.initial_proc
        end = self.last_proc
        text = (
            f"Quickshell soak-test summary\n"
            f"Started: {datetime.fromtimestamp(time.time()-duration).astimezone().isoformat(timespec='seconds')}\n"
            f"Ended: {now()}\n"
            f"Duration seconds: {duration:.1f}\n"
            f"Stop reason: {reason}\n"
            f"QS PID: {self.pid}\n"
            f"Actions: {self.actions}\n"
            f"Failures: {self.failures}\n"
            f"Start RSS MiB: {start.rss_kib/1024:.1f}\n"
            f"Peak RSS MiB: {self.peak_rss/1024:.1f}\n"
            f"End RSS MiB: {end.rss_kib/1024:.1f}\n"
            f"Start RssAnon MiB: {start.rss_anon_kib/1024:.1f}\n"
            f"Peak RssAnon MiB: {self.peak_rss_anon/1024:.1f}\n"
            f"End RssAnon MiB: {end.rss_anon_kib/1024:.1f}\n"
            f"Start/end threads: {start.threads}/{end.threads}\n"
            f"Start/end QSGRenderThread: {start.qsg_render_threads}/{end.qsg_render_threads}\n"
            f"Start/end qs:gl*: {start.qs_gl_threads}/{end.qs_gl_threads}\n"
            f"Start/end qs:gdrv*: {start.qs_gdrv_threads}/{end.qs_gdrv_threads}\n"
            f"Start/end qs:sh*: {start.qs_sh_threads}/{end.qs_sh_threads}\n"
            f"Start/end WaylandEvent*: {start.wayland_event_threads}/{end.wayland_event_threads}\n"
            f"Start/end file descriptors: {start.fd_count}/{end.fd_count}\n"
            f"PID remained alive: {Path(f'/proc/{self.pid}').exists()}\n"
            f"Preference restore: {restore_status}\n"
        )
        if self.track_notifications:
            counts = []
            for label in (
                "before-notifications", "peak-notification-count",
                "immediately-after-dismissal", "after-cleanup-wait",
            ):
                checkpoint = self.notification_checkpoints.get(label)
                value = (
                    "unavailable"
                    if checkpoint is None or checkpoint.count is None
                    else str(checkpoint.count)
                )
                counts.append(f"{label}={value}")
            text += "Notification checkpoints: " + ", ".join(counts) + "\n"
        (self.outdir / "summary.txt").write_text(text)
        print("\n" + text)


def setting_action(excluded: frozenset[str]) -> tuple[str, Callable[[], tuple[bool, str]]]:
    plain = frozenset()
    placement = frozenset(("placement",))
    notifications = frozenset(("notifications",))
    notification_placement = frozenset(("notifications", "placement"))
    choices: list[tuple[str, object, frozenset[str]]] = [
        ("fontScale", random.choice([0.9, 1.0, 1.1, 1.25, 1.4]), plain),
        ("clockUse24Hour", random.choice([0, 1]), plain),
        ("clockShowSeconds", random.choice([0, 1]), plain),
        ("launcherPlacement", random.choice(["attached", "centered"]), placement),
        ("launcherOffsetX", random.randrange(-120, 121, 20), placement),
        ("launcherOffsetY", random.randrange(-80, 121, 20), placement),
        ("launcherShowAppsOnOpen", random.choice([0, 1]), plain),
        ("wallpaperPickerPlacement", random.choice(["attached", "centered"]), placement),
        ("wallpaperPickerOffsetX", random.randrange(-120, 121, 20), placement),
        ("wallpaperPickerOffsetY", random.randrange(-80, 121, 20), placement),
        ("wallpaperTransitionType", random.choice(["fade", "wipe", "wave", "grow", "random"]), plain),
        ("wallpaperTransitionDuration", random.choice([0.3, 0.6, 1.0, 1.5, 2.0]), plain),
        ("notifPresentation", random.choice(["bar", "detached"]), notification_placement),
        ("notifBarPosition", random.choice(["left", "center", "right"]), notification_placement),
        ("notifBarOffsetX", random.randrange(-100, 101, 20), notification_placement),
        ("notifBarShowCardBorders", random.choice([0, 1]), notifications),
        ("notifShowAppName", random.choice([0, 1]), notifications),
        ("notifIconSize", random.choice([24, 32, 40, 48, 64]), notifications),
        ("notifBodyLines", random.randint(1, 6), notifications),
        ("notifFontScale", random.choice([0.8, 0.9, 1.0, 1.15, 1.3]), notifications),
        ("notifCorner", random.choice(["top-left", "top-right", "bottom-left", "bottom-right"]), notification_placement),
        ("notifOffsetX", random.randrange(-60, 161, 20), notification_placement),
        ("notifOffsetY", random.randrange(-60, 161, 20), notification_placement),
        ("desktopClockEnabled", random.choice([0, 1]), plain),
        ("desktopClockCorner", random.choice(["top-left", "top-right", "bottom-left", "bottom-right", "centered"]), placement),
        ("desktopClockOffsetX", random.randrange(-60, 161, 20), placement),
        ("desktopClockOffsetY", random.randrange(-60, 161, 20), placement),
        ("desktopClockScale", random.choice([0.7, 0.9, 1.0, 1.2, 1.5]), plain),
        ("desktopClockShadowEnabled", random.choice([0, 1]), plain),
        ("desktopClockShadowStrength", random.choice([0, 20, 40, 60, 80, 100]), plain),
        ("desktopClockShadowOffsetX", random.randint(-8, 8), plain),
        ("desktopClockShadowOffsetY", random.randint(-8, 8), plain),
        ("desktopClockShowWeatherIcon", random.choice([0, 1]), plain),
        ("desktopClockShowTemperature", random.choice([0, 1]), plain),
        ("barBorderWidthOverride", random.choice([-1, 0, 1, 2, 3, 4]), plain),
        ("barPaddingTopOverride", random.choice([-1, 0, 2, 4, 8, 12, 18]), plain),
        ("barPaddingSideOverride", random.choice([-1, 0, 4, 8, 16, 24, 40]), plain),
        ("barPaddingBottomOverride", random.choice([-9999, -8, -4, 0, 4, 8, 16]), plain),
        ("barBorderUseThemeColor", random.choice([0, 1]), plain),
        ("barBorderCustomColor", random.choice(["#ff6b6b", "#7aa2f7", "#9ece6a", "#e0af68", "#bb9af7"]), plain),
    ]
    if THEME_DIR.is_dir():
        themes = [p.stem for p in THEME_DIR.glob("*.qml") if p.stem != "qmldir"]
        if themes:
            choices.append(("themeName", random.choice(themes), plain))
    eligible = [(key, value) for key, value, groups in choices
                if groups.isdisjoint(excluded)]
    key, value = random.choice(eligible)
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
    mode = p.add_mutually_exclusive_group()
    mode.add_argument(
        "--notification-only",
        action="store_true",
        help="generate notifications only; do not mutate settings or toggle other UI",
    )
    mode.add_argument(
        "--no-actions",
        action="store_true",
        help="record an idle baseline without test windows, IPC, notifications, or mutations",
    )
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
    p.add_argument("--exclude-group", action="append", default=[],
                   choices=sorted(KNOWN_EXCLUSION_GROUPS),
                   help="exclude an action family; repeat for multiple groups")
    p.add_argument("--cleanup-wait", type=float, default=10.0,
                   help="seconds to sample after action generation stops (default: 10)")
    p.add_argument("--no-restore-prefs", action="store_true",
                   help="deliberately leave randomized preferences in place for debugging")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    excluded = frozenset(args.exclude_group)
    if args.notification_only and "notifications" in excluded:
        print(
            "--notification-only cannot be combined with --exclude-group notifications.",
            file=sys.stderr,
        )
        return 2
    if args.seed is not None:
        random.seed(args.seed)
    if args.failure_threshold < 1:
        print("--failure-threshold must be at least 1.", file=sys.stderr)
        return 2
    if args.speed <= 0:
        print("--speed must be greater than zero.", file=sys.stderr)
        return 2
    if args.cleanup_wait < 0:
        print("--cleanup-wait cannot be negative.", file=sys.stderr)
        return 2
    effective_min_delay = args.min_delay / args.speed
    effective_max_delay = args.max_delay / args.speed
    if effective_min_delay > effective_max_delay:
        print("--min-delay cannot exceed --max-delay.", file=sys.stderr)
        return 2
    if shutil.which("qs") is None:
        print("Missing required command: qs.", file=sys.stderr)
        return 2
    track_notifications = "notifications" not in excluded and not args.no_actions
    if track_notifications and shutil.which("notify-send") is None:
        print("Missing required command: notify-send (or exclude the notifications group).",
              file=sys.stderr)
        return 2
    pid = qs_pid()
    if pid is None:
        print("No running Quickshell process found. Start qs first.", file=sys.stderr)
        return 2
    stamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    outdir = OUTROOT / stamp
    outdir.mkdir(parents=True, exist_ok=False)
    try:
        prefs_snapshot = PreferenceSnapshot.capture(PREFS, outdir)
    except OSError as exc:
        print(f"Unable to preserve {PREFS}; refusing to start: {exc}", file=sys.stderr)
        return 2
    (outdir / "run.json").write_text(json.dumps(vars(args) | {"pid": pid, "started": now()}, indent=2))

    duration = None
    if args.minutes is not None:
        duration = args.minutes * 60
    elif args.hours is not None:
        duration = args.hours * 3600

    h: Harness | None = None
    reason = "setup did not complete"
    exit_code = 0
    restore_status = "not attempted"
    try:
        h = Harness(
            pid,
            outdir,
            effective_min_delay,
            effective_max_delay,
            not args.no_test_windows and not args.notification_only and not args.no_actions,
            track_notifications,
            failure_threshold=args.failure_threshold,
            auto_backtrace=not args.no_auto_backtrace,
        )
        h.sample()
        h.write_baseline()
        h.log("INFO", f"started; PID={pid}; logs={outdir}")
        h.log("INFO", "controls: Ctrl+C or q+Enter stop; p+Enter pauses/resumes")
        h.log("INFO", "UI Profiles are not exposed to this harness")
        h.log("INFO", f"speed={args.speed:g}x; effective delay={effective_min_delay:.2f}-{effective_max_delay:.2f}s")
        h.log("INFO", f"excluded groups: {', '.join(sorted(excluded)) or 'none'}")
        if args.notification_only:
            h.log("INFO", "mode=notification-only; settings and unrelated UI actions disabled")
        elif args.no_actions:
            h.log("INFO", "mode=no-actions; test windows, IPC, notifications, and mutations disabled")
        else:
            h.log("INFO", "mode=broad-soak")
        h.log("INFO", f"auto-diagnostics after {args.failure_threshold} consecutive failures")
        if h.auto_backtrace:
            h.log("INFO", "for automatic GDB capture, run sudo -v before starting the test")
        if args.no_restore_prefs:
            h.log("WARN", "automatic preference restoration deliberately disabled")

        if not args.notification_only and not args.no_actions:
            ok, detail = ipc("soak", "set", "clockShowSeconds", "1")
            if not ok:
                raise HarnessSetupError(
                    "The soak IPC handler is unavailable. Install the supplied shell.qml "
                    f"and restart qs. {detail}"
                )

        if h.track_notifications:
            ok, detail = h.begin_notification_tracking()
            if not ok:
                raise HarnessSetupError(
                    "The notification-count IPC handler is unavailable. Install the supplied "
                    f"shell.qml and restart qs. {detail}"
                )

        h.create_windows()
        actions: list[tuple[str, frozenset[str], Callable[[], tuple[bool, str]]]] = [
            ("launcher toggle", frozenset(), lambda: ipc("launcher", "toggle")),
            ("wallpaper picker toggle", frozenset(), lambda: ipc("wallpapers", "toggle")),
            ("random wallpaper", frozenset(), lambda: ipc("wallpapers", "random")),
            ("settings toggle", frozenset(), lambda: ipc("settings", "toggle")),
            ("power screen toggle", frozenset(), lambda: ipc("power", "toggle")),
            ("notification", frozenset(("notifications",)),
             lambda: h.notification_action(False, args.speed)),
            ("notification burst", frozenset(("notifications",)),
             lambda: h.notification_action(True, args.speed)),
        ]
        actions = [action for action in actions if action[1].isdisjoint(excluded)]
        notification_actions = [
            action for action in actions if action[0] in ("notification", "notification burst")
        ]
        reason = "duration reached"
        next_sample = time.monotonic() + 5.0
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
            if args.no_actions:
                time.sleep(0.2)
                continue
            if args.notification_only:
                name, _, fn = random.choice(notification_actions)
            elif random.random() < 0.48:
                name, fn = setting_action(excluded)
            else:
                name, _, fn = random.choice(actions)
            h.action(name, fn)
            if h.unresponsive:
                reason = f"QS unresponsive after {h.consecutive_failures} consecutive failures"
                break
            time.sleep(random.uniform(h.min_delay, h.max_delay))
    except KeyboardInterrupt:
        reason = "Ctrl+C"
    except HarnessSetupError as exc:
        reason = str(exc)
        exit_code = 2
        if h is not None:
            h.log("FAIL", reason)
    except Exception as exc:
        reason = f"harness failure: {exc!r}"
        exit_code = 1
        if h is not None:
            h.log("FAIL", reason)
            (outdir / "harness-error.txt").write_text(reason + "\n")
        else:
            print(reason, file=sys.stderr)
    finally:
        previous_sigint = signal.signal(signal.SIGINT, signal.SIG_IGN)
        if h is not None:
            if args.no_actions:
                stop_detail = "no-action monitoring stopped; no cleanup IPC is required"
            elif args.notification_only:
                stop_detail = "notification generation stopped; controlled notification cleanup remains"
            elif h.track_notifications:
                stop_detail = "random action generation stopped; controlled notification cleanup remains"
            else:
                stop_detail = "action generation and IPC activity stopped"
            h.log(
                "INFO",
                stop_detail,
            )
            try:
                h.cleanup_windows()
            except BaseException as exc:
                exit_code = 1
                h.log("FAIL", f"test-window cleanup failed: {exc!r}")
            try:
                if h.track_notifications:
                    if not h.cleanup_notifications(args.cleanup_wait):
                        exit_code = 1
                    h.log("INFO", "controlled notification IPC activity stopped")
                else:
                    h.log("INFO", f"cleanup sampling for {args.cleanup_wait:g} seconds")
                    h.cleanup_wait(args.cleanup_wait)
                    h.sample()
            except BaseException as exc:
                exit_code = 1
                h.log("FAIL", f"cleanup telemetry failed: {exc!r}")
            finally:
                h.write_notification_checkpoints()
                h.resource_file.close()

        if args.no_restore_prefs:
            restore_status = "disabled by --no-restore-prefs; starting backup retained"
        else:
            restore_ok, restore_detail = prefs_snapshot.restore_and_verify()
            restore_status = ("verified: " if restore_ok else "FAILED: ") + restore_detail
            if h is not None:
                h.log("RESTORE" if restore_ok else "FAIL", restore_status)
            else:
                print(restore_status, file=sys.stderr if not restore_ok else sys.stdout)
            if not restore_ok:
                exit_code = 1

        if h is not None:
            h.write_summary(reason, restore_status)
            h.action_file.close()
        signal.signal(signal.SIGINT, previous_sigint)
        print(f"Logs: {outdir}")
    if reason == "QS process exited":
        exit_code = 1
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
