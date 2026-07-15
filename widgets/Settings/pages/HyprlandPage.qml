//=============================================================================
// widgets/Settings/pages/HyprlandPage.qml
//
// GPT: Hyprland appearance settings page extracted from SettingsWindow.qml.
// Presentation only: staged values, config generation, and Apply/Cancel remain
// owned by the parent settings window.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page

    required property var settingsRoot

    Layout.fillWidth: true
    spacing: Theme.spacingMedium

    SettingsComponents.StepperRow {
        label: "Gaps In"
        valueText: settingsRoot.shownHyprGapsIn + " px"
        staged: settingsRoot.stagedHyprGapsIn !== null
        onMinus: settingsRoot.stagedHyprGapsIn =
            Math.max(0, settingsRoot.shownHyprGapsIn - 1)
        onPlus: settingsRoot.stagedHyprGapsIn =
            Math.min(30, settingsRoot.shownHyprGapsIn + 1)
    }

    SettingsComponents.StepperRow {
        label: "Gaps Out"
        valueText: settingsRoot.shownHyprGapsOut + " px"
        staged: settingsRoot.stagedHyprGapsOut !== null
        onMinus: settingsRoot.stagedHyprGapsOut =
            Math.max(0, settingsRoot.shownHyprGapsOut - 2)
        onPlus: settingsRoot.stagedHyprGapsOut =
            Math.min(60, settingsRoot.shownHyprGapsOut + 2)
    }

    SettingsComponents.StepperRow {
        label: "Border Size"
        valueText: settingsRoot.shownHyprBorderSize + " px"
        staged: settingsRoot.stagedHyprBorderSize !== null
        onMinus: settingsRoot.stagedHyprBorderSize =
            Math.max(0, settingsRoot.shownHyprBorderSize - 1)
        onPlus: settingsRoot.stagedHyprBorderSize =
            Math.min(10, settingsRoot.shownHyprBorderSize + 1)
    }

    SettingsComponents.StepperRow {
        label: "Rounding"
        valueText: settingsRoot.shownHyprRounding + " px"
        staged: settingsRoot.stagedHyprRounding !== null
        onMinus: settingsRoot.stagedHyprRounding =
            Math.max(0, settingsRoot.shownHyprRounding - 1)
        onPlus: settingsRoot.stagedHyprRounding =
            Math.min(30, settingsRoot.shownHyprRounding + 1)
    }

    // GPT: Theme color here means the shell accent color. Hyprland does not
    // know about the shell theme directly; ConfigManager writes the resolved
    // color into the generated Hyprland appearance file.
    Text {
        text: "Active Border Color"
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    SettingsComponents.ToggleSettingRow {
        label: "Use theme color"
        value: settingsRoot.shownHyprActiveBorderUseThemeColor
        staged: settingsRoot.stagedHyprActiveBorderUseThemeColor !== null
        onToggled: settingsRoot.stagedHyprActiveBorderUseThemeColor =
            !settingsRoot.shownHyprActiveBorderUseThemeColor
    }

    SettingsComponents.HexColorRow {
        colorPickerHost: settingsRoot
        visible: !settingsRoot.shownHyprActiveBorderUseThemeColor
        shownValue: settingsRoot.shownHyprActiveBorderCustomColor
        staged: settingsRoot.stagedHyprActiveBorderCustomColor !== null
        onHexStaged: t => settingsRoot.stagedHyprActiveBorderCustomColor = t
    }

    Text {
        visible: !settingsRoot.shownHyprActiveBorderUseThemeColor
        text: "#RRGGBB (8 digits = Qt #AARRGGBB, alpha first)"
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.8)
    }

    Text {
        text: "One-time setup required: remove the 'active_border' line "
            + "from user/look.lua's col table (keep inactive_border) so it "
            + "stops fighting with the generated file over the same key. "
            + "See ConfigManager.qml's 2026-07-12 revision note."
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: Theme.colorUrgent
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.8)
    }

    Text {
        text: "Writes hypr/generated/appearance.lua — Hyprland reloads it live.\n"
            + "Requires the one-time restructure: docs/HYPR_RESTRUCTURE.md"
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.8)
    }
}
