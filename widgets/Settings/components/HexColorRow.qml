import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: hexRow

    property string label: "Hex color"
    property string shownValue: ""
    property bool staged: false
    property var colorPickerHost: null

    signal hexStaged(string text)

    readonly property var presetSwatches: [
        "#ffffff", "#d0d0d0", "#a0a0a0", "#707070", "#404040", "#000000",
        "#e06c75", "#f53c3c", "#ff9955", "#e5c07b", "#98c379", "#f8f8f2",
        "#56b6c2", "#35e0b4", "#61afef", "#268bd2", "#c678dd", "#bd93f9",
        "#ff79c6", "#eb6f92", "#282a36", "#2e3440", "#1a1b26", "#4d4d4d"
    ]

    Layout.fillWidth: true
    implicitHeight: hexField.implicitHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    color: Theme.colorSurface
    border.width: 1
    border.color: hexField.hexValid ? Theme.colorMuted : Theme.colorUrgent

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingMedium

        Text {
            text: (hexRow.staged ? "● " : "") + hexRow.label
            color: hexRow.staged ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            id: swatchIcon
            implicitWidth: 22
            implicitHeight: 22
            radius: 4
            color: hexField.hexValid ? hexField.text : Theme.colorUrgent
            border.width: 1
            border.color: Theme.colorMuted

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (hexRow.colorPickerHost && hexRow.colorPickerHost.openColorPicker) {
                        hexRow.colorPickerHost.openColorPicker(
                            swatchIcon,
                            hexRow.presetSwatches,
                            function(hex) { hexRow.hexStaged(hex); });
                    }
                }
            }
        }

        TextInput {
            id: hexField

            function hexValidText(t) {
                return new RegExp("^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$").test(t);
            }

            property bool hexValid: false
            property string lastStagedByMe: ""

            onTextChanged: hexValid = hexValidText(text)

            Component.onCompleted: {
                text = hexRow.shownValue;
                hexValid = hexValidText(text);
            }

            color: hexValid ? Theme.colorForeground : Theme.colorUrgent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            selectByMouse: true
            maximumLength: 9

            onActiveFocusChanged: if (activeFocus) selectAll()

            onTextEdited: {
                if (hexValidText(text)) {
                    lastStagedByMe = text;
                    hexRow.hexStaged(text);
                }
            }

            function syncFromShown(): void {
                if (text !== hexRow.shownValue
                        && hexRow.shownValue !== lastStagedByMe) {
                    text = hexRow.shownValue;
                    lastStagedByMe = "";
                }
            }

            Connections {
                target: hexRow
                function onShownValueChanged(): void { hexField.syncFromShown(); }
            }

            onVisibleChanged: if (visible) syncFromShown()
        }
    }
}
