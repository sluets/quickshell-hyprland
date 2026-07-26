//=============================================================================
// services/AlbumArtService.qml
// Fetches/caches album art for the current MPD track.
// Lookup order uses MPD itself: embedded picture first, then folder cover.
// GPT — 2026-07-26
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
            if (fetchProcess.running) {
                // Route deliberate cancellation through the restart branch so
                // the outgoing helper result can never be mistaken for a
                // successful empty-art response. // GPT 2026-07-26
                restartAfterExit = true;
                fetchProcess.running = false;
            } else {
                busy = false;
                clear();
            }
            return;
        }

        if (nextFile === artFile && hasArt)
            return;

        if (fetchProcess.running) {
            // Keep the previous artwork visible while the old helper exits.
            // The replacement fetch starts from onExited below.
            restartAfterExit = true;
            fetchProcess.running = false;
            return;
        }

        startFetch(nextFile);
    }

    function startFetch(filePath: string): void {
        if (filePath === "") {
            busy = false;
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

        if (wantedFile !== requestedFile) {
            if (wantedFile === "")
                clear();
            else
                startFetch(wantedFile);
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

        // `busy` is owned only by startFetch/applyResult. Mirroring Process.running
        // here raced with result handling and could leave notifications waiting
        // for their full artwork timeout. // GPT 2026-07-26
        onExited: (code, _status) => {
            if (root.restartAfterExit) {
                root.restartAfterExit = false;
                if (root.wantedFile === "") {
                    root.busy = false;
                    root.clear();
                } else {
                    root.startFetch(root.wantedFile);
                }
                return;
            }

            root.applyResult(code);
        }
    }
}
