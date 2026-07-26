=================================================================
FILE
=================================================================

docs/MUSIC_PLAYER_PLAN.md   (v3 — approved build specification;
                             supersedes v2 where amended by the
                             reviewed builder packet)

=================================================================
STATUS — STABILIZED CHECKPOINT 2026-07-26
=================================================================

The original v3 builder specification below is retained as design history, but
it is no longer an active phase-by-phase work order. The live implementation
now exceeds the deliberately narrow v3 commitment in several places.

Completed and live-tested:

- MPD installed and running with the user-session Unix socket at
  `$XDG_RUNTIME_DIR/mpd/socket`; no nonexistent fallback socket is rotated in.
- Two hardened MPD command connections: the playback/status service polls
  lightweight status/current-song data, while the library/queue service uses a
  45-second `ping` keepalive so MPD does not close the otherwise idle socket at
  its connection timeout. A dedicated MPD `idle` event socket remains optional
  future work, not a current requirement.
- Direct top-bar controls: left-click play/pause, middle-click previous,
  right-click next. The text is blank when MPD is stopped with no current song.
- The former attached compact popout is preserved in source but disabled.
- A persistent standalone `MusicWindow.qml`, opened from the launcher or IPC,
  with Library, All Songs, and Queue tabs.
- Artist -> folder-derived album -> track browsing, flat searchable library,
  queue refresh/clear/play, album queueing, and filtered-set queue replacement.
- Normal Hyprland tiling behavior. `MusicWindow.qml` deliberately leaves
  `maximumSize` unset because an xdg_toplevel maximum-size hint caused Dwindle
  to float the window whenever the proposed tile exceeded that hint.
- Real album art through MPD itself: `readpicture` first, `albumart` second.
  The helper uses atomic writes and a persistent, oldest-first-pruned cache at
  `~/.cache/quickshell-music-art`, capped at 128 MiB. Rapid skips cancel stale
  fetches without flashing the placeholder or clearing valid previous art.
- Real 32-band PipeWire-output visualization through CAVA raw output. The
  approved baseline is 60 FPS and CAVA's default `noise_reduction = 77`, with
  no extra QML attack/decay smoothing. In MPD-only mode CAVA now exists only
  while MPD is actively playing; pause, stop, or closing the Music window shuts
  it down and clears the bars. System-audio mode remains window-scoped.
- Song-start and song-change notifications through the existing Quickshell
  notification daemon, containing album art, title, and artist. Cold-boot state
  is primed before observation so the first real play still notifies. Startup,
  pause, seek, and ordinary refreshes do not create notifications. Artwork is
  supplied through both the icon argument and freedesktop `image-path` hint.
- Local launcher icon at `assets/icons/music.svg`.
- IPC control surface for status, refresh, playback, track navigation, seek,
  and volume, plus `musicwindow toggle`.
- Smooth locally interpolated progress between MPD polls. Dragging the seek bar
  previews locally and emits exactly one seek command on release.
- Window-scoped keyboard controls: Space toggles play/pause and Escape closes
  the Music window.
- Search/filter cleanup resets stale artist selection when the selected artist
  is no longer visible, and shared panel sizing now has one source of truth.
- A dedicated Music Settings page is implemented through the split transaction,
  context, and page architecture, including visualizer source/style controls.

Current component map:

```text
services/MpdConnection.qml       MPD protocol transport and request queue
services/MusicService.qml        current-song/status state and playback commands
services/MusicLibrary.qml        library/queue models and queue-building actions
services/AlbumArtService.qml     current-track art state and helper lifecycle
services/AudioVisualizer.qml     CAVA process and normalized spectrum bands
services/MusicNotifications.qml  song-start/song-change notifications
scripts/mpd-fetch-art.py         MPD binary-art retrieval and runtime cache
widgets/Music/MusicWindow.qml    standalone Library / All Songs / Queue window
widgets/Music/MusicPanel.qml     now-playing metadata, art, seek, and controls
widgets/Music/AudioSpectrum.qml  single left-to-right spectrum
widgets/TopBar/MusicIndicator.qml direct top-bar controls
assets/cava-music.conf           explicit settings-ready CAVA profile
assets/icons/music.svg           launcher icon
```

Current checkpoint:

