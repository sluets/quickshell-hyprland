import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    default property alias content: contentColumn.data
    property alias overlayContent: overlayLayer.data
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

    // Non-layout children live here so selectors can float over later
    // sections without increasing the card or popout height. // GPT Rev 31
    Item {
        id: overlayLayer
        anchors.fill: parent
        z: 100
        clip: false
    }
}
