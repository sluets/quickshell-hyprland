//=============================================================================
// services/MpdConnection.qml
// MPD protocol transport: one serialized local Unix command socket.
// Phase 1 Rev 2 intentionally avoids a second long-lived idle socket because
// transient idle-socket closes were tearing down otherwise healthy state.
// GPT — 2026-07-25
//=============================================================================

import QtQuick
import Quickshell.Io

Item {
    id: root

    property var socketCandidates: []
    property bool enabled: false
    property int requestTimeoutMs: 5000

    readonly property bool ready: cmdReady
    readonly property string activePath: ready ? currentPath() : ""
    property string lastError: ""

    property bool cmdReady: false
    property bool tearingDown: false
    property int candidateIndex: 0
    property int backoffMs: 1000
    property var pending: []

    function request(command, callback): void {
        if (!ready) {
            if (callback)
                callback(false, [], "not connected");
            return;
        }

        const next = pending.slice();
        next.push({ callback: callback || null, lines: [] });
        pending = next;

        cmdSocket.write(command + "\n");
        cmdSocket.flush();
        requestGuard.restart();
    }

    function currentPath(): string {
        if (!socketCandidates || socketCandidates.length === 0)
            return "";
        return String(socketCandidates[candidateIndex % socketCandidates.length]);
    }

    function attemptConnect(): void {
        if (!enabled)
            return;

        const path = currentPath();
        if (path === "") {
            lastError = "no MPD socket path configured";
            return;
        }

        cmdSocket.path = path;
        cmdSocket.connected = true;
        connectGuard.restart();
    }

    function failPending(reason): void {
        const stale = pending;
        pending = [];
        requestGuard.stop();
        for (let i = 0; i < stale.length; ++i) {
            if (stale[i].callback)
                stale[i].callback(false, stale[i].lines, reason);
        }
    }

    function disconnectSocket(): void {
        failPending("connection lost");
        cmdReady = false;
        cmdSocket.connected = false;
    }

    function teardown(reason): void {
        tearingDown = true;
        connectGuard.stop();
        retryTimer.stop();
        disconnectSocket();
        tearingDown = false;
        if (reason !== "")
            lastError = reason;
    }

    function failCurrentAttempt(reason): void {
        if (tearingDown || retryTimer.running)
            return;

        tearingDown = true;
        connectGuard.stop();
        disconnectSocket();
        tearingDown = false;

        lastError = reason + " (" + currentPath() + ")";
        candidateIndex = (candidateIndex + 1) % Math.max(1, socketCandidates.length);
        if (enabled) {
            retryTimer.interval = backoffMs;
            backoffMs = Math.min(backoffMs * 2, 30000);
            retryTimer.restart();
        }
    }

    function completeRequest(ok, errorText): void {
        const queue = pending.slice();
        const request = queue.shift();
        pending = queue;

        if (pending.length === 0)
            requestGuard.stop();
        else
            requestGuard.restart();

        if (request && request.callback)
            request.callback(ok, request.lines, errorText);
    }

    onEnabledChanged: {
        if (enabled) {
            candidateIndex = 0;
            backoffMs = 1000;
            lastError = "";
            attemptConnect();
        } else {
            teardown("disabled");
        }
    }

    onReadyChanged: {
        if (ready) {
            connectGuard.stop();
            backoffMs = 1000;
            lastError = "";
        }
    }

    Timer {
        id: connectGuard
        interval: 3000
        repeat: false
        onTriggered: {
            if (!root.ready)
                root.failCurrentAttempt("connect/handshake timeout");
        }
    }

    Timer {
        id: requestGuard
        interval: root.requestTimeoutMs
        repeat: false
        onTriggered: {
            if (root.pending.length > 0)
                root.failCurrentAttempt("MPD command timeout");
        }
    }

    Timer {
        id: retryTimer
        repeat: false
        onTriggered: root.attemptConnect()
    }

    Socket {
        id: cmdSocket

        onConnectedChanged: {
            if (!connected && root.enabled && !root.tearingDown)
                root.failCurrentAttempt("connection lost");
        }

        onError: error => root.failCurrentAttempt("command socket error: " + error)

        parser: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const text = String(line).replace(/\r$/, "");
                if (!root.cmdReady) {
                    if (text.indexOf("OK MPD ") === 0)
                        root.cmdReady = true;
                    return;
                }

                if (text === "OK") {
                    root.completeRequest(true, "");
                } else if (text.indexOf("ACK ") === 0) {
                    root.completeRequest(false, text);
                } else if (root.pending.length > 0) {
                    root.pending[0].lines.push(text);
                }
            }
        }
    }
}
