# Feature Backlog

Updated: 2026-07-26
Owner: GPT

This is the canonical prioritized project backlog. Detailed implementation plans may live in separate documents, but every active project should appear here.

## Current checkpoint

1. Commit and push the stabilized MPD music-player baseline.
2. Provide the resulting clean canonical ZIP before further player work.
3. Install and live-verify EasyEffects before writing equalizer integration.

## Next small features

1. **Calculator unit converter** — mil/thou, inch, millimeter, and micrometer/micron, with all results visible and clickable to copy. See `SMALL_ADDITIONS_BACKLOG.md`.
2. **Screenshot and `wf-recorder` bar controls** — wrap the exact already-tested keybind commands; keep the keybinds.
3. **Quick notes scratchpad**.
4. **Color picker and bounded color history**.
5. **Do Not Disturb toggle** using the existing notification service.
6. **Audio-device quick picker**.
7. **Launcher calculator/converter expressions**.

## Active larger feature

### Music settings and EasyEffects integration

The MPD music player itself is implemented and live-tested. See
`MUSIC_PLAYER_PLAN.md` for the exact current component map and completed scope.

Next work:

- EasyEffects-backed equalizer enable/preset controls after dependency health and
  command/preset behavior are verified on the live system;
- optional player-only font selection later.

The dedicated Music Settings page, visualizer controls, MPD/system-audio source
selection, album-art behavior, and song notifications are implemented and
live-tested.

Do not implement DSP in QML or create a custom PipeWire filter chain while a
proven EasyEffects backend satisfies the requirement.

## Structural and maintenance work

- Add automated QML/parser smoke checks for changed files.
- Continue ConfigManager splitting only when a concrete change benefits from it.
- Add calculator, clock-tools, and clipboard action families to the soak harness if they become meaningful stress surfaces.
- Review stale comments that reference completed history documents.
- Keep completed plans and incident reports under `docs/history/`.

## Deferred / parked

Music-player review items are detailed in `MUSIC_PLAYER_PLAN.md`. In summary:
large-queue confirmation/append behavior, queue remove/reorder, MPRIS duplicate
protection, a Canvas visualizer rewrite, a dedicated MPD `idle` socket,
resizable library columns, a QML-native CAVA config writer, search-binding
cleanup, and visible volume controls are shelved until a concrete need appears.
The FIFO visualizer-source proposal is rejected for the current verified setup.

- Displays/monitor configuration UI until a safe apply/revert design is proven.
- Wallpaper-derived dynamic color theme.
- Notification history UI.
- Workspace click-to-switch.
- System statistics widget.
- Idle inhibitor toggle.
- Per-monitor refresh-rate quick switching.
- Optional SDDM deactivate/rollback UI and machine-specific monitor-layout management.

## Completed recent block

- MPD local-library player with direct bar controls and standalone tiled window.
- Artist/folder-album/track browsing, searchable All Songs view, and Queue view.
- MPD album art with persistent bounded cache, CAVA/PipeWire spectrum with
  playback-aware lifecycle, smooth seek/progress behavior, keyboard controls,
  song-change notifications, and dedicated transactional Music Settings.

- Calculator as a launcher-integrated internal application.
- Launcher favorites, usage ranking, hide behavior, and calculator aliases.
- Split date and time click targets.
- Timer, stopwatch, laps, interval notifications, alarm, sound preview, and sound-disable control.
- Clipboard persistence/history UI with capped entries and image thumbnails.
- Notification hard caps and memory-stabilization work.
- Hyprland animation presets and current Settings split.
