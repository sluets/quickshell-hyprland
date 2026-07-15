//=============================================================================
// widgets/Settings/pages/DesktopPage.qml
//
// Desktop clock settings page extracted from SettingsWindow.qml.
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
        text: "Desktop Clock"
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    SettingsComponents.ToggleSettingRow {
        label: "Enabled"
        value: settingsRoot.shownDesktopClockEnabled
        staged: settingsRoot.stagedDesktopClockEnabled !== null
        onToggled: settingsRoot.stagedDesktopClockEnabled =
            !settingsRoot.shownDesktopClockEnabled
    }

    SettingsComponents.OptionPickerRow {
        label: "Corner"
        options: settingsRoot.clockCornerOptions
        shownValue: settingsRoot.shownDesktopClockCorner
        staged: settingsRoot.stagedDesktopClockCorner !== null
        onPicked: v => settingsRoot.stagedDesktopClockCorner = v
    }

    SettingsComponents.StepperRow {
        label: "Offset X"
        valueText: settingsRoot.shownDesktopClockOffsetX + " px"
        staged: settingsRoot.stagedDesktopClockOffsetX !== null
        onMinus: settingsRoot.stagedDesktopClockOffsetX =
            Math.max(-500, settingsRoot.shownDesktopClockOffsetX - 5)
        onPlus: settingsRoot.stagedDesktopClockOffsetX =
            Math.min(2000, settingsRoot.shownDesktopClockOffsetX + 5)
    }

    SettingsComponents.StepperRow {
        label: "Offset Y"
        valueText: settingsRoot.shownDesktopClockOffsetY + " px"
        staged: settingsRoot.stagedDesktopClockOffsetY !== null
        onMinus: settingsRoot.stagedDesktopClockOffsetY =
            Math.max(-500, settingsRoot.shownDesktopClockOffsetY - 5)
        onPlus: settingsRoot.stagedDesktopClockOffsetY =
            Math.min(2000, settingsRoot.shownDesktopClockOffsetY + 5)
    }

    SettingsComponents.OptionPickerRow {
        label: "Monitor"
        options: settingsRoot.monitorOptions
        shownValue: settingsRoot.shownDesktopClockMonitor
        staged: settingsRoot.stagedDesktopClockMonitor !== null
        onPicked: v => settingsRoot.stagedDesktopClockMonitor = v
    }

    Text {
        text: "Colors"
        Layout.topMargin: Theme.spacingLarge
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    SettingsComponents.ToggleSettingRow {
        label: "Use theme color"
        value: settingsRoot.shownDesktopClockUseThemeColor
        staged: settingsRoot.stagedDesktopClockUseThemeColor !== null
        onToggled: settingsRoot.stagedDesktopClockUseThemeColor =
            !settingsRoot.shownDesktopClockUseThemeColor
    }

    SettingsComponents.HexColorRow {
        colorPickerHost: settingsRoot
        visible: !settingsRoot.shownDesktopClockUseThemeColor
        label: "Text hex"
        shownValue: settingsRoot.shownDesktopClockCustomColor
        staged: settingsRoot.stagedDesktopClockCustomColor !== null
        onHexStaged: t => settingsRoot.stagedDesktopClockCustomColor = t
    }

    SettingsComponents.ToggleSettingRow {
        label: "Shadow"
        value: settingsRoot.shownDesktopClockShadowEnabled
        staged: settingsRoot.stagedDesktopClockShadowEnabled !== null
        onToggled: settingsRoot.stagedDesktopClockShadowEnabled =
            !settingsRoot.shownDesktopClockShadowEnabled
    }

    SettingsComponents.ToggleSettingRow {
        visible: settingsRoot.shownDesktopClockShadowEnabled
        label: "Shadow uses theme color"
        value: settingsRoot.shownDesktopClockShadowUseThemeColor
        staged: settingsRoot.stagedDesktopClockShadowUseThemeColor !== null
        onToggled: settingsRoot.stagedDesktopClockShadowUseThemeColor =
            !settingsRoot.shownDesktopClockShadowUseThemeColor
    }

    SettingsComponents.HexColorRow {
        colorPickerHost: settingsRoot
        visible: settingsRoot.shownDesktopClockShadowEnabled
                 && !settingsRoot.shownDesktopClockShadowUseThemeColor
        label: "Shadow hex"
        shownValue: settingsRoot.shownDesktopClockShadowCustomColor
        staged: settingsRoot.stagedDesktopClockShadowCustomColor !== null
        onHexStaged: t => settingsRoot.stagedDesktopClockShadowCustomColor = t
    }

    Text {
        text: "Custom hex colors are how you match a wallpaper by hand.\nAutomatic wallpaper-derived colors are a future project."
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.8)
    }
}
