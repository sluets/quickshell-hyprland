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

    function markLayoutDirty() { layoutDirty = true; }

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
        if (includeTheme)
            command.push("--theme");
        if (includeWallpaper)
            command.push("--wallpaper");
        if (preview || layoutDirty)
            command.push("--layout");
        command.push(
            "--background", colorHex(Theme.colorBackground),
            "--foreground", colorHex(Theme.colorForeground),
            "--accent", colorHex(Theme.colorAccent),
            "--urgent", colorHex(Theme.colorUrgent),
            "--muted", colorHex(Theme.colorMuted),
            "--surface", colorHex(Theme.colorSurface),
            "--hover", colorHex(Theme.colorHover),
            "--border", colorHex(Theme.barBorderColor),
            "--font", Theme.fontFamily,
            "--radius", String(Theme.radiusMedium),
            "--clock-x-offset", String(clockXOffset),
            "--clock-y-offset", String(clockYOffset),
            "--login-x-offset", String(loginXOffset),
            "--login-y-offset", String(loginYOffset),
            "--clock-scale-percent", String(clockScalePercent),
            "--login-scale-percent", String(loginScalePercent),
            "--login-panel-width", String(loginPanelWidth),
            "--login-panel-spacing", String(loginPanelSpacing),
            "--custom-login-text", effectiveLoginText
        );
        return command;
    }

    function changeClockScale(amount) { clockScalePercent = clampScale(clockScalePercent + amount); markLayoutDirty(); }
    function changeLoginScale(amount) { loginScalePercent = clampScale(loginScalePercent + amount); markLayoutDirty(); }
    function changeLoginPanelWidth(amount) { loginPanelWidth = clampPanelWidth(loginPanelWidth + amount); markLayoutDirty(); }
    function changeLoginPanelSpacing(amount) { loginPanelSpacing = clampPanelSpacing(loginPanelSpacing + amount); markLayoutDirty(); }

    function resetClockScale() { if (clockScalePercent !== 100) { clockScalePercent = 100; markLayoutDirty(); } }
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
        if (applying || (!includeTheme && !includeWallpaper && !layoutDirty))
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
        summary: (page.includeTheme ? "Theme" : "No theme") + " · " + (page.includeWallpaper ? "Wallpaper" : "No wallpaper")
        expanded: true

        SettingsComponents.ToggleSettingRow {
            label: "Include current theme"
            value: page.includeTheme
            staged: false
            onToggled: page.includeTheme = !page.includeTheme
        }

        SettingsComponents.ToggleSettingRow {
            label: "Include current wallpaper"
            value: page.includeWallpaper
            staged: false
            onToggled: page.includeWallpaper = !page.includeWallpaper
        }
    }

    SettingsComponents.CollapsibleSection {
        title: "Clock layout"
        summary: page.clockScalePercent + "% · X " + page.clockXOffset + " · Y " + page.clockYOffset
        expanded: false

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
            enabled: !page.applying && (page.includeTheme || page.includeWallpaper || page.layoutDirty)
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
            "d=json.loads(p.read_text()); print(json.dumps({'layout': d.get('layout', {}), 'greeting': d.get('greeting', 'Welcome back')}))"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const saved = JSON.parse(text.trim());
                    const layout = saved.layout || {};
                    page.clockXOffset = page.clampOffset(Number(layout.clockXOffset || 0));
                    page.clockYOffset = page.clampOffset(Number(layout.clockYOffset || 0));
                    page.loginXOffset = page.clampOffset(Number(layout.loginXOffset || 0));
                    page.loginYOffset = page.clampOffset(Number(layout.loginYOffset || 0));
                    page.clockScalePercent = page.clampScale(Number(layout.clockScalePercent || 100));
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
