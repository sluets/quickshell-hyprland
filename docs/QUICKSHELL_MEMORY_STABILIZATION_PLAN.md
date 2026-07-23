# Quickshell Memory Investigation — Stabilization Plan

**Project lead:** GPT  
**Canonical parent:** Latest clean project ZIP supplied after Git commit/push  
**Scope:** Fix only issues that interfere with memory testing, corrupt test state, or are directly implicated in resource retention.

**Status:** Complete and technically approved, 2026-07-23.

## Final result

The stabilization work is complete. The notification state is bounded, the
notification surfaces no longer churn window objects, the harness restores and
verifies preferences, and all focused and broad validation runs passed.

Final evidence:

- Notification-only soak: RSS `420.0 -> 405.5 MiB`.
- Thirty-minute no-action baseline: RSS `419.6 -> 401.2 MiB`.
- Twenty full-shell DPMS cycles: RSS `412.1 -> 395.7 MiB`,
  RssAnon `230.6 -> 214.3 MiB`, threads `53 -> 48`, and file descriptors
  `66 -> 58`. Render and Mesa worker families remained bounded.
- Seven-hour broad soak at `--speed 8`: 85,511 actions, zero failures, and the
  original QS PID remained alive. RSS was `444.2 -> 618.4 MiB` after a
  `709.1 MiB` peak; RssAnon was `255.7 -> 415.2 MiB` after a `497.0 MiB`
  peak. Notifications remained capped at eight and returned to zero after
  cleanup. Preferences were restored and verified byte-for-byte.
- The broad soak ended with total threads `55 -> 64` and file descriptors
  `60 -> 67`. `qs:sh*` changed from `3 -> 10`, but total threads stayed
  bounded, render/GL/driver workers decreased, memory fell substantially from
  its peak, and no corresponding resource ratchet or failure occurred. Record
  the shell-worker shift, but do not mislabel it as a demonstrated leak.
- During the separate prolonged physical zero-output failure, memory remained
  stable around `409 MiB`. GDB proved that failure is a Qt Wayland / Qt Quick /
  Mesa rendering-path wedge, not memory exhaustion or notification growth.

Conclusion: there is no evidence of a remaining cumulative Quickshell memory
leak under the tested workloads. No additional soak testing is warranted
without a new symptom or regression.

## Objective

Before running additional memory-leak experiments, correct the known notification-state problem, remove destructive notification-window churn, and make the soak harness safe and diagnostically useful.

No unrelated cleanup, optimization, feature work, UI redesign, or general bug fixing will be included during this phase.

---

## Phase 0 — Establish the canonical checkpoint

Before editing:

1. Confirm the newly uploaded project archive matches the latest Git commit.
2. Confirm the working tree inside the archive is clean.
3. Record:
   - Git commit hash
   - Quickshell version
   - Whether jemalloc is enabled
   - Initial QS RSS and RssAnon
   - Initial total thread count
   - Initial counts of:
     - `QSGRenderThread`
     - `qs:gl*`
     - `qs:gdrv*`
     - `qs:sh*`
     - `WaylandEvent*`
   - Initial file-descriptor count
4. Stop hypridle during controlled tests unless DPMS is the variable being tested.

### Jemalloc verification

Check both methods where practical:

```bash
ldd "$(command -v qs)" | grep -i jemalloc
```

Also inspect a Quickshell crash-report header for:

```text
Use jemalloc:
```

Record the result with the baseline. Do not assume the Arch package setting without confirming it.

---

## Phase 1 — Make the soak harness safe

Fix the testing tools before using them again.

### Required changes

1. Preserve the starting `user-prefs.json`.
2. Restore the original preferences automatically when a soak test ends.
3. Perform restoration from a `finally` path so it also happens after:
   - normal completion;
   - test failure;
   - keyboard interruption;
   - QS becoming unresponsive.
4. Stop all IPC and test activity before restoration.
5. Complete the cleanup wait and collect the final telemetry sample before restoration.
6. Make the preference restore the final test action.
7. Wait approximately two seconds after restoring the file.
8. Re-read the live preferences file and verify byte-for-byte that the restored content survived.
9. Mark the run failed if verification does not match.
10. Preserve the saved starting preferences for manual recovery when verification fails.
11. Add an explicit option to disable restoration only for deliberate debugging.
12. Sample the following throughout every run:
    - RSS
    - RssAnon
    - total thread count
    - `QSGRenderThread` count
    - `qs:gl*` count
    - `qs:gdrv*` count
    - `qs:sh*` count
    - `WaylandEvent*` count
    - file-descriptor count
13. Add test-group exclusions so notification and placement activity can be removed without manually editing the script.
14. Document launching QS with `QSG_INFO=1`.
15. Do not run another broad soak yet.

### Thread-name matching

`/proc/<pid>/task/*/comm` truncates thread names to 15 characters.

Use:

```text
QSGRenderThread
qs:gl
qs:gdrv
qs:sh
WaylandEv
```

Match Mesa and Wayland thread names by prefix rather than requiring complete names.

### Reason

The existing harness can leave the live shell in a randomized configuration, and RSS alone cannot distinguish live state, allocator high-water behavior, and retained render contexts.

