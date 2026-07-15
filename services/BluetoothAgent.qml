//=============================================================================
// FILE
//=============================================================================
//
// services/BluetoothAgent.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Registers a BlueZ pairing agent for the life of the shell. Nothing
// else in this project does this, and BlueZ REQUIRES some agent to be
// registered before it will authorize ANY device pairing/connection —
// even "Just Works" (no PIN) pairing still needs something to approve
// the authorization request. Without this, BlueZ silently rejects.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell               (Singleton)
// Quickshell.Io            (Process — wraps `bluetoothctl`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/Bluetooth.qml — references BluetoothAgent.active purely
// to force this singleton to instantiate at shell startup (see DESIGN
// NOTES, "FORCING INSTANTIATION" — same trick services/Notifs.qml relies
// on via NotificationPopups.qml).
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No agent gets registered, and Bluetooth pairing goes back to failing
// with "Authentication attempt without agent" / "Access denied:
// org.bluez.Error.Rejected" in the bluetoothd journal — exactly the bug
// this file fixes. Already-paired/bonded devices are unaffected (see
// DESIGN NOTES on why connect/disconnect of paired devices worked fine
// without this).
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// ⚠ WRITTEN FROM A JOURNAL LOG, NOT YET LIVE-CONFIRMED FIXED: diagnosed
// from `journalctl -u bluetooth`showing "Authentication attempt without
// agent" / "Access denied: org.bluez.Error.Rejected" when pairing a
// controller via the popout's new pairing feature. bluetoothctl itself
// (run directly by the maintainer) presumably works because it
// registers its own agent internally for its session — this service
// does the same thing, just kept alive for the whole shell session
// instead of one terminal command. VERIFY LIVE before trusting fully:
// confirm bluetoothctl's own output shows "Agent registered" /
// "Default agent request successful" after this starts, and confirm
// the controller actually pairs afterward.
//
// WHY CONNECT/DISCONNECT OF ALREADY-PAIRED DEVICES WORKED WITHOUT THIS:
// once a device is bonded, BlueZ has a stored trust/link-key
// relationship already — reconnecting doesn't need a NEW authorization
// decision the way first-time pairing does. That's why the paired-
// devices list (headphones, etc.) was fine, and it was specifically the
// new pairing feature that exposed the missing agent.
//
// WHY bluetoothctl, NOT A HAND-ROLLED D-BUS AGENT: BlueZ's actual agent
// registration is a D-Bus service the requester has to implement
// (org.bluez.Agent1) — nontrivial from QML directly. bluetoothctl
// already implements exactly this and ships as part of bluez-utils,
// which is already a dependency of this project (nmcli/bluetoothctl
// both assumed present per the root README.md). Piping commands
// into a long-lived bluetoothctl process is a known, common technique
// for headless/scripted BlueZ agent registration.
//
// NoInputNoOutput CAPABILITY: tells BlueZ this agent can't display or
// accept a PIN — i.e. "Just Works" pairing only. Matches the scope
// decision already made in widgets/TopBar/Bluetooth.qml (no PIN/agent
// UI built there either). A device that specifically demands PIN entry
// still won't pair through this; `bluetoothctl` run by hand (which can
// prompt interactively) remains the fallback for that case.
//
// KEEPING STDIN OPEN, NEVER SENDING "exit": bluetoothctl only stays
// registered as an agent for as long as its process is alive — closing
// stdin or letting it exit deregisters it. This Process is deliberately
// never told to exit; if it dies unexpectedly (bluetoothd restart,
// crash), the restart timer relaunches it and re-registers, mirroring
// the `nmcli monitor` restart pattern in services/Network.qml's history
// (see docs/REVISION_HISTORY.md, 2026-07-03 entry, monitorRestartTimer).
//
// FORCING INSTANTIATION: a `pragma Singleton` QML type is only created
// the first time something references it. This service has to exist
// for the WHOLE shell session, not just while the Bluetooth popout is
// open, so widgets/TopBar/Bluetooth.qml (always loaded, part of the
// bar) references `BluetoothAgent.active` once purely to force early
// creation — the exact same trick services/Notifs.qml relies on via
// NotificationPopups.qml being an always-loaded top-level item.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Created — fixes controller pairing failing with
//             "Access denied: org.bluez.Error.Rejected" (no agent
//             registered). ⚠ Not yet live-confirmed — see DESIGN NOTES.
//
//=============================================================================
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool active: agentProc.running

    Process {
        id: agentProc
        command: ["bluetoothctl"]
        running: true
        stdinEnabled: true

        onRunningChanged: {
            if (running) {
                write("agent NoInputNoOutput\n");
                write("default-agent\n");
            }
        }

        onExited: restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: agentProc.running = true
    }
}
