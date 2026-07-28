//=============================================================================
// FILE: widgets/Settings/pages/AppearancePage.qml
// PURPOSE: Rev 0 visual-polish test page. Behavior remains owned by SettingsWindow.
//=============================================================================
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page
    required property var settingsRoot
    readonly property alias themeDropdownAnchor: themeDropdownButton
    readonly property alias fontDropdownAnchor: fontDropdownButton
    Layout.fillWidth: true
    spacing: Theme.spacingSmall

    SettingsComponents.SettingsSectionHeader { title: "Theme & Typography"; Layout.topMargin: 0 }
    SettingsComponents.SettingsCard {
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(themeLabel.implicitHeight, themeDropdownButton.implicitHeight) + Theme.spacingSmall * 2
            color: "transparent"

            Text {
                id: themeLabel
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingMedium
                anchors.verticalCenter: parent.verticalCenter
                text: "Theme"
                color: settingsRoot.stagedTheme !== null ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Rectangle {
                id: themeDropdownButton
                anchors.left: parent.left
                anchors.leftMargin: Math.min(250, Math.max(Theme.spacingMedium, parent.width - width - Theme.spacingMedium))
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(320, parent.width - x - Theme.spacingMedium)
                implicitHeight: themeValue.implicitHeight + Theme.spacingSmall * 2
                radius: Theme.radiusMedium
                color: themeButtonMouse.containsMouse ? Theme.colorHover : Theme.colorControl
                border.width: settingsRoot.themeDropdownOpen ? 1 : 0
                border.color: Theme.colorAccent

                Text {
                    id: themeValue
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.right: themeArrow.left
                    anchors.rightMargin: Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: settingsRoot.shownTheme
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    id: themeArrow
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    text: settingsRoot.themeDropdownOpen ? "▴" : "▾"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                MouseArea {
                    id: themeButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        settingsRoot.themeDropdownOpen = !settingsRoot.themeDropdownOpen;
                        if (settingsRoot.themeDropdownOpen) {
                            settingsRoot.fontFamilyDropdownOpen = false;
                            settingsRoot.wallpaperTransitionTypeDropdownOpen = false;
                        }
                    }
                }
            }

            Rectangle {
                visible: settingsRoot.stagedTheme !== null
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height - Theme.spacingMedium
                radius: 2
                color: Theme.colorAccent
            }
        }

        SettingsComponents.StepperRow {
            label: "Font scale"
            description: "Scale text throughout the shell"
            valueText: settingsRoot.shownFontScale.toFixed(1) + "×"
            staged: settingsRoot.stagedFontScale !== null
            onMinus: settingsRoot.stagedFontScale = Math.max(0.8, Math.round((settingsRoot.shownFontScale - 0.1) * 10) / 10)
            onPlus: settingsRoot.stagedFontScale = Math.min(2.5, Math.round((settingsRoot.shownFontScale + 0.1) * 10) / 10)
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(fontLabel.implicitHeight, fontDropdownButton.implicitHeight) + Theme.spacingSmall * 2
            color: "transparent"

            Text {
                id: fontLabel
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacingMedium
                anchors.verticalCenter: parent.verticalCenter
                text: "Font family"
                color: settingsRoot.stagedFontFamilyOverride !== null ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            Rectangle {
                id: fontDropdownButton
                anchors.left: parent.left
                anchors.leftMargin: Math.min(250, Math.max(Theme.spacingMedium, parent.width - width - Theme.spacingMedium))
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(320, parent.width - x - Theme.spacingMedium)
                implicitHeight: fontValue.implicitHeight + Theme.spacingSmall * 2
                radius: Theme.radiusMedium
                color: fontButtonMouse.containsMouse ? Theme.colorHover : Theme.colorControl
                border.width: settingsRoot.fontFamilyDropdownOpen ? 1 : 0
                border.color: Theme.colorAccent

                Text {
                    id: fontValue
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.right: fontArrow.left
                    anchors.rightMargin: Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: settingsRoot.shownFontFamilyOverride === "" ? "Theme default" : settingsRoot.shownFontFamilyOverride
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    id: fontArrow
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    text: settingsRoot.fontFamilyDropdownOpen ? "▴" : "▾"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                MouseArea {
                    id: fontButtonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        settingsRoot.fontFamilyDropdownOpen = !settingsRoot.fontFamilyDropdownOpen;
                        if (settingsRoot.fontFamilyDropdownOpen) {
                            settingsRoot.themeDropdownOpen = false;
                            settingsRoot.wallpaperTransitionTypeDropdownOpen = false;
                        }
                    }
                }
            }

            Rectangle {
                visible: settingsRoot.stagedFontFamilyOverride !== null
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height - Theme.spacingMedium
                radius: 2
                color: Theme.colorAccent
            }
        }
    }

    SettingsComponents.SettingsSectionHeader { title: "Bar Layout" }
    SettingsComponents.SettingsCard {
        SettingsComponents.ToggleSettingRow {
            label: "Custom padding"; description: "Override the active theme's bar spacing"
            value: settingsRoot.shownBarPaddingTopOverride >= 0
            staged: settingsRoot.stagedBarPaddingTopOverride !== null || settingsRoot.stagedBarPaddingSideOverride !== null || settingsRoot.stagedBarPaddingBottomOverride !== null
            onToggled: {
                if (settingsRoot.shownBarPaddingTopOverride >= 0) {
                    settingsRoot.stagedBarPaddingTopOverride = -1; settingsRoot.stagedBarPaddingSideOverride = -1; settingsRoot.stagedBarPaddingBottomOverride = UserPrefs.barPaddingBottomOffSentinel;
                } else {
                    settingsRoot.stagedBarPaddingTopOverride = Theme.barPaddingTop; settingsRoot.stagedBarPaddingSideOverride = Theme.barPaddingSide; settingsRoot.stagedBarPaddingBottomOverride = Theme.barPaddingBottom;
                }
            }
        }
        SettingsComponents.StepperRow { visible: settingsRoot.shownBarPaddingTopOverride >= 0; label: "Top"; valueText: settingsRoot.shownBarPaddingTopOverride + " px"; staged: settingsRoot.stagedBarPaddingTopOverride !== null; onMinus: settingsRoot.stagedBarPaddingTopOverride = Math.max(0, settingsRoot.shownBarPaddingTopOverride - 1); onPlus: settingsRoot.stagedBarPaddingTopOverride = Math.min(200, settingsRoot.shownBarPaddingTopOverride + 1) }
        SettingsComponents.StepperRow { visible: settingsRoot.shownBarPaddingTopOverride >= 0; label: "Sides"; valueText: settingsRoot.shownBarPaddingSideOverride + " px"; staged: settingsRoot.stagedBarPaddingSideOverride !== null; onMinus: settingsRoot.stagedBarPaddingSideOverride = Math.max(0, settingsRoot.shownBarPaddingSideOverride - 1); onPlus: settingsRoot.stagedBarPaddingSideOverride = Math.min(200, settingsRoot.shownBarPaddingSideOverride + 1) }
        SettingsComponents.StepperRow { visible: settingsRoot.shownBarPaddingTopOverride >= 0; label: "Bottom"; valueText: settingsRoot.shownBarPaddingBottomOverride + " px"; staged: settingsRoot.stagedBarPaddingBottomOverride !== null; onMinus: settingsRoot.stagedBarPaddingBottomOverride = Math.max(-100, settingsRoot.shownBarPaddingBottomOverride - 1); onPlus: settingsRoot.stagedBarPaddingBottomOverride = Math.min(200, settingsRoot.shownBarPaddingBottomOverride + 1) }
    }

    SettingsComponents.SettingsSectionHeader { title: "Bar Styling" }
    SettingsComponents.SettingsCard {
        SettingsComponents.ToggleSettingRow { label: "Custom border width"; value: settingsRoot.shownBarBorderWidthOverride >= 0; staged: settingsRoot.stagedBarBorderWidthOverride !== null; onToggled: settingsRoot.stagedBarBorderWidthOverride = settingsRoot.shownBarBorderWidthOverride >= 0 ? -1 : Theme.barBorderWidth }
        SettingsComponents.StepperRow { visible: settingsRoot.shownBarBorderWidthOverride >= 0; label: "Border width"; valueText: settingsRoot.shownBarBorderWidthOverride + " px"; staged: settingsRoot.stagedBarBorderWidthOverride !== null; onMinus: settingsRoot.stagedBarBorderWidthOverride = Math.max(0, settingsRoot.shownBarBorderWidthOverride - 1); onPlus: settingsRoot.stagedBarBorderWidthOverride = Math.min(12, settingsRoot.shownBarBorderWidthOverride + 1) }
        SettingsComponents.ToggleSettingRow { label: "Use theme color"; description: "Follow the active theme's bar border colors"; value: settingsRoot.shownBarBorderUseThemeColor; staged: settingsRoot.stagedBarBorderUseThemeColor !== null; onToggled: settingsRoot.stagedBarBorderUseThemeColor = !settingsRoot.shownBarBorderUseThemeColor }
        SettingsComponents.HexColorRow { colorPickerHost: settingsRoot; visible: !settingsRoot.shownBarBorderUseThemeColor; shownValue: settingsRoot.shownBarBorderCustomColor; staged: settingsRoot.stagedBarBorderCustomColor !== null; onHexStaged: t => settingsRoot.stagedBarBorderCustomColor = t }
    }

    SettingsComponents.SettingsSectionHeader { title: "Settings Window" }
    SettingsComponents.SettingsCard {
        SettingsComponents.StepperRow { label: "Default width"; description: "Used the next time Settings opens"; valueText: settingsRoot.shownSettingsWindowDefaultWidth + " px"; staged: settingsRoot.stagedSettingsWindowDefaultWidth !== null; showReset: true; onMinus: settingsRoot.stagedSettingsWindowDefaultWidth = Math.max(700, settingsRoot.shownSettingsWindowDefaultWidth - 50); onPlus: settingsRoot.stagedSettingsWindowDefaultWidth = Math.min(1800, settingsRoot.shownSettingsWindowDefaultWidth + 50); onReset: settingsRoot.stagedSettingsWindowDefaultWidth = 1036 }
        SettingsComponents.StepperRow { label: "Default height"; description: "Manual resizing remains temporary"; valueText: settingsRoot.shownSettingsWindowDefaultHeight + " px"; staged: settingsRoot.stagedSettingsWindowDefaultHeight !== null; showReset: true; onMinus: settingsRoot.stagedSettingsWindowDefaultHeight = Math.max(500, settingsRoot.shownSettingsWindowDefaultHeight - 50); onPlus: settingsRoot.stagedSettingsWindowDefaultHeight = Math.min(1200, settingsRoot.shownSettingsWindowDefaultHeight + 50); onReset: settingsRoot.stagedSettingsWindowDefaultHeight = 616 }
    }
}
