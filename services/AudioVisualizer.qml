// CAVA-backed audio spectrum state for the standalone music window.
// Captures the active PipeWire output and exposes 32 normalized bands.
// GPT — 2026-07-25

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool processEnabled: false
    property var bands: Array(32).fill(0)
    property string lastError: ""

    readonly property string configPath: Quickshell.shellPath("assets/cava-music.conf")

    function clearBands(): void {
        bands = Array(32).fill(0);
    }

    function consumeFrame(line): void {
        const parts = String(line).trim().split(";").filter(value => value !== "");
        if (parts.length === 0)
            return;

        const next = [];
        for (let i = 0; i < 32; ++i) {
            const raw = i < parts.length ? Number(parts[i]) : 0;
            next.push(Number.isFinite(raw)
                ? Math.max(0, Math.min(1, raw / 1000))
                : 0);
        }
        // CAVA already applies its own smoothing. Publishing each frame
        // directly keeps the QML view as responsive as terminal CAVA.
        bands = next;
    }

    onActiveChanged: {
        lastError = "";
        restartTimer.stop();
        processEnabled = active;
        if (!active)
            clearBands();
    }

    Process {
        id: cavaProcess
        command: ["cava", "-p", root.configPath]
        running: root.processEnabled

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.consumeFrame(data)
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const text = String(data).trim();
                if (text !== "")
                    root.lastError = text;
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.clearBands();
            if (root.active) {
                root.lastError = "CAVA exited (" + exitCode + ")";
                root.processEnabled = false;
                restartTimer.restart();
            }
        }
    }

    Timer {
        id: restartTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (root.active)
                root.processEnabled = true;
        }
    }
}
