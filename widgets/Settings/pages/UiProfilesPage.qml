//=============================================================================
// widgets/Settings/pages/UiProfilesPage.qml
//
// Phase 1 UI Profiles page: one manually chosen known-good restore point.
// It snapshots the complete persisted UserPrefs JSON plus the wallpaper that
// awww currently reports. Named profiles and profile browsing are deliberately
// deferred; this page exists first as a safe testing escape hatch.
//=============================================================================

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

ColumnLayout {
    id: page

    required property var settingsRoot

    Layout.fillWidth: true
    spacing: Theme.spacingMedium

    property bool busy: false
    property bool hasDefault: false
    property string savedAt: ""
    property string savedWallpaper: ""
    property string statusText: "Save your current working setup before stress-testing the Settings menu."
    property string processOutput: ""
    property string processError: ""

    readonly property string helperPath: Quickshell.env("HOME") + "/.config/quickshell/scripts/settings-profile.sh"

    function wallpaperName(path) {
        const value = String(path || "");
        if (value === "") return "No wallpaper stored";
        const parts = value.split("/");
        return parts[parts.length - 1];
    }

    function refreshStatus() {
        if (busy) return;
        processOutput = "";
        processError = "";
        statusProcess.running = true;
    }

    function saveDefault() {
        busy = true;
        processOutput = "";
        processError = "";
        saveProcess.running = true;
    }

    function restoreDefault() {
        busy = true;
        processOutput = "";
        processError = "";
        restoreProcess.running = true;
    }

    Text {
        Layout.fillWidth: true
        text: "UI Profiles"
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 1.45)
        font.bold: true
    }

    Text {
        Layout.fillWidth: true
        text: "Phase 1 is intentionally simple: one known-good snapshot called My Default. It contains the complete persisted UI settings file and the wallpaper currently shown by awww."
        wrapMode: Text.WordWrap
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: profileLayout.implicitHeight + Theme.spacingLarge * 2
        radius: Theme.radiusMedium
        color: Theme.colorSurface
        border.width: 1
        border.color: Theme.colorMuted

        ColumnLayout {
            id: profileLayout
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMedium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: "My Default"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 1.15)
                        font.bold: true
                    }
                    Text {
                        Layout.fillWidth: true
                        text: page.hasDefault
                            ? "Saved " + (page.savedAt || "at an unknown time")
                            : "No restore point saved yet"
                        color: page.hasDefault ? Theme.colorMuted : Theme.colorAccent
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 0.86)
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: page.hasDefault
                        text: "Wallpaper: " + page.wallpaperName(page.savedWallpaper)
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 0.82)
                        elide: Text.ElideMiddle
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Saving overwrites the previous My Default snapshot. Restoring replaces the live settings file, discards anything currently staged in this window, and restores the saved wallpaper when that file still exists."
                wrapMode: Text.WordWrap
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.88)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMedium

                Button {
                    text: page.hasDefault ? "Overwrite My Default" : "Set Current as My Default"
                    enabled: !page.busy
                    onClicked: saveConfirm.open()
                }

                Button {
                    text: "Restore My Default"
                    enabled: !page.busy && page.hasDefault
                    onClicked: restoreConfirm.open()
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: page.busy ? "Working…" : page.statusText
        wrapMode: Text.WordWrap
        color: page.processError !== "" ? "#ff6b6b" : Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(Theme.fontSize * 0.9)
    }

    Dialog {
        id: saveConfirm
        modal: true
        anchors.centerIn: Overlay.overlay
        title: page.hasDefault ? "Overwrite My Default?" : "Save My Default?"
        standardButtons: Dialog.Save | Dialog.Cancel
        onAccepted: page.saveDefault()

        Text {
            width: Math.min(420, page.width - 80)
            text: "This saves the current applied settings and current wallpaper as your known-good restore point. Any older My Default snapshot will be replaced."
            wrapMode: Text.WordWrap
        }
    }

    Dialog {
        id: restoreConfirm
        modal: true
        anchors.centerIn: Overlay.overlay
        title: "Restore My Default?"
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: page.restoreDefault()

        Text {
            width: Math.min(420, page.width - 80)
            text: "This replaces your current applied UI settings with My Default and discards staged changes in this Settings window."
            wrapMode: Text.WordWrap
        }
    }

    Process {
        id: statusProcess
        command: [page.helperPath, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                page.hasDefault = lines[0] === "saved";
                page.savedAt = lines.length > 1 ? lines[1].trim() : "";
                page.savedWallpaper = lines.length > 2 ? lines[2].trim() : "";
            }
        }
    }

    Process {
        id: saveProcess
        command: [page.helperPath, "save"]
        stdout: StdioCollector { onStreamFinished: page.processOutput = text.trim() }
        stderr: StdioCollector { onStreamFinished: page.processError = text.trim() }
        onExited: code => {
            page.busy = false;
            page.statusText = code === 0 ? (page.processOutput || "My Default saved.")
                                          : "Could not save My Default (exit " + code + ").";
            page.refreshStatus();
        }
    }

    // GPT Rev 24: JsonAdapter reloads the restored file first; then the normal
    // Settings transaction path regenerates Hyprland's generated appearance.
    // The small delay avoids reading the old in-memory values in the same event.
    Timer {
        id: restoredHyprApplyTimer
        interval: 250
        repeat: false
        onTriggered: {
            if (!page.settingsRoot.reapplyCurrentHyprland()) {
                page.statusText = "Profile restored, but Hyprland could not be reapplied while ConfigManager was busy.";
                return;
            }
            page.statusText = "My Default restored; Hyprland settings are being reapplied.";
        }
    }

    Process {
        id: restoreProcess
        command: [page.helperPath, "restore"]
        stdout: StdioCollector { onStreamFinished: page.processOutput = text.trim() }
        stderr: StdioCollector { onStreamFinished: page.processError = text.trim() }
        onExited: code => {
            page.busy = false;
            if (code === 0) {
                page.settingsRoot.discardStaged();
                page.statusText = page.processOutput || "My Default restored.";
                restoredHyprApplyTimer.restart();
            } else {
                page.statusText = "Could not restore My Default (exit " + code + ").";
            }
            page.refreshStatus();
        }
    }

    Component.onCompleted: refreshStatus()
}
