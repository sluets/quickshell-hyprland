import QtQuick
import QtQuick.Layouts
import qs.core

RowLayout {
    id: root
    required property string label
    required property real value
    property real minimum: 0.1
    property real maximum: 20
    property real step: 0.1
    property int decimals: 2
    property string suffix: ""
    property bool enabled: true
    property bool staged: false
    signal valueEdited(real value)

    Layout.fillWidth: true
    spacing: Theme.spacingMedium
    opacity: enabled ? 1 : 0.45

    Text {
        text: root.label
        Layout.preferredWidth: 235
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    Rectangle {
        Layout.preferredWidth: 180
        implicitHeight: Math.round(Theme.fontSize * 2.15)
        radius: Theme.radiusMedium
        color: Theme.colorControl
        border.width: 1
        border.color: input.activeFocus ? Theme.colorAccent : Theme.colorDivider

        RowLayout {
            anchors.fill: parent
            spacing: 0
            Rectangle {
                Layout.preferredWidth: 42; Layout.fillHeight: true
                color: minus.containsMouse ? Theme.colorHover : "transparent"
                Text { anchors.centerIn: parent; text: "−"; color: Theme.colorForeground; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
                MouseArea { id: minus; anchors.fill: parent; hoverEnabled: true; enabled: root.enabled; onClicked: root.valueEdited(Math.max(root.minimum, root.value - root.step)) }
            }
            Rectangle { width: 1; Layout.fillHeight: true; color: Theme.colorDivider }
            TextInput {
                id: input
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: Number(root.value).toFixed(root.decimals) + root.suffix
                color: root.staged ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                selectByMouse: true
                enabled: root.enabled
                onEditingFinished: {
                    const parsed = Number(text.replace(root.suffix, "").trim());
                    if (!isNaN(parsed)) root.valueEdited(Math.min(root.maximum, Math.max(root.minimum, parsed)));
                    text = Number(root.value).toFixed(root.decimals) + root.suffix;
                }
            }
            Rectangle { width: 1; Layout.fillHeight: true; color: Theme.colorDivider }
            Rectangle {
                Layout.preferredWidth: 42; Layout.fillHeight: true
                color: plus.containsMouse ? Theme.colorHover : "transparent"
                Text { anchors.centerIn: parent; text: "+"; color: Theme.colorForeground; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
                MouseArea { id: plus; anchors.fill: parent; hoverEnabled: true; enabled: root.enabled; onClicked: root.valueEdited(Math.min(root.maximum, root.value + root.step)) }
            }
        }
    }
    Item { Layout.fillWidth: true }
}
