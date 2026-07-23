# Feature Backlog

Updated: 2026-07-23
Owner: GPT

This is the canonical prioritized project backlog. Detailed implementation plans may live in separate documents, but every active project should appear here.

## Current checkpoint

1. Finish documentation cleanup for the calculator, clock tools, clipboard history, and approved MPD plan.
2. Commit and push a clean canonical tree.
3. Restore/pull that tree on the work laptop.
4. Do not start another large feature before the checkpoint is clean.

## Next small features

1. **Calculator unit converter** — mil/thou, inch, millimeter, and micrometer/micron, with all results visible and clickable to copy. See `SMALL_ADDITIONS_BACKLOG.md`.
2. **Screenshot and `wf-recorder` bar controls** — wrap the exact already-tested keybind commands; keep the keybinds.
3. **Quick notes scratchpad**.
4. **Color picker and bounded color history**.
5. **Do Not Disturb toggle** using the existing notification service.
6. **Audio-device quick picker**.
7. **Launcher calculator/converter expressions**.

## Approved larger feature

### MPD music player

The agreed specification is `MUSIC_PLAYER_PLAN.md` v3. The immediate next step is Phase 0 after MPD is installed and configured.

Before changing code, verify:

- MPD is installed and running;
- its Unix socket is reachable;
- the library and queue contain expected data;
- the exact Phase-0 `mpc`/socket commands work.

Do not build against an assumed backend.

## Structural and maintenance work

- Add automated QML/parser smoke checks for changed files.
- Continue ConfigManager splitting only when a concrete change benefits from it.
- Add calculator, clock-tools, and clipboard action families to the soak harness if they become meaningful stress surfaces.
- Review stale comments that reference completed history documents.
- Keep completed plans and incident reports under `docs/history/`.

## Deferred / parked

- Full Tauon-style music library window.
- Displays/monitor configuration UI until a safe apply/revert design is proven.
- Wallpaper-derived dynamic color theme.
- Notification history UI.
- Workspace click-to-switch.
- System statistics widget.
- Idle inhibitor toggle.
- Per-monitor refresh-rate quick switching.
- Optional SDDM deactivate/rollback UI and machine-specific monitor-layout management.

## Completed recent block

- Calculator as a launcher-integrated internal application.
- Launcher favorites, usage ranking, hide behavior, and calculator aliases.
- Split date and time click targets.
- Timer, stopwatch, laps, interval notifications, alarm, sound preview, and sound-disable control.
- Clipboard persistence/history UI with capped entries and image thumbnails.
- Notification hard caps and memory-stabilization work.
- Hyprland animation presets and current Settings split.
