// Screen color picker with persistent bounded history. // GPT
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

FloatingWindow {
    id: root

    title: "Quickshell Color Picker"
    color: Theme.colorBackground
    implicitWidth: Math.round(Theme.fontSize * 42)
    implicitHeight: Math.round(Theme.fontSize * 38)
    minimumSize: Qt.size(Math.round(Theme.fontSize * 34), Math.round(Theme.fontSize * 30))
    maximumSize: Qt.size(1000, 900)
    visible: shown

    property bool shown: false
    property bool loaded: false
    property bool clearArmed: false
    property var currentColor: ({})
    property string feedback: ""
    readonly property bool hasColor: currentColor.hex !== undefined && currentColor.hex !== ""
    readonly property string helperPath: Quickshell.shellPath("scripts/color-picker.py")

    function open(): void {
        shown = true;
        if (!loaded && !loadProcess.running)
            loadProcess.running = true;
        Qt.callLater(function() { keyScope.forceActiveFocus(); });
    }

    function close(): void {
        shown = false;
    }

    function toggle(): void {
        if (shown) close(); else open();
    }

    function setHistory(items: var): void {
        historyModel.clear();
        if (!items)
            return;
        for (let i = 0; i < items.length; i++)
            historyModel.append(items[i]);
    }

    function selectColor(item: var): void {
        currentColor = {
            hex: item.hex,
            rgb: item.rgb,
            hsl: item.hsl,
            r: item.r,
            g: item.g,
            b: item.b,
            h: item.h,
            s: item.s,
            l: item.l
        };
    }

    function pickColor(): void {
        if (pickProcess.running)
            return;
        feedback = "Pick a pixel…";
        pickProcess.running = true;
    }

    function copyValue(value: string): void {
        if (!value || copyProcess.running)
            return;
        copyProcess.command = ["python3", helperPath, "copy", value];
        copyProcess.running = true;
    }

    function requestClear(): void {
        if (!clearArmed) {
            clearArmed = true;
            clearArmTimer.restart();
            return;
        }
        clearArmTimer.stop();
        clearArmed = false;
        clearProcess.running = true;
    }

    onClosed: shown = false

    ListModel { id: historyModel }

    Process {
        id: loadProcess
        command: ["python3", root.helperPath, "load"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const items = JSON.parse(text || "[]");
                    root.setHistory(items);
                    if (items.length > 0)
                        root.selectColor(items[0]);
                    root.loaded = true;
                } catch (error) {
                    root.feedback = "Could not load history";
                }
            }
        }
    }

    Process {
        id: pickProcess
        command: ["python3", root.helperPath, "pick"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text || "{}");
                    if (result.cancelled) {
                        root.feedback = "Selection cancelled";
                    } else if (result.error) {
                        root.feedback = result.error;
                    } else if (result.color) {
                        root.selectColor(result.color);
                        root.setHistory(result.history);
                        root.feedback = "Color selected";
                    }
                } catch (error) {
                    root.feedback = "Picker returned invalid data";
                }
                feedbackTimer.restart();
                Qt.callLater(function() { keyScope.forceActiveFocus(); });
            }
        }
    }

    Process {
        id: copyProcess
        onExited: function(code, status) {
            root.feedback = code === 0 ? "Copied" : "Copy failed";
            feedbackTimer.restart();
        }
    }

    Process {
        id: clearProcess
        command: ["python3", root.helperPath, "clear"]
        onExited: function(code, status) {
            if (code === 0) {
                historyModel.clear();
                root.feedback = "History cleared";
            } else {
                root.feedback = "Could not clear history";
            }
            feedbackTimer.restart();
        }
    }

    Timer {
        id: feedbackTimer
        interval: 1800
        repeat: false
        onTriggered: root.feedback = ""
    }

    Timer {
        id: clearArmTimer
        interval: 3000
        repeat: false
        onTriggered: root.clearArmed = false
    }

    Item {
        id: keyScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.pickColor();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMedium

                Text {
                    text: "Color Picker"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 1.15)
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: Math.round(Theme.fontSize * 11)
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    implicitHeight: Math.round(Theme.fontSize * 2.5)
                    radius: Theme.radiusMedium
                    color: pickMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                    border.width: 1
                    border.color: Theme.colorAccent

                    Text {
                        id: pickLabel
                        anchors.centerIn: parent
                        text: pickProcess.running ? "Picking…" : "Pick Screen Color"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        id: pickMouse
                        anchors.fill: parent
                        enabled: !pickProcess.running
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pickColor()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(Theme.fontSize * 9)
                radius: Theme.radiusMedium
                color: Theme.colorSurface
                border.width: 1
                border.color: Theme.colorMuted

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingLarge

                    Rectangle {
                        Layout.preferredWidth: Math.round(Theme.fontSize * 7)
                        Layout.fillHeight: true
                        radius: Theme.radiusMedium
                        color: root.hasColor ? root.currentColor.hex : Theme.colorBackground
                        border.width: 1
                        border.color: Theme.colorMuted
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall

                        Text {
                            text: root.hasColor ? root.currentColor.hex : "No color selected"
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 1.35)
                            font.bold: true
                        }

                        ValueRow {
                            Layout.fillWidth: true
                            label: "HEX"
                            value: root.hasColor ? root.currentColor.hex : "—"
                            enabled: root.hasColor
                            onCopyRequested: root.copyValue(value)
                        }

                        ValueRow {
                            Layout.fillWidth: true
                            label: "RGB"
                            value: root.hasColor ? root.currentColor.rgb : "—"
                            enabled: root.hasColor
                            onCopyRequested: root.copyValue(value)
                        }

                        ValueRow {
                            Layout.fillWidth: true
                            label: "HSL"
                            value: root.hasColor ? root.currentColor.hsl : "—"
                            enabled: root.hasColor
                            onCopyRequested: root.copyValue(value)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Recent Colors"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Text {
                    text: historyModel.count + "/16"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.9)
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: Math.round(Theme.fontSize * 8.5)
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    implicitHeight: Math.round(Theme.fontSize * 2.2)
                    radius: Theme.radiusMedium
                    color: clearMouse.containsMouse ? Theme.colorHover : "transparent"
                    border.width: 1
                    border.color: root.clearArmed ? Theme.colorAccent : Theme.colorMuted

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: root.clearArmed ? "Click again" : "Clear History"
                        color: root.clearArmed ? Theme.colorAccent : Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 0.9)
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        enabled: historyModel.count > 0 && !clearProcess.running
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.requestClear()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMedium
                color: Theme.colorSurface
                border.width: 1
                border.color: Theme.colorMuted
                clip: true

                GridView {
                    id: historyGrid
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    cellWidth: Math.max(Math.round(Theme.fontSize * 8.5), width / 4)
                    cellHeight: Math.round(Theme.fontSize * 6.2)
                    model: historyModel
                    clip: true

                    delegate: Rectangle {
                        required property string hex
                        required property string rgb
                        required property string hsl
                        required property int r
                        required property int g
                        required property int b
                        required property int h
                        required property int s
                        required property int l

                        width: historyGrid.cellWidth - Theme.spacingSmall
                        height: historyGrid.cellHeight - Theme.spacingSmall
                        radius: Theme.radiusMedium
                        color: historyMouse.containsMouse ? Theme.colorHover : Theme.colorBackground
                        border.width: 1
                        border.color: root.hasColor && root.currentColor.hex === hex ? Theme.colorAccent : Theme.colorMuted

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            spacing: Theme.spacingSmall

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: Math.max(2, Math.round(Theme.radiusMedium / 2))
                                color: hex
                                border.width: 1
                                border.color: Theme.colorMuted
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: hex
                                color: Theme.colorForeground
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.round(Theme.fontSize * 0.85)
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: historyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectColor({ hex: hex, rgb: rgb, hsl: hsl, r: r, g: g, b: b, h: h, s: s, l: l })
                            onDoubleClicked: root.copyValue(hex)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.loaded && historyModel.count === 0
                        text: "Picked colors will appear here"
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.preferredWidth: Math.round(Theme.fontSize * 11)
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    text: root.feedback
                    color: Theme.colorAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.9)
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: "Enter/Space: pick  •  Double-click history: copy HEX  •  Esc: close"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.8)
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }
    }

    component ValueRow: Rectangle {
        id: valueRoot
        property string label: ""
        property string value: ""
        signal copyRequested()

        implicitHeight: Math.round(Theme.fontSize * 1.8)
        radius: Math.max(2, Math.round(Theme.radiusMedium / 2))
        color: valueMouse.containsMouse && enabled ? Theme.colorHover : "transparent"

        RowLayout {
            anchors.fill: parent
            spacing: Theme.spacingMedium

            Text {
                Layout.preferredWidth: Math.round(Theme.fontSize * 3)
                text: valueRoot.label
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.85)
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: valueRoot.value
                color: valueRoot.enabled ? Theme.colorForeground : Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            Text {
                text: "Copy"
                visible: valueRoot.enabled
                color: Theme.colorAccent
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.85)
            }
        }

        MouseArea {
            id: valueMouse
            anchors.fill: parent
            enabled: valueRoot.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: valueRoot.copyRequested()
        }
    }
}
