//=============================================================================
// widgets/Settings/pages/NotificationsPage.qml
//
// Notifications settings page extracted from SettingsWindow.qml.
// Presentation only: staged values and Apply/Cancel remain owned by the parent.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page

    required property var settingsRoot

    Layout.fillWidth: true
    spacing: Theme.spacingMedium

    Text {
        text: "Presentation"
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    SettingsComponents.OptionPickerRow {
        label: "Style"
        options: settingsRoot.notifPresentationOptions
        shownValue: settingsRoot.shownNotifPresentation
        staged: settingsRoot.stagedNotifPresentation !== null
        onPicked: value => settingsRoot.stagedNotifPresentation = value
    }

    SettingsComponents.OptionPickerRow {
        visible: settingsRoot.shownNotifPresentation === "bar"
        label: "Bar Position"
        options: settingsRoot.notifBarPositionOptions
        shownValue: settingsRoot.shownNotifBarPosition
        staged: settingsRoot.stagedNotifBarPosition !== null
        onPicked: value => settingsRoot.stagedNotifBarPosition = value
    }

    ColumnLayout {
        visible: settingsRoot.shownNotifPresentation === "bar"
        Layout.fillWidth: true
        spacing: Theme.spacingSmall

        Text {
            text: "Horizontal Offset"
            color: settingsRoot.stagedNotifBarOffsetX !== null ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        SettingsComponents.StepperRow {
            label: ""
            labelColumnWidth: 0
            valueColumnWidth: 72
            valueText: settingsRoot.shownNotifBarOffsetX + " px"
            staged: settingsRoot.stagedNotifBarOffsetX !== null
            onMinus: settingsRoot.stagedNotifBarOffsetX =
                Math.max(-2000, settingsRoot.shownNotifBarOffsetX - 5)
            onPlus: settingsRoot.stagedNotifBarOffsetX =
                Math.min(2000, settingsRoot.shownNotifBarOffsetX + 5)
        }
    }

    Text {
        visible: settingsRoot.shownNotifPresentation === "bar"
        text: "Offset is added after the safe edge inset. Extreme values may intentionally clip the connected fillet."
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.8)
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }

    SettingsComponents.ToggleSettingRow {
        label: "Show App Name"
        value: settingsRoot.shownNotifShowAppName
        staged: settingsRoot.stagedNotifShowAppName !== null
        onToggled: settingsRoot.stagedNotifShowAppName = !settingsRoot.shownNotifShowAppName
    }

    SettingsComponents.StepperRow {
        label: "Icon Size"
        valueText: settingsRoot.shownNotifIconSize + " px"
        staged: settingsRoot.stagedNotifIconSize !== null
        onMinus: settingsRoot.stagedNotifIconSize =
            Math.max(24, settingsRoot.shownNotifIconSize - 8)
        onPlus: settingsRoot.stagedNotifIconSize =
            Math.min(96, settingsRoot.shownNotifIconSize + 8)
    }

    SettingsComponents.StepperRow {
        label: "Body Lines"
        valueText: String(settingsRoot.shownNotifBodyLines)
        staged: settingsRoot.stagedNotifBodyLines !== null
        onMinus: settingsRoot.stagedNotifBodyLines =
            Math.max(1, settingsRoot.shownNotifBodyLines - 1)
        onPlus: settingsRoot.stagedNotifBodyLines =
            Math.min(10, settingsRoot.shownNotifBodyLines + 1)
    }

    SettingsComponents.StepperRow {
        label: "Font Scale"
        valueText: settingsRoot.shownNotifFontScale.toFixed(1) + "×"
        staged: settingsRoot.stagedNotifFontScale !== null
        onMinus: settingsRoot.stagedNotifFontScale =
            Math.max(0.8, Math.round((settingsRoot.shownNotifFontScale - 0.1) * 10) / 10)
        onPlus: settingsRoot.stagedNotifFontScale =
            Math.min(2.0, Math.round((settingsRoot.shownNotifFontScale + 0.1) * 10) / 10)
    }

    Text {
        visible: settingsRoot.shownNotifPresentation === "detached"
        text: "Position"
        Layout.topMargin: Theme.spacingLarge
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    SettingsComponents.OptionPickerRow {
        visible: settingsRoot.shownNotifPresentation === "detached"
        label: "Corner"
        options: settingsRoot.notifCornerOptions
        shownValue: settingsRoot.shownNotifCorner
        staged: settingsRoot.stagedNotifCorner !== null
        onPicked: value => settingsRoot.stagedNotifCorner = value
    }

    SettingsComponents.StepperRow {
        visible: settingsRoot.shownNotifPresentation === "detached"
        label: "Offset X"
        valueText: settingsRoot.shownNotifOffsetX + " px"
        staged: settingsRoot.stagedNotifOffsetX !== null
        onMinus: settingsRoot.stagedNotifOffsetX =
            Math.max(-500, settingsRoot.shownNotifOffsetX - 5)
        onPlus: settingsRoot.stagedNotifOffsetX =
            Math.min(2000, settingsRoot.shownNotifOffsetX + 5)
    }

    SettingsComponents.StepperRow {
        visible: settingsRoot.shownNotifPresentation === "detached"
        label: "Offset Y"
        valueText: settingsRoot.shownNotifOffsetY + " px"
        staged: settingsRoot.stagedNotifOffsetY !== null
        onMinus: settingsRoot.stagedNotifOffsetY =
            Math.max(-500, settingsRoot.shownNotifOffsetY - 5)
        onPlus: settingsRoot.stagedNotifOffsetY =
            Math.min(2000, settingsRoot.shownNotifOffsetY + 5)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingMedium

        Rectangle {
            implicitWidth: testNotifText.implicitWidth + Theme.spacingLarge * 2
            implicitHeight: testNotifText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: testNotifMouse.containsMouse ? Theme.colorHover : Theme.colorSurface

            Text {
                id: testNotifText
                anchors.centerIn: parent
                text: "Send Test Notification"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: testNotifMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached([
                    "notify-send", "-a", "Shell Settings",
                    "Test Notification",
                    "Corner + offset preview — this is where popups appear."
                ])
            }
        }

        Item { Layout.fillWidth: true }
    }

    Text {
        text: "Test shows APPLIED settings — Apply position changes first, then test."
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.8)
    }

    Text {
        text: "Test with:  notify-send \"Song Title\" \"Artist — Album\""
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.8)
    }
}
