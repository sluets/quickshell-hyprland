//=============================================================================
// FILE
//=============================================================================
//
// services/Network.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The one place the shell talks to NetworkManager. Two halves:
//
//   READING (connection status) — Quickshell's built-in
//   Quickshell.Networking module (reactive: device list, wifi enabled
//   state, active network, SSID, signal strength). This part works fine —
//   confirmed live (toggle + status display both correct).
//
//   READING (scan list) + CONTROLLING — nmcli. See DESIGN NOTES below for
//   why the scan list moved off Quickshell.Networking.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell               (Singleton)
// Quickshell.Networking    (Networking singleton, DeviceType)
// Quickshell.Io            (Process, StdioCollector — for nmcli)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/Wifi.qml (bar display + the popout's toggle / list /
// connect actions).
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Wifi.qml fails to resolve `Network` and the bar fails to load.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY THE SCAN LIST IS PARSED FROM nmcli, NOT Networking.wifiDevice.networks:
// confirmed live 2026-07-05 that `nmcli device wifi list` sees every nearby
// network correctly, but Quickshell's own `Networking.wifiDevice.networks`
// stayed empty after rescan — no warnings, no errors, just silently never
// populated. Maintained Quickshell configs in the wild don't use that
// API for the scan list either — they parse `nmcli` output directly.
// Same approach here: `wifiEnabled` / `wiredConnected` /
// `wifiConnected` / `wifiSsid` / `wifiSignal` all still come from
// Quickshell.Networking (those are confirmed working), only the
// list-of-visible-networks piece is now nmcli-driven.
//
// TERSE PARSING (`-t -f IN-USE,SSID,SIGNAL,SECURITY`): nmcli's terse mode
// separates fields with `:` and escapes literal colons inside a field as
// `\:` (relevant for BSSID-shaped or colon-containing SSIDs). parseWifiList
// swaps escaped colons out before splitting, then back in after.
//
// DEDUPE: one physical AP can show up multiple times (multiple BSSIDs
// broadcasting the same SSID, e.g. mesh/repeater setups) — collapse to one
// row per SSID, preferring the in-use one, then the strongest signal.
//
// ONE Process FOR LIST, ONE FOR RESCAN-THEN-LIST: `rescan()` uses
// `nmcli dev wifi list --rescan yes`, which forces a fresh scan AND
// returns the list in one call — matches the proven-working reference
// command exactly, rather than firing a separate `wifi rescan` and hoping
// the list updates after.
//
// NO BACKGROUND POLLING, BY DESIGN: nmcli only runs when Wifi.qml's
// popout opens (refreshList(), a cheap non-forcing list) or when the
// user clicks Rescan (rescan(), the forcing version). Nothing runs while
// the menu is closed — no timer, no periodic scan.
//
// CONNECT STRATEGY (connectTo): unchanged from before — try
// `nmcli connection up id <ssid>` first (saved profile), fall back to
// `nmcli device wifi connect <ssid> [password <pw>]` if that fails. Still
// flagged as less-tested than the list/toggle path; watch lastError.
//
// ⚠ connectTo() is comparatively less battle-tested than the list/toggle
// fixes above — confirm it against a real secured network before trusting
// it fully.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Wifi scan list moved from Networking.wifiDevice.networks
//             (confirmed silently non-functional live) to nmcli-parsed
//             list, matching the reference config's proven approach.
//             wifiNetworks is now a plain property populated by a
//             Process, not a computed binding into Networking.
// 2026-07-03  Added the control half: setWifiEnabled(), rescan(),
//             connectTo(ssid, password), forget(ssid), plus
//             `connecting` / `lastError` state. Reading half unchanged.
// 2026-07-02  Added backendAvailable (inferred) for the
//             "NetworkManager Off" diagnosis.
// 2026-07-01  Initial read-only service.
//
//=============================================================================
pragma Singleton
import Quickshell
import Quickshell.Networking
import Quickshell.Io

