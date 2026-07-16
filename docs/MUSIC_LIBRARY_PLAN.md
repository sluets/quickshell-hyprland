=================================================================
FILE
=================================================================

docs/MUSIC_LIBRARY_PLAN.md

=================================================================
PURPOSE
=================================================================

GPT: Planning document for a future local-music player interface built
into Quickshell with MPD as the backend.

This is intentionally NOT part of the current Settings-window work.
Build it only after the Settings split, known bug fixes, and structural
cleanup are complete. Each phase must be built and live-tested before
moving to the next.

The user does not stream music and does not maintain playlists. The
normal workflow is to load the entire local MP3 library and jump freely
between artists, albums, folders, and tracks. Fast library navigation is
therefore more important than playlist creation or management.

=================================================================
CORE OWNERSHIP — DO NOT BLUR THIS
=================================================================

MPD owns:

- audio playback and decoding
- the music database
- queue state
- seek position
- shuffle / repeat state
- library scanning
- audio output

Quickshell owns:

- compact bar controls
- now-playing popout
- library browser window
- artist / album / folder / track navigation
- search
- album-art display and caching
- queue display and click-to-play behavior
- presentation and interaction only

GPT: This keeps the project from accidentally becoming its own audio
engine. It will be a custom MPD client, not a replacement for MPD.

=================================================================
TARGET USER EXPERIENCE
=================================================================

---- Compact bar item ----

- music icon or small album art
- current song title, optionally artist
- play / pause
- click opens the music popout
- setting to hide/show later if wanted

---- Now-playing popout ----

- album art
- song title
- artist and album
- previous / play-pause / next
- seekable progress bar
- elapsed and total time
- shuffle and repeat
- current queue
- click any queued track to jump directly to it
- quick search or button to open the full library window
- optional decorative equalizer animation

---- Full library window ----

Tauon-inspired layout, adapted to this project's theme and smaller-file
architecture:

- searchable local library
- fast jump between artists
- artist, album, folder, and track views
- grouped album track lists
- duration display
- album art / track-information side panel
- click a track to play immediately
- play an album or artist from the selected track onward
- append or replace the current queue
- folder browsing for collections organized as Artist/Album/Track

Playlist editing is not a priority. Saved-playlist support should remain
out of scope unless the user's workflow changes.

=================================================================
RECOMMENDED FILE STRUCTURE
=================================================================

GPT: Names may change during the future naming/architecture cleanup.
Keep responsibilities separated even if the final filenames differ.

services/music/
  MusicService.qml          public facade and UI-facing state
  MpdConnection.qml         MPD connection and command transport
  MpdPlaybackModel.qml      current song, state, time, volume
  MpdQueueModel.qml         current queue and queue operations
  MpdLibraryModel.qml       artists, albums, folders, tracks, search
  AlbumArtCache.qml         artwork discovery and caching

widgets/TopBar/
  MusicIndicator.qml        compact bar item only

widgets/Music/
  MusicPopup.qml
  MusicLibraryWindow.qml
  NowPlayingView.qml
  QueueView.qml
  ArtistView.qml
  AlbumView.qml
  FolderView.qml
  TrackListView.qml

widgets/Music/components/
  PlaybackControls.qml
  TrackRow.qml
  AlbumRow.qml
  ArtistRow.qml
  ProgressSlider.qml
  SearchField.qml
  AlbumArt.qml
  DecorativeEq.qml

GPT: Do not create microscopic files merely to hit a line-count target.
Each file should have one obvious responsibility and generally remain
small enough to troubleshoot without understanding the entire feature.

=================================================================
TECHNICAL APPROACH — DECIDE BEFORE PHASE 1
=================================================================

Possible MPD transports:

1. mpc command-line calls
   - simplest prototype
   - easy to test manually
   - poor fit for frequent position updates, queue models, and a large
     live library because it requires repeated processes and parsing

2. direct MPD TCP protocol from a small helper/service
   - better long-term fit
   - persistent connection and event-driven updates
   - more initial engineering

3. MPRIS bridge for basic playback plus direct MPD access for library
   and queue
   - Quickshell has native MPRIS support for basic metadata/control
   - MPRIS alone is insufficient for the complete MPD library and queue

Recommended direction:

- prototype connection/control in the least risky way
- use a persistent MPD-capable service for the final library feature
- keep transport hidden behind MusicService so widgets never run raw
  commands or parse MPD output themselves

