//=============================================================================
// widgets/Settings/pages/SddmPage.qml
//
// Manual SDDM snapshot/apply page. This is intentionally independent from the
// Settings window's global staged Apply transaction: nothing happens until the
// dedicated button is pressed. Theme/wallpaper browsing never touches root.
//=============================================================================

import QtQuick
import QtQuick.Controls
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

    property bool includeTheme: true
    property string selectedThemeName: UserPrefs.themeName
    property bool includeWallpaper: true
    property bool applying: false
    property bool testing: false
    property bool layoutLoaded: false
    property bool layoutDirty: false
    property int clockXOffset: 0
    property int clockYOffset: 0
    property int loginXOffset: 0
    property int loginYOffset: 0
    property int clockScalePercent: 100
    property bool showDate: true
    property int dateScalePercent: 100
    property int clockDateSpacing: 8
    property bool clockUseThemeColors: true
    property string clockTimeColor: "#FFFFFF"
    property string clockDateColor: "#FFFFFF"
    property string clockShadowColor: "#000000"
    property int clockShadowOpacityPercent: 56
    property int clockShadowXOffset: 2
    property int clockShadowYOffset: 2
    property int loginScalePercent: 100
    property int loginPanelWidth: 430
    property int loginPanelSpacing: 14
    property bool useCustomLoginText: false
    property string customLoginText: "Welcome back"
    property string statusText: "Ready — nothing is copied until you press Apply to SDDM."
    property bool lastSucceeded: false
    property string processOutput: ""
    property string processError: ""
    property string testProcessError: ""

    readonly property var selectedThemeObject: Theme.themes[selectedThemeName] ?? Theme.themes[Theme.fallbackThemeName]
    readonly property var effectiveThemeObject: includeTheme ? Theme : selectedThemeObject

    readonly property string effectiveLoginText: {
        const value = customLoginText.trim();
        return useCustomLoginText && value !== "" ? value : "Welcome back";
    }

    function chanHex(v) {
        const n = Math.round(Math.max(0, Math.min(1, v)) * 255);
        const h = n.toString(16).toUpperCase();
        return h.length < 2 ? "0" + h : h;
    }

    function colorHex(c) {
        return "#" + chanHex(c.r) + chanHex(c.g) + chanHex(c.b);
    }

    function clampScale(value) { return Math.max(50, Math.min(200, value)); }
    function clampPanelWidth(value) { return Math.max(320, Math.min(720, value)); }
    function clampPanelSpacing(value) { return Math.max(6, Math.min(30, value)); }
    function clampOffset(value) { return Math.max(-4096, Math.min(4096, value)); }
    function clampShadowOpacity(value) { return Math.max(0, Math.min(100, value)); }
    function clampShadowOffset(value) { return Math.max(-20, Math.min(20, value)); }
    function clampDateSpacing(value) { return Math.max(0, Math.min(40, value)); }
    function validHex(value, fallback) {
        const text = String(value || "").trim();
        return new RegExp("^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$").test(text) ? text.toUpperCase() : fallback;
    }

    function markLayoutDirty() { layoutDirty = true; }

    function themeIndex(name) {
        const names = Theme.themeNames;
        const index = names.indexOf(name);
        return index >= 0 ? index : names.indexOf(Theme.fallbackThemeName);
    }

    function changeOffset(propertyName, amount) {
        page[propertyName] = clampOffset(page[propertyName] + amount);
        markLayoutDirty();
    }

    function buildSnapshotCommand(preview) {
        const command = [
            "python3",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-sddm-current.py"
        ];
        if (preview)
            command.push("--preview");
        // A theme is always exported: either the active Quickshell theme or
        // the separately selected SDDM theme.
        command.push("--theme");
        if (includeWallpaper)
            command.push("--wallpaper");
        if (preview || layoutDirty)
            command.push("--layout");
        command.push(
            "--background", colorHex(effectiveThemeObject.colorBackground),
            "--foreground", colorHex(effectiveThemeObject.colorForeground),
            "--accent", colorHex(effectiveThemeObject.colorAccent),
            "--urgent", colorHex(effectiveThemeObject.colorUrgent),
            "--muted", colorHex(effectiveThemeObject.colorMuted),
            "--surface", colorHex(effectiveThemeObject.colorSurface),
            "--hover", colorHex(effectiveThemeObject.colorHover),
            "--border", colorHex(effectiveThemeObject.barBorderColor),
            "--font", effectiveThemeObject.fontFamily,
            "--radius", String(effectiveThemeObject.radiusMedium),
            "--theme-source-mode", includeTheme ? "current" : "selected",
            "--source-theme-name", includeTheme ? UserPrefs.themeName : selectedThemeName,
            "--clock-x-offset", String(clockXOffset),
            "--clock-y-offset", String(clockYOffset),
            "--login-x-offset", String(loginXOffset),
            "--login-y-offset", String(loginYOffset),
            "--clock-scale-percent", String(clockScalePercent),
            "--show-date", showDate ? "true" : "false",
            "--date-scale-percent", String(dateScalePercent),
            "--clock-date-spacing", String(clockDateSpacing),
            "--clock-use-theme-colors", clockUseThemeColors ? "true" : "false",
            "--clock-time-color", clockUseThemeColors ? colorHex(effectiveThemeObject.colorForeground) : validHex(clockTimeColor, "#FFFFFF"),
            "--clock-date-color", clockUseThemeColors ? colorHex(effectiveThemeObject.colorForeground) : validHex(clockDateColor, "#FFFFFF"),
            "--clock-shadow-color", clockUseThemeColors ? "#000000" : validHex(clockShadowColor, "#000000"),
            "--clock-shadow-opacity-percent", String(clockShadowOpacityPercent),
            "--clock-shadow-x-offset", String(clockShadowXOffset),
            "--clock-shadow-y-offset", String(clockShadowYOffset),
            "--login-scale-percent", String(loginScalePercent),
            "--login-panel-width", String(loginPanelWidth),
            "--login-panel-spacing", String(loginPanelSpacing),
            "--custom-login-text", effectiveLoginText
        );
        return command;
    }

    function changeClockScale(amount) { clockScalePercent = clampScale(clockScalePercent + amount); markLayoutDirty(); }
    function changeDateScale(amount) { dateScalePercent = clampScale(dateScalePercent + amount); markLayoutDirty(); }
    function changeClockDateSpacing(amount) { clockDateSpacing = clampDateSpacing(clockDateSpacing + amount); markLayoutDirty(); }
    function changeClockShadowOpacity(amount) { clockShadowOpacityPercent = clampShadowOpacity(clockShadowOpacityPercent + amount); markLayoutDirty(); }
    function changeClockShadowOffset(propertyName, amount) { page[propertyName] = clampShadowOffset(page[propertyName] + amount); markLayoutDirty(); }
    function changeLoginScale(amount) { loginScalePercent = clampScale(loginScalePercent + amount); markLayoutDirty(); }
    function changeLoginPanelWidth(amount) { loginPanelWidth = clampPanelWidth(loginPanelWidth + amount); markLayoutDirty(); }
    function changeLoginPanelSpacing(amount) { loginPanelSpacing = clampPanelSpacing(loginPanelSpacing + amount); markLayoutDirty(); }

    function resetClockScale() { if (clockScalePercent !== 100) { clockScalePercent = 100; markLayoutDirty(); } }
    function resetDateScale() { if (dateScalePercent !== 100) { dateScalePercent = 100; markLayoutDirty(); } }
    function resetClockDateSpacing() { if (clockDateSpacing !== 8) { clockDateSpacing = 8; markLayoutDirty(); } }
    function resetClockColors() {
        clockUseThemeColors = true;
        clockTimeColor = "#FFFFFF";
        clockDateColor = "#FFFFFF";
        clockShadowColor = "#000000";
        markLayoutDirty();
    }
    function resetClockShadowOpacity() { if (clockShadowOpacityPercent !== 56) { clockShadowOpacityPercent = 56; markLayoutDirty(); } }
    function resetClockShadowOffset(propertyName) {
        const defaultValue = propertyName === "clockShadowXOffset" || propertyName === "clockShadowYOffset" ? 2 : 0;
        if (page[propertyName] !== defaultValue) { page[propertyName] = defaultValue; markLayoutDirty(); }
    }
    function resetLoginScale() { if (loginScalePercent !== 100) { loginScalePercent = 100; markLayoutDirty(); } }
    function resetLoginPanelWidth() { if (loginPanelWidth !== 430) { loginPanelWidth = 430; markLayoutDirty(); } }
    function resetLoginPanelSpacing() { if (loginPanelSpacing !== 14) { loginPanelSpacing = 14; markLayoutDirty(); } }
    function resetOffset(propertyName) { if (page[propertyName] !== 0) { page[propertyName] = 0; markLayoutDirty(); } }
    function resetCustomLoginText() {
        useCustomLoginText = false;
        customLoginText = "Welcome back";
        markLayoutDirty();
    }

    function beginTest() {
        if (testing)
            return;
        processError = "";
        testProcessError = "";
        lastSucceeded = false;
        statusText = "Building temporary SDDM preview…";
        testProcess.command = buildSnapshotCommand(true);
        testing = true;
        testProcess.running = true;
    }

    function beginApply() {
        if (applying)
            return;
        processOutput = "";
        processError = "";
        lastSucceeded = false;
        statusText = "Preparing SDDM snapshot…";
        applyProcess.command = buildSnapshotCommand(false);
        applying = true;
        applyProcess.running = true;
    }

    Text {
        text: "SDDM Login Screen"
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    Text {
        Layout.fillWidth: true
        text: "Copies a deliberate snapshot of the current desktop look to the login screen. Expand only the sections you want to customize."
        wrapMode: Text.WordWrap
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.85)
    }

    SettingsComponents.CollapsibleSection {
        title: "Theme & wallpaper"
        summary: (page.includeTheme ? "Current theme" : page.selectedThemeName) + " · " + (page.includeWallpaper ? "Current wallpaper" : "No wallpaper")
        expanded: true

        SettingsComponents.ToggleSettingRow {
            label: "Include current theme"
            value: page.includeTheme
            staged: false
            onToggled: page.includeTheme = !page.includeTheme
        }

        ColumnLayout {
            visible: !page.includeTheme
            Layout.fillWidth: true
            spacing: Theme.spacingSmall

            Text {
                text: "SDDM theme"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.85)
                font.bold: true
            }

            ComboBox {
                id: sddmThemeCombo
                Layout.fillWidth: true
                model: Theme.themeNames
                currentIndex: page.themeIndex(page.selectedThemeName)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize

                onActivated: index => { // qmllint disable signal-handler-parameters
                    if (index >= 0 && index < Theme.themeNames.length)
                        page.selectedThemeName = Theme.themeNames[index];
                }

                contentItem: Text {
                    leftPadding: Theme.spacingMedium
                    rightPadding: Theme.spacingMedium
                    text: sddmThemeCombo.displayText
                    color: Theme.colorForeground
                    font: sddmThemeCombo.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    implicitHeight: 44
                    radius: Theme.radiusMedium
                    color: sddmThemeCombo.hovered ? Theme.colorHover : Theme.colorSurface
                    border.width: sddmThemeCombo.activeFocus ? 2 : 1
                    border.color: sddmThemeCombo.activeFocus ? Theme.colorAccent : Theme.colorMuted
                }

                popup: Popup {
                    y: sddmThemeCombo.height
                    width: sddmThemeCombo.width
                    implicitHeight: Math.min(contentItem.implicitHeight, 320)
                    padding: 1

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: sddmThemeCombo.popup.visible ? sddmThemeCombo.delegateModel : null
                        currentIndex: sddmThemeCombo.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator {}
                    }

                    background: Rectangle {
                        radius: Theme.radiusMedium
                        color: Theme.colorSurface
                        border.width: 1
                        border.color: Theme.colorMuted
                    }
                }

                delegate: ItemDelegate {
                    required property var modelData
                    required property int index
                    width: sddmThemeCombo.width
                    highlighted: sddmThemeCombo.highlightedIndex === index

                    contentItem: Text {
                        text: modelData
                        color: highlighted ? Theme.colorBackground : Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    background: Rectangle {
                        color: highlighted ? Theme.colorAccent : (hovered ? Theme.colorHover : "transparent")
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Preview and Apply will export this theme without changing the active desktop theme."
                wrapMode: Text.WordWrap
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.75)
            }
        }

        SettingsComponents.ToggleSettingRow {
            label: "Include current wallpaper"
            value: page.includeWallpaper
            staged: false
            onToggled: page.includeWallpaper = !page.includeWallpaper
        }
    }

    SettingsComponents.CollapsibleSection {
        title: "Clock"
        summary: (page.showDate ? "Time + date" : "Time only") + " · " + page.clockScalePercent + "%"
        expanded: false

        SettingsComponents.CollapsibleSection {
            title: "Position & scale"
            summary: "X " + page.clockXOffset + " · Y " + page.clockYOffset
            expanded: true

            SettingsComponents.StepperRow {
                label: "Clock scale"
                valueText: page.clockScalePercent + "%"
                staged: page.layoutDirty
                showReset: true
                labelColumnWidth: 220
                valueColumnWidth: 78
                onMinus: page.changeClockScale(-10)
                onPlus: page.changeClockScale(10)
                onReset: page.resetClockScale()
            }

            SettingsComponents.StepperRow {
                label: "Clock horizontal"
                valueText: (page.clockXOffset > 0 ? "+" : "") + page.clockXOffset + " px"
                staged: page.layoutDirty
                showReset: true
                labelColumnWidth: 220
                valueColumnWidth: 78
                onMinus: page.changeOffset("clockXOffset", -10)
                onPlus: page.changeOffset("clockXOffset", 10)
                onReset: page.resetOffset("clockXOffset")
            }

            SettingsComponents.StepperRow {
                label: "Clock vertical"
                valueText: (page.clockYOffset > 0 ? "+" : "") + page.clockYOffset + " px"
                staged: page.layoutDirty
                showReset: true
                labelColumnWidth: 220
                valueColumnWidth: 78
                onMinus: page.changeOffset("clockYOffset", -10)
                onPlus: page.changeOffset("clockYOffset", 10)
                onReset: page.resetOffset("clockYOffset")
            }
        }

        SettingsComponents.CollapsibleSection {
            title: "Date"
            summary: page.showDate ? (page.dateScalePercent + "% · " + page.clockDateSpacing + " px gap") : "Hidden"
            expanded: false

            SettingsComponents.ToggleSettingRow {
                label: "Show date"
                value: page.showDate
                staged: page.layoutDirty
                onToggled: { page.showDate = !page.showDate; page.markLayoutDirty(); }
            }

            SettingsComponents.StepperRow {
                visible: page.showDate
                label: "Date scale"
                valueText: page.dateScalePercent + "%"
                staged: page.layoutDirty
                showReset: true
                labelColumnWidth: 220
                valueColumnWidth: 78
                onMinus: page.changeDateScale(-10)
                onPlus: page.changeDateScale(10)
                onReset: page.resetDateScale()
            }

            SettingsComponents.StepperRow {
                visible: page.showDate
                label: "Time/date spacing"
                valueText: page.clockDateSpacing + " px"
                staged: page.layoutDirty
                showReset: true
                labelColumnWidth: 220
                valueColumnWidth: 78
                onMinus: page.changeClockDateSpacing(-2)
                onPlus: page.changeClockDateSpacing(2)
                onReset: page.resetClockDateSpacing()
            }
        }

        SettingsComponents.CollapsibleSection {
            title: "Colors"
            summary: page.clockUseThemeColors ? "Theme colors" : "Custom colors"
            expanded: false

            SettingsComponents.ToggleSettingRow {
                label: "Use theme colors"
                value: page.clockUseThemeColors
                staged: page.layoutDirty
                onToggled: { page.clockUseThemeColors = !page.clockUseThemeColors; page.markLayoutDirty(); }
            }

            SettingsComponents.HexColorRow {
                visible: !page.clockUseThemeColors
                colorPickerHost: page.settingsRoot
                label: "Time color"
                shownValue: page.clockTimeColor
                staged: page.layoutDirty
                onHexStaged: text => { page.clockTimeColor = text; page.markLayoutDirty(); }
            }

            SettingsComponents.HexColorRow {
                visible: !page.clockUseThemeColors
                colorPickerHost: page.settingsRoot
                label: "Date color"
                shownValue: page.clockDateColor
                staged: page.layoutDirty
                onHexStaged: text => { page.clockDateColor = text; page.markLayoutDirty(); }
            }

            SettingsComponents.HexColorRow {
                visible: !page.clockUseThemeColors
                colorPickerHost: page.settingsRoot
                label: "Shadow color"
                shownValue: page.clockShadowColor
                staged: page.layoutDirty
                onHexStaged: text => { page.clockShadowColor = text; page.markLayoutDirty(); }
            }

            Rectangle {
                visible: !page.clockUseThemeColors
                Layout.alignment: Qt.AlignLeft
                implicitWidth: resetClockColorsText.implicitWidth + Theme.spacingMedium * 2
                implicitHeight: resetClockColorsText.implicitHeight + Theme.spacingSmall * 2
                radius: Theme.radiusMedium
                color: resetClockColorsMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                Text { id: resetClockColorsText; anchors.centerIn: parent; text: "Reset clock colors"; color: Theme.colorForeground; font.family: Theme.fontFamily; font.pixelSize: Math.round(Theme.fontSize * 0.82) }
                MouseArea { id: resetClockColorsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.resetClockColors() }
            }
        }

        SettingsComponents.CollapsibleSection {
            title: "Shadow"
            summary: page.clockShadowOpacityPercent + "% · X " + page.clockShadowXOffset + " · Y " + page.clockShadowYOffset
            expanded: false

            SettingsComponents.StepperRow {
                label: "Shadow strength"
                valueText: page.clockShadowOpacityPercent + "%"
                staged: page.layoutDirty
                showReset: true
                labelColumnWidth: 220
                valueColumnWidth: 78
                onMinus: page.changeClockShadowOpacity(-5)
                onPlus: page.changeClockShadowOpacity(5)
                onReset: page.resetClockShadowOpacity()
            }

            SettingsComponents.StepperRow {
                label: "Shadow horizontal"
                valueText: (page.clockShadowXOffset > 0 ? "+" : "") + page.clockShadowXOffset + " px"
                staged: page.layoutDirty
                showReset: true
                labelColumnWidth: 220
                valueColumnWidth: 78
                onMinus: page.changeClockShadowOffset("clockShadowXOffset", -1)
                onPlus: page.changeClockShadowOffset("clockShadowXOffset", 1)
                onReset: page.resetClockShadowOffset("clockShadowXOffset")
            }

            SettingsComponents.StepperRow {
                label: "Shadow vertical"
                valueText: (page.clockShadowYOffset > 0 ? "+" : "") + page.clockShadowYOffset + " px"
                staged: page.layoutDirty
                showReset: true
                labelColumnWidth: 220
                valueColumnWidth: 78
                onMinus: page.changeClockShadowOffset("clockShadowYOffset", -1)
                onPlus: page.changeClockShadowOffset("clockShadowYOffset", 1)
                onReset: page.resetClockShadowOffset("clockShadowYOffset")
            }
        }
    }

    SettingsComponents.CollapsibleSection {
        title: "Login panel layout"
        summary: page.loginPanelWidth + " px · " + page.loginScalePercent + "%"
        expanded: false

        SettingsComponents.StepperRow {
            label: "Login panel scale"
            valueText: page.loginScalePercent + "%"
            staged: page.layoutDirty
            showReset: true
            labelColumnWidth: 220
            valueColumnWidth: 78
            onMinus: page.changeLoginScale(-10)
            onPlus: page.changeLoginScale(10)
            onReset: page.resetLoginScale()
        }

        SettingsComponents.StepperRow {
            label: "Login panel width"
            valueText: page.loginPanelWidth + " px"
            staged: page.layoutDirty
            showReset: true
            labelColumnWidth: 220
            valueColumnWidth: 78
            onMinus: page.changeLoginPanelWidth(-20)
            onPlus: page.changeLoginPanelWidth(20)
            onReset: page.resetLoginPanelWidth()
        }

        SettingsComponents.StepperRow {
            label: "Panel spacing"
            valueText: page.loginPanelSpacing + " px"
            staged: page.layoutDirty
            showReset: true
            labelColumnWidth: 220
            valueColumnWidth: 78
            onMinus: page.changeLoginPanelSpacing(-2)
            onPlus: page.changeLoginPanelSpacing(2)
            onReset: page.resetLoginPanelSpacing()
        }

        SettingsComponents.StepperRow {
            label: "Login horizontal"
            valueText: (page.loginXOffset > 0 ? "+" : "") + page.loginXOffset + " px"
            staged: page.layoutDirty
            showReset: true
            labelColumnWidth: 220
            valueColumnWidth: 78
            onMinus: page.changeOffset("loginXOffset", -10)
            onPlus: page.changeOffset("loginXOffset", 10)
            onReset: page.resetOffset("loginXOffset")
        }

        SettingsComponents.StepperRow {
            label: "Login vertical"
            valueText: (page.loginYOffset > 0 ? "+" : "") + page.loginYOffset + " px"
            staged: page.layoutDirty
            showReset: true
            labelColumnWidth: 220
            valueColumnWidth: 78
            onMinus: page.changeOffset("loginYOffset", -10)
            onPlus: page.changeOffset("loginYOffset", 10)
            onReset: page.resetOffset("loginYOffset")
        }

        SettingsComponents.ToggleSettingRow {
            label: "Use custom login text"
            value: page.useCustomLoginText
            staged: page.layoutDirty
            onToggled: {
                page.useCustomLoginText = !page.useCustomLoginText;
                page.markLayoutDirty();
            }
        }

        TextField {
            id: customLoginTextField
            visible: page.useCustomLoginText
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            text: page.customLoginText
            placeholderText: "Welcome back"
            color: Theme.colorForeground
            placeholderTextColor: Theme.colorMuted
            selectionColor: Theme.colorAccent
            selectedTextColor: Theme.colorBackground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            selectByMouse: true

            background: Rectangle {
                radius: Theme.radiusMedium
                color: customLoginTextField.activeFocus ? Theme.colorHover : Theme.colorSurface
                border.width: customLoginTextField.activeFocus ? 2 : 1
                border.color: customLoginTextField.activeFocus ? Theme.colorAccent : Theme.colorMuted
            }

            onTextEdited: {
                page.customLoginText = text;
                page.markLayoutDirty();
            }
        }

        Rectangle {
            visible: page.useCustomLoginText
            Layout.alignment: Qt.AlignLeft
            implicitWidth: resetLoginText.implicitWidth + Theme.spacingMedium * 2
            implicitHeight: resetLoginText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: resetLoginTextMouse.containsMouse ? Theme.colorHover : Theme.colorSurface

            Text {
                id: resetLoginText
                anchors.centerIn: parent
                text: "Reset login text"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.82)
            }

            MouseArea {
                id: resetLoginTextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.resetCustomLoginText()
            }
        }
    }

    SettingsComponents.CollapsibleSection {
        title: "Advanced"
        summary: "Preview and apply details"
        expanded: false

        Text {
            Layout.fillWidth: true
            text: "Positive X moves right; positive Y moves down. Test builds a temporary user-owned theme and never writes to /usr/share."
            wrapMode: Text.WordWrap
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.78)
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacingSmall
        implicitHeight: applyLabel.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: applyMouse.containsMouse && applyMouse.enabled ? Theme.colorHover : Theme.colorAccent
        opacity: applyMouse.enabled ? 1.0 : 0.45

        Text {
            id: applyLabel
            anchors.centerIn: parent
            text: page.applying ? "Applying…" : "Apply to SDDM"
            color: Theme.colorBackground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        MouseArea {
            id: applyMouse
            anchors.fill: parent
            enabled: !page.applying
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: page.beginApply()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: testLabel.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: testMouse.containsMouse && testMouse.enabled ? Theme.colorHover : Theme.colorSurface
        border.width: 1
        border.color: Theme.colorAccent
        opacity: testMouse.enabled ? 1.0 : 0.45

        Text {
            id: testLabel
            anchors.centerIn: parent
            text: page.testing ? "SDDM Test Running…" : "Test SDDM Theme"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        MouseArea {
            id: testMouse
            anchors.fill: parent
            enabled: !page.testing && !page.applying
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: page.beginTest()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: statusColumn.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: Theme.colorSurface
        border.width: 1
        border.color: page.lastSucceeded ? Theme.colorAccent : Theme.colorMuted

        ColumnLayout {
            id: statusColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingMedium
            spacing: Theme.spacingSmall

            Text {
                Layout.fillWidth: true
                text: page.statusText
                wrapMode: Text.WordWrap
                color: page.lastSucceeded ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.85)
            }

            Text {
                visible: page.processError !== ""
                Layout.fillWidth: true
                text: page.processError
                wrapMode: Text.WrapAnywhere
                color: Theme.colorUrgent
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.75)
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "The installed snapshot is hash-compared first. If it is already identical, the helper reports that it is up to date and writes nothing."
        wrapMode: Text.WordWrap
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.78)
    }

    Process {
        id: layoutReadProcess
        command: [
            "python3", "-c",
            "import json,pathlib; p=pathlib.Path.home()/'.config/sddm-project/snapshot/snapshot-input.json'; " +
            "d=json.loads(p.read_text()); print(json.dumps({'layout': d.get('layout', {}), 'greeting': d.get('greeting', 'Welcome back'), 'themeSelection': d.get('themeSelection', {}), 'clockAppearance': d.get('clockAppearance', {})}))"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const saved = JSON.parse(text.trim());
                    const layout = saved.layout || {};
                    const themeSelection = saved.themeSelection || {};
                    const clockAppearance = saved.clockAppearance || {};
                    const savedThemeName = String(themeSelection.name || UserPrefs.themeName);
                    page.includeTheme = String(themeSelection.mode || "current") !== "selected";
                    page.selectedThemeName = Theme.themes[savedThemeName] ? savedThemeName : Theme.fallbackThemeName;
                    page.clockXOffset = page.clampOffset(Number(layout.clockXOffset || 0));
                    page.clockYOffset = page.clampOffset(Number(layout.clockYOffset || 0));
                    page.loginXOffset = page.clampOffset(Number(layout.loginXOffset || 0));
                    page.loginYOffset = page.clampOffset(Number(layout.loginYOffset || 0));
                    page.clockScalePercent = page.clampScale(Number(layout.clockScalePercent || 100));
                    page.showDate = layout.showDate !== false;
                    page.dateScalePercent = page.clampScale(Number(layout.dateScalePercent || 100));
                    page.clockDateSpacing = page.clampDateSpacing(Number(layout.clockDateSpacing ?? 8));
                    page.clockUseThemeColors = clockAppearance.useThemeColors !== false;
                    page.clockTimeColor = page.validHex(clockAppearance.timeColor, "#FFFFFF");
                    page.clockDateColor = page.validHex(clockAppearance.dateColor, "#FFFFFF");
                    page.clockShadowColor = page.validHex(clockAppearance.shadowColor, "#000000");
                    page.clockShadowOpacityPercent = page.clampShadowOpacity(Number(layout.clockShadowOpacityPercent ?? 56));
                    page.clockShadowXOffset = page.clampShadowOffset(Number(layout.clockShadowXOffset ?? 2));
                    page.clockShadowYOffset = page.clampShadowOffset(Number(layout.clockShadowYOffset ?? 2));
                    page.loginScalePercent = page.clampScale(Number(layout.loginScalePercent || 100));
                    page.loginPanelWidth = page.clampPanelWidth(Number(layout.loginPanelWidth || 430));
                    page.loginPanelSpacing = page.clampPanelSpacing(Number(layout.loginPanelSpacing || 14));
                    page.customLoginText = String(saved.greeting || "Welcome back");
                    page.useCustomLoginText = page.customLoginText !== "Welcome back";
                    page.layoutDirty = false;
                    page.layoutLoaded = true;
                } catch (error) {
                    page.processError = "Could not read saved SDDM layout: " + error;
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    page.processError = "Could not read saved SDDM layout: " + text.trim();
            }
        }
    }

    Component.onCompleted: layoutReadProcess.running = true

    Process {
        id: testProcess

        stderr: StdioCollector {
            // SDDM test mode writes normal diagnostic chatter to stderr,
            // including a harmless QLocalSocket warning because no real
            // display-manager daemon is attached. Keep it hidden unless the
            // process actually fails.
            onStreamFinished: page.testProcessError = text.trim()
        }

        onExited: code => { // qmllint disable signal-handler-parameters
            page.testing = false;
            if (code === 0) {
                page.processError = "";
                page.statusText = "Temporary SDDM preview closed normally — nothing was installed.";
            } else {
                page.processError = page.testProcessError;
                page.statusText = "SDDM test failed (exit " + code + ").";
            }
        }
    }

    Process {
        id: applyProcess

        stdout: StdioCollector {
            onStreamFinished: page.processOutput = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: page.processError = text.trim()
        }
        onExited: code => { // qmllint disable signal-handler-parameters
            page.applying = false;
            page.lastSucceeded = (code === 0);
            if (code === 0) {
                page.layoutDirty = false;
                if (page.processOutput.indexOf("already up to date") >= 0)
                    page.statusText = "SDDM is already up to date — no files were written.";
                else
                    page.statusText = "SDDM theme snapshot applied successfully.";
            } else {
                page.statusText = "SDDM apply failed (exit " + code + ").";
            }
        }
    }
}
