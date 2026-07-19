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
        text: "Bar Clock"
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    SettingsComponents.ToggleSettingRow {
        label: "24-hour time"
        value: settingsRoot.shownClockUse24Hour
        staged: settingsRoot.stagedClockUse24Hour !== null
        onToggled: settingsRoot.stagedClockUse24Hour = !settingsRoot.shownClockUse24Hour
    }

    SettingsComponents.ToggleSettingRow {
        label: "Show seconds"
        value: settingsRoot.shownClockShowSeconds
        staged: settingsRoot.stagedClockShowSeconds !== null
        onToggled: settingsRoot.stagedClockShowSeconds = !settingsRoot.shownClockShowSeconds
    }

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
        text: "Display"
        Layout.topMargin: Theme.spacingLarge
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    SettingsComponents.StepperRow {
        label: "Overall scale"
        valueText: settingsRoot.shownDesktopClockScale.toFixed(2) + "x"
        staged: settingsRoot.stagedDesktopClockScale !== null
        onMinus: settingsRoot.stagedDesktopClockScale = Math.max(0.5, Math.round((settingsRoot.shownDesktopClockScale - 0.05) * 100) / 100)
        onPlus: settingsRoot.stagedDesktopClockScale = Math.min(2.5, Math.round((settingsRoot.shownDesktopClockScale + 0.05) * 100) / 100)
    }

    SettingsComponents.ToggleSettingRow {
        label: "Show weather icon"
        value: settingsRoot.shownDesktopClockShowWeatherIcon
        staged: settingsRoot.stagedDesktopClockShowWeatherIcon !== null
        onToggled: settingsRoot.stagedDesktopClockShowWeatherIcon = !settingsRoot.shownDesktopClockShowWeatherIcon
    }

    SettingsComponents.ToggleSettingRow {
        label: "Show temperature"
        value: settingsRoot.shownDesktopClockShowTemperature
        staged: settingsRoot.stagedDesktopClockShowTemperature !== null
        onToggled: settingsRoot.stagedDesktopClockShowTemperature = !settingsRoot.shownDesktopClockShowTemperature
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

    SettingsComponents.StepperRow {
        visible: settingsRoot.shownDesktopClockShadowEnabled
        label: "Shadow strength"
        valueText: settingsRoot.shownDesktopClockShadowStrength + "%"
        staged: settingsRoot.stagedDesktopClockShadowStrength !== null
        onMinus: settingsRoot.stagedDesktopClockShadowStrength =
            Math.max(0, settingsRoot.shownDesktopClockShadowStrength - 5)
        onPlus: settingsRoot.stagedDesktopClockShadowStrength =
            Math.min(100, settingsRoot.shownDesktopClockShadowStrength + 5)
    }

    SettingsComponents.StepperRow {
        visible: settingsRoot.shownDesktopClockShadowEnabled
        label: "Shadow X offset"
        valueText: settingsRoot.shownDesktopClockShadowOffsetX + " px"
        staged: settingsRoot.stagedDesktopClockShadowOffsetX !== null
        onMinus: settingsRoot.stagedDesktopClockShadowOffsetX =
            Math.max(-20, settingsRoot.shownDesktopClockShadowOffsetX - 1)
        onPlus: settingsRoot.stagedDesktopClockShadowOffsetX =
            Math.min(20, settingsRoot.shownDesktopClockShadowOffsetX + 1)
    }

    SettingsComponents.StepperRow {
        visible: settingsRoot.shownDesktopClockShadowEnabled
        label: "Shadow Y offset"
        valueText: settingsRoot.shownDesktopClockShadowOffsetY + " px"
        staged: settingsRoot.stagedDesktopClockShadowOffsetY !== null
        onMinus: settingsRoot.stagedDesktopClockShadowOffsetY =
            Math.max(-20, settingsRoot.shownDesktopClockShadowOffsetY - 1)
        onPlus: settingsRoot.stagedDesktopClockShadowOffsetY =
            Math.min(20, settingsRoot.shownDesktopClockShadowOffsetY + 1)
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