The restore verification protects this phase from the known external-file restore race without expanding scope into a full UserPrefs rewrite.

---

## Phase 2 — Fix unbounded notification state

Correct the notification model before using notifications in another soak.

### Required behavior

1. Add a hard cap to the **tracked notification collection**, not merely the visible delegates.
2. Use a small total tracked limit of **8 notifications**.
3. Use a separate sub-cap of **2 critical notifications**.
4. When the total cap is exceeded:
   - dismiss the oldest tracked notification;
   - retain the newest notifications.
5. When the critical sub-cap is exceeded:
   - dismiss the oldest tracked critical notification;
   - retain the newest two critical notifications.
6. Critical notifications remain persistent unless:
   - manually dismissed; or
   - displaced by the critical sub-cap; or
   - displaced as the oldest notification by the total tracked cap.
7. Notifications with `expireTimeout === 0` follow the same bounded policy.
8. Keep the existing visible-count rule as a presentation limit only.
9. Expose the existing `Notifs.dismissAll()` operation through IPC.
10. Add explicit tests for:
   - normal notifications;
   - critical notifications;
   - timeout-zero notifications;
   - more notifications than the tracked cap;
   - `dismissAll()` cleanup.

### IPC implementation

`Notifs.dismissAll()` already exists.

Add an IPC endpoint in `shell.qml` using an `IpcHandler` with target:

```qml
IpcHandler {
    target: "notifs"
}
```

Expose only the required cleanup operation. Do not create a second notification-dismiss implementation.

### Teardown warning watch

When cap displacement dismisses the oldest notification:

1. The server removes it from `trackedNotifications`.
2. The Repeater destroys its delegate.
3. Any pending expiry or removal Timers owned by that delegate are destroyed.

That lifecycle is expected. However, watch for warnings such as stale or null `modelData` access during teardown.

A warning is not automatically harmless. Stop and inspect whether it:

- occurs once during expected destruction;
- repeats continuously;
- leaves a broken delegate;
- prevents later notifications from displaying;
- correlates with retained objects, crashes, or incorrect state.

### Deliberate behavior change

Record this in the revision history:

> The tracked collection is capped at eight total notifications and two critical notifications. A third critical alert displaces the oldest critical alert. The total cap remains oldest-first across all urgency levels, so an old critical notification can also be displaced by total queue pressure.

### Reason

The current Repeater instantiates a complete delegate for every tracked notification even when `visible` is false. Critical and timeout-zero notifications can therefore leave unlimited live QML trees and image resources in memory.

---

## Phase 3 — Remove notification window destruction/recreation

Bring notification surfaces in line with the already-correct launcher and wallpaper-picker lifecycle pattern.

### Required changes

1. Stop using Loader activation to destroy and recreate the bar and detached notification windows.
2. Instantiate both notification presentation surfaces once.
3. Toggle their exposed/open/visible state instead of destroying them.
4. Ensure inactive notification surfaces do not remain visibly exposed.
5. Gate detached visibility by both presentation and notification count:

```qml
visible: presentation === "detached" && Notifs.count > 0
```

6. Gate attached-surface count handling and animation behavior on attached/bar presentation being active.
7. Ensure only the active presentation reacts to notification-count changes.
8. Keep the current reactive focused-bar result only as a **candidate anchor**.
9. Copy the candidate into a latched anchor property when a popup session opens.
10. Keep that anchor unchanged while the popup session remains open.
11. Clear the latched anchor after the popup session fully closes.
12. Do not continuously move an active popup anchor between bars when monitor focus changes.
13. If the anchored bar or screen becomes invalid, perform controlled recovery rather than retaining a dead reference.
14. Verify only one presentation surface is active at a time.
15. Verify repeated bar/detached switching does not produce continuing render-thread or Mesa-worker growth.

### Anchor implementation shape

The current reactive binding in `shell.qml` should become the candidate source:

```text
barForFocused() -> candidate anchor
```

The popup surface should imperatively latch that candidate only when opening.

When the anchored bar is destroyed, the candidate naturally becomes null. Recovery should then follow the invalid-anchor path rather than continuously rebinding the live popup across focus changes.

### Reason

The current notification implementation is the clearest code-level candidate for repeated window, Wayland surface, and GL-context construction. Its focus-following anchor behavior also aligns with the retained render groups observed after output and focus churn.

---

## Phase 4 — Add controlled notification cleanup to tests

Once the notification cap and IPC endpoint exist:

1. At the end of every notification-related test:
   - stop all action generation;
   - call `Notifs.dismissAll()` through IPC;
   - wait approximately 10 seconds;
   - collect the final resource sample.
2. Record resource values:
   - before notifications;
   - at peak notification count;
   - immediately after dismissal;
   - after the cleanup wait.
3. Restore preferences only after the final telemetry sample.
4. Do not judge the result solely by whether RSS returns to its starting value.
5. Compare:
   - live notification count;
   - RssAnon;
   - thread counts;
   - file descriptors;
   - behavior across repeated fresh-process runs.

### Reason