1. Commit and push this stabilized player state as the new canonical baseline.
2. Use EasyEffects as the proven PipeWire DSP/equalizer backend rather than
   implementing audio processing in QML. Verify the dependency and preset/control
   surface live before adding equalizer controls.
3. Player-specific font selection remains optional and deferred. The player
   currently follows `Theme.fontFamily`, matching the rest of the UI.

=================================================================
SHELVED REVIEW ITEMS — REVISIT ONLY WITH A REAL NEED
=================================================================

- **Large queue operations:** consider a confirmation/cap for replacing the
  queue with a very large filtered library, plus an explicit append gesture or
  action. Current replacement behavior is accepted and working.
- **Queue editing:** remove/reorder controls are deferred. MPD remains the queue
  owner; any future UI must preserve queue IDs and refresh from MPD afterward.
- **MPRIS duplication guard:** unnecessary while no MPD-MPRIS bridge is
  installed. Revisit only if MPD is later exposed through MPRIS and the existing
  Now Playing surface can display the same source twice.
- **Visualizer renderer rewrite:** do not replace the current delegate-based
  spectrum with a Canvas merely on theoretical performance grounds. Profile a
  demonstrated frame-time or allocation problem first.
- **Visualizer capture transport:** keep the verified `mpd.PipeWire` CAVA source.
  The proposed FIFO migration is rejected for the current system because live
  testing proved the MPD monitor carries MPD audio and excludes Firefox audio.
- **Dedicated MPD `idle` socket:** optional future efficiency improvement. The
  current polling plus library keepalive is stable and low-cost.
- **Request-timeout refinement:** revisit only if real MPD requests time out or
  reconnect churn returns.
- **Resizable library columns / SplitView:** deferred UI enhancement, not needed
  for current use.
- **QML-native CAVA configuration writer:** deferred while the current generated
  config path is stable.
- **Search binding cleanup:** deferred unless the current filter model develops a
  concrete correctness or performance issue.
- **Player volume UI:** service support exists; a visible control is optional and
  not part of the stabilized baseline.

These items are intentionally parked. Do not reopen them as generic cleanup;
require a user-visible limitation, profiling result, or new integration need.

=================================================================
OWNERSHIP — carried from v1, unchanged
=================================================================

MPD owns: playback, decoding, the music database, queue state, seek,
shuffle/repeat, library scanning, audio output.

Quickshell owns: presentation and interaction only. This is a custom
MPD client, never an audio engine.

=================================================================
ARCHITECTURE DECISIONS (decide/confirm in Phase 0, build after)
=================================================================

---- D1. Transport: Quickshell.Io Socket speaking raw MPD protocol ----

v1 listed three options; v2 picks #2 (direct protocol) as the build
target and drops mpc/MPRIS as primary paths:

- MPD's protocol is line-based text over TCP or a Unix socket —
  exactly what Quickshell's Socket + SplitParser handle natively.
- TWO persistent connections, both in MpdConnection.qml:
  - IDLE connection: sits in `idle player mixer playlist options
    database`; MPD answers `changed: <subsystem>` when anything
    happens; re-arm after each wakeup. Zero polling, event-driven —
    the same discipline as the watchdog's socket2 handling: events
    mean "go look", so each wakeup triggers a fresh `status` /
    `currentsong` / queue fetch on the command connection. Never
    trust the event alone.
  - COMMAND connection: FIFO of pending requests; MPD answers
    strictly in order, each response terminated by `OK` or `ACK …`.
    A simple pending-callback queue is sufficient — no correlation
    IDs needed.
- Unix socket preferred (no auth, no TCP): probe
  `$XDG_RUNTIME_DIR/mpd/socket` then `~/.config/mpd/socket`, fall
  back to `127.0.0.1:6600`. One settings key overrides.
- Reconnect with EXPONENTIAL BACKOFF (1s → 2s → 4s → max 30s), reset
  on success. This is finding W-2 (BluetoothAgent's 2s-forever
  respawn) applied preemptively: MPD not installed/running must cost
  ~nothing and log once, not fork-or-connect-spam forever.
- mpc remains a Phase-0 hand-testing tool and ONE production duty
  (album art extraction, D2). MPRIS is untouched: today's
  NowPlaying.qml keeps serving browser/other media. Without an
  mpd-mpris bridge MPD is invisible to MPRIS, so the two widgets
  can never double-report the same source.

