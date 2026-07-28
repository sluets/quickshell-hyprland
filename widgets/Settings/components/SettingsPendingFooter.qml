//=============================================================================
// FILE: widgets/Settings/components/SettingsPendingFooter.qml
// PURPOSE: Compact Settings action bar. Change details are reviewed on Apply.
//
// Rev 6 (GPT, 2026-07-28): The permanently expanded pending-changes panel was
// removed. This bar keeps the stable Apply/Discard actions and a small status
// count; SettingsView owns the confirmation overlay that lists the changes.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Rectangle {
    id: root

    required property var changes

    signal cancelRequested()
    signal applyRequested()

    Layout.fillWidth: true
    implicitHeight: actionRow.implicitHeight + Theme.spacingMedium * 2
    radius: Theme.radiusLarge
    color: Theme.colorCard
    border.width: 1
    border.color: Theme.colorCardBorder

    RowLayout {
        id: actionRow
        anchors.fill: parent
        anchors.margins: Theme.spacingMedium
        spacing: Theme.spacingMedium

        Text {
            Layout.fillWidth: true
            text: ConfigManager.busy !== "" ? "Working (" + ConfigManager.busy + ")…"
                : ConfigManager.lastError !== "" ? "Error: " + ConfigManager.lastError
                : root.changes.length > 0
                    ? root.changes.length + " pending change" + (root.changes.length === 1 ? "" : "s")
                    : ""
            elide: Text.ElideRight
            color: ConfigManager.lastError !== "" ? Theme.colorUrgent
                 : root.changes.length > 0 ? Theme.colorAccent
                 : Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.85)
            font.bold: root.changes.length > 0
        }

        Rectangle {
            readonly property bool enabled_: root.changes.length > 0
            implicitWidth: discardText.implicitWidth + Theme.spacingLarge * 2
            implicitHeight: discardText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: discardMouse.containsMouse && enabled_ ? Theme.colorHover : Theme.colorControl
            opacity: enabled_ ? 1.0 : 0.4

            Text {
                id: discardText
                anchors.centerIn: parent
                text: "Discard"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: discardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.enabled_ ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (parent.enabled_) root.cancelRequested()
            }
        }

        Rectangle {
            readonly property bool enabled_: root.changes.length > 0 && ConfigManager.busy === ""
            implicitWidth: applyText.implicitWidth + Theme.spacingLarge * 2
            implicitHeight: applyText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: applyMouse.containsMouse && enabled_ ? Theme.colorHover : Theme.colorAccent
            opacity: enabled_ ? 1.0 : 0.4

            Text {
                id: applyText
                anchors.centerIn: parent
                text: "Apply"
                color: Theme.colorBackground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }

            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.enabled_ ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (parent.enabled_) root.applyRequested()
            }
        }
    }
}
