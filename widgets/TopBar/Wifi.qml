// Combined Wi-Fi + Bluetooth connectivity widget. // GPT Rev 34
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: barRow.implicitWidth
    implicitHeight: barRow.implicitHeight

    readonly property bool networkActive: Network.wiredConnected || Network.wifiConnected
    readonly property bool adapterEnabled: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
    readonly property bool discovering: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.discovering
    readonly property bool _agentLoaded: BluetoothAgent.active

    property string selectedSsid: ""

    readonly property var pairedDevices: Bluetooth.devices.values
        .filter(device => device.bonded)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

    readonly property var newDevices: Bluetooth.devices.values
        .filter(device => !device.bonded)
        .sort((a, b) => (b.pairing - a.pairing) || a.name.localeCompare(b.name))

    RowLayout {
        id: barRow
        spacing: Theme.spacingLarge

        Text {
            text: Network.wiredConnected ? "\uef09" : "\uf1eb"
            color: (popout.open || barMouse.containsMouse)
                ? Theme.colorAccent
                : (root.networkActive ? Theme.colorForeground : Theme.colorMuted)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: "\uf294"
            color: (popout.open || barMouse.containsMouse)
                ? Theme.colorAccent
                : (root.adapterEnabled ? Theme.colorForeground : Theme.colorMuted)
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

        // Match the wider two-column connectivity concept rather than the
        // narrow single-column Wi-Fi menu. // GPT Rev 35
        Item { Layout.minimumWidth: 520; implicitHeight: 0 }

        onOpenChanged: {
            root.selectedSsid = "";
            if (open)
                Network.refreshList();

            if (Bluetooth.defaultAdapter !== null)
                Bluetooth.defaultAdapter.discovering = open && root.adapterEnabled;
        }

        SectionLabel { text: "Quick Toggles" }

        ConnectivitySectionCard {
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingLarge * 2

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "\uf1eb"
                    text: "Wi-Fi"
                    iconTextSpacing: Theme.spacingLarge
                    checked: Network.wifiEnabled
                    onToggled: value => Network.setWifiEnabled(value)
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "\uf294"
                    text: "Bluetooth"
                    iconTextSpacing: Theme.spacingLarge
                    checked: root.adapterEnabled
                    onToggled: value => {
                        if (Bluetooth.defaultAdapter !== null) {
                            Bluetooth.defaultAdapter.enabled = value;
                            Bluetooth.defaultAdapter.discovering = value && popout.open;
                        }
                    }
                }
            }

            MenuButton {
                Layout.fillWidth: true
                icon: "⟳"
                text: "Rescan Wi-Fi"
                onClicked: Network.rescan()
            }
        }

        SectionLabel {
            visible: Network.wifiEnabled
            text: "Available Networks"
        }

        ConnectivitySectionCard {
            visible: Network.wifiEnabled
            contentSpacing: 0

            Repeater {
                model: Network.wifiNetworks.slice(0, 8)

                ColumnLayout {
                    required property var modelData

                    readonly property bool isConnected: modelData.connected
                    readonly property bool isSelected: root.selectedSsid === modelData.name
                    readonly property bool isPending: Network.connecting && Network.pendingSsid === modelData.name

                    Layout.fillWidth: true
                    spacing: Theme.spacingSmall

                    DeviceRow {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 300
                        title: parent.modelData.name
                        subtitle: parent.isConnected ? "Connected" : (parent.isPending ? "Connecting…" : "")
                        statusColor: parent.isConnected
                            ? Theme.colorAccent
                            : (parent.isSelected ? Theme.colorMuted : "transparent")
                        pulsing: parent.isPending
                        showSignal: true
                        signalStrength: parent.modelData.signalStrength

                        onClicked: {
                            if (parent.isConnected)
                                return;

                            root.selectedSsid = parent.isSelected ? "" : parent.modelData.name;
                            if (root.selectedSsid !== "") {
                                inlinePassword.text = "";
                                Qt.callLater(() => inlinePassword.forceActiveFocus());
                            }
                        }
                    }

                    ColumnLayout {
                        visible: parent.isSelected && !parent.isConnected
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.spacingMedium
                        Layout.rightMargin: Theme.spacingSmall
                        Layout.bottomMargin: Theme.spacingSmall
                        spacing: Theme.spacingSmall

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: inlinePassword.implicitHeight + Theme.spacingSmall * 2
                            radius: Theme.radiusMedium
                            color: Theme.colorControl
                            border.width: 1
                            border.color: inlinePassword.activeFocus ? Theme.colorAccent : Theme.colorDivider

                            TextInput {
                                id: inlinePassword
                                anchors.fill: parent
                                anchors.margins: Theme.spacingSmall
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                color: Theme.colorForeground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                clip: true

                                onAccepted: Network.connectTo(modelData.name, text)

                                Text {
                                    visible: inlinePassword.text.length === 0 && !inlinePassword.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Password — leave empty if saved or open"
                                    color: Theme.colorMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Math.round(Theme.fontSize * 0.82)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingSmall

                            Item { Layout.fillWidth: true }

                            MenuButton {
                                icon: "×"
                                text: "Cancel"
                                onClicked: root.selectedSsid = ""
                            }

                            MenuButton {
                                icon: "→"
                                text: Network.connecting ? "Connecting…" : "Connect"
                                onClicked: Network.connectTo(modelData.name, inlinePassword.text)
                            }
                        }
                    }
                }
            }

            Text {
                visible: Network.wifiNetworks.length === 0
                Layout.fillWidth: true
                text: "No networks found"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

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

        SectionLabel { text: "Bluetooth Devices" }

        ConnectivitySectionCard {
            Repeater {
                model: root.pairedDevices

                DeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.minimumWidth: 300
                    title: modelData.name
                    subtitle: modelData.connected ? "Connected" : "Paired"
                    statusColor: modelData.connected ? Theme.colorAccent : "transparent"
                    onClicked: modelData.connected = !modelData.connected
                }
            }

            Text {
                visible: root.pairedDevices.length === 0
                text: root.adapterEnabled ? "No paired devices" : "Bluetooth is off"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Repeater {
                model: root.adapterEnabled ? root.newDevices : []

                DeviceRow {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.minimumWidth: 300
                    title: modelData.name || "Unknown device"
                    subtitle: modelData.pairing ? "Pairing…" : "Available"
                    statusColor: modelData.pairing ? Theme.colorMuted : "transparent"
                    pulsing: modelData.pairing
                    onClicked: modelData.pair()
                }
            }

            Text {
                visible: root.adapterEnabled && root.newDevices.length === 0
                text: root.discovering ? "Searching for devices…" : "No new devices"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }
}