---- D2. Album art: sidecar files first, embedded second ----

1. Sidecar: currentsong's `file:` tag → dirname under the music
   root → first match of cover/folder/front/albumart .jpg/.png.
   Pure path math + Image element. Needs one settings key for the
   music root (readable path to the same tree MPD indexes).
2. Embedded fallback: one STATIC reused Process running
   `mpc readpicture <uri>` into
   `$XDG_RUNTIME_DIR/qs-music-art/<md5 of uri>.img`.
   - STABLE per-song filenames — never timestamp cache-busting
     (unique URLs would grow Qt's pixmap cache without bound; the
     notification-image lesson).
   - Cache dir capped by the same helper: keep newest ~40 files
     (`ls -t | tail -n +41 | xargs -r rm --`).
3. `sourceSize` capped on every Image (wallpaper-thumb lesson).
4. Placeholder glyph when neither source produces art.

---- D3. "Band" = albumartist, probably ----

Filtering on the `artist` tag fragments collections ("X feat. Y" is
a different artist). MPD tracks `albumartist` separately and most
tagged libraries fill it. Phase 0 inspects real tags from the
library (`mpc list albumartist | wc -l` vs `mpc list artist | wc -l`
plus spot checks); default to albumartist with artist fallback per
track, and keep the chosen tag in ONE place in MpdLibraryModel.

---- D4. Settings: minimal keys, full ST-1 discipline ----

Every key costs six touchpoints (UserPrefs adapter+setter,
Transaction staged*, shown*, changes diff, ConfigManager apply
switch, soak IPC switch). v1 keys, deliberately few:

- musicEnabled        (bool, true)  — bar widget visibility
- musicMpdAddress     (string, "")  — "" = auto-probe per D1
- musicRootPath       (string, "")  — for sidecar art; "" disables D2.1
- musicBarMaxLength   (int, 40)     — reuse nowPlayingMaxLength? NO —
                                      independent widget, own key

Settings UI: one small "Music" section appended to an existing page
(DesktopPage) rather than a new page file — four keys don't justify
page #9. All mutations flow through staged; the page never touches
UserPrefs directly.

---- D5. Lifecycle rules (CODE_REVIEW §10, non-negotiable) ----

- The panel is a persistent BarPopout per bar, toggled via open —
  the launcher pattern. NOTHING destroys/recreates windows at
  runtime.
- Queue and artist lists are ListView + reuseItems + clip, never
  Repeater (the launcher-results churn lesson, at 10–20k-track
  scale).
- All Processes static and reused (Network.qml pattern).
- Service state lives in singletons; per-bar widgets hold no service
  state, so multi-monitor mirrors the launcher: one service, one
  panel per bar, whichever is open binds the same models.
- Elapsed-time ticker Timer runs ONLY while (panel open && state ==
  play). The bar widget shows no progress → no always-on timer.

=================================================================
COMPONENT MAP (v1 structure, trimmed to v2 scope)
=================================================================

services/music/
  MusicService.qml     public facade: state, currentsong, queue model,
                       artist model, artist-mode state machine, all
                       commands the UI may call
  MpdConnection.qml    sockets, protocol framing, request FIFO,
                       reconnect/backoff              (internal only)
  AlbumArt.qml         D2 resolution + bounded cache  (internal only)

widgets/TopBar/
  MusicIndicator.qml   bar item + its attached MusicPanel popout

widgets/Music/
  MusicPanel.qml       the screenshot panel (BarPopout content)
  QueueView.qml        collapsible queue ListView
  ArtistSearchView.qml collapsible artist search + results

Widgets never speak protocol; only MusicService's API.

=================================================================
FEATURE SPEC
=================================================================

---- Bar item (MusicIndicator) ----

- "Title — Artist", truncated at musicBarMaxLength; hidden entirely
  when disconnected or musicEnabled is false; optional small state
  glyph when paused.
- Coexists with NowPlaying.qml (MPRIS); both visible only when both
  have active sources. W-7 (dangling separator) must not be
  reintroduced: the neighboring Separator's visible binds to the
  widget's.
