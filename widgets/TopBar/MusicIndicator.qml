// MPD top-bar direct controls. The former dropdown is preserved below but disabled.
// GPT — 2026-07-25

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services
import qs.widgets.Music

Item {
    id: root

    visible: MusicService.connected
    implicitWidth: visible ? barRow.implicitWidth : 0
    implicitHeight: barRow.implicitHeight

    readonly property bool isPlaying: MusicService.playbackState === "play"
    readonly property int maxBarChars: 42

    function truncate(str: string): string {
        const value = String(str || "");
        return value.length > maxBarChars
            ? value.slice(0, maxBarChars - 1) + "…"
            : value;
    }

    function displayText(): string {
        if (MusicService.title !== "" && MusicService.artist !== "")
            return truncate(MusicService.title + " — " + MusicService.artist);
        if (MusicService.title !== "")
            return truncate(MusicService.title);
        if (MusicService.fileUri !== "")
            return truncate(MusicService.fileUri.split("/").pop());
        return MusicService.playbackState === "stop" ? "" : "MPD";
    }

    RowLayout {
        id: barRow
        spacing: Theme.spacingSmall

        Text {
            text: root.displayText()
            color: barMouse.containsMouse
                ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: barMouse
        anchors.fill: barRow
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                MusicService.toggle();
            else if (mouse.button === Qt.MiddleButton)
                MusicService.previous();
            else if (mouse.button === Qt.RightButton)
                MusicService.next();
        }
    }

    /*
     * Preserved MPD dropdown implementation. Disabled now that the full music
     * library window is available from the app launcher. Re-enable this block
     * if a compact bar popout is wanted again later. // GPT 2026-07-25
     *
    BarPopout {
        id: popout
        anchorItem: root
        alignment: "left"

        MusicPanel {
            Layout.minimumWidth: 540
            onLibraryRequested: {
                popout.open = false;
                Signals.toggleMusicWindow();
            }
        }
    }
    */
}
