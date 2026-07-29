import QtQuick
import QtQuick.Layouts
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page
    required property var settingsRoot
    spacing: Theme.spacingMedium
    property string selectedKey: "accent"

    readonly property string editedThemeName: {
        const name = settingsRoot.shownTheme;
        return Theme.themesWithoutCustom[name] ? name : Theme.fallbackThemeName;
    }
    readonly property var baseTheme: Theme.themesWithoutCustom[editedThemeName] || Theme.themesWithoutCustom[Theme.fallbackThemeName]
    readonly property var rows: [
        { key:"background", label:"Background", fallback:baseTheme.colorBackground.toString() },
        { key:"surface", label:"Surface", fallback:baseTheme.colorSurface.toString() },
        { key:"hover", label:"Hover", fallback:baseTheme.colorHover.toString() },
        { key:"foreground", label:"Foreground", fallback:baseTheme.colorForeground.toString() },
        { key:"muted", label:"Muted", fallback:baseTheme.colorMuted.toString() },
        { key:"accent", label:"Accent", fallback:baseTheme.colorAccent.toString() },
        { key:"urgent", label:"Urgent", fallback:baseTheme.colorUrgent.toString() },
        { key:"border", label:"Border primary", fallback:baseTheme.barBorderColor.toString() },
        { key:"border2", label:"Border secondary", fallback:baseTheme.barBorderColor2.a < 0.001 ? "transparent" : baseTheme.barBorderColor2.toString() }
    ]

    function rowFor(key) { for (let r of rows) if (r.key === key) return r; return rows[0]; }
    function currentValueFor(key) {
        const row = rowFor(key);
        return settingsRoot.themeOverride(editedThemeName, key, row.fallback);
    }
    function currentValue() {
        const value = currentValueFor(selectedKey);
        return value === "transparent" ? "#000000" : value;
    }
    function stage(key, value) { settingsRoot.stageThemeOverride(editedThemeName, key, value); }

    SettingsComponents.SettingsSectionHeader { title: "Palette · " + editedThemeName.replace(/Theme$/, "") }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            rowSpacing: Theme.spacingSmall
            columnSpacing: Theme.spacingSmall
            Repeater {
                model: page.rows
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: Theme.radiusMedium
                    color: page.selectedKey === modelData.key ? Theme.colorHover : Theme.colorSurface
                    border.width: page.selectedKey === modelData.key ? 1 : 0
                    border.color: Theme.colorAccent
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingSmall
                        Rectangle {
                            width: 24; height: 24; radius: 4
                            color: page.currentValueFor(modelData.key) === "transparent" ? "transparent" : page.currentValueFor(modelData.key)
                            border.width: 1
                            border.color: Theme.colorMuted
                        }
                        Text {
                            text: modelData.label
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * .85)
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: settingsRoot.hasThemeOverride(page.editedThemeName, modelData.key)
                            text: "•"
                            color: Theme.colorAccent
                            font.pixelSize: Theme.fontSize
                        }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.selectedKey = modelData.key }
                }
            }
        }

        SettingsComponents.ColorGradientPicker {
            id: picker
            Layout.fillWidth: true
            value: page.currentValue()
            onColorEdited: value => page.stage(page.selectedKey, value)
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Selected: " + page.rowFor(page.selectedKey).label; color: Theme.colorMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
            Item { Layout.fillWidth: true }
            TextInput {
                text: page.currentValue()
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                selectByMouse: true
                onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) page.stage(page.selectedKey, text)
            }
            Rectangle {
                visible: settingsRoot.hasThemeOverride(page.editedThemeName, page.selectedKey)
                implicitWidth: resetColorText.implicitWidth + Theme.spacingMedium * 2
                implicitHeight: 34
                radius: Theme.radiusMedium
                color: resetColorMouse.containsMouse ? Theme.colorHover : Theme.colorControl
                border.width: 1; border.color: Theme.colorDivider
                Text { id: resetColorText; anchors.centerIn: parent; text: "Reset color"; color: Theme.colorForeground; font.family: Theme.fontFamily; font.pixelSize: Math.round(Theme.fontSize * .8) }
                MouseArea { id: resetColorMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: settingsRoot.resetThemeOverride(page.editedThemeName, page.selectedKey) }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: page.selectedKey === "border2"
            Text { text: "Secondary border can be transparent for a solid border."; color: Theme.colorMuted; font.family: Theme.fontFamily; font.pixelSize: Math.round(Theme.fontSize * .85); Layout.fillWidth: true; wrapMode: Text.WordWrap }
            Rectangle {
                implicitWidth: 90; implicitHeight: 34; radius: Theme.radiusMedium; color: Theme.colorControl
                Text { anchors.centerIn: parent; text: "Transparent"; color: Theme.colorForeground; font.family: Theme.fontFamily; font.pixelSize: Math.round(Theme.fontSize * .8) }
                MouseArea { anchors.fill: parent; onClicked: page.stage("border2", "transparent") }
            }
        }
    }

    SettingsComponents.SettingsSectionHeader { title: "Border" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall
        SettingsComponents.StepperRow {
            label: "Gradient angle"
            valueColumnWidth: 72
            valueText: Math.round(settingsRoot.themeOverride(page.editedThemeName, "borderAngle", page.baseTheme.barBorderGradientAngle)) + "°"
            staged: settingsRoot.hasThemeOverride(page.editedThemeName, "borderAngle")
            onMinus: {
                const value = Number(settingsRoot.themeOverride(page.editedThemeName, "borderAngle", page.baseTheme.barBorderGradientAngle));
                settingsRoot.stageThemeOverride(page.editedThemeName, "borderAngle", (value + 345) % 360);
            }
            onPlus: {
                const value = Number(settingsRoot.themeOverride(page.editedThemeName, "borderAngle", page.baseTheme.barBorderGradientAngle));
                settingsRoot.stageThemeOverride(page.editedThemeName, "borderAngle", (value + 15) % 360);
            }
            showReset: settingsRoot.hasThemeOverride(page.editedThemeName, "borderAngle")
            onReset: settingsRoot.resetThemeOverride(page.editedThemeName, "borderAngle")
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: resetThemeText.implicitHeight + Theme.spacingMedium * 2
            radius: Theme.radiusMedium
            color: resetThemeMouse.containsMouse ? Theme.colorHover : Theme.colorControl
            border.width: 1; border.color: Theme.colorDivider
            Text { id: resetThemeText; anchors.centerIn: parent; text: "Reset all edits for " + page.editedThemeName.replace(/Theme$/, ""); color: Theme.colorForeground; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
            MouseArea { id: resetThemeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: settingsRoot.resetThemeOverrides(page.editedThemeName) }
        }
    }
}
