//=============================================================================
// widgets/Settings/pages/SddmPage.qml
//
// Manual SDDM snapshot/apply page. This is intentionally independent from the
// Settings window's global staged Apply transaction: nothing happens until the
// dedicated button is pressed. Theme/wallpaper browsing never touches root.
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

    property bool includeTheme: true
    property bool includeWallpaper: true
    property bool applying: false
    property bool testing: false
    property string statusText: "Ready — nothing is copied until you press Apply to SDDM."
    property bool lastSucceeded: false
    property string processOutput: ""
    property string processError: ""
    property string testProcessError: ""

    function chanHex(v) {
        const n = Math.round(Math.max(0, Math.min(1, v)) * 255);
        const h = n.toString(16).toUpperCase();
        return h.length < 2 ? "0" + h : h;
    }

    function colorHex(c) {
        return "#" + chanHex(c.r) + chanHex(c.g) + chanHex(c.b);
    }

    function beginTest() {
        if (testing)
            return;

        processError = "";
        testProcessError = "";
        lastSucceeded = false;
        statusText = "Launching SDDM test window…";
        testing = true;
        testProcess.running = true;
    }

    function beginApply() {
        if (applying || (!includeTheme && !includeWallpaper))
            return;

        processOutput = "";
        processError = "";
        lastSucceeded = false;
        statusText = "Preparing SDDM snapshot…";

        const command = [
            "python3",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-sddm-current.py"
        ];
        if (includeTheme)
            command.push("--theme");
        if (includeWallpaper)
            command.push("--wallpaper");
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
            "--radius", String(Theme.radiusMedium)
        );
        applyProcess.command = command;
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
        text: "Copies a deliberate snapshot of the current desktop look to the login screen. Changing themes or wallpapers normally does not write anything."
        wrapMode: Text.WordWrap
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.85)
    }

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

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Theme.spacingMedium
        implicitHeight: applyLabel.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: applyMouse.containsMouse && applyMouse.enabled
               ? Theme.colorHover : Theme.colorAccent
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
            enabled: !page.applying && (page.includeTheme || page.includeWallpaper)
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: page.beginApply()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: testLabel.implicitHeight + Theme.spacingMedium * 2
        radius: Theme.radiusMedium
        color: testMouse.containsMouse && testMouse.enabled
               ? Theme.colorHover : Theme.colorSurface
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
        id: testProcess
        command: [
            "bash", "-lc",
            "theme=/usr/share/sddm/themes/quickshell-custom; " +
            "if [[ ! -d \"$theme\" ]]; then " +
            "echo 'Installed SDDM theme not found. Apply it first.' >&2; exit 2; " +
            "fi; " +
            "if command -v sddm-greeter-qt6 >/dev/null 2>&1; then " +
            "exec sddm-greeter-qt6 --test-mode --theme \"$theme\"; " +
            "elif command -v sddm-greeter >/dev/null 2>&1; then " +
            "exec sddm-greeter --test-mode --theme \"$theme\"; " +
            "else echo 'No SDDM greeter executable was found.' >&2; exit 127; fi"
        ]

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
                page.statusText = "SDDM test window closed normally.";
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
