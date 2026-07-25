//=============================================================================
// services/MusicNotifications.qml
// Song-change / playback-start notifications for the local MPD player.
// Uses notify-send to deliver through this shell's existing notification
// daemon. Waits briefly for AlbumArtService so artwork and metadata arrive
// together, and suppresses the initial state observed at Quickshell startup.
// GPT — 2026-07-25
//=============================================================================

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    readonly property bool ready: initialized

    property bool initialized: false
    property string previousFile: ""
    property string previousState: "unknown"

    property string pendingFile: ""
    property string pendingTitle: ""
    property string pendingArtist: ""
    property int waitAttempts: 0
    property bool sendQueued: false

    property string commandTitle: ""
    property string commandArtist: ""
    property string commandArtPath: ""

    function currentTitle(): string {
        if (MusicService.title !== "")
            return MusicService.title;
        if (MusicService.fileUri !== "")
            return MusicService.fileUri.split("/").pop();
        return "Unknown track";
    }

    function currentArtist(): string {
        return MusicService.artist !== "" ? MusicService.artist : "Unknown artist";
    }

    function observePlayback(): void {
        const file = MusicService.fileUri || "";
        const state = MusicService.playbackState || "unknown";

        // The service connects and populates state asynchronously at startup.
        // Record that first complete snapshot without announcing a song that
        // was already playing before Quickshell launched.
        if (!initialized) {
            if (file === "" || state === "unknown")
                return;
            previousFile = file;
            previousState = state;
            initialized = true;
            return;
        }

        const trackChanged = file !== "" && file !== previousFile;
        const startedPlaying = state === "play" && previousState !== "play";

        previousFile = file;
        previousState = state;

        if (state !== "play" || file === "")
            return;

        if (trackChanged || startedPlaying)
            queueNotification(file, currentTitle(), currentArtist());
    }

    function queueNotification(file: string, title: string, artist: string): void {
        pendingFile = file;
        pendingTitle = title;
        pendingArtist = artist;
        waitAttempts = 0;
        sendQueued = true;
        artWait.restart();
    }

    function trySend(): void {
        if (!sendQueued || pendingFile === "")
            return;

        // AlbumArtService changes tracks independently and may need a moment
        // to retrieve/cache the matching image. Wait up to ~1.5 seconds, then
        // send without artwork rather than delaying the notification forever.
        const artReady = AlbumArtService.artFile === pendingFile
            && !AlbumArtService.busy;
        if (!artReady && waitAttempts < 10) {
            waitAttempts += 1;
            artWait.restart();
            return;
        }

        commandTitle = pendingTitle;
        commandArtist = pendingArtist;
        commandArtPath = artReady ? AlbumArtService.artPath : "";
        sendQueued = false;

        // Stop a stale invocation only during rapid manual skipping. The next
        // command starts after this one exits, so metadata cannot cross tracks.
        if (notifyProcess.running) {
            sendQueued = true;
            notifyProcess.running = false;
            restartSend.restart();
            return;
        }
        notifyProcess.running = true;
    }

    Connections {
        target: MusicService
        function onFileUriChanged(): void { Qt.callLater(root.observePlayback); }
        function onPlaybackStateChanged(): void { Qt.callLater(root.observePlayback); }
    }

    Component.onCompleted: Qt.callLater(root.observePlayback)

    Timer {
        id: artWait
        interval: 150
        repeat: false
        onTriggered: root.trySend()
    }

    Timer {
        id: restartSend
        interval: 50
        repeat: false
        onTriggered: root.trySend()
    }

    Process {
        id: notifyProcess
        command: {
            const args = [
                "notify-send",
                "--app-name=Quickshell Music",
                "--urgency=normal",
                "--expire-time=5000"
            ];
            if (root.commandArtPath !== "")
                args.push("--icon=" + root.commandArtPath);
            args.push(root.commandTitle, root.commandArtist);
            return args;
        }
        onExited: (_code, _status) => {
            if (root.sendQueued)
                restartSend.restart();
        }
    }
}
