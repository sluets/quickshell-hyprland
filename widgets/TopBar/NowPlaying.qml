//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/NowPlaying.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Shows the currently playing track ("Title — Artist") from whichever
// MPRIS media player is active, ignoring players listed in
// Settings.nowPlayingIgnoredPlayers (Firefox by default — browser tabs
// register as MPRIS players same as real media apps). Left-click
// play/pause, middle-click previous track, right-click next track.
// Collapses to
// nothing (no reserved space) when no qualifying player is active.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// Quickshell.Services.Mpris (Quickshell's built-in MPRIS integration —
//                             no custom service needed, same reasoning
//                             as Workspaces.qml using Quickshell.Hyprland
//                             directly)
// core/Theme.qml    (singleton, via `import qs.core`)
// core/Settings.qml (singleton, via `import qs.core` — reads
//                    nowPlayingIgnoredPlayers and nowPlayingMaxLength)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/TopBar.qml (instantiated directly — no import needed,
// since Quickshell auto-imports uppercase-named neighboring files in the
// same folder)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// TopBar loses the now-playing display entirely. Nothing else depends on
// this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// TRACK METADATA COMES FROM MPRIS (D-BUS), NOT PIPEWIRE:
// PipeWire handles audio routing/mixing; it doesn't carry track titles
// or artists. That metadata comes from MPRIS, a separate D-Bus interface
// most media players (including browsers, for any tab playing audio or
// video) implement independently of PipeWire. Quickshell's built-in
// `Mpris` singleton (`import Quickshell.Services.Mpris`) talks to that
// directly — same "check for a built-in before writing a custom
// service" pattern as Workspaces.qml and Clock.qml. See
// docs/PROBLEMS_AND_FIXES.md.
//
// WHY "IGNORED PLAYERS" INSTEAD OF "ALLOWED PLAYERS":
// The obvious alternative — only show a specific allow-listed player
// name — was rejected in favor of an ignore-list. An ignore-list means any new
// player you start using later (a different music app, mpv, etc.) shows
// up automatically; an allow-list would need editing every time you
// tried something new. Only browsers (which register as MPRIS players
// for any playing tab, not just intentional music playback) need to be
// actively excluded.
//
// WHICH PLAYER GETS SHOWN WHEN MULTIPLE ARE ACTIVE:
// Prefers whichever non-ignored player is actually in the Playing
// state; falls back to the first non-ignored player found (e.g. one
// that's paused) if none are playing; shows nothing if there are no
// non-ignored players at all. This means a paused player won't get
// stuck showing over a different player that started playing after it —
// "what's actually making sound" wins.
//
// NO HOVER TOOLTIP (deliberately) — a fuller "click for controls" UI
// (transport buttons, maybe a seek bar) is planned once MPD is wired up
// instead, rather than building tooltip-based metadata display now and
// throwing it away later. See docs/REVISION_HISTORY.md.
//
// OTHER PLAUSIBLE FEATURES, STILL NOT IMPLEMENTED: scroll-to-seek or
// scroll-to-switch-player, per-player
// icons, marquee/scrolling text for long titles instead of truncating.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-12  (Opus) Removed the ▶/⏸ glyph before the track text — it
//             was redundant (audible whether music plays) and ate
//             horizontal space. isPlaying stays (the click handler
//             toggles play/pause on it); only the visual indicator is
//             gone. Now shows just the track/artist text.
// 2026-07-01  Removed the hover tooltip added earlier this session —
//             not wanted. Click functionality (play-pause/previous/
//             next) unchanged. A fuller click-driven controls UI is
//             planned alongside MPD instead of tooltip-based info.
// 2026-07-01  Added a hover tooltip: full (untruncated) title/artist,
//             album (if present), and live position/duration while
//             playing. (Removed — see entry above.)
// 2026-07-01  Initial version.
//
//=============================================================================

import QtQuick
import Quickshell.Services.Mpris
import qs.core

Item {
    id: root

    // Every player not matched by Settings.nowPlayingIgnoredPlayers.
    readonly property var candidates: Mpris.players.values.filter(p => {
        const name = ((p.dbusName || "") + " " + (p.desktopEntry || "")).toLowerCase();
        return !Settings.nowPlayingIgnoredPlayers.some(ignored => name.includes(ignored.toLowerCase()));
    })

    // Prefer whichever candidate is actually playing; otherwise the
    // first candidate found; null if there are none. See DESIGN NOTES.
    readonly property var activePlayer: {
        const playing = candidates.find(p => p.playbackState === MprisPlaybackState.Playing);
        return playing !== undefined ? playing : (candidates.length > 0 ? candidates[0] : null);
    }

    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing

    function truncate(str) {
        const max = Settings.nowPlayingMaxLength;
        return str.length > max ? str.slice(0, max - 1) + "…" : str;
    }

    readonly property string displayText: {
        if (activePlayer === null)
            return "";
        const title = activePlayer.trackTitle || "Unknown Title";
        const artist = activePlayer.trackArtist || "Unknown Artist";
        return truncate(title + " — " + artist);
    }

    visible: activePlayer !== null
    implicitWidth: visible ? content.implicitWidth : 0
    implicitHeight: content.implicitHeight

    Row {
        id: content
        spacing: Theme.spacingSmall

        // Play/pause glyph removed 2026-07-12 — redundant (it's obvious
        // from the audio whether something's playing) and it just ate
        // horizontal space. isPlaying is still used by the click
        // handler below; only the visual indicator is gone.
        Text {
            text: root.displayText
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        anchors.fill: content
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            const player = root.activePlayer;
            if (player === null)
                return;

            if (mouse.button === Qt.LeftButton) {
                if (root.isPlaying) {
                    if (player.canPause) player.pause();
                } else {
                    if (player.canPlay) player.play();
                }
            } else if (mouse.button === Qt.MiddleButton) {
                if (player.canGoPrevious) player.previous();
            } else if (mouse.button === Qt.RightButton) {
                if (player.canGoNext) player.next();
            }
        }
    }
}