- Click bindings — Phase 0 DECISION, recommended default:
    left    = open/close panel   (the screenshot workflow)
    middle  = play/pause
    right   = next track
    scroll  = MPD volume ±5      (setvol; OSD-free, panel shows it)
  Alternative preserving today's NowPlaying muscle memory exactly
  (left=play/pause, middle=prev, right=next) pushes panel-open onto
  the art/icon area only. Owner picks one; both are one MouseArea.

---- Panel (MusicPanel), mapped to the reference screenshot ----

Row 1: album art (left) · title + artist/album (center) ·
       shuffle toggle + repeat toggle (right, lit when active —
       MPD `random` and `repeat`; long-press or right-click repeat
       cycles `single` for track-repeat)
Row 2: seekable progress bar + elapsed/total (from status `elapsed`
       and `duration`, interpolated by the D5 ticker; seek via
       `seekcur <seconds>` on release, not per-pixel drag)
Row 3: prev · play/pause · next · queue toggle · artist-search
       toggle · volume slider (inline, `setvol`)

The screenshot's "+" has no MPD meaning in this scope — omitted.
Rows 4/5 are the two collapsible sections below; opening one closes
the other (single expanded section keeps popout height sane).

---- Queue dropdown (QueueView) ----

- Data: `playlistinfo` parsed into a ListModel (pos, id, title,
  artist, duration). Refetched on idle `playlist` events.
- ListView, height capped (~420px), scrollbar, reuseItems.
- Current track highlighted (status `songid` vs row id — ids are
  stable across reorders, positions are not); auto
  positionViewAtIndex(current, Center) on expand.
- Click row → `play <pos>`. v1 has NO remove/reorder — display and
  jump only, exactly as requested.
- Scale plan: full refetch is fine to ~5k tracks. Above that, MPD's
  `plchanges <version>` gives incremental diffs (status carries the
  queue version) — wired in Phase 4 only if the owner's real queue
  size demands it. Measure first.

---- ARTIST MODE (the headline feature) ----

Search: `list albumartist` (D3) fetched once per idle `database`
event into a cached string list; TextInput filters it client-side,
case-insensitive substring (launcher-style, no scoring needed);
results ListView shows name + track count (`count albumartist "X"`,
fetched lazily per visible row — or skipped in v1).

Enter (click an artist, or Enter on unique match):
  1. Snapshot return state: current queue saved as stored playlist
     `qs-return-queue` (`rm` stale copy first, then `save`), plus
     the current song uri + elapsed + random flag held in service
     state.
  2. `clear` → `findadd albumartist "X"` (exact match — the list
     came from MPD, so exactness is safe; searchadd only as a
     fuzzy fallback path)
  3. `random 1` → `play`. Panel shows a breadcrumb chip:
     「Artist: X  ✕」.
Exit (chip's ✕, or entering a different artist re-runs Enter
against the ORIGINAL snapshot — never snapshot artist-over-artist):
  1. `clear` → `load qs-return-queue` → restore saved random flag.
  2. Find the saved song uri in the reloaded queue; if found,
     `play <pos>` + `seekcur <saved elapsed>`; else `play`.
State machine in MusicService: OFF → ENTERING → ON → EXITING → OFF,
with explicit failure edges (save/load ACK → surface error, stay in
prior state, never half-clear). Loose booleans forbidden (v1 rule).

Documented edge cases:
- Queue edits made DURING artist mode are discarded on exit (the
  snapshot wins). Stated in the panel via the chip's tooltip.
- Requires mpd playlist_directory (default present); ACK from `save`
  → artist mode refuses to enter, with a visible reason.
- `consume` must be off for restore fidelity; service reads it and
  warns rather than silently toggling the user's setting.
- Shell/MPD restart mid-mode: `qs-return-queue` persists on disk;
  service startup detects the leftover + offers restore via the
  chip (state recorded in service, not prefs — acceptable v1 loss:
  after a crash the chip is gone but the playlist file remains for
  manual `mpc load`).

=================================================================
MPD PROTOCOL CRIB (everything v2 uses)
=================================================================

