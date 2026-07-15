//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/Bluetooth.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Bluetooth in the bar — now interactive. Bar display unchanged (filled
// bluetooth glyph + connected-device count). Left-click opens a popout:
//
//   • Adapter on/off toggle
//   • Paired ("bonded") device list, connected ones first — click to
//     connect/disconnect
//   • New (unpaired) device list — populated by scanning while the
//     popout is open, click to pair
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// Quickshell.Bluetooth            (Bluetooth singleton — used directly,
//                                  no service wrapper for connect/pair
//                                  itself; see DESIGN NOTES)
// services/BluetoothAgent.qml     (singleton via `import qs.services` —
//                                  referenced only to force it to load;
//                                  see DESIGN NOTES)
// core/Theme.qml                  (singleton via `import qs.core`)
// widgets/TopBar/BarPopout.qml    (neighboring file)
// widgets/TopBar/MenuDivider.qml  (neighboring file)
// widgets/TopBar/ToggleRow.qml    (neighboring file — adapter on/off)
// widgets/TopBar/SectionLabel.qml (neighboring file — section headers)
// widgets/TopBar/DeviceRow.qml    (neighboring file — device list rows)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/TopBar.qml
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// TopBar loses the bluetooth indicator and controls. Nothing else
// depends on this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY PAIRING WAS FAILING (found live 2026-07-05): bluetoothd's journal
// showed "Authentication attempt without agent" / "Access denied:
// org.bluez.Error.Rejected" when pairing a controller. BlueZ requires
// SOME agent registered before it will authorize any new pairing, even
// PIN-less "Just Works" pairing — nothing here was registering one, so
// BlueZ had no one to ask and auto-rejected. Fixed by
// services/BluetoothAgent.qml, a small always-running service that
// registers a NoInputNoOutput agent for the whole shell session. This
// widget just forces that singleton to load (see _agentLoaded above) —
// the actual agent logic lives in that file, not here.
//
// STILL NO services/Bluetooth.qml WRAPPER for connect/disconnect/pair
// THEMSELVES: the original reasoning holds
// (see this file's 2026-07-02 header and docs/REVISION_HISTORY.md) —
// Quickshell.Bluetooth is already a clean reactive singleton, and this
// is still the only consumer. The popout landing here doesn't change
// that; it's the same widget.
//
// CONTROL API — verified against real-world usage of the same
// Quickshell 0.3 module in a maintained config:
//   adapter.enabled = bool          -> powers the adapter on/off
//   adapter.discovering = bool      -> starts/stops scanning for new
//                                       devices; discovered-but-unpaired
//                                       devices show up in Bluetooth
//                                       .devices.values same as bonded
//                                       ones, distinguished by .bonded
//   device.connected = !connected   -> connects/disconnects a device
//   device.pair()                  -> pairs a discovered device
// All async; BlueZ does the work and the reactive properties update
// when it lands. No PIN/agent dialog is implemented here — the
// reference doesn't build one either, relying on modern Bluetooth's
// "Just Works" pairing, which covers the large majority of devices
// (headphones, controllers, most keyboards/mice). A device that
// specifically requires PIN entry won't complete via this popout;
// `bluetoothctl` remains the fallback for that rare case.
//
// SCAN LIFETIME TIED TO THE POPOUT: discovery starts when the popout
// opens and stops when it closes (via BarPopout's onOpenChanged) rather
// than running continuously — same reasoning as Wifi.qml's rescan
// approach (see docs/PROBLEMS_AND_FIXES.md and 2026-07-05 Wifi fix):
// nothing should be scanning while the menu is closed. Discovery only
// starts if the adapter is actually enabled.
//
// WHY PAIRED DEVICES STAY SEPARATE FROM NEW DEVICES: connect/disconnect
// of already-known devices is the 99% bar interaction (headphones,
// controller) and shouldn't be buried under a scan list that's
// constantly reordering. New devices get their own section below,
// populated only while scanning.
//
// COUNT still filters .connected explicitly — see
// docs/PROBLEMS_AND_FIXES.md ("connected-device count didn't match
// reality"). Do not trust the list to be pre-filtered.
//
// VISUAL REFRESH (2026-07-05): the adapter toggle moved from a
// MenuButton whose LABEL changed text to a ToggleRow with a real
// animated switch. Paired/new device rows moved from single-line
// MenuButton ("Device Name  (connected)", using "●"/"○"/"◐" text
// characters as status) to DeviceRow's two-line title+subtitle with a
// proper status dot — connected = filled accent dot + "Connected"
// subtitle, pairing = pulsing muted dot + "Pairing…" subtitle (the
// pulse is the one place in this pass motion carries actual
// information — in-progress vs settled — not just decoration). See
// ToggleRow.qml/DeviceRow.qml/SectionLabel.qml for the shared-
// component rationale (built for this AND Wifi.qml together).
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Visual refresh: ToggleRow for the adapter switch,
//             DeviceRow (two-line + status dot, pulsing while pairing)
//             for both device lists, SectionLabel for section headers.
//             See DESIGN NOTES. No logic changes — same
//             Quickshell.Bluetooth calls, same discovery lifecycle.
// 2026-07-05  Added discovery + pairing: adapter.discovering toggled by
//             popout open/close, new "New Devices" section listing
//             unbonded Bluetooth.devices entries, click-to-pair via
//             device.pair(). Paired-device connect/disconnect unchanged.
// 2026-07-03  Interactive rewrite: popout with adapter toggle and
//             per-device connect/disconnect. Bar display unchanged.
// 2026-07-02  Explicit .connected filter for the count; filled icon.
// 2026-07-01  Initial display-only widget.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: barRow.implicitWidth
    implicitHeight: barRow.implicitHeight

    readonly property bool adapterEnabled: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
    readonly property bool discovering: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.discovering
    readonly property int connectedCount: Bluetooth.devices.values.filter(d => d.connected).length

    // Forces services/BluetoothAgent.qml to instantiate at shell
    // startup (see that file's DESIGN NOTES, "FORCING INSTANTIATION") —
    // otherwise nothing ever references the singleton and BlueZ has no
    // agent registered, so pairing gets silently rejected. Not used for
    // anything else; the value itself doesn't matter.
    readonly property bool _agentLoaded: BluetoothAgent.active

    // Bonded (paired) devices, connected first, then alphabetical.
    readonly property var pairedDevices: Bluetooth.devices.values
        .filter(d => d.bonded)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

    // Discovered-but-unpaired devices, in-progress pairing first, then
    // alphabetical — only meaningfully populated while discovering.
    readonly property var newDevices: Bluetooth.devices.values
        .filter(d => !d.bonded)
        .sort((a, b) => (b.pairing - a.pairing) || a.name.localeCompare(b.name))

    RowLayout {
        id: barRow
        spacing: Theme.spacingSmall

        Text {
            text: "\uf294"
            color: (popout.open || barMouse.containsMouse)
                ? Theme.colorAccent
                : (root.adapterEnabled ? Theme.colorForeground : Theme.colorMuted)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            visible: root.adapterEnabled && root.connectedCount > 0
            text: root.connectedCount.toString()
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: barMouse
        anchors.fill: barRow
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popout.open = !popout.open
    }

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "right"

        // Scan only while the popout is open, and only if the adapter
        // is enabled — see DESIGN NOTES ("SCAN LIFETIME TIED TO THE
        // POPOUT"). BarPopout's `open` is the logical state to watch,
        // not `visible` (same reasoning as everywhere else in this
        // file's dependencies — see BarPopout.qml's own DESIGN NOTES).
        onOpenChanged: {
            if (Bluetooth.defaultAdapter === null) return;
            Bluetooth.defaultAdapter.discovering = open && root.adapterEnabled;
        }

        Text {
            text: "Bluetooth"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        ToggleRow {
            Layout.fillWidth: true
            Layout.minimumWidth: 240
            icon: "\uf294"
            text: "Bluetooth"
            checked: root.adapterEnabled
            onToggled: value => {
                if (Bluetooth.defaultAdapter !== null)
                    Bluetooth.defaultAdapter.enabled = value;
            }
        }

        MenuDivider { Layout.fillWidth: true }

        SectionLabel {
            text: "Paired Devices"
        }

        Repeater {
            model: root.pairedDevices

            DeviceRow {
                required property var modelData

                Layout.fillWidth: true
                title: modelData.name
                subtitle: modelData.connected ? "Connected" : ""
                statusColor: modelData.connected ? Theme.colorAccent : "transparent"
                // Writable property — BlueZ connects/disconnects async;
                // see DESIGN NOTES for where this is verified.
                onClicked: modelData.connected = !modelData.connected
            }
        }

        Text {
            visible: root.pairedDevices.length === 0
            text: root.adapterEnabled ? "No paired devices" : "Adapter is off"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        MenuDivider { Layout.fillWidth: true; visible: root.adapterEnabled }

        SectionLabel {
            visible: root.adapterEnabled
            text: root.discovering ? "New Devices — Scanning" : "New Devices"
        }

        Repeater {
            model: root.adapterEnabled ? root.newDevices : []

            DeviceRow {
                required property var modelData

                Layout.fillWidth: true
                Layout.minimumWidth: 240
                title: modelData.name || "Unknown device"
                subtitle: modelData.pairing ? "Pairing…" : ""
                statusColor: modelData.pairing ? Theme.colorMuted : "transparent"
                pulsing: modelData.pairing
                // pair() is a no-op if already bonded/pairing; BlueZ
                // handles that, no guard needed here.
                onClicked: modelData.pair()
            }
        }

        Text {
            visible: root.adapterEnabled && root.newDevices.length === 0
            text: root.discovering ? "Searching…" : "No new devices found"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
