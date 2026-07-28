// Launcher settings page. Presentation only; transaction state stays in SettingsTransaction. // GPT Rev 42
import QtQuick
import QtQuick.Layouts
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    required property var settingsRoot
    Layout.fillWidth: true
    spacing: Theme.spacingMedium

    SettingsComponents.SettingsSectionHeader { title: "Behavior" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall

        SettingsComponents.OptionPickerRow {
            label: "Placement"
        description: "Attached connects to the bar; centered opens on the focused monitor."
        options: settingsRoot.launcherPlacementOptions
        shownValue: settingsRoot.shownLauncherPlacement
        staged: settingsRoot.stagedLauncherPlacement !== null
        onPicked: value => settingsRoot.stagedLauncherPlacement = value
    }

    SettingsComponents.StepperRow {
        Layout.fillWidth: true
        label: "Horizontal Offset"
        valueColumnWidth: 72
        valueText: settingsRoot.shownLauncherOffsetX + " px"
        staged: settingsRoot.stagedLauncherOffsetX !== null
        enabled: settingsRoot.shownLauncherPlacement === "centered"
        opacity: enabled ? 1.0 : 0.45
        onMinus: settingsRoot.stagedLauncherOffsetX = Math.max(-500, settingsRoot.shownLauncherOffsetX - 5)
        onPlus: settingsRoot.stagedLauncherOffsetX = Math.min(2000, settingsRoot.shownLauncherOffsetX + 5)
    }

    SettingsComponents.StepperRow {
        Layout.fillWidth: true
        label: "Vertical Offset"
        valueColumnWidth: 72
        valueText: settingsRoot.shownLauncherOffsetY + " px"
        staged: settingsRoot.stagedLauncherOffsetY !== null
        enabled: settingsRoot.shownLauncherPlacement === "centered"
        opacity: enabled ? 1.0 : 0.45
        onMinus: settingsRoot.stagedLauncherOffsetY = Math.max(-500, settingsRoot.shownLauncherOffsetY - 5)
        onPlus: settingsRoot.stagedLauncherOffsetY = Math.min(2000, settingsRoot.shownLauncherOffsetY + 5)
    }

    SettingsComponents.ToggleSettingRow {
        label: "Show Applications Immediately"
        value: settingsRoot.shownLauncherShowAppsOnOpen
        staged: settingsRoot.stagedLauncherShowAppsOnOpen !== null
        onToggled: settingsRoot.stagedLauncherShowAppsOnOpen = !settingsRoot.shownLauncherShowAppsOnOpen
    }

    }

    SettingsComponents.SettingsSectionHeader { title: "Application Data" }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: launcherDataColumn.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: Theme.colorSurface

        ColumnLayout {
            id: launcherDataColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Theme.spacingMedium
            anchors.rightMargin: Theme.spacingMedium
            spacing: Theme.spacingSmall

            Text {
                text: "Launcher Learning"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Text {
                Layout.fillWidth: true
                text: "The launcher ranks favorites first, then applications you launch most often. Use the star and × buttons in the launcher to favorite or hide entries."
                wrapMode: Text.WordWrap
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.8)
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Repeater {
                    model: [
                        { label: "Clear Usage", action: function() { UserPrefs.clearLauncherUsage(); } },
                        { label: "Clear Favorites", action: function() { UserPrefs.clearLauncherFavorites(); } },
                        { label: "Restore Hidden", action: function() { UserPrefs.clearLauncherHidden(); } }
                    ]

                    Rectangle {
                        required property var modelData
                        implicitWidth: actionLabel.implicitWidth + Theme.spacingMedium * 2
                        implicitHeight: actionLabel.implicitHeight + Theme.spacingSmall * 2
                        radius: Theme.radiusMedium
                        color: actionMouse.containsMouse ? Theme.colorHover : Theme.colorBackground
                        border.width: 1
                        border.color: Theme.colorMuted

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.82)
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.modelData.action()
                        }
                    }
                }
            }
        }
    }
}
