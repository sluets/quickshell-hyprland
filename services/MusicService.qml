//=============================================================================
// services/MusicService.qml
// Read/control surface for the local MPD instance.
// Phase 1 intentionally contains no UI or queue-replacement behavior.
// GPT — 2026-07-25
//=============================================================================

pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    readonly property string runtimeSocket: runtimeDir !== "" ? runtimeDir + "/mpd/socket" : ""
    // Connect only to the active user-session MPD socket. Do not rotate to a
    // nonexistent ~/.config/mpd/socket fallback after a transient disconnect.
    readonly property var socketCandidates: runtimeSocket !== ""
        ? [runtimeSocket]
        : []

    readonly property bool connected: connection.ready
    readonly property string connectionPath: connection.activePath
    readonly property string lastError: connection.lastError

    property string playbackState: "unknown" // play | pause | stop | unknown
    property string title: ""
    property string artist: ""
    property string album: ""
    property string fileUri: ""
    property int songId: -1
    property int songPosition: -1
    property real elapsedSeconds: 0
    property real durationSeconds: 0
    property int volume: -1
    property bool repeat: false
    property bool random: false
    property bool single: false
    property bool consume: false
    property int queueLength: 0
    property int databaseUpdatingJob: 0
    property string lastCommandResult: ""

    function valueMap(lines): var {
        const result = {};
        for (let i = 0; i < lines.length; ++i) {
            const line = String(lines[i]);
            const split = line.indexOf(": ");
            if (split < 0)
                continue;
            const key = line.slice(0, split).toLowerCase();
            const value = line.slice(split + 2);
            if (result[key] === undefined)
                result[key] = value;
        }
        return result;
    }

    function asInt(value, fallback): int {
        const parsed = Number.parseInt(value, 10);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function asReal(value, fallback): real {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function setResult(ok, error): void {
        lastCommandResult = ok ? "ok" : String(error || "command failed");
    }

    function refreshStatus(): void {
        connection.request("status", function(ok, lines, error) {
            if (!ok) {
                root.setResult(false, error);
                return;
            }
            const data = root.valueMap(lines);
            root.playbackState = data.state || "unknown";
            root.volume = root.asInt(data.volume, -1);
            root.repeat = data.repeat === "1";
            root.random = data.random === "1";
            root.single = data.single === "1";
            root.consume = data.consume === "1";
            root.songId = root.asInt(data.songid, -1);
            root.songPosition = root.asInt(data.song, -1);
            root.queueLength = root.asInt(data.playlistlength, 0);
            root.elapsedSeconds = root.asReal(data.elapsed, 0);
            root.durationSeconds = root.asReal(data.duration, 0);
            root.databaseUpdatingJob = root.asInt(data.updating_db, 0);
            root.setResult(true, "");
        });
    }

    function refreshCurrentSong(): void {
        connection.request("currentsong", function(ok, lines, error) {
            if (!ok) {
                root.setResult(false, error);
                return;
            }
            const data = root.valueMap(lines);
            root.fileUri = data.file || "";
            root.title = data.title || (root.fileUri !== "" ? root.fileUri.split("/").pop() : "");
            root.artist = data.artist || data.albumartist || "";
            root.album = data.album || "";
            root.songId = root.asInt(data.id, root.songId);
            root.songPosition = root.asInt(data.pos, root.songPosition);
            root.durationSeconds = root.asReal(data.duration, root.durationSeconds);
            root.setResult(true, "");
        });
    }

    function refreshAll(): void {
        if (!connected)
            return;
        refreshStatus();
        refreshCurrentSong();
    }

    function command(text): void {
        connection.request(text, function(ok, _lines, error) {
            root.setResult(ok, error);
            if (ok)
                root.refreshAll();
        });
    }

    function play(): void { command("play"); }
    function pause(): void { command("pause 1"); }
    function resume(): void { command("pause 0"); }

    function toggle(): void {
        if (playbackState === "play")
            pause();
        else if (playbackState === "pause")
            resume();
        else
            play();
    }

    function stop(): void { command("stop"); }

    function changeTrack(commandText: string): void {
        const shouldStart = playbackState === "stop" || playbackState === "unknown";
        connection.request(commandText, function(ok, _lines, error) {
            root.setResult(ok, error);
            if (!ok)
                return;
            if (shouldStart)
                root.play();
            else
                root.refreshAll();
        });
    }

    function previous(): void { changeTrack("previous"); }
    function next(): void { changeTrack("next"); }
    function restartSong(): void { command("seekcur 0"); }
    function seek(seconds): void { command("seekcur " + Math.max(0, Number(seconds) || 0)); }
    function setVolume(percent): void { command("setvol " + Math.max(0, Math.min(100, Math.round(percent)))); }
    function setRandom(enabled: bool): void { command("random " + (enabled ? "1" : "0")); }
    function toggleRandom(): void { setRandom(!random); }
    function setRepeat(enabled: bool): void { command("repeat " + (enabled ? "1" : "0")); }
    function toggleRepeat(): void { setRepeat(!repeat); }

    function statusText(): string {
        return [
            "connected=" + connected,
            "path=" + (connectionPath || ""),
            "state=" + playbackState,
            "song=" + songPosition + "/" + queueLength,
            "elapsed=" + elapsedSeconds,
            "duration=" + durationSeconds,
            "volume=" + volume,
            "artist=" + artist,
            "album=" + album,
            "title=" + title,
            "file=" + fileUri,
            "error=" + lastError,
            "result=" + lastCommandResult
        ].join("\n");
    }

    MpdConnection {
        id: connection
        enabled: true
        socketCandidates: root.socketCandidates

        onReadyChanged: {
            if (ready)
                initialRefresh.restart();
            else
                root.playbackState = "unknown";
        }
    }

    // Defer the first request until the greeting/ready transition has fully
    // settled. This avoids losing the initial status request during startup.
    Timer {
        id: initialRefresh
        interval: 100
        repeat: false
        onTriggered: root.refreshAll()
    }

    // Temporary robust refresh path for Phase 1. One local MPD status/current
    // song refresh per second while playing (three seconds otherwise) is tiny,
    // and avoids depending on a second idle socket until that path is hardened.
    Timer {
        id: refreshTimer
        interval: root.playbackState === "play" ? 1000 : 3000
        repeat: true
        running: root.connected
        onTriggered: root.refreshAll()
    }
}
