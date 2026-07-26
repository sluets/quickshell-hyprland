// MPD library/queue index used by the standalone music window.
// Albums are derived from the parent folder because this library's album tags
// are not reliable. Artist/title tags remain preferred with path fallbacks.
// GPT — 2026-07-25

pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    readonly property string runtimeSocket: runtimeDir !== "" ? runtimeDir + "/mpd/socket" : ""

    readonly property bool connected: connection.ready
    readonly property string lastError: connection.lastError

    property bool libraryLoading: false
    property bool queueLoading: false
    property string libraryError: ""
    property string queueError: ""
    property var songs: []
    property var queueSongs: []
    property var artists: []
    property int libraryRevision: 0
    property int queueRevision: 0

    function cleanText(value): string {
        return String(value === undefined || value === null ? "" : value).trim();
    }

    function stripExtension(filename): string {
        return cleanText(filename).replace(/\.[^/.]+$/, "");
    }

    function stripTrackPrefix(filename): string {
        return stripExtension(filename)
            .replace(/^\s*\d+[\s._-]+/, "")
            .replace(/^\s*track\s*\d+[\s._-]*/i, "")
            .trim();
    }

    function asInt(value, fallback): int {
        const parsed = Number.parseInt(value, 10);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function asReal(value, fallback): real {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : fallback;
    }

    function finalizeRecord(data): var {
        const file = cleanText(data.file);
        if (file === "")
            return null;

        const parts = file.split("/").filter(p => p !== "");
        const filename = parts.length > 0 ? parts[parts.length - 1] : file;
        const parentFolder = parts.length >= 2 ? parts[parts.length - 2] : "Loose Tracks";
        const pathArtist = parts.length >= 3 ? parts[0] : "Unknown Artist";
        const taggedArtist = cleanText(data.artist || data.albumartist);
        const taggedTitle = cleanText(data.title);
        const trackText = cleanText(data.track).split("/")[0];

        return {
            file: file,
            title: taggedTitle !== "" ? taggedTitle : stripTrackPrefix(filename),
            artist: taggedArtist !== "" ? taggedArtist : pathArtist,
            album: parentFolder,
            track: asInt(trackText, 0),
            disc: asInt(data.disc, 0),
            duration: asReal(data.duration || data.time, 0),
            id: asInt(data.id, -1),
            pos: asInt(data.pos, -1)
        };
    }

    function parseSongRecords(lines): var {
        const result = [];
        let data = null;

        function pushCurrent() {
            if (data === null)
                return;
            const record = root.finalizeRecord(data);
            if (record !== null)
                result.push(record);
        }

        for (let i = 0; i < lines.length; ++i) {
            const line = String(lines[i]);
            const split = line.indexOf(": ");
            if (split < 0)
                continue;
            const key = line.slice(0, split).toLowerCase();
            const value = line.slice(split + 2);
            if (key === "file") {
                pushCurrent();
                data = { file: value };
            } else if (data !== null && data[key] === undefined) {
                data[key] = value;
            }
        }
        pushCurrent();
        return result;
    }

    function songCompare(a, b): int {
        const artistCompare = a.artist.localeCompare(b.artist, undefined, { sensitivity: "base" });
        if (artistCompare !== 0)
            return artistCompare;
        const albumCompare = a.album.localeCompare(b.album, undefined, { sensitivity: "base" });
        if (albumCompare !== 0)
            return albumCompare;
        if (a.disc !== b.disc)
            return a.disc - b.disc;
        if (a.track !== b.track)
            return a.track - b.track;
        return a.title.localeCompare(b.title, undefined, { sensitivity: "base" });
    }

    function rebuildArtists(): void {
        const seen = {};
        const values = [];
        for (let i = 0; i < songs.length; ++i) {
            const artist = songs[i].artist || "Unknown Artist";
            const key = artist.toLowerCase();
            if (seen[key] === undefined) {
                seen[key] = true;
                values.push(artist);
            }
        }
        values.sort((a, b) => a.localeCompare(b, undefined, { sensitivity: "base" }));
        artists = values;
    }

    function refreshLibrary(): void {
        if (!connected || libraryLoading)
            return;
        libraryLoading = true;
        libraryError = "";
        connection.request("listallinfo", function(ok, lines, error) {
            root.libraryLoading = false;
            if (!ok) {
                root.libraryError = String(error || "library query failed");
                return;
            }
            const parsed = root.parseSongRecords(lines);
            parsed.sort(root.songCompare);
            root.songs = parsed;
            root.rebuildArtists();
            root.libraryRevision++;
        });
    }

    function refreshQueue(): void {
        if (!connected || queueLoading)
            return;
        queueLoading = true;
        queueError = "";
        connection.request("playlistinfo", function(ok, lines, error) {
            root.queueLoading = false;
            if (!ok) {
                root.queueError = String(error || "queue query failed");
                return;
            }
            const parsed = root.parseSongRecords(lines);
            parsed.sort((a, b) => a.pos - b.pos);
            root.queueSongs = parsed;
            root.queueRevision++;
        });
    }

    function albumsForArtist(artist): var {
        const wanted = cleanText(artist);
        if (wanted === "")
            return [];
        const seen = {};
        const result = [];
        for (let i = 0; i < songs.length; ++i) {
            const song = songs[i];
            if (song.artist !== wanted)
                continue;
            const key = song.album.toLowerCase();
            if (seen[key] === undefined) {
                seen[key] = true;
                result.push({
                    name: song.album,
                    artist: wanted,
                    trackCount: 1
                });
            } else {
                for (let j = 0; j < result.length; ++j)
                    if (result[j].name.toLowerCase() === key) {
                        result[j].trackCount++;
                        break;
                    }
            }
        }
        result.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }));
        return result;
    }

    function tracksForAlbum(artist, album): var {
        const result = songs.filter(song => song.artist === artist && song.album === album);
        result.sort((a, b) => {
            if (a.disc !== b.disc) return a.disc - b.disc;
            if (a.track !== b.track) return a.track - b.track;
            return a.title.localeCompare(b.title, undefined, { sensitivity: "base" });
        });
        return result;
    }

    function filteredSongs(query): var {
        const needle = cleanText(query).toLowerCase();
        if (needle === "")
            return songs;
        return songs.filter(song =>
            song.title.toLowerCase().includes(needle)
            || song.artist.toLowerCase().includes(needle)
            || song.album.toLowerCase().includes(needle)
            || song.file.toLowerCase().includes(needle));
    }

    function quote(value): string {
        return "\"" + String(value).replace(/\\/g, "\\\\").replace(/\"/g, "\\\"") + "\"";
    }

    function commandList(commands, callback): void {
        if (!connected) {
            if (callback) callback(false, "not connected");
            return;
        }
        const text = "command_list_begin\n" + commands.join("\n") + "\ncommand_list_end";
        connection.request(text, function(ok, _lines, error) {
            if (callback) callback(ok, error);
            if (ok) queueRefreshDelay.restart();
        });
    }

    function playAlbum(artist, album, selectedFile): void {
        const tracks = tracksForAlbum(artist, album);
        if (tracks.length === 0)
            return;
        let selected = 0;
        const commands = ["clear"];
        for (let i = 0; i < tracks.length; ++i) {
            commands.push("add " + quote(tracks[i].file));
            if (tracks[i].file === selectedFile)
                selected = i;
        }
        commands.push("play " + selected);
        commandList(commands, null);
    }

    // Replace MPD's queue with an arbitrary visible song set and start at the
    // clicked song. This gives All Songs the same next/previous behavior as an
    // album: an unfiltered view queues the whole library; a filtered view queues
    // only the matching songs. Random mode then shuffles inside that set.
    function playSongSet(trackSet, selectedFile): void {
        const tracks = Array.isArray(trackSet) ? trackSet : [];
        if (tracks.length === 0 || cleanText(selectedFile) === "")
            return;

        let selected = 0;
        const commands = ["clear"];
        for (let i = 0; i < tracks.length; ++i) {
            commands.push("add " + quote(tracks[i].file));
            if (tracks[i].file === selectedFile)
                selected = i;
        }
        commands.push("play " + selected);
        commandList(commands, null);
    }

    function playSingle(file): void {
        if (cleanText(file) === "")
            return;
        playSongSet([{ file: file }], file);
    }

    function playQueueId(id): void {
        if (id < 0)
            return;
        connection.request("playid " + id, function(ok, _lines, _error) {
            if (ok) queueRefreshDelay.restart();
        });
    }

    function clearQueue(): void {
        connection.request("clear", function(ok, _lines, error) {
            if (!ok)
                root.queueError = String(error || "clear failed");
            queueRefreshDelay.restart();
        });
    }

    MpdConnection {
        id: connection
        enabled: true
        socketCandidates: root.runtimeSocket !== "" ? [root.runtimeSocket] : []
        requestTimeoutMs: 30000

        onReadyChanged: {
            if (ready) {
                initialLoad.restart();
            } else {
                root.libraryLoading = false;
                root.queueLoading = false;
            }
        }
    }

    Timer {
        id: initialLoad
        interval: 150
        repeat: false
        onTriggered: {
            root.refreshLibrary();
            root.refreshQueue();
        }
    }

    // MPD closes non-idle client connections after its configured inactivity
    // timeout (commonly 60 seconds). MusicLibrary can otherwise sit quiet after
    // loading, causing a PeerClosedError/reconnect/full-library refresh cycle.
    // A tiny ping keeps only this library socket alive without changing MPD's
    // global timeout or adding an idle socket. // GPT 2026-07-26
    Timer {
        id: connectionKeepalive
        interval: 45000
        repeat: true
        running: root.connected
        onTriggered: connection.request("ping", null)
    }

    Timer {
        id: queueRefreshDelay
        interval: 250
        repeat: false
        onTriggered: root.refreshQueue()
    }
}
