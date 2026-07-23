// Notification stack hosted by the bar's connected popout shell. // GPT Rev 52
import QtQuick
import qs.core
import qs.services
import qs.widgets.TopBar as TopBarComponents
import "." as NotificationComponents

TopBarComponents.BarPopout {
    id: root

    property bool presentationActive: false
    property Item candidateAnchorItem: null
    property Item latchedAnchorItem: null

    // Focus changes update only the candidate. A visible popup remains on the
    // bar where that notification session began. // GPT
    anchorItem: root.latchedAnchorItem

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

    function _canOpenSession(): bool {
        return root.presentationActive
            && Notifs.count > 0
            && root.candidateAnchorItem !== null;
    }

    function _openSession(): void {
        if (!root._canOpenSession())
            return;

        // A dormant host may retain the previous session's valid anchor so
        // PopupWindow never observes a null anchor during a visibility
        // transition. Re-latch to the current candidate before exposing the
        // next session. // GPT Memory stabilization Phase 3 crash fix
        if (!root.open && !root.visible)
            root.latchedAnchorItem = root.candidateAnchorItem;
        if (root.latchedAnchorItem === null)
            return;

        root.closingForEmptyStack = false;
        root.lastNotifCount = Notifs.count;
        root.open = true;
    }

    // Presentation changes and invalid anchors must stop exposure immediately;
    // otherwise detached and attached windows can overlap during retraction.
    function _hideImmediately(): void {
        const bar = root._findBarHost();
        root.open = false;
        root.visible = false;
        // Capture the current bar before hiding so its gap can be removed even
        // if the compositor changes window state during the callback.
        if (bar)
            bar.clearPopoutGap(root._gapKey);
        root.revealProgress = 0;
        root.closingForEmptyStack = false;
        root.gapReleasedEarly = false;
        // Keep the last valid anchor while dormant. Clearing it synchronously
        // from a visibility change can make Quickshell's PopupWindow binding
        // dereference an invalid QQuickItem while QWindow is still updating.
    }

    function _handleCountChanged(): void {
        const nextCount = Notifs.count;
        if (!root.presentationActive) {
            root.lastNotifCount = nextCount;
            return;
        }

        if (nextCount > 0 && (!root.open && !root.visible)) {
            root.lastNotifCount = nextCount;
            root._openSession();
            return;
        }

        // A genuinely new notification arriving during retraction cancels
        // the pending close and opens the surface again. Count decreases from
        // animated removals must not reopen it.
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
        if (root.presentationActive)
            root._openSession();
    }

    onVisibleChanged: {
        if (!visible) {
            closingForEmptyStack = false;
            // Do not clear the anchor here. onVisibleChanged runs inside
            // Quickshell/Qt's native visibility update, and changing the
            // PopupWindow anchor from this callback can invalidate the item
            // QQuickItem::window() is still using. // GPT
            if (presentationActive && Notifs.count > 0)
                Qt.callLater(() => root._openSession());
        }
    }

    onPresentationActiveChanged: {
        root.lastNotifCount = Notifs.count;
        if (presentationActive)
            root._openSession();
        else
            root._hideImmediately();
    }

    onCandidateAnchorItemChanged: {
        if (presentationActive && Notifs.count > 0
                && latchedAnchorItem === null)
            Qt.callLater(() => root._openSession());
    }

    onLatchedAnchorItemChanged: {
        // QObject references become null when their bar is destroyed. Hide the
        // invalid popup, then recover on the current candidate if one exists.
        if (latchedAnchorItem === null && (open || visible)) {
            root._hideImmediately();
            if (presentationActive && Notifs.count > 0)
                Qt.callLater(() => root._openSession());
        }
    }

    Connections {
        target: Notifs
        enabled: root.presentationActive
        function onCountChanged(): void {
            root._handleCountChanged();
        }
    }

    NotificationComponents.NotificationCards {
        id: cards
        active: root.presentationActive
        attached: true
        // The final card stays fully rendered while the BarPopout itself
        // scrolls back into the bar. This matches launcher/wallpaper close
        // behavior and keeps the popup border covering the bar gap until the
        // host reaches zero reveal. Remove the model only afterward. // GPT Rev 63
        finalHostExitDuration: root.revealDuration + 40

        onStackWillEmpty: {
            if (!root.presentationActive)
                return;
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
