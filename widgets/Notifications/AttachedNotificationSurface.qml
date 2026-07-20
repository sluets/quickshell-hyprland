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

    // Card removal happens after its collapse animation. Close the BarPopout
    // when the final card STARTS collapsing, not after Notifs.count reaches
    // zero, so the popout outline and the bar gap retract together. // GPT Rev 62
    property bool closingForEmptyStack: false
    property int lastNotifCount: 0

    // A PopupWindow and the bar border live on separate compositor surfaces.
    // Waiting until revealProgress reaches exactly zero to clear the bar gap
    // leaves a visible frame where the popup surface is already gone but the
    // bar Canvas has not rebuilt yet. Hand the seam back to the bar while the
    // last fillet-height slice of the popup is still covering it. // GPT Rev 64
    property bool gapReleasedEarly: false
    readonly property real gapReleaseProgress: Math.min(
        0.25,
        Math.max(
            0.03,
            (Theme.barBorderFillet + Theme.barBorderWidth * 2)
                / Math.max(1, implicitHeight)))

    onRevealProgressChanged: {
        if (open || revealProgress > gapReleaseProgress) {
            gapReleasedEarly = false;
            return;
        }

        if (!gapReleasedEarly && visible) {
            const bar = _findBarHost();
            if (bar)
                bar.clearPopoutGap(_gapKey);
            gapReleasedEarly = true;
        }
    }

    Component.onCompleted: {
        lastNotifCount = Notifs.count;
        root.open = Notifs.count > 0;
    }

    onVisibleChanged: {
        if (!visible)
            closingForEmptyStack = false;
    }

    Connections {
        target: Notifs
        function onCountChanged(): void {
            const nextCount = Notifs.count;

            // A genuinely new notification arriving during retraction cancels
            // the pending close and opens the surface again. Count decreases
            // from animated removals must not reopen it.
            if (nextCount > root.lastNotifCount) {
                root.closingForEmptyStack = false;
                root.open = true;
            } else if (nextCount === 0) {
                if (!root.closingForEmptyStack)
                    root.open = false;
            } else if (!root.closingForEmptyStack) {
                root.open = true;
            }

            root.lastNotifCount = nextCount;
        }
    }

    NotificationComponents.NotificationCards {
        id: cards
        attached: true
        // The final card stays fully rendered while the BarPopout itself
        // scrolls back into the bar. This matches launcher/wallpaper close
        // behavior and keeps the popup border covering the bar gap until the
        // host reaches zero reveal. Remove the model only afterward. // GPT Rev 63
        finalHostExitDuration: root.revealDuration + 40

        onStackWillEmpty: {
            root.closingForEmptyStack = true;
            root.open = false;
        }

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
