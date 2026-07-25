//=============================================================================
// services/AlbumArtService.qml
// Fetches/caches album art for the current MPD track.
// Lookup order uses MPD itself: embedded picture first, then folder cover.
// GPT — 2026-07-25
//=============================================================================

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property string artPath: ""
    property url artUrl: ""
    property string artFile: ""
    property string lastError: ""
    property bool busy: false

    readonly property bool hasArt: artPath !== ""
    readonly property string helperPath: Quickshell.shellPath("scripts/mpd-fetch-art.py")

    property string wantedFile: ""
    property string requestedFile: ""
    property bool restartAfterExit: false
    property string helperOutput: ""
    property string helperError: ""
    property int artRevision: 0

    function clear(): void {
        artPath = "";
        artUrl = "";
        artFile = "";
        lastError = "";
    }

    function refresh(): void {
        const nextFile = MusicService.fileUri || "";
        wantedFile = nextFile;

        if (nextFile === "") {
            restartAfterExit = false;
            if (fetchProcess.running) {
                fetchProcess.running = false;
            } else {
                clear();
            }
            return;
        }

        if (nextFile === artFile && hasArt)
            return;

        if (fetchProcess.running) {
            restartAfterExit = true;
            fetchProcess.running = false;
            return;
        }

        startFetch(nextFile);
    }

    function startFetch(filePath: string): void {
        if (filePath === "") {
            clear();
            return;
        }
        requestedFile = filePath;
        helperOutput = "";
        helperError = "";
        lastError = "";
        busy = true;
        fetchProcess.running = true;
    }

    function applyResult(exitCode: int): void {
        busy = false;

        if (exitCode === 0) {
            const path = helperOutput.trim();
            artFile = requestedFile;
            artPath = path;
            artRevision += 1;
            artUrl = path !== "" ? ("file://" + path + "?v=" + artRevision) : "";
            lastError = "";
        } else {
            artFile = requestedFile;
            artPath = "";
            artUrl = "";
            lastError = helperError.trim();
        }

        if (restartAfterExit || wantedFile !== requestedFile) {
            restartAfterExit = false;
            if (wantedFile === "") {
                clear();
            } else {
                startFetch(wantedFile);
            }
        }
    }

    Connections {
        target: MusicService
        function onFileUriChanged(): void { root.refresh(); }
    }


    Component.onCompleted: root.refresh()

    Process {
        id: fetchProcess
        command: ["python3", root.helperPath, root.requestedFile]
        stdout: StdioCollector { onStreamFinished: root.helperOutput = text }
        stderr: StdioCollector { onStreamFinished: root.helperError = text }
        onRunningChanged: root.busy = running
        onExited: (code, _status) => root.applyResult(code)
    }
}