status, currentsong, idle/noidle,
play [POS], pause 1/0, next, previous, seekcur SEC, setvol 0-100,
random 0/1, repeat 0/1, single 0/1,
playlistinfo, plchanges VERSION,
list albumartist, count albumartist "X", findadd albumartist "X",
searchadd albumartist "X",
clear, save NAME, rm NAME, load NAME,
readpicture URI (via mpc only, D2)

Responses: `key: value` lines, terminated by `OK` or
`ACK [err@cmd] {cmd} message`. UTF-8 throughout. Quote values with
embedded quotes escaped (\") — one escaping helper in
MpdConnection, used everywhere, tested against artist names
containing quotes/backslashes in Phase 0.

=================================================================
PHASES — one at a time, live-tested, per change-control culture
=================================================================

Phase 0 — Environment + decisions (no code in the shell)
- mpd running; socket path confirmed; version noted (needs ≥0.21
  for readpicture; findadd/albumartist are ancient, fine)
- D3 tag audit; D1 address probe order confirmed against the real
  machine; art naming survey for D2.1; bar click-binding decision
- hand-test every crib command via `mpc`/netcat, including quoted
  artist names and the save/load round-trip
- record queue size + library size (drives the Phase 4 plchanges
  decision)

Phase 1 — MpdConnection + MusicService core
- sockets, idle loop, FIFO, backoff, parse status/currentsong
- commands: play/pause/next/previous/seek/setvol/random/repeat
- kill/restart MPD mid-session: clean disconnect state, capped
  backoff, silent recovery
- Gate: service state matches `mpc status` under all transitions
  with zero polling traffic when idle

Phase 2 — MusicIndicator bar item
- text, truncation, hide-when-dead, click bindings, W-7 guard
- Gate: a full day of daily driving without bar layout glitches

Phase 3 — MusicPanel popout
- persistent BarPopout, rows 1–3, art via D2, seek, volume, ticker
  gating per D5
- Gate: panel open/close soak (harness action) — thread/context
  counts flat, per the stabilization telemetry

Phase 4 — QueueView
- fetch/parse/display, highlight-by-id, jump-to-current, click-to-
  play, idle-driven refresh; plchanges only if Phase 0 numbers
  demand it
- Gate: queue of real size scrolls at 60fps; refetch on external
  `mpc add` appears without interaction

Phase 5 — Artist mode
- artist list + search view, state machine, enter/exit, breadcrumb,
  all documented edge cases exercised deliberately (kill mpd
  mid-ENTERING, save-ACK path, quoted names)
- Gate: 20 consecutive enter/exit cycles return the exact original
  queue (diff `playlistinfo` before/after), position restored

Phase 6 — Integration hardening
- settings keys wired through all six ST-1 touchpoints + soak IPC
- soak harness: add music action family (panel toggle, queue
  toggle, artist enter/exit, transport) behind the Phase-1-style
  exclusion flag; run a music-only soak; art-cache dir stays ≤ cap
- CODE_REVIEW addendum entry + REVISION_HISTORY entry

=================================================================
DEFERRED (unchanged intent from v1, plus v2 additions)
=================================================================

Full Tauon-style library window (v1 Ph. 5–6) · album/folder views ·
queue editing (remove/reorder) · saved-playlist management ·
lyrics/spectrum/ReplayGain/output selection · mpd-mpris bridge
evaluation · bar album-art thumbnail · plchanges optimization unless
Phase 0 numbers force it.

=================================================================
REVISION HISTORY
=================================================================

2026-07-23  Claude/GPT: v3 approved after builder-packet revisions.
            Shared restoration/cleanup pipeline, abort cleanup,
            callback-confirmed restore, temp-playlist cleanup,
            random/play-state restoration, and recovery tests added.
2026-07-23  Claude: v2. Scope narrowed to bar item + panel + queue
            view + artist mode per owner request (reference
            screenshot). Transport decided: Quickshell Socket, raw
            MPD protocol, dual connection, idle-driven, backoff per
            finding W-2. Artist mode designed as explicit state
            machine over MPD save/clear/findadd/load with snapshot
            restore. Lifecycle rules bound to CODE_REVIEW §10;
            settings bound to ST-1 six-touchpoint checklist; soak
            integration made a phase gate. v1 (2026-07-15, GPT)
            remains the reference for the deferred library window.
2026-07-15  GPT: Initial plan (MUSIC_LIBRARY_PLAN.md).
