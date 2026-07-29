import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root
    default property alias content: contentColumn.data
    property int contentSpacing: Theme.spacingSmall

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + Theme.spacingLarge * 2
    radius: Theme.radiusMedium
    color: Theme.colorCard
    border.width: Theme.colorCardBorder.a > 0 ? 1 : 0
    border.color: Theme.colorCardBorder

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: root.contentSpacing
    }
}
