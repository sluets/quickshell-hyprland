//=============================================================================
// widgets/TopBar/Wifi.qml
//
// The Connectivity popout: quick toggles, current network, available
// Wi-Fi networks, Bluetooth devices. Network/Bluetooth ownership stays in
// services/Network.qml and Quickshell.Bluetooth — this file is
// presentation and interaction only.
//
//=============================================================================
// THE MISCLICK PROBLEM AND WHAT FIXES IT (2026-07-29)
//=============================================================================
//
// Reported: the menu changes size and rows move while you're reaching for
// one, so you click the wrong thing. There were THREE independent causes,
// and only the third is the one people notice first:
//
//   1. SIZE. Both lists were unbounded — the card's height was the number
//      of results. An async nmcli result or a newly discovered Bluetooth
//      device grew the card, moving everything below it (and the whole
//      popout's height) mid-reach.
//   2. ORDER. `Network.wifiNetworks` is sorted by signal strength, and
//      signal strength changes every scan. Rows didn't just move down,
//      they SWAPPED. Clicking "CoffeeShop_WiFi" and connecting to the
//      neighbour's network is the worst version of this bug, because it
//      looks like a UI glitch and behaves like a security one.
//   3. TIMING. Nothing the user did caused either. The list refreshed on
//      open, and Bluetooth discovery ran continuously for as long as the
//      popout was open, so devices trickled in forever.
//
// The fixes, in the same order:
//
//   1. Both lists are FIXED-HEIGHT scroll areas, sized in rows
//      (`rowHeight * N`). Contents changing can never change the popout's
//      geometry. This is also what the maintainer's mockup shows — a
//      scrollbar on the networks card.
//   2. The Wi-Fi list is a FROZEN SNAPSHOT (`wifiRows`), adopted only
//      when the user asks for a scan (or on the first open, when the list
//      is empty and there is nothing to misclick). Connected/connecting
//      state is still LIVE, matched by SSID — a row can change its
//      subtitle, it just can't move. The service's own post-connect
//      refreshList() no longer reshuffles the list under the cursor.
//   3. Scanning is EXPLICIT. Wi-Fi has a Scan button and shows how stale
//      the list is; Bluetooth discovery only runs while the user has
//      asked for it, auto-stops after 30 s, and stops on close. Radio
//      time and battery are not spent because a menu is open.
//
// The general rule worth keeping: a list the user is about to click into
// may change its CONTENTS, but must not change its GEOMETRY or its ORDER
// unless the user asked for it.
//
// Password entry moved OUT of the list (it used to expand inline inside
// the rows, reflowing everything below it) into a fixed panel below the
// card. One TextInput instead of one per row, and the list stays put.
//
//=============================================================================
// WIDTH (2026-07-29 — same trap as Volume.qml, worth knowing once)
//=============================================================================
//
// This popout was much wider than its contents needed, for two reasons
// that both look like design decisions rather than bugs:
//
//   1. `elide: Text.ElideRight` does NOT reduce a Text's implicitWidth —
//      an elided Text still reports its full single-line width to the
//      layout. One long SSID or error string set the width of the whole
//      menu, while itself appearing neatly elided.
//   2. The min width was a floor ABOVE the natural content width
//      (fontSize * 40), so the rest was dead space.
//
// Fixed with `Layout.preferredWidth: 0` next to `Layout.fillWidth: true`
// on every elided/wrapping Text, and a floor (fontSize * 25) that sits
// just under the widest row. The widest row here is the QUICK TOGGLES
// card — two ToggleRows whose labels are deliberately left able to set
// their width, since "Bluetooth" eliding would be worse than the pixels.
//
// Rows inside the ScrollLists are exempt from all of this: content inside
// a Flickable is decoupled from the layout above it, which is a second
// reason the fixed-height lists were the right call.
//
//=============================================================================
// NOT DONE HERE (deliberate, needs the maintainer's call)
//=============================================================================
//
// - Airplane-mode and VPN toggles from the mockup: both need new service
//   work (`nmcli radio all off` + adapter off; VPN needs connection-profile
//   enumeration). Not invented offline.
// - "Network Settings" / "Bluetooth Settings" footer buttons: they'd have
//   to launch external tools (nm-connection-editor, blueman-manager) that
//   may not be installed. Say the word and they go in with a
//   presence check.
// - Per-device ⋮ menu (forget/disconnect). `Network.forget(ssid)` already
//   exists for Wi-Fi; Bluetooth would need a small popup.
//
//=============================================================================
// ⚠ WRITTEN OFFLINE — NOT YET RUN LIVE. Test checklist:
//   - Open the popout: NOTHING should scan unless the network list was
//     empty. No size change on open, ever.
//   - Press Scan (Wi-Fi): spinner text appears, list is replaced when
//     results land, "Scanned just now" appears, popout height unchanged.
//   - With the popout open, walk around / toggle a hotspot: the list must
//     NOT reorder on its own.
//   - Select a secured network: highlight + panel below the card;
//     password + Enter connects; Cancel dismisses. Row order unchanged.
//   - Press Scan (Bluetooth): discovery starts, devices append at the
//     BOTTOM (never inserted mid-list), auto-stops after 30 s, Stop
//     works, closing the popout stops discovery (verify with
//     `bluetoothctl show | grep Discovering`).
//   - Toggle Wi-Fi off: networks section hides; toggle back on: it
//     returns and auto-scans once (list was cleared).
//   - fontScale 1.0 / 1.5: five visible network rows at both, no clipped
//     text, scrollbar appears when there are more.
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-29  (Claude Fable 5) Width fix — see the WIDTH section above.
// 2026-07-29  (Claude Fable 5) Rebuilt around explicit scanning, frozen
//             row order and fixed-height lists (see the section above).
//             Added the CURRENT NETWORK card and a header row; password
//             entry moved out of the list; all sizes font-relative.
// 2026-07-xx  (GPT Rev 34/35) Combined Wi-Fi + Bluetooth widget.
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

    readonly property bool networkActive: Network.wiredConnected || Network.wifiConnected
    readonly property bool adapterEnabled: Bluetooth.defaultAdapter !== null
        && Bluetooth.defaultAdapter.enabled
    readonly property bool discovering: Bluetooth.defaultAdapter !== null
        && Bluetooth.defaultAdapter.discovering
    // Referenced so the agent singleton is instantiated (pairing prompts).
    readonly property bool _agentLoaded: BluetoothAgent.active

    // ---- Uniform row geometry (see the notes up top) ----------------------
    readonly property int rowHeight: Math.max(42, Math.round(Theme.fontSize * 3.0))
    readonly property int wifiListRows: 5
    readonly property int btListRows: 4

    // ---- Frozen Wi-Fi list ------------------------------------------------
    // Display order is adopted from the service ONLY when the user scans.
    property var wifiRows: []
    property bool wifiAdoptPending: false
    property double wifiScannedMs: 0
    property string selectedSsid: ""

    // ---- Explicit Bluetooth discovery ------------------------------------
    property bool btScanActive: false
    // Append-only during a scan so existing rows never shift underneath
    // the cursor; cleared when the popout closes so no reference to a
    // destroyed device object outlives the session.
    property var btNewRows: []

    property double nowMs: Date.now()

    readonly property var pairedDevices: Bluetooth.devices.values
        .filter(device => device.bonded)
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

    // ---- Wi-Fi helpers ----------------------------------------------------

    function adoptWifiList() {
        wifiRows = Network.wifiNetworks.slice(0, 24);
        wifiScannedMs = Date.now();
        nowMs = wifiScannedMs;
    }

    function startWifiScan() {
        if (!Network.wifiEnabled || Network.scanning)
            return;
        wifiAdoptPending = true;
        Network.rescan();
    }

    function qualityWord(strength) {
        if (strength >= 0.75) return "Excellent";
        if (strength >= 0.5) return "Good";
        if (strength >= 0.25) return "Fair";
        return "Weak";
    }

    function scanAgeText() {
        if (Network.scanning)
            return "Scanning…";
        if (wifiScannedMs <= 0)
            return "Not scanned";
        const seconds = Math.max(0, Math.round((nowMs - wifiScannedMs) / 1000));
        if (seconds < 45)
            return "Scanned just now";
        const minutes = Math.round(seconds / 60);
        return "Scanned " + minutes + "m ago";
    }

    function isRowConnected(name) {
        return Network.wifiConnected && Network.wifiSsid === name;
    }

    function isRowPending(name) {
        return Network.connecting && Network.pendingSsid === name;
    }

    Connections {
        target: Network
        // Only a user-requested scan is allowed to replace the display
        // order. The service also refreshes after connect attempts; that
        // result updates nothing visible except live connected state.
        function onWifiNetworksChanged() {
            if (!root.wifiAdoptPending)
                return;
            root.wifiAdoptPending = false;
            root.adoptWifiList();
        }
        function onWifiEnabledChanged() {
            if (!Network.wifiEnabled) {
                root.wifiRows = [];
                root.wifiScannedMs = 0;
                root.selectedSsid = "";
            } else if (popout.open) {
                // The radio needs a moment after `nmcli radio wifi on`
                // before a scan returns anything.
                wifiEnableDelay.restart();
            }
        }
    }

    Timer {
        id: wifiEnableDelay
        interval: 1500
        onTriggered: root.startWifiScan()
    }

    // ---- Bluetooth helpers ------------------------------------------------

    function startBtScan() {
        if (Bluetooth.defaultAdapter === null || !adapterEnabled)
            return;
        btNewRows = [];
        btScanActive = true;
        Bluetooth.defaultAdapter.discovering = true;
        btScanTimeout.restart();
    }

    function stopBtScan() {
        btScanActive = false;
        btScanTimeout.stop();
        if (Bluetooth.defaultAdapter !== null)
            Bluetooth.defaultAdapter.discovering = false;
    }

    // Polled rather than signal-driven: one cheap list walk a second
    // while the user is explicitly scanning, and no dependence on the
    // exact change-signal name of an ObjectModel's `values`.
    function pollBtDevices() {
        const live = Bluetooth.devices.values.filter(d => d !== null && !d.bonded);
        // Keep existing rows in place (dropping any the adapter lost),
        // then append newcomers at the end.
        const next = btNewRows.filter(d => live.indexOf(d) !== -1);
        for (const device of live) {
            if (next.indexOf(device) === -1)
                next.push(device);
        }
        if (next.length !== btNewRows.length)
            btNewRows = next;
    }

    Timer {
        id: btScanTimeout
        interval: 30000
        onTriggered: root.stopBtScan()
    }

    Timer {
        id: btPoll
        interval: 1000
        repeat: true
        running: root.btScanActive
        onTriggered: root.pollBtDevices()
    }

    // Only ticks while the popout is open — it exists to age the
    // "Scanned Xm ago" label, nothing else.
    Timer {
        interval: 15000
        repeat: true
        running: popout.open
        onTriggered: root.nowMs = Date.now()
    }

    // ---- Shared bits ------------------------------------------------------

    component Chip: Rectangle {
        id: chip
        property string label: ""
        property bool selected: false
        signal clicked
        implicitWidth: chipText.implicitWidth + Theme.spacingMedium * 2
        implicitHeight: chipText.implicitHeight + Theme.spacingSmall * 2
        Layout.minimumWidth: implicitWidth
        radius: Theme.radiusMedium
        color: selected
            ? Theme.colorSelected
            : (chipMouse.containsMouse ? Theme.colorHover : Theme.colorControl)
        border.width: 1
        border.color: selected ? Theme.colorAccent : Theme.colorDivider

        Behavior on color {
            ColorAnimation {
                duration: Theme.animationDuration
                easing.type: Theme.animationEasing
            }
        }

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(11, Math.round(Theme.fontSize * 0.88))
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    // A fixed-height scrolling column. Height is `rows` tall ALWAYS —
    // that constancy is the whole point (see the notes up top).
    component ScrollList: Item {
        id: list
        property int rows: 4
        default property alias content: listColumn.data

        Layout.fillWidth: true
        implicitHeight: root.rowHeight * rows

        Flickable {
            id: flick
            anchors.fill: parent
            contentWidth: width
            contentHeight: listColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            clip: true

            ColumnLayout {
                id: listColumn
                width: flick.width
                spacing: 0
            }

            WheelHandler {
                target: null
                onWheel: event => {
                    const delta = event.pixelDelta.y !== 0
                        ? event.pixelDelta.y
                        : event.angleDelta.y / 2;
                    const maximum = Math.max(0, flick.contentHeight - flick.height);
                    flick.contentY = Math.max(0, Math.min(maximum, flick.contentY - delta));
                    event.accepted = true;
                }
            }
        }

        // Hand-rolled indicator rather than QQC2's ScrollBar, per this
        // project's "plain primitives over Controls styling" convention.
        Rectangle {
            visible: flick.contentHeight > flick.height + 1
            width: 3
            radius: 1.5
            x: list.width - width
            y: flick.contentHeight > 0
                ? (flick.contentY / flick.contentHeight) * list.height : 0
            height: Math.max(Theme.fontSize,
                list.height * (flick.height / Math.max(1, flick.contentHeight)))
            color: Theme.colorMuted
            opacity: 0.45
        }
    }

    // ---- Bar widget --------------------------------------------------------

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

    // ---- Popout ------------------------------------------------------------

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "right"

        onOpenChanged: {
            if (open) {
                root.selectedSsid = "";
                root.nowMs = Date.now();
                // Only scan unprompted when there is nothing to show —
                // an empty card has nothing to misclick.
                if (Network.wifiEnabled && root.wifiRows.length === 0)
                    root.startWifiScan();
            } else {
                root.stopBtScan();
                root.btNewRows = [];
                root.selectedSsid = "";
            }
        }

        Item {
            Layout.minimumWidth: Math.max(400, Math.round(Theme.fontSize * 25))
            implicitHeight: 0
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            Text {
                text: "\uf1eb"
                color: Theme.colorAccent
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.2)
            }

            Text {
                text: "Connectivity"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.35)
                font.bold: true
            }
        }

        // ---- Quick toggles -------------------------------------------------
        SectionLabel { text: "QUICK TOGGLES" }
        ConnectivitySectionCard {
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingLarge

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "\uf1eb"
                    text: "Wi-Fi"
                    iconTextSpacing: Theme.spacingMedium
                    checked: Network.wifiEnabled
                    onToggled: value => Network.setWifiEnabled(value)
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "\uf294"
                    text: "Bluetooth"
                    iconTextSpacing: Theme.spacingMedium
                    checked: root.adapterEnabled
                    onToggled: value => {
                        if (Bluetooth.defaultAdapter !== null) {
                            Bluetooth.defaultAdapter.enabled = value;
                            if (!value)
                                root.stopBtScan();
                        }
                    }
                }
            }
        }

        // ---- Current network -----------------------------------------------
        SectionLabel { text: "CURRENT NETWORK" }
        ConnectivitySectionCard {
            // Fixed height: this card must never resize, whatever it shows.
            Item {
                Layout.fillWidth: true
                implicitHeight: root.rowHeight

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingSmall
                    anchors.rightMargin: Theme.spacingSmall
                    spacing: Theme.spacingMedium

                    Text {
                        text: Network.wiredConnected
                            ? "\uef09"
                            : (Network.wifiConnected ? "\uf1eb" : "\uf127")
                        color: root.networkActive ? Theme.colorAccent : Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            // Elided Texts report their full width to the
                            // layout — a long SSID must not set the
                            // popout's width. Same for every one below.
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: Network.wiredConnected
                                ? "Wired connection"
                                : (Network.wifiConnected
                                    ? Network.wifiSsid : "Not connected")
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            text: root.networkActive
                                ? "Connected"
                                : (Network.wifiEnabled
                                    ? "Pick a network below" : "Wi-Fi is off")
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.8)
                            elide: Text.ElideRight
                        }
                    }

                    ColumnLayout {
                        visible: Network.wifiConnected && !Network.wiredConnected
                        spacing: 1

                        SignalBars {
                            Layout.alignment: Qt.AlignRight
                            strength: Network.wifiSignal
                        }

                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: root.qualityWord(Network.wifiSignal)
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.75))
                        }
                    }
                }
            }
        }

        // ---- Available networks --------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            visible: Network.wifiEnabled
            spacing: Theme.spacingSmall

            SectionLabel { text: "AVAILABLE NETWORKS" }

            // Absorbs the status text's width changes so the Scan chip
            // never moves (a moving button is its own misclick source).
            Item { Layout.fillWidth: true }

            Text {
                text: root.scanAgeText()
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.8))
            }

            Chip {
                label: Network.scanning ? "Scanning" : "Scan"
                selected: Network.scanning
                onClicked: root.startWifiScan()
            }
        }

        ConnectivitySectionCard {
            visible: Network.wifiEnabled
            contentSpacing: 0

            ScrollList {
                rows: root.wifiListRows

                Repeater {
                    model: root.wifiRows

                    DeviceRow {
                        required property var modelData
                        readonly property bool isConnected: root.isRowConnected(modelData.name)
                        readonly property bool isPending: root.isRowPending(modelData.name)
                        readonly property bool isSelected: root.selectedSsid === modelData.name

                        Layout.fillWidth: true
                        Layout.preferredHeight: root.rowHeight
                        // A locked network shows the padlock inline with
                        // its name, as in the mockup.
                        title: modelData.name
                            + ((modelData.security || "").length > 0 ? "  \uf023" : "")
                        subtitle: isConnected
                            ? "Connected"
                            : (isPending ? "Connecting…"
                                : (isSelected ? "Selected" : ""))
                        statusColor: isConnected
                            ? Theme.colorAccent
                            : (isSelected ? Theme.colorMuted : "transparent")
                        pulsing: isPending
                        showSignal: true
                        signalStrength: modelData.signalStrength

                        onClicked: {
                            if (isConnected)
                                return;
                            root.selectedSsid = isSelected ? "" : modelData.name;
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.margins: Theme.spacingMedium
                    visible: root.wifiRows.length === 0
                    text: Network.scanning
                        ? "Searching for networks…"
                        : "No networks yet — press Scan."
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Connect panel — deliberately OUTSIDE the list, so selecting a
        // network can't reflow the rows around it.
        ConnectivitySectionCard {
            visible: root.selectedSsid !== ""
            contentSpacing: Theme.spacingSmall

            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                text: "Connect to " + root.selectedSsid
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: passwordInput.implicitHeight + Theme.spacingSmall * 2
                radius: Theme.radiusMedium
                color: Theme.colorControl
                border.width: 1
                border.color: passwordInput.activeFocus
                    ? Theme.colorAccent : Theme.colorDivider

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

                    onAccepted: Network.connectTo(root.selectedSsid, text)

                    Text {
                        visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
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

                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    visible: Network.lastError !== ""
                    text: Network.lastError
                    color: Theme.colorUrgent
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.8)
                    elide: Text.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                    visible: Network.lastError === ""
                }

                Chip {
                    label: "Cancel"
                    onClicked: root.selectedSsid = ""
                }

                Chip {
                    label: Network.connecting ? "Connecting…" : "Connect"
                    selected: true
                    onClicked: Network.connectTo(root.selectedSsid, passwordInput.text)
                }
            }
        }

        // ---- Bluetooth devices ---------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            SectionLabel { text: "BLUETOOTH DEVICES" }

            Item { Layout.fillWidth: true }

            Text {
                visible: root.btScanActive
                text: "Scanning…"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.8))
            }

            Chip {
                enabled: root.adapterEnabled
                opacity: root.adapterEnabled ? 1.0 : 0.45
                label: root.btScanActive ? "Stop" : "Scan"
                selected: root.btScanActive
                onClicked: {
                    if (!root.adapterEnabled)
                        return;
                    if (root.btScanActive)
                        root.stopBtScan();
                    else
                        root.startBtScan();
                }
            }
        }

        ConnectivitySectionCard {
            contentSpacing: 0

            ScrollList {
                rows: root.btListRows

                Repeater {
                    model: root.pairedDevices

                    DeviceRow {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.rowHeight
                        title: modelData?.name || "Unknown device"
                        subtitle: (modelData?.connected ? "Connected" : "Paired")
                            // Strict === true: if a Quickshell version
                            // doesn't expose batteryAvailable, undefined
                            // fails the test instead of printing "NaN%".
                            + (modelData?.batteryAvailable === true
                                ? " · " + Math.round(modelData.battery * 100) + "%" : "")
                        statusColor: modelData?.connected
                            ? Theme.colorAccent : "transparent"
                        onClicked: {
                            if (modelData)
                                modelData.connected = !modelData.connected;
                        }
                    }
                }

                Repeater {
                    model: root.btNewRows

                    DeviceRow {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.rowHeight
                        title: modelData?.name || "Unknown device"
                        subtitle: modelData?.pairing ? "Pairing…" : "Available — click to pair"
                        statusColor: modelData?.pairing ? Theme.colorMuted : "transparent"
                        pulsing: modelData?.pairing ?? false
                        onClicked: {
                            if (modelData)
                                modelData.pair();
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.margins: Theme.spacingMedium
                    visible: root.pairedDevices.length === 0 && root.btNewRows.length === 0
                    text: root.adapterEnabled
                        ? "No paired devices — press Scan to find one."
                        : "Bluetooth is off."
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
