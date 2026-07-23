#!/usr/bin/env python3
"""qs-output-watchdog.py — external zero-output watchdog for Quickshell. (v2.3)

WHY THIS EXISTS (short version — full story in docs/ZERO_OUTPUT_WATCHDOG.md):

When every physical monitor is powered off, Hyprland removes all wl_outputs
and Qt Wayland creates a synthetic "FALLBACK" placeholder screen. After a
few minutes in that state, Quickshell wedges: IPC and notifications stop
responding, a Mesa worker (qs:gl0) and Qt's WaylandEventThread burn ~1 core
between them, and only a restart recovers it. Live GDB captures show
QSGRenderThread blocked in QRhi::endFrame -> QWaylandGLContext::swapBuffers
-> Mesa dri_flush while a Mesa qs:gl0 worker is inside an EGL-triggered
wl_display_roundtrip_queue. Whatever the exact upstream ownership, the
demonstrated failure lives in the Qt Wayland / Qt Quick / Mesa rendering
interaction below QML. In-shell guards reduced symptoms but could not prevent
it, and a wedged Quickshell cannot rescue itself.
Hence: an EXTERNAL watchdog.

TWO MITIGATION MODES:

  --mode restart    (DEFAULT — production workaround) After a sustained
                    zero-output period (default 3s), cleanly stop
                    Quickshell (SIGTERM, escalating to SIGKILL) well before
                    the ~120s wedge window closes, then relaunch it once a
                    real output has been back for a few seconds. Loses
                    in-memory state (open popouts, notification popups);
                    persisted settings are unaffected. Proven approach.

  --mode headless   (EXPERIMENTAL — requires live validation, see doc §7)
                    Shortly after real outputs hit zero (default 1s),
                    create a Hyprland headless output. Qt created its
                    placeholder the moment the last real output vanished —
                    this does NOT prevent that — but it ENDS the
                    placeholder-only state within ~a second, keeping the
                    exposure far below the observed wedge window while
                    Quickshell keeps running with all state intact. The
                    headless output is removed once a real monitor returns.
                    Note: output create/remove is still a monitor-layout
                    transition (workspace/focus movement possible); "less
                    destructive than a restart" is not "free".

DESIGN RULES (each one earned by the failure report or review):

  * Event-driven: subscribes to Hyprland's socket2 for monitor events; a
    periodic re-verify backstops missed events. Every event triggers a
    fresh `hyprctl -j monitors` read — events mean "go look", never truth.
  * Debounced BOTH directions, with PER-MODE removal grace: restart mode
    waits 3s, well before the observed wedge; headless mode waits only 1s
    because creating an output is cheap to do and undo, and every second
    shaved shortens placeholder
    exposure. Return grace (default 3s) covers monitors that renegotiate
    slowly on wake — Hyprland is known to briefly destroy/recreate
    slow-waking outputs (hyprwm/Hyprland#5752) — and covers the
    noisy-cable case for headless removal.
  * `hyprctl` failure is treated as "unknown", never as "zero monitors".
  * Headless creation is VERIFIED against `hyprctl -j monitors all` (the
    command exiting 0 proves nothing about the output existing); failure
    cleans up any partial result and falls back to restart behavior.
  * A pre-existing headless output from a dead predecessor is ADOPTED if
    the outage is still ongoing, removed if it is stale.
  * Manages a TRACKED PID (captured at startup, updated on relaunch),
    falling back to pgrep discovery only when the tracked PID is gone —
    and the pgrep fallback kills EVERY user process named qs/quickshell,
    which is stated here plainly because it matters if a second instance
    (test config, SDDM preview) ever runs alongside.
  * Singleton via flock; duplicate launches exit silently.
  * Hyprland restart: old socket closed explicitly, immediate re-evaluate
    after reconnect (monitor state is most likely to have changed exactly
    then); if Hyprland is really gone, exit — the new instance's exec-once
    spawns a fresh watchdog.
  * Cleanup on exit leaves the world sane: headless output removed ONLY if
    a real output exists (removing it mid-outage would re-enter the
    placeholder state; a successor watchdog adopts it instead), and qs is
    restarted if we stopped it and there is a screen to show it on.

USAGE:

  qs-output-watchdog.py [--mode restart|headless] [--zero-grace SEC]
                        [--return-grace SEC] [--headless-name NAME]
                        [--always-start] [--verbose]

  --zero-grace defaults per mode: 3 (restart) / 1 (headless).

Hyprland lua integration (startup.lua):

  hl.on("hyprland.start", function()
      hl.exec_cmd(os.getenv("HOME") ..
          "/.config/quickshell/qs-output-watchdog.py")
  end)

Stdlib only. No jq, no external deps. Written for Hyprland 0.55+.

REVISION HISTORY
  2026-07-23  v2.3 (GPT post-live validation): corrected restart-mode
              documentation to the implemented 3s zero-output grace. Physical
              power-off testing captured the active wedge in three stable GDB
              snapshots. Restart mode then stopped and relaunched Quickshell
              successfully when a real monitor returned. Restart mode is the
              validated production workaround.
  2026-07-20  v2.2 (GPT final pre-live review): distinguish named headless
              output states as absent / invalid / active. Disabled or
              zero-geometry QSWATCHDOG entries are removed before create or
              adoption instead of being ignored, preventing duplicate-name
              creation failure and stale-output leakage. Headless removal is
              now verified against `monitors all`.
  2026-07-20  v2.1 (second GPT review): stale-headless reconciliation is
              now MODE-AWARE (restart mode never adopts an output or jumps
              to MITIGATED — it reaps a stray predecessor output only after
              a real monitor returns, via _reap_foreign_headless); headless
              adoption/verification now requires an ACTIVE output with valid
              geometry (headless_active replaces headless_present — a
              disabled QSWATCHDOG gives Qt no usable screen and must not
              count as protection); socket var initialized before the try so
              a socket() failure can't hit an unbound name in except; header
              claims kept at observation level.
  2026-07-20  v2 (joint Claude/GPT review): per-mode zero-grace defaults
              (12s restart / 1s headless); headless creation verified
              against `monitors all` with partial-result cleanup and
              restart fallback; stale-headless ADOPTION during an ongoing
              outage (startup + act-time) and re-creation if it vanishes
              mid-mitigation (e.g. Hyprland reload); tracked-PID process
              management with pgrep as stated fallback; centralized
              QS_COMMAND; explicit old-socket close + immediate
              re-evaluate on reconnect; grace validation (no negatives,
              minimum 0.5s, restart ceiling <100s); exit cleanup keeps
              the headless output alive if the outage is ongoing;
              root-cause language softened to working-hypothesis status;
              mode statuses labeled (restart=default, headless=
              experimental).
  2026-07-20  Initial version, built from the zero-output failure report
              (Quickshell-zero-output-failure-report.md). Both modes,
              socket2 subscription, dual debounce, flock singleton,
              cleanup-on-exit.
"""