This separates memory held by legitimate live notification objects from resources that remain after those objects have been dismissed.

---

## Phase 5 — Validation before further leak hunting

Run focused regression tests against the fixes.

### Test A — Notification cap

Generate more than the tracked limit using:

- normal urgency;
- critical urgency;
- timeout zero;
- mixed urgency.

Pass conditions:

- tracked notifications never exceed the configured hard cap;
- tracked critical notifications never exceed two;
- oldest notifications are dismissed first;
- a third critical notification displaces the oldest critical notification;
- total-cap overflow remains oldest-first across all urgency levels;
- no unlimited delegate stack forms;
- `dismissAll()` leaves zero tracked notifications;
- no persistent teardown warnings or broken delegate state appears.

### Test B — Notification presentation switching

From a fresh QS process:

- switch bar ↔ detached approximately 200 times;
- do not generate unrelated actions.

Measure throughout the full run and cleanup period.

Pass conditions:

- `QSGRenderThread` count reaches a stable plateau;
- `qs:gl*` and `qs:gdrv*` counts reach a stable plateau;
- FD count remains stable;
- RSS/RssAnon plateaus rather than increasing approximately linearly with switch count;
- only the selected presentation surface reacts.

Do **not** require Mesa workers to return to baseline after every individual switch. Driver workers may remain alive briefly after context destruction.

Fail the test when counts or RssAnon continue ratcheting with switch count and do not stabilize over the completed run.

### Test C — Notification-only soak

Run at a sane speed, initially speed 1 or 2.

Pass conditions:

- tracked count remains bounded;
- memory growth is dramatically lower than the contaminated prior run;
- thread counts stabilize;
- cleanup succeeds at test end;
- preference restoration verifies successfully after telemetry is complete.

### Test D — No-action baseline

Run a fresh QS process for approximately 30 minutes without UI actions.

Purpose:

- establish natural cache/high-water behavior;
- determine whether memory rises and plateaus without interaction.

---

## Phase 6 — Broader isolation results

Phase 6 passed.

1. Twenty DPMS cycles on the full shell produced no memory, thread, worker, or
   file-descriptor ratchet.
2. The conditional minimal-shell DPMS test was unnecessary because the full
   shell passed.
3. The final seven-hour broad soak survived nearly three times the previous
   2.5-hour failure point, completed 85,511 actions with zero failures, and
   ended below its RSS and RssAnon peaks.
4. `QSG_RENDER_LOOP=basic` was unnecessary because the simpler tests did not
   reproduce a leak.

The prolonged physical zero-output wedge was isolated separately and is
documented in `Quickshell-zero-output-failure-report.md` and
`ZERO_OUTPUT_WATCHDOG.md`.

---

## Explicitly deferred work

The following findings remain untouched during stabilization unless one becomes necessary to complete the work above:

- failed Settings Apply discarding staged edits;
- UserPrefs write debouncing;
- UI Profile restore race;
- Bluetooth discovery cleanup;
- Bluetooth agent backoff;
- workspace filtering or click behavior;
- launcher result-model optimization;
- desktop-clock surface sizing;
- wallpaper thumbnail improvements;
- Wi-Fi password argv handling;
- SDDM Test/Apply overlap;
- SDDM helper hardening;
- greeter timeout and clock fallback;
- ConfigManager prune/revert races;
- visual and cosmetic fixes;
- general architecture cleanup;
- new features.

These are valid backlog items, but mixing them into the current patch would enlarge the regression surface and make memory-test results harder to attribute.

---

## Change-control rules

1. One logical fix block at a time.
2. No opportunistic cleanup in neighboring files.
3. Test after each fix block before proceeding.
4. Preserve the current split architecture.
5. Changed files only.
6. Multi-file handoffs packaged in one revisioned ZIP with real destination filenames inside.
7. Build only from the latest approved canonical archive.
8. Record before/after telemetry for each lifecycle-related change.
9. Do not merge memory-investigation findings into the zero-output watchdog issue without direct evidence.
10. Stop and reassess if a fix creates new warnings, crashes, visual regressions, or thread growth.
11. Treat teardown warnings as a benign-versus-real judgment only after checking their frequency, impact, and persistence.
12. Do not broaden this phase into deferred cleanup while touching adjacent code.

---

## Completion criteria

The stabilization phase is complete when:

- the soak harness restores the user’s original preferences;
- restored preferences are verified after a short delay;
- restoration occurs after final telemetry and all IPC activity;
- continuous resource telemetry is available;
- thread-name sampling handles `/proc` truncation correctly;
- tracked notifications are strictly bounded;
- critical notifications are capped at two and timeout-zero notifications cannot grow without limit;
- `dismissAll()` works through IPC;
- cap displacement behavior is documented;
- notification presentation changes no longer destroy/recreate windows;
- inactive notification surfaces do not react;
- popup anchoring does not churn across focus changes;
- notification presentation flipping reaches a stable resource plateau;
- a notification-only soak completes with bounded state;
- a clean no-action baseline has been recorded.

All completion criteria were met. Memory stabilization was closed on
2026-07-23 after the final seven-hour broad soak and watchdog recovery test.

— GPT
