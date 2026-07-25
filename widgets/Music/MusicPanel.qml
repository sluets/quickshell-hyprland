// Compact permanent MPD now-playing panel.
// Album-art retrieval is wired in the next phase; the art slot is final UI.
// GPT — 2026-07-25

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: 540
    implicitHeight: panelColumn.implicitHeight
    property bool showLibraryButton: true
    signal libraryRequested()

    readonly property bool isPlaying: MusicService.playbackState === "play"
    readonly property string shownTitle: MusicService.title !== ""
        ? MusicService.title
        : (MusicService.fileUri !== "" ? MusicService.fileUri.split("/").pop() : "Nothing playing")
    readonly property string shownArtist: MusicService.artist !== "" ? MusicService.artist : "Unknown artist"

    function formatSeconds(value): string {
        const seconds = Math.max(0, Math.floor(Number(value) || 0));
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = seconds % 60;
        function pad(n) { return n < 10 ? "0" + n : String(n); }
        return hours > 0
            ? hours + ":" + pad(minutes) + ":" + pad(secs)
            : minutes + ":" + pad(secs);
    }

    function progressRatio(): real {
        if (MusicService.durationSeconds <= 0)
            return 0;
        return Math.max(0, Math.min(1,
            MusicService.elapsedSeconds / MusicService.durationSeconds));
    }

    component IconButton: Rectangle {
        id: button
        property string glyph: ""
        property bool active: false
        property bool prominent: false
        signal clicked

        implicitWidth: prominent ? 52 : 44
        implicitHeight: implicitWidth
        radius: Theme.radiusMedium
        color: mouse.containsMouse ? Theme.colorHover : "transparent"
        scale: mouse.pressed ? 0.92 : 1

        Text {
            anchors.centerIn: parent
            text: button.glyph
            color: button.active ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: button.prominent ? Theme.fontSize * 1.5 : Theme.fontSize * 1.25
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    ColumnLayout {
        id: panelColumn
        width: parent.width
        spacing: Theme.spacingMedium

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 96
                radius: Theme.radiusMedium
                color: Theme.colorSurface
                border.width: 1
                border.color: Theme.colorMuted
                clip: true

                Image {
                    anchors.fill: parent
                    source: AlbumArtService.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: AlbumArtService.hasArt
                }

                Text {
                    anchors.centerIn: parent
                    text: AlbumArtService.busy ? "…" : "♪"
                    visible: !AlbumArtService.hasArt
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize * 2.4
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Theme.spacingSmall / 2

                Text {
                    Layout.fillWidth: true
                    text: root.shownTitle
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize * 1.15
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.shownArtist
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                }

            }

        }

        Item {
            id: seekBar
            Layout.fillWidth: true
            implicitHeight: Theme.fontSize

            Rectangle {
                id: seekTrack
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.colorMuted
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: seekTrack.width * root.progressRatio()
                height: seekTrack.height
                radius: seekTrack.radius
                color: Theme.colorAccent
            }

            Rectangle {
                visible: MusicService.durationSeconds > 0
                x: seekTrack.width * root.progressRatio() - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.fontSize * 0.8
                height: width
                radius: width / 2
                color: Theme.colorAccent
            }

            MouseArea {
                anchors.fill: parent
                enabled: MusicService.durationSeconds > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: mouse => MusicService.seek(
                    Math.max(0, Math.min(1, mouse.x / width))
                    * MusicService.durationSeconds)
                onPositionChanged: mouse => {
                    if (pressed && enabled)
                        MusicService.seek(Math.max(0, Math.min(1, mouse.x / width))
                            * MusicService.durationSeconds);
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingLarge

            IconButton {
                glyph: "\uf048"
                onClicked: MusicService.previous()
            }

            IconButton {
                glyph: root.isPlaying ? "\uf04c" : "\uf04b"
                prominent: true
                active: true
                onClicked: MusicService.toggle()
            }

            IconButton {
                glyph: "\uf051"
                onClicked: MusicService.next()
            }

            Item { Layout.fillWidth: true }

            IconButton {
                glyph: "\uf074"
                active: MusicService.random
                onClicked: MusicService.toggleRandom()
            }

            IconButton {
                glyph: "\uf01e"
                active: MusicService.repeat
                onClicked: MusicService.toggleRepeat()
            }

            IconButton {
                visible: root.showLibraryButton
                glyph: "\uf02d"
                onClicked: root.libraryRequested()
            }
        }
    }
}
