//=============================================================================
// widgets/TopBar/ToggleRow.qml
//
// A labelled switch row for dropdown cards — icon, label, ToggleSwitch,
// full-row hover and full-row click target. Used by the Connectivity
// popout's quick toggles.
//
//=============================================================================
// WHY `checked` IS PUSHED, NOT BOUND (2026-07-29)
//=============================================================================
//
// This used to declare `ToggleSwitch { checked: root.checked }`. That is
// the project's documented never-do: ToggleSwitch assigns its OWN
// `checked` inside its click handler, and an assignment from C++/QML
// internals silently DESTROYS a declarative binding on that property
// (same failure mode as BarPopout's `visible` under grabFocus, and its
// HyprlandFocusGrab `active` — see BarPopout.qml's DESIGN NOTES). Result
// after the first click: the switch is a free-floating boolean that no
// longer reflects Network.wifiEnabled or the Bluetooth adapter at all.
// Turn Wi-Fi off from anywhere else and the switch keeps saying "on".
//
// Now: the switch starts from `root.checked`, is re-pushed whenever
// `root.checked` changes, and — because the underlying operation is
// asynchronous and can FAIL (nmcli refusing, rfkill, no adapter) — is
// reconciled against reality a beat after any user toggle. The row stays
// optimistic for that beat, which is what makes it feel responsive, then
// tells the truth.
//
// ⚠ written offline — NOT yet run live. Test: toggle Wi-Fi from the
// popout, then from `nmcli radio wifi off` in a terminal with the popout
// open — the switch must follow in both directions. Then toggle with the
// adapter removed/rfkill-blocked: the switch should snap back within
// ~1.5 s instead of lying.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-29  (Claude Fable 5) Replaced the destroyable `checked`
//             binding with imperative sync + post-toggle reconcile.
// 2026-07-05  Created for the dropdown-menu visual refresh.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property bool checked: false
    property int iconTextSpacing: Theme.spacingMedium
    signal toggled(bool value)

    implicitWidth: content.implicitWidth + Theme.spacingMedium * 2
    implicitHeight: content.implicitHeight + Theme.spacingMedium * 2
    radius: Theme.radiusMedium
    color: mouseArea.containsMouse ? Theme.colorHover : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.animationEasing
        }
    }

    // External truth changed (service, another UI, rfkill) — push it in.
    onCheckedChanged: toggleSwitch.checked = root.checked

    function _emit(value) {
        root.toggled(value);
        reconcile.restart();
    }

    // The operation behind a toggle is async and can fail. Stay
    // optimistic briefly, then show what actually happened.
    Timer {
        id: reconcile
        interval: 1500
        onTriggered: toggleSwitch.checked = root.checked
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.iconTextSpacing

        Text {
            text: root.icon
            visible: root.icon.length > 0
            Layout.preferredWidth: Theme.fontSize
            horizontalAlignment: Text.AlignHCenter
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: root.text
            Layout.fillWidth: true
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
        }

        ToggleSwitch {
            id: toggleSwitch
            Component.onCompleted: checked = root.checked
            onToggled: value => root._emit(value)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleSwitch.checked = !toggleSwitch.checked;
            root._emit(toggleSwitch.checked);
        }
    }
}
