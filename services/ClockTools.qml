pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool alertSoundEnabled: true
    property string alertSound: "soft"
    readonly property var soundChoices: ["soft", "double", "urgent"]

    // Date.now() alone does not make QML bindings reactive. The service
    // timer updates this clock value so visible elapsed/remaining bindings
    // are reevaluated while any clock tool is active.
    property double nowMs: Date.now()

    property bool timerRunning: false
    property bool timerPaused: false
    property double timerDeadlineMs: 0
    property int timerPausedRemainingMs: 0
    property int timerDurationMs: 5 * 60 * 1000
    property bool timerNearNotified: false
    readonly property int timerRemainingMs: timerRunning
        ? Math.max(0, Math.ceil(timerDeadlineMs - nowMs))
        : timerPausedRemainingMs

    property bool stopwatchRunning: false
    property double stopwatchStartedMs: 0
    property int stopwatchAccumulatedMs: 0
    property int stopwatchIntervalMinutes: 0
    property int stopwatchLastInterval: 0
    readonly property int stopwatchElapsedMs: stopwatchAccumulatedMs
        + (stopwatchRunning ? Math.max(0, Math.floor(nowMs - stopwatchStartedMs)) : 0)
    property var laps: []

    property bool alarmEnabled: false
    property int alarmHour: 7
    property int alarmMinute: 0
    property double alarmTargetMs: 0

    readonly property bool anyActive: timerRunning || timerPaused || stopwatchRunning || alarmEnabled

    function two(n) { return String(Math.floor(n)).padStart(2, "0"); }
    function formatDuration(ms, showTenths) {
        ms = Math.max(0, Number(ms) || 0);
        const totalSeconds = Math.floor(ms / 1000);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;
        let out = hours > 0 ? hours + ":" + two(minutes) + ":" + two(seconds)
                            : two(minutes) + ":" + two(seconds);
        if (showTenths)
            out += "." + Math.floor((ms % 1000) / 100);
        return out;
    }

    function soundPath() {
        return "$HOME/.config/quickshell/assets/sounds/clock-" + alertSound + ".wav";
    }

    function playAlert(forcePreview) {
        if (!alertSoundEnabled && forcePreview !== true)
            return;
        Quickshell.execDetached(["sh", "-c",
            "f=\"" + soundPath() + "\"; " +
            "if command -v pw-play >/dev/null 2>&1; then pw-play \"$f\"; " +
            "elif command -v aplay >/dev/null 2>&1; then aplay -q \"$f\"; fi"]);
    }

    function notify(title, body, urgency) {
        const args = ["notify-send", "-a", "Quickshell Clock", "-u", urgency || "normal", title, body];
        Quickshell.execDetached(args);
    }

    function setTimerMinutes(minutes) {
        timerDurationMs = Math.max(1000, Math.round(minutes * 60000));
        timerPausedRemainingMs = timerDurationMs;
        timerRunning = false;
        timerPaused = false;
        timerNearNotified = false;
    }
    function startTimer() {
        const remaining = timerPaused && timerPausedRemainingMs > 0 ? timerPausedRemainingMs : timerDurationMs;
        nowMs = Date.now();
        timerDeadlineMs = nowMs + Math.max(1000, remaining);
        timerRunning = true;
        timerPaused = false;
        timerNearNotified = false;
    }
    function pauseTimer() {
        if (!timerRunning) return;
        timerPausedRemainingMs = timerRemainingMs;
        timerRunning = false;
        timerPaused = true;
    }
    function resetTimer() {
        timerRunning = false;
        timerPaused = false;
        timerPausedRemainingMs = timerDurationMs;
        timerNearNotified = false;
    }

    function toggleStopwatch() {
        if (stopwatchRunning) {
            stopwatchAccumulatedMs = stopwatchElapsedMs;
            stopwatchRunning = false;
        } else {
            nowMs = Date.now();
            stopwatchStartedMs = nowMs;
            stopwatchRunning = true;
        }
    }
    function resetStopwatch() {
        stopwatchRunning = false;
        stopwatchAccumulatedMs = 0;
        stopwatchLastInterval = 0;
        laps = [];
    }
    function addLap() {
        if (stopwatchElapsedMs <= 0) return;
        const next = laps.slice();
        next.unshift(stopwatchElapsedMs);
        laps = next;
    }

    function computeNextAlarm() {
        const now = new Date();
        let target = new Date(now.getFullYear(), now.getMonth(), now.getDate(), alarmHour, alarmMinute, 0, 0);
        if (target.getTime() <= now.getTime())
            target.setDate(target.getDate() + 1);
        alarmTargetMs = target.getTime();
    }
    function enableAlarm() {
        computeNextAlarm();
        alarmEnabled = true;
    }
    function disableAlarm() { alarmEnabled = false; }
    function alarmLabel() {
        if (!alarmEnabled) return "Alarm off";
        return "Next: " + Qt.formatDateTime(new Date(alarmTargetMs), "ddd h:mm AP");
    }

    Timer {
        interval: 100
        repeat: true
        running: root.anyActive
        onTriggered: {
            root.nowMs = Date.now();
            const now = root.nowMs;
            if (root.timerRunning) {
                const remaining = root.timerDeadlineMs - now;
                if (!root.timerNearNotified && root.timerDurationMs > 60000 && remaining <= 60000 && remaining > 0) {
                    root.timerNearNotified = true;
                    root.notify("Timer nearly finished", "1 minute remaining.", "normal");
                }
                if (remaining <= 0) {
                    root.timerRunning = false;
                    root.timerPaused = false;
                    root.timerPausedRemainingMs = 0;
                    root.notify("Timer finished", "Your timer is complete.", "critical");
                    root.playAlert();
                }
            }
            if (root.stopwatchRunning && root.stopwatchIntervalMinutes > 0) {
                const intervalMs = root.stopwatchIntervalMinutes * 60000;
                const current = Math.floor(root.stopwatchElapsedMs / intervalMs);
                if (current > root.stopwatchLastInterval) {
                    root.stopwatchLastInterval = current;
                    root.notify("Stopwatch interval", root.formatDuration(root.stopwatchElapsedMs, false) + " elapsed.", "normal");
                    root.playAlert();
                }
            }
            if (root.alarmEnabled && now >= root.alarmTargetMs) {
                root.alarmEnabled = false;
                root.notify("Alarm", Qt.formatDateTime(new Date(), "h:mm AP"), "critical");
                root.playAlert();
            }
        }
    }
}
