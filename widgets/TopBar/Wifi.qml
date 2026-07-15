//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/Wifi.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Network status in the bar — now interactive. Bar display is unchanged
// (SSID + signal % when on wifi, ethernet icon when wired, status text
// otherwise). Left-click opens a popout with:
//
//   • Wi-Fi on/off toggle
//   • Rescan
//   • The visible network list (strongest first), click to connect
//   • A password row that appears when you pick a network — leave it
//     empty for open networks or ones you've connected to before
//     (saved profile), fill it in for a new secured network
//   • Connection progress / failure feedback from the service
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// core/Theme.qml                  (singleton via `import qs.core`)
// services/Network.qml            (singleton via `import qs.services`)
// widgets/TopBar/BarPopout.qml    (neighboring file)
// widgets/TopBar/MenuButton.qml   (neighboring file — Rescan row only)
// widgets/TopBar/MenuDivider.qml  (neighboring file)
// widgets/TopBar/ToggleRow.qml    (neighboring file — Wi-Fi on/off)
// widgets/TopBar/SectionLabel.qml (neighboring file — "Networks" header)
// widgets/TopBar/DeviceRow.qml    (neighboring file — network list rows)
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
// TopBar loses the network indicator and wifi controls. Nothing else
// depends on this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// CONNECT FLOW: clicking a network row does NOT connect immediately — it
// selects the row and reveals the password field + Connect button.
// Connecting straight on click would strand secured-new-network attempts
// (nmcli would just fail asking for a secret). One extra click, zero
// dead ends. The service tries the saved profile first, so the password
// field genuinely can be left empty for anything you've joined before —
// the hint text says so.
//
// PASSWORD INPUT is a themed TextInput, not a Controls TextField — same
// reasoning as Volume.qml's hand-rolled slider (platform styling fights
// the theme). BarPopout sets grabFocus, which is what gives the popup
// keyboard input at all.
//
// NO LOCK ICON on rows: whether Quickshell 0.3's WifiNetwork exposes a
// "secured" flag (and under what name) wasn't verifiable offline, and
// per docs/PROBLEMS_AND_FIXES.md ("...fail silently") this project
// doesn't ship guessed property names. The password-optional connect
// flow makes the lock cosmetic anyway. Revisit against the live type
// reference if wanted.
//
// LIST LENGTH capped at 8 (strongest first) so a dense apartment block
// doesn't produce a popup taller than the screen.
//
// VISUAL REFRESH (2026-07-05): the enable toggle moved from a
// MenuButton whose LABEL changed text ("Turn Wi-Fi Off"/"On") to a
// ToggleRow with a real animated switch — same information, faster to
// read at a glance. Network rows moved from one crammed line
// ("SSID  73%  (connected)") to DeviceRow's two-line title+subtitle
// with trailing SignalBars instead of a raw percentage — status
// (connected/connecting) reads as a status DOT + subtitle line rather
// than parenthetical text appended to the name. Rescan stays a plain
// MenuButton — it's an action, not a status row, so it doesn't need
// the same treatment. See ToggleRow.qml/DeviceRow.qml/SignalBars.qml/
// SectionLabel.qml for the shared-component rationale (built for this
// AND Bluetooth.qml together, not duplicated per-file).
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Visual refresh: ToggleRow for the enable switch,
//             DeviceRow (two-line + SignalBars) for the network list,
//             SectionLabel for the "Networks" header. See DESIGN
//             NOTES. No logic changes — same Network.qml calls, same
//             connect flow, same password behavior.
// 2026-07-05  Popout open now triggers Network.refreshList() (a cheap,
//             non-forcing nmcli list) so the network list is current
//             without any background polling. Manual Rescan button
//             still does the heavier forced radio scan.
// 2026-07-03  Interactive rewrite: popout with toggle / rescan / network
//             list / connect-with-optional-password. Bar display
//             unchanged. Was display-only before.
// 2026-07-02  value-then-icon reorder; "NetworkManager Off" diagnosis.
// 2026-07-01  Initial display-only widget.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: barRow.implicitWidth
    implicitHeight: barRow.implicitHeight

    readonly property bool active: Network.wiredConnected || Network.wifiConnected

    // SSID the user has clicked in the list (pending password entry).
    property string selectedSsid: ""

    function statusText(): string {
        if (!Network.backendAvailable) return "NetworkManager Off";
        if (!Network.wifiEnabled) return "Wifi Off";
        return "Disconnected";
    }

    RowLayout {
        id: barRow
        spacing: Theme.spacingSmall

        Text {
            visible: Network.wifiConnected && !Network.wiredConnected
            text: Math.round(Network.wifiSignal * 100) + "%"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            visible: !root.active
            text: root.statusText()
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: Network.wiredConnected ? "\uef09" : "\uf1eb"
            color: (popout.open || barMouse.containsMouse)
                ? Theme.colorAccent
                : (root.active ? Theme.colorForeground : Theme.colorMuted)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: barMouse
        anchors.fill: barRow
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.selectedSsid = "";
            passwordInput.text = "";
            const opening = !popout.open;
            popout.open = opening;
            if (opening) Network.refreshList();
        }
    }

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "right"

        Text {
            text: "Wi-Fi"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        ToggleRow {
            Layout.fillWidth: true
            icon: "\uf1eb"
            text: "Wi-Fi"
            checked: Network.wifiEnabled
            onToggled: value => Network.setWifiEnabled(value)
        }

        MenuButton {
            Layout.fillWidth: true
            icon: "⟳"
            text: "Rescan"
            onClicked: Network.rescan()
        }

        MenuDivider { Layout.fillWidth: true }

        SectionLabel {
            visible: Network.wifiNetworks.length > 0
            text: "Networks"
        }

        // ---- Visible networks, strongest first, capped ----
        Repeater {
            model: Network.wifiNetworks.slice(0, 8)

            DeviceRow {
                required property var modelData
                readonly property bool isConnected: modelData.connected
                readonly property bool isSelected: root.selectedSsid === modelData.name
                readonly property bool isPending: Network.connecting && Network.pendingSsid === modelData.name

                Layout.fillWidth: true
                Layout.minimumWidth: 260
                title: modelData.name
                subtitle: isConnected ? "Connected" : (isPending ? "Connecting…" : "")
                statusColor: isConnected ? Theme.colorAccent
                    : (isSelected ? Theme.colorMuted : "transparent")
                pulsing: isPending
                showSignal: true
                signalStrength: modelData.signalStrength
                onClicked: {
                    if (isConnected) return;
                    root.selectedSsid = modelData.name;
                    passwordInput.text = "";
                    passwordInput.forceActiveFocus();
                }
            }
        }

        Text {
            visible: Network.wifiEnabled && Network.wifiNetworks.length === 0
            text: "No networks found"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        // ---- Password row — only when a network is selected ----
        MenuDivider {
            visible: root.selectedSsid !== ""
            Layout.fillWidth: true
        }

        Text {
            visible: root.selectedSsid !== ""
            text: "Connect to " + root.selectedSsid
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        Rectangle {
            visible: root.selectedSsid !== ""
            Layout.fillWidth: true
            implicitHeight: passwordInput.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: Theme.colorBackground
            border.color: passwordInput.activeFocus ? Theme.colorAccent : Theme.colorMuted
            border.width: 1

            TextInput {
                id: passwordInput
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                clip: true
                onAccepted: {
                    Network.connectTo(root.selectedSsid, text);
                }

                Text {
                    visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password (empty if open/saved)"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }

        MenuButton {
            visible: root.selectedSsid !== ""
            Layout.fillWidth: true
            icon: "→"
            text: Network.connecting ? "Connecting…" : "Connect"
            onClicked: Network.connectTo(root.selectedSsid, passwordInput.text)
        }

        // ---- Failure feedback from the service ----
        Text {
            visible: Network.lastError !== ""
            Layout.fillWidth: true
            text: Network.lastError
            wrapMode: Text.WordWrap
            color: Theme.colorUrgent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
}