from __future__ import annotations

import argparse
import fcntl
import json
import os
import select
import signal
import socket
import subprocess
import sys
import time

# ---------------------------------------------------------------------------
# Defaults — tune via CLI flags, not by editing these.
# ---------------------------------------------------------------------------

MODE_ZERO_GRACE = {"restart": 3.0, "headless": 1.0}  # per-mode (see header)
DEFAULT_RETURN_GRACE = 3.0    # seconds of sustained real-output before restoring
MIN_GRACE = 0.5               # floor for either grace — 0/negative = footgun
DEFAULT_HEADLESS_NAME = "QSWATCHDOG"
PERIODIC_VERIFY = 15.0        # safety-net re-check even with no events
TERM_TIMEOUT = 5.0            # SIGTERM -> SIGKILL escalation window
HYPRCTL_TIMEOUT = 5.0
HEADLESS_VERIFY_TIMEOUT = 3.0  # how long to wait for a created output to appear
SOCKET_RECONNECT_TRIES = 5
QS_PROC_NAMES = ("qs", "quickshell")  # pgrep-fallback process names

# The exact relaunch command, in one place (review item #6). Bare `qs` is
# correct for THIS machine: shell.qml sits at the quickshell root and there
# is no -c flag in use — see docs/INTEGRATION_NOTES.md. If the launch method
# ever changes (wrapper, named config), change it HERE.
QS_COMMAND = ["qs"]

# NOTE on the headless name: Hyprland names a created headless output with the
# exact string given to `hyprctl output create headless <name>`. Pick something
# that can never collide with a real connector (DP-*, HDMI-A-*, eDP-*). The
# Rev 72 QML guards exclude this exact name — if you change --headless-name,
# update isRealScreen() in shell.qml AND DesktopClock.qml to match.


