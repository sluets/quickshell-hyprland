//=============================================================================
// FILE: widgets/Settings/components/SettingsPendingFooter.qml
// PURPOSE: Shared fixed-height pending-changes panel and Apply/Cancel footer.
//
// Extracted from SettingsWindow.qml by GPT on 2026-07-18. This component owns
// only presentation and button signals. The window/controller still owns the
// staged transaction, change model, discard behavior, and apply behavior.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

ColumnLayout {
    id: root

    required property var changes
    property int pendingVisibleLines: 3

    signal cancelRequested()
    signal applyRequested()

    spacing: Theme.spacingMedium

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.colorMuted
    }

    // Fixed-height panel: staging and unstaging change its contents, never its
    // geometry. This prevents the controls above it from shifting under the
    // pointer while settings are being edited.
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: pendingColumn.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: Theme.colorSurface
        border.width: 1
        border.color: Theme.colorMuted

        ColumnLayout {
            id: pendingColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingMedium
            spacing: Theme.spacingMedium

            Text {
                text: root.changes.length > 0
                      ? "Pending changes (" + root.changes.length + "):"
                      : "Pending changes: none"
                color: root.changes.length > 0
                       ? Theme.colorForeground
                       : Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }

            Text {
                id: pendingProbe
                visible: false
                text: "Xg"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: pendingProbe.implicitHeight * root.pendingVisibleLines
                                        + spacing * (root.pendingVisibleLines - 1)
                spacing: 2
                clip: true
                interactive: contentHeight > height
                model: root.changes

                delegate: Text {
                    required property var modelData
                    width: ListView.view.width
                    text: "  " + modelData.label + ":  "
                          + modelData.from + "  →  " + modelData.to
                    elide: Text.ElideRight
                    color: Theme.colorAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingMedium
                    visible: root.changes.length === 0
                    text: "Nothing staged — changes made on any tab collect\nhere, and nothing touches disk until Apply."
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.8)
                }
            }

            Text {
                Layout.fillWidth: true
                text: ConfigManager.busy !== "" ? "Working (" + ConfigManager.busy + ")…"
                    : ConfigManager.lastError !== "" ? "Error: " + ConfigManager.lastError
                    : ConfigManager.lastOutput !== "" ? ConfigManager.lastOutput
                    : " "
                elide: Text.ElideRight
                color: ConfigManager.lastError !== ""
                       ? Theme.colorUrgent
                       : Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.8)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingMedium

        Item { Layout.fillWidth: true }

        Rectangle {
            readonly property bool enabled_: root.changes.length > 0
            implicitWidth: cancelText.implicitWidth + Theme.spacingLarge * 2
            implicitHeight: cancelText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: cancelMouse.containsMouse && enabled_
                   ? Theme.colorHover
                   : Theme.colorSurface
            opacity: enabled_ ? 1.0 : 0.4

            Text {
                id: cancelText
                anchors.centerIn: parent
                text: "Cancel"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: cancelMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.enabled_
                             ? Qt.PointingHandCursor
                             : Qt.ArrowCursor
                onClicked: if (parent.enabled_) root.cancelRequested()
            }
        }

        Rectangle {
            readonly property bool enabled_: root.changes.length > 0
                                             && ConfigManager.busy === ""
            implicitWidth: applyText.implicitWidth + Theme.spacingLarge * 2
            implicitHeight: applyText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: applyMouse.containsMouse && enabled_
                   ? Theme.colorHover
                   : Theme.colorAccent
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
                cursorShape: parent.enabled_
                             ? Qt.PointingHandCursor
                             : Qt.ArrowCursor
                onClicked: if (parent.enabled_) root.applyRequested()
            }
        }
    }
}
