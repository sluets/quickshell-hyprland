// Historical detached notification window, preserved as the default. // GPT Rev 52
import QtQuick
import Quickshell
import qs.core
import qs.services
import "." as NotificationComponents

PanelWindow {
    id: root

    property bool presentationActive: false

    readonly property string _corner: UserPrefs.notifCorner
    readonly property bool _top: _corner === "top-left" || _corner === "top-right"
    readonly property bool _left: _corner === "top-left" || _corner === "bottom-left"

    anchors {
        top: root._top
        bottom: !root._top
        left: root._left
        right: !root._left
    }

    margins {
        top: (Theme.barHeight + Theme.barMargin + Theme.spacingMedium) + UserPrefs.notifOffsetY
        bottom: Theme.barMargin + UserPrefs.notifOffsetY
        left: Theme.barMargin + UserPrefs.notifOffsetX
        right: Theme.barMargin + UserPrefs.notifOffsetX
    }

    exclusiveZone: 0
    color: "transparent"
    visible: root.presentationActive && Notifs.count > 0
    implicitWidth: cards.implicitWidth
    implicitHeight: cards.implicitHeight

    NotificationComponents.NotificationCards {
        id: cards
        active: root.presentationActive
        attached: false
    }
}
