import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: section

    property string title: ""
    property string summary: ""
    property bool expanded: false
    default property alias contentData: content.data

    Layout.fillWidth: true
    spacing: Theme.spacingSmall

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: headerMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
        border.width: 1
        border.color: section.expanded ? Theme.colorAccent : Theme.colorMuted

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingMedium
            anchors.rightMargin: Theme.spacingMedium
            spacing: Theme.spacingMedium

            Text {
                text: section.expanded ? "▾" : "▸"
                color: Theme.colorAccent
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Text {
                text: section.title
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }

            Text {
                visible: !section.expanded && section.summary !== ""
                Layout.fillWidth: true
                text: section.summary
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.78)
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            Item { visible: section.expanded; Layout.fillWidth: true }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: section.expanded = !section.expanded
        }
    }

    ColumnLayout {
        id: content
        visible: section.expanded
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spacingSmall
        Layout.rightMargin: Theme.spacingSmall
        spacing: Theme.spacingSmall
    }
}