=================================================================
PHASES
=================================================================

---- Phase 0 — Environment and scope confirmation ----

Goal: confirm the real MPD setup before building UI.

- confirm MPD package and service are installed/running
- confirm music directory and existing MPD database behavior
- confirm whether MPD listens only on localhost or uses a Unix socket
- confirm album-art naming patterns in the library
- inspect actual Artist / Album / AlbumArtist tags from sample files
- decide the connection transport
- decide whether full-folder loading means one permanent queue or a
  queue rebuilt from library selection

No production UI in this phase.

---- Phase 1 — Playback service ----

Goal: reliable MPD state and basic controls without library browsing.

- connect/disconnect state
- current song metadata
- playback state
- previous / play-pause / next
- elapsed and total time
- seeking
- shuffle and repeat
- clear user-facing error when MPD is unavailable
- explicit connection/playback state machine, not loose booleans

Live-test all commands before moving on.

---- Phase 2 — Compact bar item ----

Goal: useful daily controls with minimal visual footprint.

- add MusicIndicator to the bar
- show title or icon without breaking bar sizing
- play/pause control
- click opens popout
- inactive/MPD-off state
- multi-monitor popout ownership follows existing focused-monitor rules

---- Phase 3 — Now-playing popout ----

Goal: polished current-track control.

- album art
- metadata
- transport controls
- progress slider
- elapsed / duration labels
- shuffle / repeat
- decorative EQ only if it does not delay functional work

A decorative EQ must be clearly presentation-only unless real audio
spectrum data is deliberately added later.

---- Phase 4 — Current queue ----

Goal: support the user's frequent track jumping.

- load and display the entire current MPD queue
- identify the current track
- click any track to play it immediately
- efficient updates when the queue changes
- optional remove / clear / replace / append actions

No saved-playlist editor is required.

---- Phase 5 — Library indexing and search ----

Goal: expose the whole local collection without loading everything into
one giant visual model at once.

- artists
- albums
- tracks
- folders
- search across artist, album, and title
- stable sorting and handling of missing/inconsistent tags
- lazy loading or chunked models if the library is large

This phase should establish the data model before visual polish.

---- Phase 6 — Full library window ----

Goal: Tauon-inspired browsing optimized for quick jumping.

- artist navigation
- grouped albums and tracks
- folder view
- duration column
- album-art/details panel
- click-to-play
- play selected album/artist from a chosen track
- replace or append queue behavior
- keyboard navigation where practical

The interface should remain readable and match the active Quickshell
theme rather than cloning Tauon literally.

---- Phase 7 — Album-art cache and polish ----

Goal: fast, reliable artwork without rescanning disks unnecessarily.

- common cover filenames (cover.*, folder.*, front.*)
- embedded-art fallback only if practical
- cache invalidation
- placeholder art
- no blocking filesystem scans on the UI thread
- responsive resizing and large-library performance pass

---- Phase 8 — Optional later features ----

Only after the core player is stable:

- real audio spectrum visualizer
- lyrics
- ReplayGain controls
- MPD output selection
- saved playlists
- tag editing

These are not part of the initial commitment.

=================================================================
SAFETY / MAINTENANCE RULES
=================================================================

- GPT: Build and test one phase at a time.
- Keep MPD transport and parsing out of visual files.
- Do not pass secrets through command-line arguments if MPD auth is
  ever enabled.
- Use explicit state machines for connection and long operations.
- Detect missing MPD/mpc dependencies and display a useful message.
- Avoid polling faster than necessary; prefer idle/event notifications.
- Keep library models incremental so large collections do not freeze UI.
- Sign new documentation and important in-file comments with GPT.
- Add smoke checks for missing imports/files as the feature grows.

=================================================================
NOT PART OF THE CURRENT WORK ORDER
=================================================================

Before beginning this plan, finish:

1. Settings-menu split
2. requested Settings adjustments
3. known bugs, especially border-color linkage
4. structural cleanup, naming, and smaller-file organization
5. automated smoke-check foundation

=================================================================
REVISION HISTORY
=================================================================

2026-07-15  GPT: Initial plan based on the requested MPD-backed,
            Tauon-inspired local-library player. Playlists intentionally
            deprioritized; fast artist/album/folder/track navigation is
            the primary workflow.
