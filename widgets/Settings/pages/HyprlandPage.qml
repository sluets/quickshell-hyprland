//=============================================================================
// widgets/Settings/pages/HyprlandPage.qml
//
// GPT: Hyprland appearance settings page extracted from SettingsWindow.qml.
// Presentation only: staged values, config generation, and Apply/Cancel remain
// owned by the parent settings window.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page

    required property var settingsRoot

    Layout.fillWidth: true
    spacing: Theme.spacingMedium

    property bool setupCheckComplete: false
    property bool setupReady: false
    property bool setupFileMissing: false

    Process {
        id: setupCheck
        command: ["sh", "-c",
            "file=\"$1/.config/hypr/user/look.lua\"; "
            + "[ -f \"$file\" ] || exit 2; "
            + "grep -Eq '^[[:space:]]*active_border[[:space:]]*=' \"$file\" && exit 1; "
            + "exit 0",
            "hyprland-setup-check", Quickshell.env("HOME")]

        onExited: (exitCode, exitStatus) => {
            page.setupCheckComplete = true;
            page.setupReady = (exitCode === 0);
            page.setupFileMissing = (exitCode === 2);
        }
    }

    Component.onCompleted: setupCheck.running = true

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
        visible: page.setupCheckComplete && !page.setupReady
        text: page.setupFileMissing
            ? "Hyprland setup check could not find ~/.config/hypr/user/look.lua."
            : "One-time setup required: remove the active_border assignment "
              + "from user/look.lua (keep inactive_border) so it does not "
              + "fight with generated/appearance.lua."
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
