// Standalone MPD library window: Now Playing + Library / All Songs / Queue.
// The initial library browser uses artist tags and folder-derived albums.
// GPT — 2026-07-25

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.core
import qs.services

FloatingWindow {
    id: root

    title: "Quickshell Music"
    color: Theme.colorBackground
    implicitWidth: Math.round(Theme.fontSize * 86)
    implicitHeight: Math.round(Theme.fontSize * 55)
    minimumSize: Qt.size(Math.round(Theme.fontSize * 66), Math.round(Theme.fontSize * 42))
    // Deliberately no maximumSize. Hyprland's Dwindle layout may force a
    // Quickshell xdg_toplevel to float whenever its proposed tile is larger
    // than the client's maximum-size hint. Preferred floating geometry still
    // comes from implicitWidth/implicitHeight. // GPT 2026-07-25

    property bool shown: false
    property int activeTab: 0 // 0 Library, 1 All Songs, 2 Queue
    property string selectedArtist: ""
    property string selectedAlbum: ""
    property string searchText: ""

    visible: shown

    // Window-scoped media shortcut. Qt.WindowShortcut limits this to the
    // active music window, so Space does not become a global play/pause key.
    // GPT — 2026-07-26
    Shortcut {
        sequence: "Space"
        context: Qt.WindowShortcut
        enabled: root.shown
        onActivated: MusicService.toggle()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.shown
        onActivated: root.close()
    }

    // Keep system-audio capture available while the window is open, because
    // Firefox or another application may still be producing sound. The MPD-only
    // source is narrower: pause/stop tears CAVA down and clears the spectrum.
    // GPT — 2026-07-26
    readonly property bool visualizerPlaybackActive:
        UserPrefs.musicVisualizerSource === "system"
        || MusicService.playbackState === "play"

    Binding {
        target: AudioVisualizer
        property: "active"
        value: root.shown
            && UserPrefs.musicVisualizerEnabled
            && root.visualizerPlaybackActive
    }

    readonly property var shownArtists: {
        const _revision = MusicLibrary.libraryRevision;
        const needle = searchText.trim().toLowerCase();
        return needle === ""
            ? MusicLibrary.artists
            : MusicLibrary.artists.filter(name => name.toLowerCase().includes(needle));
    }
    readonly property var selectedAlbums: {
        const _revision = MusicLibrary.libraryRevision;
        return MusicLibrary.albumsForArtist(selectedArtist);
    }
    readonly property var selectedTracks: {
        const _revision = MusicLibrary.libraryRevision;
        return MusicLibrary.tracksForAlbum(selectedArtist, selectedAlbum);
    }
    readonly property var allSongs: {
        const _revision = MusicLibrary.libraryRevision;
        return MusicLibrary.filteredSongs(searchText);
    }

    function open(): void {
        shown = true;
        if (MusicLibrary.songs.length === 0)
            MusicLibrary.refreshLibrary();
        MusicLibrary.refreshQueue();
    }
    function close(): void { shown = false; }
    function toggle(): void { shown ? close() : open(); }

    onClosed: shown = false

    onShownArtistsChanged: {
        if (shownArtists.length === 0) {
            selectedArtist = "";
        } else if (shownArtists.indexOf(selectedArtist) < 0) {
            selectedArtist = shownArtists[0];
        }
    }
    onSelectedAlbumsChanged: {
        if (selectedAlbums.length === 0) {
            selectedAlbum = "";
        } else if (!selectedAlbums.some(item => item.name === selectedAlbum)) {
            selectedAlbum = selectedAlbums[0].name;
        }
    }
    onActiveTabChanged: {
        searchText = "";
        if (activeTab === 2)
            MusicLibrary.refreshQueue();
    }

    function clampScroll(view, value): real {
        return Math.max(0, Math.min(Math.max(0, view.contentHeight - view.height), value));
    }

    function pageMove(view, direction): void {
        if (!view || view.count <= 0)
            return;
        const rowHeight = Math.max(1, Theme.fontSize * 3.3 + 2);
        const rows = Math.max(1, Math.floor(view.height / rowHeight) - 1);
        view.currentIndex = Math.max(0, Math.min(view.count - 1,
            view.currentIndex + direction * rows));
        view.positionViewAtIndex(view.currentIndex, ListView.Contain);
    }

    component FastListView: ListView {
        id: list
        property var leftTarget: null
        property var rightTarget: null
        readonly property real scrollbarWidth: Math.max(8, Theme.fontSize * 0.55)
        readonly property real scrollbarGutter: scrollbarWidth + Theme.spacingSmall
        property bool alwaysShowScrollbar: false
        signal activated(var item)

        spacing: 2
        clip: true
        keyNavigationEnabled: true
        keyNavigationWraps: false
        currentIndex: count > 0 ? 0 : -1
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: Math.max(0, height * 2)

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (currentIndex >= 0 && currentIndex < count) {
                    activated(model[currentIndex]);
                    event.accepted = true;
                }
                break;
            case Qt.Key_PageUp:
                root.pageMove(list, -1);
                event.accepted = true;
                break;
            case Qt.Key_PageDown:
                root.pageMove(list, 1);
                event.accepted = true;
                break;
            case Qt.Key_Left:
                if (leftTarget) {
                    leftTarget.forceActiveFocus();
                    event.accepted = true;
                }
                break;
            case Qt.Key_Right:
                if (rightTarget) {
                    rightTarget.forceActiveFocus();
                    event.accepted = true;
                }
                break;
            }
        }

        // Qt's default wheel step is conservative for these long lists. Keep
        // touchpad pixel scrolling smooth, but multiply both input forms.
        WheelHandler {
            target: null
            onWheel: event => {
                const pixel = event.pixelDelta.y;
                const delta = pixel !== 0
                    ? pixel * 2.2
                    : (event.angleDelta.y / 120) * Theme.fontSize * 8;
                list.contentY = root.clampScroll(list, list.contentY - delta);
                event.accepted = true;
            }
        }

        ScrollBar.vertical: ScrollBar {
            // Explicitly keep the attached bar on this ListView's outer edge.
            // The parent override is intentional: without it, the Controls
            // style may place the attached bar relative to an internal item.
            parent: list
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            policy: list.alwaysShowScrollbar ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
            active: list.alwaysShowScrollbar || hovered || pressed
            interactive: true
            width: list.scrollbarWidth
            z: 20
        }
    }

    component TabButton: Rectangle {
        id: tab
        property string label: ""
        property bool selected: false
        signal clicked
        implicitWidth: labelText.implicitWidth + Theme.spacingLarge * 2
        implicitHeight: labelText.implicitHeight + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: selected ? Theme.colorAccent : (mouse.containsMouse ? Theme.colorHover : "transparent")

        Text {
            id: labelText
            anchors.centerIn: parent
            text: tab.label
            color: tab.selected ? Theme.colorBackground : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: tab.selected
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tab.clicked()
        }
    }

    component ColumnHeader: Text {
        color: Theme.colorForeground
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
    }

    component LibraryRow: Rectangle {
        id: row
        property string title: ""
        property string subtitle: ""
        property bool selected: false
        property bool playing: false
        signal clicked

        implicitHeight: subtitle === "" ? Theme.fontSize * 2.4 : Theme.fontSize * 3.3
        radius: Theme.radiusMedium
        color: selected ? Theme.colorHover : (mouse.containsMouse ? Theme.colorSurface : "transparent")

        Text {
            id: playingGlyph
            visible: row.playing
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            text: "▶"
            color: Theme.colorAccent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Column {
            anchors.left: row.playing ? playingGlyph.right : parent.left
            anchors.leftMargin: Theme.spacingSmall
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: row.title
                color: row.playing ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }
            Text {
                visible: row.subtitle !== ""
                width: parent.width
                text: row.subtitle
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize * 0.86
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }


    component AlbumRow: Rectangle {
        id: albumRow
        property string title: ""
        property string trackText: ""
        property bool selected: false
        signal clicked

        implicitHeight: Theme.fontSize * 3.8
        radius: Theme.radiusMedium
        color: selected ? Theme.colorHover : (albumMouse.containsMouse ? Theme.colorSurface : "transparent")

        ColumnLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.spacingSmall
            anchors.rightMargin: Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: albumRow.title
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: albumRow.trackText
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize * 0.86
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: albumMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: albumRow.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colorBackground

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: nowPlayingPanel.implicitHeight
                Layout.maximumHeight: nowPlayingPanel.implicitHeight
                spacing: Theme.spacingLarge

                MusicPanel {
                    id: nowPlayingPanel
                    Layout.preferredWidth: implicitWidth
                    Layout.maximumWidth: implicitWidth
                    showLibraryButton: false
                }

                AudioSpectrum {
                    visible: UserPrefs.musicVisualizerEnabled
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: visible ? 220 : 0
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                TabButton {
                    label: "Library"
                    selected: root.activeTab === 0
                    onClicked: root.activeTab = 0
                }
                TabButton {
                    label: "All Songs"
                    selected: root.activeTab === 1
                    onClicked: root.activeTab = 1
                }
                TabButton {
                    label: "Queue"
                    selected: root.activeTab === 2
                    onClicked: root.activeTab = 2
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: MusicLibrary.libraryLoading ? "Loading library…"
                        : MusicLibrary.songs.length + " songs"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            Rectangle {
                visible: root.activeTab !== 2
                Layout.fillWidth: true
                implicitHeight: searchInput.implicitHeight + Theme.spacingSmall * 2
                radius: Theme.radiusMedium
                color: Theme.colorSurface
                border.width: 1
                border.color: searchInput.activeFocus ? Theme.colorAccent : Theme.colorMuted

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.rightMargin: Theme.spacingMedium
                    anchors.topMargin: Theme.spacingSmall
                    anchors.bottomMargin: Theme.spacingSmall
                    text: root.searchText
                    color: Theme.colorForeground
                    selectionColor: Theme.colorAccent
                    selectedTextColor: Theme.colorBackground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    clip: true
                    onTextChanged: root.searchText = text
                    Keys.onPressed: event => {
                        if (event.key !== Qt.Key_Down)
                            return;
                        if (root.activeTab === 0)
                            artistList.forceActiveFocus();
                        else if (root.activeTab === 1)
                            allSongsList.forceActiveFocus();
                        event.accepted = true;
                    }
                }

                Text {
                    visible: searchInput.text === "" && !searchInput.activeFocus
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.activeTab === 0 ? "Filter artists…" : "Search title, artist, album folder, or path…"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Library: artist -> folder album -> track.
                RowLayout {
                    id: libraryColumns
                    anchors.fill: parent
                    visible: root.activeTab === 0
                    spacing: Theme.spacingMedium

                    readonly property real usableWidth: Math.max(0, width - spacing * 2)

                    ColumnLayout {
                        Layout.preferredWidth: libraryColumns.usableWidth * 0.31
                        Layout.minimumWidth: Layout.preferredWidth
                        Layout.maximumWidth: Layout.preferredWidth
                        Layout.fillHeight: true
                        spacing: Theme.spacingSmall
                        ColumnHeader { text: "Artists" }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.radiusMedium
                            color: Theme.colorSurface
                            clip: true
                            FastListView {
                                id: artistList
                                anchors.fill: parent
                                anchors.margins: Theme.spacingSmall
                                model: root.shownArtists
                                rightTarget: albumList
                                onActivated: item => root.selectedArtist = String(item)
                                delegate: LibraryRow {
                                    required property var modelData
                                    required property int index
                                    width: Math.max(0, ListView.view.width - ListView.view.scrollbarGutter)
                                    title: String(modelData)
                                    selected: root.selectedArtist === String(modelData)
                                        || (ListView.isCurrentItem && artistList.activeFocus)
                                    onClicked: {
                                        artistList.currentIndex = index;
                                        artistList.forceActiveFocus();
                                        root.selectedArtist = String(modelData);
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: libraryColumns.usableWidth * 0.38
                        Layout.minimumWidth: Layout.preferredWidth
                        Layout.maximumWidth: Layout.preferredWidth
                        Layout.fillHeight: true
                        spacing: Theme.spacingSmall
                        ColumnHeader { text: "Albums (folders)" }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.radiusMedium
                            color: Theme.colorSurface
                            clip: true
                            FastListView {
                                id: albumList
                                anchors.fill: parent
                                anchors.margins: Theme.spacingSmall
                                model: root.selectedAlbums
                                leftTarget: artistList
                                rightTarget: trackList
                                onActivated: item => root.selectedAlbum = item.name
                                delegate: AlbumRow {
                                    required property var modelData
                                    required property int index
                                    width: Math.max(0, ListView.view.width - ListView.view.scrollbarGutter)
                                    title: modelData.name
                                    trackText: modelData.trackCount + (modelData.trackCount === 1 ? " track" : " tracks")
                                    selected: root.selectedAlbum === modelData.name
                                        || (ListView.isCurrentItem && albumList.activeFocus)
                                    onClicked: {
                                        albumList.currentIndex = index;
                                        albumList.forceActiveFocus();
                                        root.selectedAlbum = modelData.name;
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: libraryColumns.usableWidth * 0.31
                        Layout.minimumWidth: Layout.preferredWidth
                        Layout.maximumWidth: Layout.preferredWidth
                        Layout.fillHeight: true
                        spacing: Theme.spacingSmall
                        ColumnHeader {
                            width: parent.width
                            text: root.selectedAlbum === "" ? "Tracks" : root.selectedAlbum
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.radiusMedium
                            color: Theme.colorSurface
                            clip: true
                            FastListView {
                                id: trackList
                                anchors.fill: parent
                                anchors.margins: Theme.spacingSmall
                                alwaysShowScrollbar: true
                                model: root.selectedTracks
                                leftTarget: albumList
                                onActivated: item => MusicLibrary.playAlbum(item.artist, item.album, item.file)
                                delegate: LibraryRow {
                                    required property var modelData
                                    required property int index
                                    width: Math.max(0, ListView.view.width - ListView.view.scrollbarGutter)
                                    title: (modelData.track > 0 ? String(modelData.track).padStart(2, "0") + "  " : "") + modelData.title
                                    subtitle: modelData.artist
                                    selected: ListView.isCurrentItem && trackList.activeFocus
                                    playing: MusicService.fileUri === modelData.file
                                    onClicked: {
                                        trackList.currentIndex = index;
                                        trackList.forceActiveFocus();
                                        MusicLibrary.playAlbum(modelData.artist, modelData.album, modelData.file);
                                    }
                                }
                            }
                        }
                    }
                }

                // Searchable flat library.
                ColumnLayout {
                    anchors.fill: parent
                    visible: root.activeTab === 1
                    spacing: Theme.spacingSmall
                    ColumnHeader { text: "All Songs" }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusMedium
                        color: Theme.colorSurface
                        clip: true
                        FastListView {
                            id: allSongsList
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            model: root.allSongs
                            onActivated: item => MusicLibrary.playSongSet(root.allSongs, item.file)
                            delegate: LibraryRow {
                                required property var modelData
                                required property int index
                                width: Math.max(0, ListView.view.width - ListView.view.scrollbarGutter)
                                title: modelData.title
                                subtitle: modelData.artist + "  —  " + modelData.album
                                selected: ListView.isCurrentItem && allSongsList.activeFocus
                                playing: MusicService.fileUri === modelData.file
                                onClicked: {
                                    allSongsList.currentIndex = index;
                                    allSongsList.forceActiveFocus();
                                    MusicLibrary.playSongSet(root.allSongs, modelData.file);
                                }
                            }
                        }
                    }
                }

                // Current MPD queue.
                ColumnLayout {
                    anchors.fill: parent
                    visible: root.activeTab === 2
                    spacing: Theme.spacingSmall
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnHeader { text: "Current Queue" }
                        Item { Layout.fillWidth: true }
                        TabButton {
                            label: "Refresh"
                            selected: false
                            onClicked: MusicLibrary.refreshQueue()
                        }
                        TabButton {
                            label: "Clear"
                            selected: false
                            onClicked: MusicLibrary.clearQueue()
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusMedium
                        color: Theme.colorSurface
                        clip: true
                        FastListView {
                            id: queueList
                            anchors.fill: parent
                            anchors.margins: Theme.spacingSmall
                            model: MusicLibrary.queueSongs
                            onActivated: item => MusicLibrary.playQueueId(item.id)
                            delegate: LibraryRow {
                                required property var modelData
                                required property int index
                                width: Math.max(0, ListView.view.width - ListView.view.scrollbarGutter)
                                title: (modelData.pos >= 0 ? (modelData.pos + 1) + ".  " : "") + modelData.title
                                subtitle: modelData.artist + "  —  " + modelData.album
                                selected: ListView.isCurrentItem && queueList.activeFocus
                                playing: MusicService.songId === modelData.id
                                onClicked: {
                                    queueList.currentIndex = index;
                                    queueList.forceActiveFocus();
                                    MusicLibrary.playQueueId(modelData.id);
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: MusicLibrary.libraryError !== "" && root.activeTab !== 2
                    text: MusicLibrary.libraryError
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
