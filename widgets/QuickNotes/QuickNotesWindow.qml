// Persistent single-note scratchpad backed by ~/.local/share/quickshell/quick-notes.txt. // GPT
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.core

FloatingWindow {
    id: root

    title: "Quickshell Quick Notes"
    color: Theme.colorBackground
    implicitWidth: Math.round(Theme.fontSize * 48)
    implicitHeight: Math.round(Theme.fontSize * 34)
    minimumSize: Qt.size(Math.round(Theme.fontSize * 34), Math.round(Theme.fontSize * 24))
    maximumSize: Qt.size(1400, 1100)
    visible: shown

    property bool shown: false
    property bool loaded: false
    property bool dirty: false
    property bool saveQueued: false
    property bool clearArmed: false
    property string statusText: loaded ? (dirty ? "Unsaved changes" : "Saved automatically") : "Loading…"
    readonly property string helperPath: Quickshell.shellPath("scripts/quick-notes.py")

    function open(): void {
        shown = true;
        if (!loaded && !loadProcess.running)
            loadProcess.running = true;
        Qt.callLater(function() { editor.forceActiveFocus(); });
    }

    function close(): void {
        saveNow();
        shown = false;
    }

    function toggle(): void {
        if (shown) close(); else open();
    }

    function queueSave(): void {
        if (!loaded)
            return;
        dirty = true;
        saveDebounce.restart();
    }

    function saveNow(): void {
        if (!loaded || !dirty)
            return;
        saveDebounce.stop();
        if (saveProcess.running) {
            saveQueued = true;
            return;
        }
        saveQueued = false;
        dirty = false;
        saveProcess.command = ["python3", helperPath, "write", editor.text];
        saveProcess.running = true;
    }

    function copyAll(): void {
        if (copyProcess.running)
            return;
        copyProcess.command = ["python3", helperPath, "copy", editor.text];
        copyProcess.running = true;
    }

    function requestClear(): void {
        if (!clearArmed) {
            clearArmed = true;
            clearArmTimer.restart();
            return;
        }
        clearArmTimer.stop();
        clearArmed = false;
        editor.text = "";
        dirty = true;
        saveNow();
        editor.forceActiveFocus();
    }

    onClosed: {
        saveNow();
        shown = false;
    }

    Timer {
        id: saveDebounce
        interval: 500
        repeat: false
        onTriggered: root.saveNow()
    }

    Timer {
        id: clearArmTimer
        interval: 3000
        repeat: false
        onTriggered: root.clearArmed = false
    }

    Process {
        id: loadProcess
        command: ["python3", root.helperPath, "load"]
        stdout: StdioCollector {
            onStreamFinished: {
                editor.text = text;
                root.loaded = true;
                root.dirty = false;
                Qt.callLater(function() {
                    editor.cursorPosition = editor.length;
                    if (root.shown)
                        editor.forceActiveFocus();
                });
            }
        }
    }

    Process {
        id: saveProcess
        onExited: function(code, status) {
            if (code !== 0)
                root.dirty = true;
            if (root.saveQueued || root.dirty) {
                root.saveQueued = false;
                Qt.callLater(function() { root.saveNow(); });
            }
        }
    }

    Process {
        id: copyProcess
        onExited: function(code, status) {
            copyFeedback.text = code === 0 ? "Copied" : "Copy failed";
            copyFeedbackTimer.restart();
        }
    }

    Timer {
        id: copyFeedbackTimer
        interval: 1600
        repeat: false
        onTriggered: copyFeedback.text = ""
    }

    Item {
        id: keyScope
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
                root.saveNow();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMedium

                Text {
                    text: "Quick Notes"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 1.15)
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + Theme.spacingLarge * 2
                    implicitHeight: Math.round(Theme.fontSize * 2.4)
                    radius: Theme.radiusMedium
                    color: clearMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                    border.width: 1
                    border.color: root.clearArmed ? Theme.colorAccent : Theme.colorMuted

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: root.clearArmed ? "Click again to clear" : "Clear"
                        color: root.clearArmed ? Theme.colorAccent : Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.requestClear()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusMedium
                color: Theme.colorSurface
                border.width: 1
                border.color: editor.activeFocus ? Theme.colorAccent : Theme.colorMuted
                clip: true

                Flickable {
                    id: editorFlick
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    contentWidth: width
                    contentHeight: Math.max(height, editor.contentHeight)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    TextEdit {
                        id: editor
                        width: editorFlick.width
                        height: Math.max(editorFlick.height, contentHeight)
                        color: Theme.colorForeground
                        selectionColor: Theme.colorAccent
                        selectedTextColor: Theme.colorBackground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        persistentSelection: true
                        textFormat: TextEdit.PlainText
                        focus: true

                        onTextChanged: root.queueSave()

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
                                root.saveNow();
                                event.accepted = true;
                            }
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingMedium
                    visible: root.loaded && editor.text.length === 0 && !editor.activeFocus
                    text: "Type or paste anything here…"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMedium

                Text {
                    text: root.statusText
                    color: root.dirty ? Theme.colorAccent : Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.9)
                }

                Item { Layout.fillWidth: true }

                Text {
                    id: copyFeedback
                    text: ""
                    color: Theme.colorAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.9)
                }

                Rectangle {
                    implicitWidth: copyLabel.implicitWidth + Theme.spacingLarge * 2
                    implicitHeight: Math.round(Theme.fontSize * 2.4)
                    radius: Theme.radiusMedium
                    color: copyMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                    border.width: 1
                    border.color: Theme.colorMuted

                    Text {
                        id: copyLabel
                        anchors.centerIn: parent
                        text: "Copy All"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.copyAll()
                    }
                }
            }
        }
    }
}
