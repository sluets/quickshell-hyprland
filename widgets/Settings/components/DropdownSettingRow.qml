import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core

Rectangle {
    id: root

    required property string label
    required property var options
    required property string shownValue
    property string description: ""
    property bool staged: false
    property int controlColumnX: 235
    property int controlWidth: 250
    signal picked(string value)

    Layout.fillWidth: true
    implicitHeight: 44
    radius: Theme.radiusMedium
    color: rowMouse.containsMouse ? Theme.colorHover : "transparent"

    Rectangle {
        visible: root.staged
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: Math.max(18, parent.height - Theme.spacingMedium * 2)
        radius: 2
        color: Theme.colorAccent
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingMedium
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingSmall

        Text {
            id: labelText
            text: root.label
            color: root.staged ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            visible: root.description !== ""
            text: "ⓘ"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.78)
            anchors.verticalCenter: labelText.verticalCenter
        }
    }

    ComboBox {
        id: combo

        readonly property real rowAvailableWidth: Math.max(0, root.width - Theme.spacingMedium * 2)
        readonly property real resolvedWidth: Math.min(root.controlWidth, rowAvailableWidth)
        readonly property real resolvedLeftMargin: Math.min(
            root.controlColumnX,
            Math.max(Theme.spacingMedium, root.width - resolvedWidth - Theme.spacingMedium)
        )

        anchors.left: parent.left
        anchors.leftMargin: resolvedLeftMargin
        anchors.verticalCenter: parent.verticalCenter
        width: resolvedWidth
        height: 34
        model: root.options
        textRole: "text"
        valueRole: "value"
        currentIndex: {
            for (let i = 0; i < root.options.length; ++i)
                if (root.options[i].value === root.shownValue) return i;
            return 0;
        }
        onActivated: index => root.picked(root.options[index].value)
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize

        contentItem: Text {
            leftPadding: Theme.spacingMedium
            rightPadding: Theme.spacingLarge
            text: combo.displayText
            color: root.staged ? Theme.colorAccent : Theme.colorForeground
            font: combo.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Text {
            x: combo.width - width - Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            text: "▾"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.75)
        }

        background: Rectangle {
            radius: Theme.radiusMedium
            color: combo.hovered ? Theme.colorHover : Theme.colorControl
            border.width: combo.activeFocus ? 2 : 1
            border.color: combo.activeFocus ? Theme.colorAccent : Theme.colorDivider
        }

        popup: Popup {
            y: combo.height + 2
            width: combo.width
            implicitHeight: Math.min(contentItem.implicitHeight + 2, 280)
            padding: 1

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: combo.popup.visible ? combo.delegateModel : null
                currentIndex: combo.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator {}
            }

            background: Rectangle {
                radius: Theme.radiusMedium
                color: Theme.colorSurface
                border.width: 1
                border.color: Theme.colorDivider
            }
        }

        delegate: ItemDelegate {
            required property var modelData
            required property int index
            width: combo.width
            height: 36
            highlighted: combo.highlightedIndex === index

            contentItem: Text {
                leftPadding: Theme.spacingMedium
                rightPadding: Theme.spacingMedium
                text: modelData.text
                color: parent.highlighted ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                radius: Math.max(2, Math.round(Theme.radiusMedium * 0.65))
                color: parent.highlighted ? Theme.colorHover : "transparent"
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
    }

    ToolTip.visible: root.description !== "" && rowMouse.containsMouse
    ToolTip.text: root.description
    ToolTip.delay: 450
}