def log(msg: str) -> None:
    print(f"[qs-watchdog {time.strftime('%H:%M:%S')}] {msg}", flush=True)


class Watchdog:
    # State machine:
    #   NORMAL          real outputs exist, nothing mitigated
    #   ZERO_PENDING    zero real outputs seen; debouncing before acting
    #   MITIGATED       action taken (qs stopped / headless created-or-adopted)
    #   RESTORE_PENDING real output back; debouncing before restoring
    NORMAL, ZERO_PENDING, MITIGATED, RESTORE_PENDING = range(4)
    STATE_NAMES = {0: "NORMAL", 1: "ZERO_PENDING", 2: "MITIGATED", 3: "RESTORE_PENDING"}

    def __init__(self, args: argparse.Namespace) -> None:
        self.mode = args.mode
        self.zero_grace = args.zero_grace
        self.return_grace = args.return_grace
        self.headless_name = args.headless_name
        self.always_start = args.always_start
        self.verbose = args.verbose
        self.qs_command = list(QS_COMMAND)

        self.state = self.NORMAL
        self.deadline: float | None = None   # when the current debounce expires
        self.we_stopped_qs = False           # restart mode: did WE stop it?
        self.headless_created = False        # headless mode: created OR adopted
        self._foreign_headless = False       # restart mode: stray predecessor output
        self.tracked_pid: int | None = None  # the qs instance we manage

        runtime = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
        sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
        if not sig:
            sys.exit("HYPRLAND_INSTANCE_SIGNATURE not set — not inside a "
                     "Hyprland session (launch this from exec-once).")
        self.socket2_path = os.path.join(runtime, "hypr", sig, ".socket2.sock")
        self.lock_path = os.path.join(runtime, "qs-output-watchdog.lock")
        self.qs_log_path = os.path.join(runtime, "qs-output-watchdog-relaunch.log")
        self._lock_fh = None
        self.sock: socket.socket | None = None

    # ------------------------------------------------------------------ setup

    def acquire_singleton_lock(self) -> None:
        """flock-based singleton. Duplicate launches exit quietly (success —
        exec-once firing twice, or a manual launch alongside it, is normal)."""
        self._lock_fh = open(self.lock_path, "w")
        try:
            fcntl.flock(self._lock_fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            sys.exit(0)
        self._lock_fh.write(str(os.getpid()))
        self._lock_fh.flush()

    def connect_socket2(self) -> bool:
        for attempt in range(SOCKET_RECONNECT_TRIES):
            s = None
            try:
                s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                s.connect(self.socket2_path)
                s.setblocking(False)
                self.sock = s
                if attempt:
                    log("socket2 reconnected")
                return True
            except OSError:
                if s is not None:
                    s.close()
                time.sleep(1.0 + attempt)
        return False

    def _drop_socket(self) -> None:
        """Explicitly close the current socket before replacing it (review
        item #7) — a long-running daemon should not rely on GC for fds."""
        if self.sock is not None:
            try:
                self.sock.close()
            except OSError:
                pass
            self.sock = None

    # -------------------------------------------------------------- hyprctl IO

    def _hyprctl(self, *args: str) -> str | None:
        try:
            out = subprocess.run(
                ["hyprctl", *args],
                capture_output=True, text=True, timeout=HYPRCTL_TIMEOUT,
            )
            return out.stdout if out.returncode == 0 else None
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return None

    def _monitors_json(self, include_all: bool = False) -> list | None:
        args = ("-j", "monitors", "all") if include_all else ("-j", "monitors")
        raw = self._hyprctl(*args)
        if raw is None:
            return None
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            return None
        return data if isinstance(data, list) else None

    def real_output_count(self) -> int | None:
        """Count real, enabled outputs. None = the probe itself failed (treat
        as 'unknown', never as zero — the watchdog must not act on its own
        glitchy hyprctl call)."""
        monitors = self._monitors_json()
        if monitors is None:
            return None
        count = 0
        for m in monitors:
            name = m.get("name", "")
            if name == "FALLBACK":           # Qt's placeholder (shouldn't appear
                continue                      # in hyprctl, but belt-and-braces)
            if name == self.headless_name:    # our own mitigation output
                continue
            if m.get("disabled"):
                continue
            count += 1
        return count

    def headless_state(self) -> str | None:
        """Return the named headless output state.

        Values:
          "absent"  no matching output exists
          "invalid" matching output exists but is disabled or has bad geometry
          "active"  enabled matching output with non-zero geometry
          None      probe failed

        A disabled or zero-geometry output does not give Qt a usable screen,
        but its name can still block creation of a replacement. Keeping that
        state distinct prevents false adoption and duplicate-name failures.
        """
        monitors = self._monitors_json(include_all=True)
        if monitors is None:
            return None
        for m in monitors:
            if m.get("name") != self.headless_name:
                continue
            active = (not m.get("disabled", False)
                      and m.get("width", 0) > 0
                      and m.get("height", 0) > 0)
            return "active" if active else "invalid"
        return "absent"

    # ----------------------------------------------------------- qs lifecycle

    def _pid_is_qs(self, pid: int) -> bool:
        try:
            with open(f"/proc/{pid}/comm") as f:
                return f.read().strip() in QS_PROC_NAMES
        except OSError:
            return False

    def discover_qs_pids(self) -> list[int]:
        """pgrep fallback. NOTE: matches EVERY user process named qs or
        quickshell, not just this project's instance — acceptable on a
        one-shell machine, documented hazard otherwise."""
        pids: list[int] = []
        for name in QS_PROC_NAMES:
            try:
                out = subprocess.run(["pgrep", "-x", name],
                                     capture_output=True, text=True, timeout=5)
                pids += [int(p) for p in out.stdout.split()]
            except (subprocess.TimeoutExpired, ValueError):
                pass
        return sorted(set(p for p in pids if p != os.getpid()))

    def adopt_running_qs(self) -> None:
        """Capture the qs instance we're responsible for at startup."""
        pids = self.discover_qs_pids()
        if len(pids) == 1:
            self.tracked_pid = pids[0]
            log(f"tracking quickshell pid {self.tracked_pid}")
        elif len(pids) > 1:
            self.tracked_pid = pids[0]
            log(f"WARNING: multiple qs-like processes {pids} — tracking "
                f"{pids[0]}; the pgrep fallback would stop ALL of them")
        else:
            log("no quickshell process found at startup — will track one "
                "if/when this watchdog launches it")

    def _target_pids(self) -> list[int]:
        """The PID(s) a stop action applies to: the tracked instance if it's
        alive and still a qs process, else pgrep discovery (logged)."""
        if self.tracked_pid is not None and self._pid_is_qs(self.tracked_pid):
            return [self.tracked_pid]
        pids = self.discover_qs_pids()
        if pids:
            log(f"tracked pid gone — pgrep fallback matches {pids} "
                f"(stopping ALL of them)")
        return pids

    def stop_qs(self) -> None:
        pids = self._target_pids()
        if not pids:
            log("zero-output confirmed but no qs process found — nothing to stop")
            self.we_stopped_qs = False
            return
        log(f"stopping quickshell (pids {pids}) — SIGTERM")
        for pid in pids:
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        deadline = time.monotonic() + TERM_TIMEOUT
        while time.monotonic() < deadline:
            if not any(self._pid_is_qs(p) for p in pids):
                log("quickshell exited cleanly")
                self.we_stopped_qs = True
                self.tracked_pid = None
                return
            time.sleep(0.25)
        # Should only trigger if qs was ALREADY wedged (grace set too high).
        log("quickshell ignored SIGTERM — escalating to SIGKILL")
        for pid in pids:
            if self._pid_is_qs(pid):
                try:
                    os.kill(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
        self.we_stopped_qs = True
        self.tracked_pid = None

    def start_qs(self) -> None:
        if self._target_pids():
            log("quickshell already running — not launching a second instance")
            self.we_stopped_qs = False
            return
        log(f"relaunching quickshell: {' '.join(self.qs_command)}")
        # Detach fully: new session, no inherited stdio. Output goes to a
        # runtime-dir log; qs also keeps its own qslog as usual.
        with open(self.qs_log_path, "ab") as qslog:
            proc = subprocess.Popen(
                self.qs_command, start_new_session=True,
                stdout=qslog, stderr=qslog,
                stdin=subprocess.DEVNULL,
            )
        self.tracked_pid = proc.pid
        log(f"tracking relaunched quickshell pid {self.tracked_pid}")
        self.we_stopped_qs = False

    # ------------------------------------------------------ headless lifecycle

    def _remove_named_headless_verified(self) -> bool:
        """Remove QSWATCHDOG and verify that its name disappears.

        Returns True when absent after the operation. A failed probe or an
        output that remains present returns False and is logged by the caller.
        """
        state = self.headless_state()
        if state == "absent":
            return True
        if state is None:
            return False

        self._hyprctl("output", "remove", self.headless_name)
        deadline = time.monotonic() + HEADLESS_VERIFY_TIMEOUT
        while time.monotonic() < deadline:
            state = self.headless_state()
            if state == "absent":
                return True
            if state is None:
                time.sleep(0.25)
                continue
            time.sleep(0.25)
        return False

    def create_headless(self) -> None:
        """Create or adopt a verified active mitigation output.

        A named but unusable output is removed first because it provides no
        protection while still potentially blocking a replacement with the
        same name. Any failure falls back to restart behavior for the episode.
        """
        state = self.headless_state()
        if state == "active":
            log(f"headless output '{self.headless_name}' already exists — "
                "adopting it as the active mitigation")
            self.headless_created = True
            return
        if state is None:
            log("could not inspect headless state — falling back to "
                "restart-mode behavior for this episode")
            self.stop_qs()
            return
        if state == "invalid":
            log(f"removing unusable stale headless output '{self.headless_name}' "
                "before creating a replacement")
            if not self._remove_named_headless_verified():
                log("FAILED to remove unusable headless output — falling back "
                    "to restart-mode behavior for this episode")
                self.stop_qs()
                return

        if self._hyprctl("output", "create", "headless", self.headless_name) is None:
            log("hyprctl rejected headless creation — cleaning up and falling "
                "back to restart-mode behavior for this episode")
            self._remove_named_headless_verified()
            self.stop_qs()
            return

        deadline = time.monotonic() + HEADLESS_VERIFY_TIMEOUT
        while time.monotonic() < deadline:
            state = self.headless_state()
            if state == "active":
                log(f"created and verified headless output "
                    f"'{self.headless_name}' — ends the zero-output state "
                    f"(Qt's placeholder existed for ~{self.zero_grace:.0f}s)")
                self.headless_created = True
                return
            time.sleep(0.25)

        log("headless output did not become active within "
            f"{HEADLESS_VERIFY_TIMEOUT:.0f}s — cleaning up and falling back "
            "to restart-mode behavior for this episode")
        self._remove_named_headless_verified()
        self.stop_qs()

    def remove_headless(self) -> None:
        if not self.headless_created:
            return
        if self._remove_named_headless_verified():
            log(f"removed and verified headless output '{self.headless_name}'")
        else:
            log(f"WARNING: could not verify removal of headless output "
                f"'{self.headless_name}' — remove manually: "
                f"hyprctl output remove {self.headless_name}")
        self.headless_created = False

    def reconcile_headless_at_startup(self) -> None:
        """Reconcile a predecessor's named output without changing modes.

        Invalid named outputs are always removed: they provide no usable Qt
        screen and can block creation of a replacement. Active outputs remain
        mode-aware: headless mode may adopt one during an outage; restart mode
        never adopts it and reaps it only after a real monitor returns.
        """
        state = self.headless_state()
        if state in (None, "absent"):
            return

        if state == "invalid":
            log(f"found unusable stale '{self.headless_name}' — removing it")
            if not self._remove_named_headless_verified():
                log(f"WARNING: could not remove unusable stale "
                    f"'{self.headless_name}'")
            return

        real = self.real_output_count()
        if real is None:
            return

        if self.mode == "headless":
            if real == 0:
                log(f"found existing '{self.headless_name}' during an ongoing "
                    "outage — adopting it (predecessor's mitigation)")
                self.headless_created = True
                self.set_state(self.MITIGATED)
            else:
                log("removing stale headless output from a previous run")
                self.headless_created = True
                self.remove_headless()
        else:
            if real > 0:
                log(f"restart mode: removing stray '{self.headless_name}' "
                    "left by a previous headless-mode run")
                if not self._remove_named_headless_verified():
                    log(f"WARNING: could not remove stray '{self.headless_name}'")
            else:
                self._foreign_headless = True
                log(f"restart mode: a stray '{self.headless_name}' exists "
                    "during an ongoing outage — will run normal stop-qs and "
                    "reap the stray output once a real monitor returns")

    def _reap_foreign_headless(self) -> None:
        """Restart mode: remove a predecessor output after a real return."""
        if not self._foreign_headless:
            return
        if self._remove_named_headless_verified():
            log(f"reaped stray '{self.headless_name}' from a previous run")
        else:
            log(f"WARNING: could not reap stray '{self.headless_name}'")
        self._foreign_headless = False

    # ------------------------------------------------------------ transitions

    def act(self) -> None:
        """Zero-output debounce expired — mitigate."""
        if self.mode == "headless":
            self.create_headless()
        else:
            self.stop_qs()

    def restore(self) -> None:
        """Return debounce expired — undo mitigation."""
        if self.mode == "headless":
            self.remove_headless()
            # If headless-create failed earlier we fell back to stopping qs;
            # make sure it comes back either way.
            if self.we_stopped_qs:
                self.start_qs()
        else:
            self._reap_foreign_headless()
            if self.we_stopped_qs or self.always_start:
                self.start_qs()
            else:
                log("monitors returned; qs was not stopped by us — leaving it alone")

    def set_state(self, new: int, deadline: float | None = None) -> None:
        if self.verbose or new != self.state:
            log(f"{self.STATE_NAMES[self.state]} -> {self.STATE_NAMES[new]}")
        self.state = new
        self.deadline = deadline

    def evaluate(self) -> None:
        """Re-read output state and advance the state machine."""
        count = self.real_output_count()
        if count is None:
            if self.verbose:
                log("hyprctl unavailable — skipping this evaluation")
            return
        now = time.monotonic()

        if self.state == self.NORMAL:
            if count == 0:
                log(f"zero real outputs — debouncing {self.zero_grace:.0f}s before acting")
                self.set_state(self.ZERO_PENDING, now + self.zero_grace)

        elif self.state == self.ZERO_PENDING:
            if count > 0:
                log("output returned during debounce — false alarm")
                self.set_state(self.NORMAL)
            elif self.deadline is not None and now >= self.deadline:
                self.act()
                self.set_state(self.MITIGATED)

        elif self.state == self.MITIGATED:
            if count > 0:
                log(f"real output returned — debouncing {self.return_grace:.0f}s before restore")
                self.set_state(self.RESTORE_PENDING, now + self.return_grace)
            elif self.mode == "headless" and self.headless_created:
                # A Hyprland reload can wipe runtime-created outputs. If our
                # mitigation output vanished while the outage continues,
                # re-create it (verified) rather than silently regressing to
                # the placeholder-only state.
                state = self.headless_state()
                if state in ("absent", "invalid"):
                    log("mitigation headless output vanished or became unusable "
                        "mid-outage — recreating")
                    self.headless_created = False
                    self.create_headless()

        elif self.state == self.RESTORE_PENDING:
            if count == 0:
                log("output vanished again during return debounce")
                self.set_state(self.MITIGATED)
            elif self.deadline is not None and now >= self.deadline:
                self.restore()
                self.set_state(self.NORMAL)

    # -------------------------------------------------------------- main loop

    def run(self) -> None:
        self.acquire_singleton_lock()
        log(f"started — mode={self.mode} zero_grace={self.zero_grace}s "
            f"return_grace={self.return_grace}s pid={os.getpid()}")
        self.adopt_running_qs()
        self.reconcile_headless_at_startup()

        if not self.connect_socket2():
            sys.exit("could not connect to Hyprland socket2 — is Hyprland running?")

        signal.signal(signal.SIGTERM, self._on_term)
        signal.signal(signal.SIGINT, self._on_term)

        self.evaluate()  # startup could already be mid-outage
        buf = b""
        last_verify = time.monotonic()

        while True:
            # Short ticks while a debounce deadline is live, long otherwise.
            timeout = 1.0 if self.deadline is not None else PERIODIC_VERIFY
            assert self.sock is not None
            ready, _, _ = select.select([self.sock], [], [], timeout)

            saw_monitor_event = False
            if ready:
                try:
                    chunk = self.sock.recv(65536)
                except OSError:
                    chunk = b""
                if not chunk:
                    # Hyprland restarted or died. Close the dead socket
                    # explicitly, reconnect, and re-evaluate IMMEDIATELY —
                    # a compositor restart is exactly when monitor state is
                    # most likely to have changed under us (review item #7).
                    log("socket2 closed — attempting reconnect")
                    self._drop_socket()
                    if not self.connect_socket2():
                        log("Hyprland appears gone — exiting")
                        self._cleanup_and_exit(0)
                    last_verify = time.monotonic()
                    self.evaluate()
                    continue
                buf += chunk
                lines, _, buf = buf.rpartition(b"\n")
                for line in lines.split(b"\n"):
                    # monitoradded / monitoraddedv2 / monitorremoved /
                    # monitorremovedv2 — treat any of them as "go look".
                    if line.startswith(b"monitor"):
                        saw_monitor_event = True
                        if self.verbose:
                            log(f"event: {line.decode(errors='replace')}")

            now = time.monotonic()
            deadline_hit = self.deadline is not None and now >= self.deadline
            periodic_due = (now - last_verify) >= PERIODIC_VERIFY
            if saw_monitor_event or deadline_hit or periodic_due:
                last_verify = now
                self.evaluate()

    # ----------------------------------------------------------------- exit

    def _on_term(self, *_args) -> None:
        log("received termination signal")
        self._cleanup_and_exit(0)

    def _cleanup_and_exit(self, code: int) -> None:
        # Leave the world the way we found it where possible — but do NOT
        # remove the headless output while the outage is ongoing: that would
        # re-enter the placeholder-only state, and a successor watchdog will
        # adopt the output instead (reconcile_headless_at_startup).
        try:
            count = self.real_output_count()
            if self.headless_created:
                if count is not None and count > 0:
                    self.remove_headless()
                else:
                    log(f"exiting mid-outage — leaving '{self.headless_name}' "
                        f"in place for a successor to adopt")
            if self.we_stopped_qs:
                if count is not None and count > 0:
                    self.start_qs()
                else:
                    log("exiting with qs stopped and no real outputs — "
                        "restart qs manually when a monitor is back")
        finally:
            self._drop_socket()
            sys.exit(code)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0],
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--mode", choices=["restart", "headless"], default="restart",
                    help="mitigation strategy. restart = default/production "
                         "workaround. headless = EXPERIMENTAL, requires the "
                         "doc §7 validation before unattended use.")
    ap.add_argument("--zero-grace", type=float, default=None,
                    help="seconds of sustained zero-output before acting. "
                         "Default is per-mode: 3 (restart) / 1 (headless).")
    ap.add_argument("--return-grace", type=float, default=DEFAULT_RETURN_GRACE,
                    help=f"seconds a returned output must persist before "
                         f"restoring (default {DEFAULT_RETURN_GRACE:.0f})")
    ap.add_argument("--headless-name", default=DEFAULT_HEADLESS_NAME,
                    help=f"name for the mitigation headless output (default "
                         f"{DEFAULT_HEADLESS_NAME}). Must match the exclusion "
                         f"in shell.qml/DesktopClock.qml isRealScreen().")
    ap.add_argument("--always-start", action="store_true",
                    help="restart mode: launch qs on monitor-return even if "
                         "the watchdog didn't stop it")
    ap.add_argument("--verbose", action="store_true",
                    help="log every event and state evaluation")
    args = ap.parse_args()

    # Grace validation (review item #8): no negatives, no effectively-zero
    # hair-trigger values, and restart mode must act while qs is still
    # healthy enough to honor SIGTERM (well under the ~120s wedge window).
    if args.zero_grace is None:
        args.zero_grace = MODE_ZERO_GRACE[args.mode]
    if args.zero_grace < MIN_GRACE:
        sys.exit(f"--zero-grace must be >= {MIN_GRACE}s")
    if args.return_grace < MIN_GRACE:
        sys.exit(f"--return-grace must be >= {MIN_GRACE}s")
    if args.mode == "restart" and args.zero_grace >= 100:
        sys.exit("--zero-grace must stay well under the ~120s wedge window "
                 "in restart mode (the point is acting while qs is still "
                 "healthy)")

    Watchdog(args).run()


if __name__ == "__main__":
    main()
