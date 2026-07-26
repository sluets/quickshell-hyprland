// Fast workshop-oriented length converter for mil, inch, millimeter, and micron. // GPT 2026-07-26
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.core

Item {
    id: root

    signal requestStandard()
    signal requestClose()

    property string sourceUnit: "mil"
    property string inputText: "1"
    property string copiedUnit: ""

    readonly property var units: [
        { key: "mil", label: "mil", name: "Mils" },
        { key: "in", label: "in", name: "Inches" },
        { key: "mm", label: "mm", name: "Millimeters" },
        { key: "um", label: "µm", name: "Microns" }
    ]

    function focusInput(): void {
        Qt.callLater(function() {
            valueInput.forceActiveFocus();
            valueInput.selectAll();
        });
    }

    function parsedValue(): real {
        const normalized = inputText.trim().replace(",", ".");
        const value = Number(normalized);
        return isFinite(value) ? value : NaN;
    }

    function millimeters(): real {
        const value = parsedValue();
        if (!isFinite(value))
            return NaN;
        switch (sourceUnit) {
        case "mil": return value * 0.0254;
        case "in": return value * 25.4;
        case "um": return value * 0.001;
        default: return value;
        }
    }

    function unitLabel(unitKey: string): string {
        switch (unitKey) {
        case "mil": return "mil";
        case "in": return "in";
        case "um": return "µm";
        default: return "mm";
        }
    }

    function converted(unit: string): real {
        const mm = millimeters();
        if (!isFinite(mm))
            return NaN;
        switch (unit) {
        case "mil": return mm / 0.0254;
        case "in": return mm / 25.4;
        case "um": return mm * 1000;
        default: return mm;
        }
    }

    function formatNumber(value: real): string {
        if (!isFinite(value))
            return "—";
        if (Math.abs(value) < 1e-14)
            value = 0;
        const magnitude = Math.abs(value);
        let decimals = 6;
        if (magnitude >= 10000) decimals = 2;
        else if (magnitude >= 1000) decimals = 3;
        else if (magnitude >= 100) decimals = 4;
        else if (magnitude >= 1) decimals = 6;
        else decimals = 8;
        return value.toFixed(decimals).replace(/\.?0+$/, "");
    }

    function copyResult(unit: string): void {
        const text = formatNumber(converted(unit));
        if (text === "—")
            return;
        copyProcess.command = ["wl-copy", text];
        copyProcess.running = true;
        copiedUnit = unit;
        copiedReset.restart();
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            root.requestClose();
            event.accepted = true;
        }
    }

    Process { id: copyProcess }

    Timer {
        id: copiedReset
        interval: 1200
        onTriggered: root.copiedUnit = ""
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingLarge

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Calculator"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.15)
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: Theme.spacingSmall

                Rectangle {
                    implicitWidth: standardText.implicitWidth + Theme.spacingMedium * 2
                    implicitHeight: standardText.implicitHeight + Theme.spacingSmall * 2
                    radius: Theme.radiusMedium
                    color: standardMouse.containsMouse ? Theme.colorHover : Theme.colorSurface

                    Text {
                        id: standardText
                        anchors.centerIn: parent
                        text: "Standard"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        id: standardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.requestStandard()
                    }
                }

                Rectangle {
                    implicitWidth: unitsText.implicitWidth + Theme.spacingMedium * 2
                    implicitHeight: unitsText.implicitHeight + Theme.spacingSmall * 2
                    radius: Theme.radiusMedium
                    color: Theme.colorAccent

                    Text {
                        id: unitsText
                        anchors.centerIn: parent
                        text: "Units"
                        color: Theme.colorBackground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(Theme.fontSize * 3.6)
                radius: Theme.radiusMedium
                color: Theme.colorSurface
                border.width: valueInput.activeFocus ? 2 : 1
                border.color: valueInput.activeFocus ? Theme.colorAccent : Theme.colorMuted

                TextInput {
                    id: valueInput
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.inputText
                    color: Theme.colorForeground
                    selectionColor: Theme.colorAccent
                    selectedTextColor: Theme.colorBackground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 1.55)
                    font.bold: true
                    selectByMouse: true
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    onTextChanged: root.inputText = text
                    Keys.onEscapePressed: root.requestClose()
                }
            }

            Text {
                text: root.unitLabel(root.sourceUnit)
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.25)
                font.bold: true
                Layout.preferredWidth: Math.round(Theme.fontSize * 3.5)
                horizontalAlignment: Text.AlignHCenter
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Repeater {
                model: root.units

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Math.round(Theme.fontSize * 2.7)
                    radius: Theme.radiusMedium
                    color: root.sourceUnit === modelData.key
                        ? Theme.colorAccent
                        : unitMouse.containsMouse ? Theme.colorHover : Theme.colorSurface

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData.name
                        color: root.sourceUnit === parent.modelData.key ? Theme.colorBackground : Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: root.sourceUnit === parent.modelData.key
                    }

                    MouseArea {
                        id: unitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.sourceUnit = parent.modelData.key;
                            root.focusInput();
                        }
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: Theme.spacingMedium
            columnSpacing: Theme.spacingMedium

            Repeater {
                model: root.units

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Math.round(Theme.fontSize * 7)
                    radius: Theme.radiusMedium
                    color: resultMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                    border.width: root.sourceUnit === modelData.key ? 1 : 0
                    border.color: Theme.colorAccent

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingLarge
                        spacing: Theme.spacingSmall

                        Text {
                            width: parent.width
                            text: parent.parent.modelData.name
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            width: parent.width
                            text: root.formatNumber(root.converted(parent.parent.modelData.key))
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: parent.parent.modelData.key === "um"
                                ? Math.round(Theme.fontSize * 2.15)
                                : Math.round(Theme.fontSize * 1.7)
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.copiedUnit === parent.parent.modelData.key
                                ? "Copied"
                                : parent.parent.modelData.label + " · click to copy"
                            color: root.copiedUnit === parent.parent.modelData.key ? Theme.colorAccent : Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.85)
                        }
                    }

                    MouseArea {
                        id: resultMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.copyResult(parent.modelData.key)
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "1 in = 25.4 mm = 1000 mil = 25,400 µm"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.9)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
