import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: card
    default property alias content: contentColumn.data
    property int contentSpacing: Theme.spacingSmall

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + Theme.spacingMedium * 2
    radius: Theme.radiusLarge
    color: Theme.colorCard
    border.width: 1
    border.color: Theme.colorCardBorder

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium
        spacing: card.contentSpacing
    }
}
