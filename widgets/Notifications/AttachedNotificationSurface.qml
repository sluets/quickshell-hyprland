// Notification stack hosted by the bar's connected popout shell. // GPT Rev 52
import QtQuick
import qs.core
import qs.services
import qs.widgets.TopBar as TopBarComponents
import "." as NotificationComponents

TopBarComponents.BarPopout {
    id: root

    alignment: UserPrefs.notifBarPosition
    // Notifications are inset from the bar ends, so both outer fillets should
    // always be drawn. Edge alignment still controls anchoring; user X offset
    // remains free to move the surface flush or beyond the bar if desired. // GPT Rev 55
    flushToBarEdge: false

    readonly property real safeEdgeInset: Math.max(
        0, Theme.barBorderFillet + Theme.barRadius - Theme.spacingMedium)
    readonly property real baselineOffset: alignment === "right"
        ? -safeEdgeInset
        : alignment === "left" ? safeEdgeInset : 0

    // The neutral baseline preserves room for the outer fillet at either bar
    // edge. The user offset is deliberately unrestricted enough to override it. // GPT Rev 54
    xOffset: baselineOffset + UserPrefs.notifBarOffsetX
    dismissOnOutsideClick: false

    Component.onCompleted: root.open = Notifs.count > 0

    Connections {
        target: Notifs
        function onCountChanged(): void {
            root.open = Notifs.count > 0;
        }
    }

    NotificationComponents.NotificationCards {
        id: cards
        attached: true

        // Notifs.count can open this PopupWindow before the first delegate has
        // completed layout. Refresh the bar gap the moment the stack publishes
        // its real width so the bar border is carved out before the card reveal
        // becomes visible. // GPT Rev 58
        onImplicitWidthChanged: {
            if (root.open)
                Qt.callLater(() => root._updateGap());
        }
    }
}
