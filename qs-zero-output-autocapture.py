#!/usr/bin/env python3
"""
qs-zero-output-autocapture.py

One-shot unattended capture harness for the Quickshell zero-output wedge.

Run this from a terminal while the monitors are still on, then physically
power off every monitor. The harness:

  1. Finds the running Quickshell process.
  2. Prompts for sudo once and temporarily sets kernel.yama.ptrace_scope=0.
  3. Waits until Hyprland reports zero real outputs.
  4. Watches the qs:gl0 / WaylandEvent* threads for sustained CPU churn.
  5. Captures three full GDB backtraces plus process/thread/monitor snapshots.
  6. Terminates the wedged Quickshell process after capture.
  7. Waits for a real output to return, then relaunches `qs`.
  8. Restores the original ptrace_scope value and creates a .tar.gz archive.

It is deliberately separate from qs-output-watchdog.py. Do not run the
watchdog at the same time: the watchdog would kill Quickshell before this
harness can capture the failure.

GPT Rev 1
"""

from __future__ import annotations

import argparse
import atexit
import json
import os
import shutil
import signal
import subprocess
import sys
import tarfile
import threading
import time
from pathlib import Path
from typing import Iterable

REAL_OUTPUT_EXCLUSIONS = {"", "FALLBACK", "QSWATCHDOG"}
QS_PROC_NAMES = ("qs", "quickshell")
DEFAULT_CPU_THRESHOLD = 55.0
DEFAULT_SUSTAIN_SECONDS = 4.0
DEFAULT_POLL_SECONDS = 1.0
DEFAULT_GDB_SNAPSHOTS = 3
DEFAULT_GDB_INTERVAL = 5.0
DEFAULT_TERM_TIMEOUT = 5.0
DEFAULT_RETURN_GRACE = 3.0
DEFAULT_MAX_WAIT_AFTER_ZERO = 900.0  # 15 minutes; 0 disables the fallback capture
TARGET_THREAD_PREFIXES = ("qs:gl0", "WaylandEvent")


def log(message: str) -> None:
    print(f"[qs-autocapture {time.strftime('%H:%M:%S')}] {message}", flush=True)


def run(
    argv: list[str],
    *,
    timeout: float | None = None,
    check: bool = False,
    text: bool = True,
) -> subprocess.CompletedProcess:
    return subprocess.run(
        argv,
        capture_output=True,
        text=text,
        timeout=timeout,
        check=check,
    )


def require_command(name: str) -> None:
    if shutil.which(name) is None:
        raise SystemExit(f"Required command not found: {name}")


def discover_qs_pids() -> list[int]:
    found: set[int] = set()
    for name in QS_PROC_NAMES:
        try:
            proc = run(["pgrep", "-x", name], timeout=5)
        except subprocess.TimeoutExpired:
            continue
        if proc.returncode not in (0, 1):
            continue
        for value in proc.stdout.split():
            try:
                found.add(int(value))
            except ValueError:
                pass
    return sorted(found)


def pid_is_qs(pid: int) -> bool:
    try:
        comm = Path(f"/proc/{pid}/comm").read_text().strip()
    except OSError:
        return False
    return comm in QS_PROC_NAMES


def hypr_monitors(include_all: bool = False) -> list[dict] | None:
    args = ["hyprctl", "-j", "monitors"]
    if include_all:
        args.append("all")
    try:
        proc = run(args, timeout=5)
    except subprocess.TimeoutExpired:
        return None
    if proc.returncode != 0:
        return None
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None
    return data if isinstance(data, list) else None


def real_output_count() -> int | None:
    monitors = hypr_monitors()
    if monitors is None:
        return None
    count = 0
    for monitor in monitors:
        name = str(monitor.get("name", ""))
        if name in REAL_OUTPUT_EXCLUSIONS:
            continue
        if monitor.get("disabled", False):
            continue
        count += 1
    return count


def task_stats(pid: int) -> dict[int, tuple[str, int]]:
    """Return tid -> (thread name, user+system jiffies)."""
    stats: dict[int, tuple[str, int]] = {}
    task_root = Path(f"/proc/{pid}/task")
    try:
        tids = list(task_root.iterdir())
    except OSError:
        return stats

    for tid_path in tids:
        try:
            tid = int(tid_path.name)
            name = (tid_path / "comm").read_text().strip()
            raw = (tid_path / "stat").read_text()
            close = raw.rfind(")")
            fields = raw[close + 2 :].split()
            # After removing "pid (comm)", fields[0] is original stat field 3.
            utime = int(fields[11])  # original field 14
            stime = int(fields[12])  # original field 15
            stats[tid] = (name, utime + stime)
        except (OSError, ValueError, IndexError):
            continue
    return stats