Singleton {
    id: root

    // =========================================================
    // READING — connection status, from Quickshell.Networking
    // (confirmed working live: toggle + status both correct)
    // =========================================================

    readonly property bool wifiEnabled: Networking.wifiEnabled

    // Inferred, not a direct API flag — if NO devices show up at all,
    // the backend almost certainly never initialized. See
    // docs/PROBLEMS_AND_FIXES.md ("Could not find an available backend").
    readonly property bool backendAvailable: Networking.devices.values.length > 0

    readonly property var wifiDevice: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        }
        return null;
    }

    readonly property var wiredDevice: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wired) return devs[i];
        }
        return null;
    }

    readonly property bool wiredConnected: wiredDevice !== null && wiredDevice.connected

    readonly property var activeWifiNetwork: {
        if (wifiDevice === null) return null;
        const nets = wifiDevice.networks.values;
        for (let i = 0; i < nets.length; i++) {
            if (nets[i].connected) return nets[i];
        }
        return null;
    }

    readonly property bool wifiConnected: activeWifiNetwork !== null
    readonly property string wifiSsid: activeWifiNetwork !== null ? activeWifiNetwork.name : ""
    readonly property real wifiSignal: activeWifiNetwork !== null ? activeWifiNetwork.signalStrength : 0

    // =========================================================
    // READING — scan list, via nmcli (see DESIGN NOTES)
    // =========================================================

    // Every visible wifi network, strongest first, deduped by SSID.
    // Shape per entry: { name, signalStrength (0-1), connected, security }.
    // Wifi.qml's popout list binds to this — shape unchanged from before,
    // only the source changed.
    property var wifiNetworks: []

    readonly property bool scanning: listProc.running

    function parseWifiList(output: string): var {
        if (!output || output.length === 0) return [];

        const ESCAPED_COLON = "\u0001";
        const lines = output.trim().split("\n").filter(l => l.length > 0);
        const parsed = [];

        for (const line of lines) {
            const safe = line.replace(/\\:/g, ESCAPED_COLON);
            const parts = safe.split(":");
            if (parts.length < 4) continue;

            const name = parts[1].replace(new RegExp(ESCAPED_COLON, "g"), ":").trim();
            if (name.length === 0) continue; // skip hidden/blank SSIDs

            const signalPct = parseInt(parts[2], 10) || 0;
            parsed.push({
                name: name,
                signalStrength: signalPct / 100,
                connected: parts[0] === "*",
                security: (parts[3] || "").trim()
            });
        }

        // Dedupe by SSID: prefer the in-use entry, then the strongest signal.
        const bySsid = new Map();
        for (const net of parsed) {
            const existing = bySsid.get(net.name);
            if (!existing || net.connected || (!existing.connected && net.signalStrength > existing.signalStrength)) {
                bySsid.set(net.name, net);
            }
        }

        return Array.from(bySsid.values()).sort((a, b) => b.signalStrength - a.signalStrength);
    }

    // =========================================================
    // CONTROLLING — nmcli (see DESIGN NOTES)
    // =========================================================

    readonly property bool connecting: connUp.running || connNew.running
    property string lastError: ""

    // SSID mid-connect, so the UI can mark the right row.
    property string pendingSsid: ""
    property string pendingPassword: ""

    function setWifiEnabled(on: bool): void {
        radioProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        radioProc.running = true;
    }

    // Forces a fresh scan AND returns the list in one nmcli call.
    function rescan(): void {
        if (listProc.running) return;
        listProc.command = ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"];
        listProc.running = true;
    }

    // Plain (non-forcing) list refresh — cheap, used on startup/timer/
    // post-connect so the list stays current without hammering the radio.
    function refreshList(): void {
        if (listProc.running) return;
        listProc.command = ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list"];
        listProc.running = true;
    }

    function connectTo(ssid: string, password: string): void {
        if (root.connecting) return;
        root.lastError = "";
        root.pendingSsid = ssid;
        root.pendingPassword = password || "";
        // Step 1: saved profile? (see DESIGN NOTES)
        connUp.command = ["nmcli", "connection", "up", "id", ssid];
        connUp.running = true;
    }

    function forget(ssid: string): void {
        forgetProc.command = ["nmcli", "connection", "delete", "id", ssid];
        forgetProc.running = true;
    }

    Process {
        id: radioProc
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiNetworks = root.parseWifiList(text);
            }
        }
    }

    Process {
        id: forgetProc
    }

    // Step 1 of connectTo — bring up an existing saved profile.
    Process {
        id: connUp
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.pendingSsid = "";
                root.pendingPassword = "";
                root.refreshList();
                return;
            }
            // No saved profile (or it failed) — step 2, create one.
            const cmd = ["nmcli", "device", "wifi", "connect", root.pendingSsid];
            if (root.pendingPassword.length > 0)
                cmd.push("password", root.pendingPassword);
            connNew.command = cmd;
            connNew.running = true;
        }
    }

    // Step 2 of connectTo — new profile via `device wifi connect`.
    Process {
        id: connNew
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.lastError = "Failed to connect to " + root.pendingSsid
                    + (root.pendingPassword.length === 0 ? " (password needed?)" : " (wrong password?)");
            root.pendingSsid = "";
            root.pendingPassword = "";
            root.refreshList();
        }
    }

    // No background polling — Wifi.qml calls refreshList() when the
    // popout opens, and rescan() when the user clicks Rescan. Nothing
    // runs nmcli while the menu is closed.
}
