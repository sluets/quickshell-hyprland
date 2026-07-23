// Bounded cliphist-backed clipboard history service. // GPT 2026-07-23
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int maxEntries: 25
    property int openViewCount: 0
    property string lastError: ""
    property string pendingDeleteId: ""
    property bool trimming: false
    property var thumbnailQueue: []
    property string thumbnailPendingId: ""
    property string thumbnailPendingPath: ""

    readonly property string thumbnailDir: {
        const runtime = Quickshell.env("XDG_RUNTIME_DIR");
        return (runtime && runtime.length > 0 ? runtime : "/tmp") + "/qs-clipboard-thumbs";
    }

    readonly property alias entries: historyModel
    readonly property int count: historyModel.count

    ListModel { id: historyModel }

    function safeId(id: string): string {
        return id.replace(/[^A-Za-z0-9_.-]/g, "_");
    }

    function thumbnailPath(id: string): string {
        return thumbnailDir + "/clip-" + safeId(id) + ".img";
    }

    function thumbnailUrl(path: string): string {
        return "file://" + path;
    }

    function queueThumbnails(): void {
        const pending = [];
        for (let i = 0; i < historyModel.count; ++i) {
            const row = historyModel.get(i);
            if (row.binary)
                pending.push({ clipId: row.clipId, path: thumbnailPath(row.clipId) });
        }
        thumbnailQueue = pending;
        startNextThumbnail();
    }

    function startNextThumbnail(): void {
        if (thumbnailProc.running || thumbnailQueue.length === 0)
            return;

        const next = thumbnailQueue.shift();
        thumbnailQueue = thumbnailQueue.slice(0);
        thumbnailPendingId = next.clipId;
        thumbnailPendingPath = next.path;
        thumbnailProc.command = ["sh", "-c",
            "mkdir -p \"$2\" && cliphist decode \"$1\" > \"$3.tmp\" && mv -f \"$3.tmp\" \"$3\"",
            "sh", next.clipId, thumbnailDir, next.path];
        thumbnailProc.running = true;
    }

    function previewFor(raw: string): string {
        let value = raw.replace(/[\r\n]+/g, " ").trim();
        if (value.length === 0)
            return "(empty clipboard item)";
        if (value.length > 180)
            value = value.slice(0, 177) + "…";
        return value;
    }

    function refresh(): void {
        // Known-good one-shot refresh: do not interrupt or restart a Process
        // that is still finishing. The next explicit open can refresh again.
        // GPT 2026-07-23
        if (listProc.running)
            return;
        lastError = "";
        listProc.running = true;
    }

    function viewOpened(): void {
        openViewCount += 1;
        refresh();
    }

    function viewClosed(): void {
        openViewCount = Math.max(0, openViewCount - 1);
    }

    function restore(id: string): void {
        if (id.length === 0 || restoreProc.running)
            return;
        lastError = "";
        restoreProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", id];
        restoreProc.running = true;
    }

    function remove(id: string): void {
        if (id.length === 0 || deleteProc.running)
            return;
        lastError = "";
        pendingDeleteId = id;
        deleteProc.command = ["sh", "-c",
            "printf '%s\\n' \"$1\" | cliphist delete && rm -f -- \"$2\" \"$2.tmp\"",
            "sh", id, thumbnailPath(id)];
        deleteProc.running = true;
    }

    function clearAll(): void {
        if (wipeProc.running)
            return;
        lastError = "";
        wipeProc.running = true;
    }

    function trim(): void {
        if (trimProc.running || historyModel.count <= maxEntries)
            return;
        trimming = true;
        trimProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                for (const rawLine of text.split("\n")) {
                    if (rawLine.length === 0)
                        continue;
                    const tab = rawLine.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const id = rawLine.slice(0, tab).trim();
                    const rawPreview = rawLine.slice(tab + 1);
                    if (id.length === 0)
                        continue;
                    rows.push({
                        clipId: id,
                        preview: root.previewFor(rawPreview),
                        binary: rawPreview.indexOf("[[ binary data") >= 0,
                        thumbSource: ""
                    });
                }

                historyModel.clear();
                for (let i = 0; i < Math.min(rows.length, root.maxEntries); ++i)
                    historyModel.append(rows[i]);

                root.queueThumbnails();

                if (rows.length > root.maxEntries)
                    root.trim();
            }
        }
        onExited: (code, status) => {
            if (code !== 0)
                root.lastError = "Could not read clipboard history. Is cliphist installed and running?";
        }
    }

    Process {
        id: thumbnailProc
        onExited: (code, status) => {
            if (code === 0) {
                for (let i = 0; i < historyModel.count; ++i) {
                    if (historyModel.get(i).clipId === root.thumbnailPendingId) {
                        historyModel.setProperty(i, "thumbSource", root.thumbnailUrl(root.thumbnailPendingPath));
                        break;
                    }
                }
            }

            root.thumbnailPendingId = "";
            root.thumbnailPendingPath = "";
            root.startNextThumbnail();
        }
    }

    Process {
        id: restoreProc
        onExited: (code, status) => {
            if (code !== 0)
                root.lastError = "Could not restore that clipboard item.";
        }
    }

    Process {
        id: deleteProc
        onExited: (code, status) => {
            if (code !== 0) {
                root.lastError = "Could not delete that clipboard item.";
            } else {
                for (let i = 0; i < historyModel.count; ++i) {
                    if (historyModel.get(i).clipId === root.pendingDeleteId) {
                        historyModel.remove(i);
                        break;
                    }
                }
            }
            root.pendingDeleteId = "";
        }
    }

    Process {
        id: wipeProc
        command: ["sh", "-c", "cliphist wipe && rm -rf -- \"$1\"", "sh", root.thumbnailDir]
        onExited: (code, status) => {
            if (code !== 0)
                root.lastError = "Could not clear clipboard history.";
            else
                historyModel.clear();
        }
    }

    Process {
        id: trimProc
        command: ["sh", "-c",
            "cliphist list | awk -F '\\t' 'NR > 25 { print $1 }' | " +
            "while IFS= read -r id; do [ -n \"$id\" ] && printf '%s\\n' \"$id\" | cliphist delete; done"]
        onExited: (code, status) => {
            root.trimming = false;
            if (code !== 0)
                root.lastError = "Could not trim clipboard history.";
        }
    }
}