def target_thread_cpu(
    previous: dict[int, tuple[str, int]],
    current: dict[int, tuple[str, int]],
    elapsed: float,
) -> tuple[float, list[tuple[int, str, float]]]:
    if elapsed <= 0:
        return 0.0, []
    hz = os.sysconf(os.sysconf_names["SC_CLK_TCK"])
    details: list[tuple[int, str, float]] = []
    total = 0.0

    for tid, (name, ticks) in current.items():
        if not any(name.startswith(prefix) for prefix in TARGET_THREAD_PREFIXES):
            continue
        old = previous.get(tid)
        if old is None:
            continue
        delta = max(0, ticks - old[1])
        cpu = delta / (hz * elapsed) * 100.0
        details.append((tid, name, cpu))
        total += cpu

    details.sort(key=lambda item: item[2], reverse=True)
    return total, details


class Harness:
    def __init__(self, args: argparse.Namespace) -> None:
        self.args = args
        self.original_ptrace: str | None = None
        self.sudo_keepalive_stop = threading.Event()
        self.sudo_thread: threading.Thread | None = None
        self.qs_pid: int | None = None
        self.capture_dir: Path | None = None
        self.capture_started = False
        self.cleaned = False

    # ---------------------------------------------------------- privilege setup

    def sudo_setup(self) -> None:
        log("Requesting sudo once so GDB can attach unattended...")
        proc = subprocess.run(["sudo", "-v"])
        if proc.returncode != 0:
            raise SystemExit("sudo authentication failed")

        current = run(["sysctl", "-n", "kernel.yama.ptrace_scope"], timeout=5)
        if current.returncode != 0:
            raise SystemExit("Could not read kernel.yama.ptrace_scope")
        self.original_ptrace = current.stdout.strip()

        proc = subprocess.run(
            ["sudo", "sysctl", "-q", "kernel.yama.ptrace_scope=0"]
        )
        if proc.returncode != 0:
            raise SystemExit("Could not set kernel.yama.ptrace_scope=0")

        self.sudo_thread = threading.Thread(
            target=self._sudo_keepalive,
            name="sudo-keepalive",
            daemon=True,
        )
        self.sudo_thread.start()
        log(f"ptrace_scope temporarily changed {self.original_ptrace} -> 0")

    def _sudo_keepalive(self) -> None:
        while not self.sudo_keepalive_stop.wait(45):
            subprocess.run(
                ["sudo", "-n", "true"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )

    def restore_ptrace(self) -> None:
        if self.cleaned:
            return
        self.cleaned = True
        self.sudo_keepalive_stop.set()

        if self.original_ptrace is not None:
            proc = subprocess.run(
                [
                    "sudo",
                    "-n",
                    "sysctl",
                    "-q",
                    f"kernel.yama.ptrace_scope={self.original_ptrace}",
                ],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            if proc.returncode == 0:
                log(f"restored kernel.yama.ptrace_scope={self.original_ptrace}")
            else:
                log(
                    "WARNING: could not restore ptrace_scope automatically. "
                    f"Run: sudo sysctl kernel.yama.ptrace_scope={self.original_ptrace}"
                )

    # --------------------------------------------------------------- preparation

    def prepare(self) -> None:
        for command in ("gdb", "hyprctl", "pgrep", "ps", "top", "sudo"):
            require_command(command)

        if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            raise SystemExit(
                "HYPRLAND_INSTANCE_SIGNATURE is not set; run inside Hyprland"
            )

        pids = discover_qs_pids()
        if not pids:
            raise SystemExit("No running Quickshell process found")
        if len(pids) > 1:
            raise SystemExit(
                f"Multiple qs/quickshell processes found: {pids}. "
                "Stop test/preview instances first."
            )

        self.qs_pid = pids[0]
        log(f"tracking Quickshell pid {self.qs_pid}")
        self.sudo_setup()

    # -------------------------------------------------------------- file capture

    def make_capture_dir(self) -> Path:
        stamp = time.strftime("%Y-%m-%d-%H%M%S")
        base = Path.home() / f"quickshell-zero-output-capture-{stamp}"
        base.mkdir(mode=0o700)
        self.capture_dir = base
        return base

    def write_command(
        self,
        filename: str,
        argv: list[str],
        *,
        timeout: float = 30,
    ) -> None:
        assert self.capture_dir is not None
        target = self.capture_dir / filename
        try:
            proc = run(argv, timeout=timeout)
            body = (
                f"$ {' '.join(argv)}\n"
                f"exit={proc.returncode}\n\n"
                f"--- stdout ---\n{proc.stdout}"
                f"\n--- stderr ---\n{proc.stderr}"
            )
        except subprocess.TimeoutExpired as exc:
            body = (
                f"$ {' '.join(argv)}\n"
                f"TIMEOUT after {timeout}s\n\n"
                f"--- stdout ---\n{exc.stdout or ''}"
                f"\n--- stderr ---\n{exc.stderr or ''}"
            )
        target.write_text(body, encoding="utf-8", errors="replace")

    def copy_proc_file(self, relative: str, destination: str) -> None:
        assert self.capture_dir is not None
        assert self.qs_pid is not None
        source = Path(f"/proc/{self.qs_pid}") / relative
        target = self.capture_dir / destination
        try:
            target.write_bytes(source.read_bytes())
        except OSError as exc:
            target.write_text(f"Could not read {source}: {exc}\n")

    def capture_metadata(self) -> None:
        assert self.qs_pid is not None
        self.write_command("hyprctl-monitors.json", ["hyprctl", "-j", "monitors", "all"])
        self.write_command("hyprctl-version.txt", ["hyprctl", "version"])
        self.write_command("qs-version.txt", ["qs", "--version"])
        self.write_command(
            "packages.txt",
            [
                "pacman",
                "-Q",
                "quickshell",
                "qt6-base",
                "qt6-wayland",
                "mesa",
                "libdrm",
                "wayland",
            ],
        )
        self.write_command("uname.txt", ["uname", "-a"])
        self.write_command(
            "ps-threads.txt",
            ["ps", "-eLo", "pid,tid,ppid,stat,pcpu,pmem,rss,comm,args"],
        )
        self.write_command(
            "top-threads.txt",
            ["top", "-H", "-b", "-n", "1", "-p", str(self.qs_pid)],
        )
        self.copy_proc_file("status", "proc-status.txt")
        self.copy_proc_file("limits", "proc-limits.txt")
        self.copy_proc_file("maps", "proc-maps.txt")
        self.copy_proc_file("smaps_rollup", "proc-smaps-rollup.txt")

    def capture_gdb_snapshot(self, index: int) -> None:
        assert self.qs_pid is not None
        assert self.capture_dir is not None
        target = self.capture_dir / f"gdb-backtrace-{index}.txt"
        command = [
            "gdb",
            "-q",
            "-batch",
            "-p",
            str(self.qs_pid),
            "-ex",
            "set pagination off",
            "-ex",
            "set print thread-events off",
            "-ex",
            "info threads",
            "-ex",
            "thread apply all bt full",
            "-ex",
            "info proc mappings",
            "-ex",
            "detach",
            "-ex",
            "quit",
        ]
        log(f"capturing GDB snapshot {index}/{self.args.snapshots}")
        try:
            proc = run(command, timeout=self.args.gdb_timeout)
            target.write_text(
                proc.stdout + "\n--- stderr ---\n" + proc.stderr,
                encoding="utf-8",
                errors="replace",
            )
        except subprocess.TimeoutExpired as exc:
            target.write_text(
                f"GDB TIMEOUT after {self.args.gdb_timeout}s\n\n"
                f"{exc.stdout or ''}\n--- stderr ---\n{exc.stderr or ''}",
                encoding="utf-8",
                errors="replace",
            )

    def capture(self, reason: str, last_cpu: float, details: Iterable[tuple[int, str, float]]) -> None:
        self.capture_started = True
        directory = self.make_capture_dir()
        log(f"capture triggered: {reason}")
        (directory / "trigger.txt").write_text(
            f"time={time.strftime('%Y-%m-%d %H:%M:%S')}\n"
            f"pid={self.qs_pid}\n"
            f"reason={reason}\n"
            f"target_thread_cpu={last_cpu:.1f}%\n"
            + "".join(
                f"thread tid={tid} name={name!r} cpu={cpu:.1f}%\n"
                for tid, name, cpu in details
            ),
            encoding="utf-8",
        )

        self.capture_metadata()
        for index in range(1, self.args.snapshots + 1):
            if self.qs_pid is None or not pid_is_qs(self.qs_pid):
                log("Quickshell disappeared before all snapshots completed")
                break
            self.capture_gdb_snapshot(index)
            if index < self.args.snapshots:
                time.sleep(self.args.snapshot_interval)

        self.write_command(
            "ps-threads-after-gdb.txt",
            ["ps", "-eLo", "pid,tid,ppid,stat,pcpu,pmem,rss,comm,args"],
        )

    # --------------------------------------------------------------- monitoring

    def wait_for_zero_outputs(self) -> None:
        log("armed — physically power off every monitor when ready")
        while True:
            if self.qs_pid is None or not pid_is_qs(self.qs_pid):
                raise SystemExit("Quickshell exited before zero-output detection")
            count = real_output_count()
            if count == 0:
                log("zero real outputs detected — monitoring for active wedge")
                return
            time.sleep(self.args.poll)

    def wait_for_trigger(self) -> tuple[str, float, list[tuple[int, str, float]]]:
        assert self.qs_pid is not None
        previous = task_stats(self.qs_pid)
        previous_time = time.monotonic()
        zero_started = previous_time
        hot_since: float | None = None
        latest_cpu = 0.0
        latest_details: list[tuple[int, str, float]] = []

        while True:
            time.sleep(self.args.poll)

            if not pid_is_qs(self.qs_pid):
                raise SystemExit("Quickshell exited before the capture trigger")

            outputs = real_output_count()
            if outputs is None:
                continue
            if outputs > 0:
                raise SystemExit(
                    "A real output returned before the wedge trigger; no capture taken"
                )

            now = time.monotonic()
            current = task_stats(self.qs_pid)
            latest_cpu, latest_details = target_thread_cpu(
                previous, current, now - previous_time
            )
            previous = current
            previous_time = now

            if latest_cpu >= self.args.cpu_threshold:
                if hot_since is None:
                    hot_since = now
                    log(
                        f"target threads hot at {latest_cpu:.1f}% — "
                        f"waiting {self.args.sustain:.1f}s sustained"
                    )
                elif now - hot_since >= self.args.sustain:
                    return (
                        f"target threads >= {self.args.cpu_threshold:.1f}% "
                        f"for {self.args.sustain:.1f}s",
                        latest_cpu,
                        latest_details,
                    )
            else:
                if hot_since is not None:
                    log(f"CPU fell back to {latest_cpu:.1f}% — resetting trigger")
                hot_since = None

            if (
                self.args.max_wait_after_zero > 0
                and now - zero_started >= self.args.max_wait_after_zero
            ):
                return (
                    f"fallback timer reached {self.args.max_wait_after_zero:.0f}s "
                    "without sustained CPU trigger",
                    latest_cpu,
                    latest_details,
                )

    # --------------------------------------------------------------- recovery

    def terminate_qs(self) -> None:
        if self.qs_pid is None or not pid_is_qs(self.qs_pid):
            return
        log(f"capture complete — sending SIGTERM to Quickshell pid {self.qs_pid}")
        try:
            os.kill(self.qs_pid, signal.SIGTERM)
        except ProcessLookupError:
            return

        deadline = time.monotonic() + self.args.term_timeout
        while time.monotonic() < deadline:
            if not pid_is_qs(self.qs_pid):
                log("Quickshell exited after capture")
                return
            time.sleep(0.25)

        log("Quickshell did not exit — sending SIGKILL")
        try:
            os.kill(self.qs_pid, signal.SIGKILL)
        except ProcessLookupError:
            pass

    def wait_and_restart_qs(self) -> None:
        log("waiting for a real monitor to return")
        stable_since: float | None = None

        while True:
            count = real_output_count()
            now = time.monotonic()
            if count is not None and count > 0:
                if stable_since is None:
                    stable_since = now
                    log(
                        f"real output detected — waiting "
                        f"{self.args.return_grace:.1f}s stable"
                    )
                elif now - stable_since >= self.args.return_grace:
                    break
            else:
                stable_since = None
            time.sleep(0.5)

        if discover_qs_pids():
            log("Quickshell is already running — not launching another instance")
            return

        log("relaunching Quickshell: qs")
        runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
        log_path = Path(runtime) / "qs-zero-output-autocapture-relaunch.log"
        with log_path.open("ab") as handle:
            subprocess.Popen(
                ["qs"],
                stdin=subprocess.DEVNULL,
                stdout=handle,
                stderr=handle,
                start_new_session=True,
            )

    def archive(self) -> Path | None:
        if self.capture_dir is None:
            return None
        archive_path = self.capture_dir.with_suffix(".tar.gz")
        with tarfile.open(archive_path, "w:gz") as archive:
            archive.add(self.capture_dir, arcname=self.capture_dir.name)
        log(f"capture archive ready: {archive_path}")
        return archive_path

    # -------------------------------------------------------------------- run

    def execute(self) -> int:
        self.prepare()
        self.wait_for_zero_outputs()
        reason, cpu, details = self.wait_for_trigger()
        self.capture(reason, cpu, details)
        self.terminate_qs()
        self.wait_and_restart_qs()
        self.archive()
        return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Automatically capture the Quickshell zero-output wedge."
    )
    parser.add_argument(
        "--cpu-threshold",
        type=float,
        default=DEFAULT_CPU_THRESHOLD,
        help=f"combined qs:gl0/WaylandEvent* CPU trigger "
        f"(default {DEFAULT_CPU_THRESHOLD:.0f}%%)",
    )
    parser.add_argument(
        "--sustain",
        type=float,
        default=DEFAULT_SUSTAIN_SECONDS,
        help=f"seconds CPU must remain above threshold "
        f"(default {DEFAULT_SUSTAIN_SECONDS:.0f})",
    )
    parser.add_argument(
        "--poll",
        type=float,
        default=DEFAULT_POLL_SECONDS,
        help=f"monitoring interval in seconds (default {DEFAULT_POLL_SECONDS:.0f})",
    )
    parser.add_argument(
        "--snapshots",
        type=int,
        default=DEFAULT_GDB_SNAPSHOTS,
        help=f"number of GDB snapshots (default {DEFAULT_GDB_SNAPSHOTS})",
    )
    parser.add_argument(
        "--snapshot-interval",
        type=float,
        default=DEFAULT_GDB_INTERVAL,
        help=f"seconds between GDB snapshots (default {DEFAULT_GDB_INTERVAL:.0f})",
    )
    parser.add_argument(
        "--gdb-timeout",
        type=float,
        default=45.0,
        help="timeout for each GDB invocation (default 45)",
    )
    parser.add_argument(
        "--term-timeout",
        type=float,
        default=DEFAULT_TERM_TIMEOUT,
        help=f"SIGTERM-to-SIGKILL timeout after capture "
        f"(default {DEFAULT_TERM_TIMEOUT:.0f})",
    )
    parser.add_argument(
        "--return-grace",
        type=float,
        default=DEFAULT_RETURN_GRACE,
        help=f"stable-monitor time before relaunch (default {DEFAULT_RETURN_GRACE:.0f})",
    )
    parser.add_argument(
        "--max-wait-after-zero",
        type=float,
        default=DEFAULT_MAX_WAIT_AFTER_ZERO,
        help="fallback capture delay after zero outputs; 0 disables "
        f"(default {DEFAULT_MAX_WAIT_AFTER_ZERO:.0f})",
    )
    args = parser.parse_args()

    if args.cpu_threshold <= 0:
        parser.error("--cpu-threshold must be > 0")
    if args.sustain <= 0 or args.poll <= 0:
        parser.error("--sustain and --poll must be > 0")
    if args.snapshots < 1:
        parser.error("--snapshots must be >= 1")
    if args.snapshot_interval < 0:
        parser.error("--snapshot-interval must be >= 0")
    if args.term_timeout < 0 or args.return_grace < 0:
        parser.error("--term-timeout and --return-grace must be >= 0")
    return args


def main() -> int:
    args = parse_args()
    harness = Harness(args)
    atexit.register(harness.restore_ptrace)

    def handle_signal(signum: int, _frame) -> None:
        log(f"received signal {signum}; exiting")
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    try:
        return harness.execute()
    finally:
        harness.restore_ptrace()


if __name__ == "__main__":
    raise SystemExit(main())
