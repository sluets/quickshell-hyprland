// CAVA-backed audio spectrum state for the standalone music window.
// Runtime settings are persisted in UserPrefs and rendered to a temporary
// CAVA profile before each process start. GPT — 2026-07-25

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    property bool active: false
    property bool processEnabled: false
    property bool configReady: false
    property var bands: Array(UserPrefs.musicVisualizerBars).fill(0)
    property string lastError: ""

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    readonly property string configPath: (runtimeDir !== "" ? runtimeDir : "/tmp") + "/quickshell-cava-music.conf"
    readonly property string writerPath: Quickshell.shellPath("scripts/write-cava-config.py")
    readonly property string configSignature: [
        UserPrefs.musicVisualizerBars,
        UserPrefs.musicVisualizerSource,
        UserPrefs.musicVisualizerFramerate,
        UserPrefs.musicVisualizerSensitivity,
        UserPrefs.musicVisualizerAutosens,
        UserPrefs.musicVisualizerLowerCutoff,
        UserPrefs.musicVisualizerHigherCutoff,
        UserPrefs.musicVisualizerSleepTimer,
        UserPrefs.musicVisualizerReverse ? 1 : 0,
        UserPrefs.musicVisualizerNoiseReduction
    ].join(":")

    function clearBands(): void {
        bands = Array(UserPrefs.musicVisualizerBars).fill(0);
    }

    function consumeFrame(line): void {
        const parts = String(line).trim().split(";").filter(value => value !== "");
        if (parts.length === 0)
            return;

        const next = [];
        for (let i = 0; i < UserPrefs.musicVisualizerBars; ++i) {
            const raw = i < parts.length ? Number(parts[i]) : 0;
            next.push(Number.isFinite(raw) ? Math.max(0, Math.min(1, raw / 1000)) : 0);
        }
        bands = next;
    }

    function prepareStart(): void {
        if (!active || !UserPrefs.musicVisualizerEnabled)
            return;
        configReady = false;
        writer.running = true;
    }

    function restartForSettings(): void {
        clearBands();
        restartTimer.stop();
        if (cavaProcess.running) {
            processEnabled = false;
            restartTimer.restart();
        } else {
            prepareStart();
        }
    }

    onActiveChanged: {
        lastError = "";
        restartTimer.stop();
        if (active && UserPrefs.musicVisualizerEnabled)
            prepareStart();
        else {
            processEnabled = false;
            clearBands();
        }
    }

    onConfigSignatureChanged: {
        if (active && UserPrefs.musicVisualizerEnabled)
            settingsDebounce.restart();
        else
            clearBands();
    }

    Connections {
        target: UserPrefs
        function onMusicVisualizerEnabledChanged(): void {
            if (!UserPrefs.musicVisualizerEnabled) {
                root.processEnabled = false;
                root.clearBands();
            } else if (root.active) {
                settingsDebounce.restart();
            }
        }
    }

    Process {
        id: writer
        command: [
            "python3", root.writerPath, root.configPath,
            "--bars", String(UserPrefs.musicVisualizerBars),
            "--source", UserPrefs.musicVisualizerSource,
            "--framerate", String(UserPrefs.musicVisualizerFramerate),
            "--sensitivity", String(UserPrefs.musicVisualizerSensitivity),
            "--autosens", String(UserPrefs.musicVisualizerAutosens),
            "--lower", String(UserPrefs.musicVisualizerLowerCutoff),
            "--higher", String(UserPrefs.musicVisualizerHigherCutoff),
            "--sleep", String(UserPrefs.musicVisualizerSleepTimer),
            "--reverse", UserPrefs.musicVisualizerReverse ? "1" : "0",
            "--noise", String(UserPrefs.musicVisualizerNoiseReduction)
        ]
        stderr: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                if (value !== "")
                    root.lastError = value;
            }
        }
        onExited: code => {
            root.configReady = code === 0;
            if (code === 0 && root.active && UserPrefs.musicVisualizerEnabled)
                root.processEnabled = true;
            else if (code !== 0)
                root.lastError = "Could not write CAVA profile (" + code + ")";
        }
    }

    Process {
        id: cavaProcess
        command: ["cava", "-p", root.configPath]
        running: root.processEnabled && root.configReady

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

        onExited: (exitCode, _exitStatus) => {
            root.clearBands();
            root.processEnabled = false;
            if (root.active && UserPrefs.musicVisualizerEnabled && !restartTimer.running) {
                root.lastError = "CAVA exited (" + exitCode + ")";
                restartTimer.restart();
            }
        }
    }

    Timer {
        id: settingsDebounce
        interval: 75
        repeat: false
        onTriggered: root.restartForSettings()
    }

    Timer {
        id: restartTimer
        interval: 250
        repeat: false
        onTriggered: root.prepareStart()
    }
}
