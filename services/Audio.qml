//=============================================================================
// FILE
//=============================================================================
//
// services/Audio.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The one place the shell talks to PipeWire. Exposes the default output
// sink's volume/mute state, the list of available output devices, and
// clean functions for changing all of it. Widgets read/call THIS — they
// never touch Quickshell.Services.Pipewire directly.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell                     (Singleton)
// Quickshell.Services.Pipewire   (Pipewire singleton, PwNode,
//                                 PwObjectTracker)
// core/Settings.qml              (volumeStep — via `import qs.core`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/Volume.qml (display, scroll-to-adjust, and the popout's
// slider / mute / device list).
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Volume.qml fails to resolve `Audio` and the bar fails to load.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// VOLUME/MUTE GUARDS: optional chaining with explicit fallbacks
// (`sink?.audio?.volume ?? 0`) plus a Number.isFinite check — this is
// the fix for the "NaN%" bug, do not regress it. Full story in
// docs/PROBLEMS_AND_FIXES.md ("Volume showed NaN% ...").
//
// SINK LIST: rebuilt whenever Pipewire.nodes changes, filtering out
// streams (per-application audio) and sources (inputs/mics). This exact
// filter (isStream / isSink / audio) was verified against a maintained
// real-world Quickshell config, not invented here. Input devices are
// deliberately NOT exposed
// yet: nothing in the bar needs a mic picker today. Add a `sources` list
// mirroring `sinks` when something does.
//
// DEVICE SWITCHING: `Pipewire.preferredDefaultAudioSink = node` is the
// documented Quickshell way to change the default output. WirePlumber
// then moves streams over.
//
// PwObjectTracker: sinks must be BOUND for their properties (volume,
// muted, description) to populate instead of reading undefined. The
// tracker below binds the default sink AND every sink in the list (the
// popout shows descriptions for all of them).
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-03  Added `sinks` (all output devices), `setSink()`,
//             `incrementVolume()` / `decrementVolume()` (step from
//             Settings.volumeStep). PwObjectTracker now binds the whole
//             sink list, not just the default. Existing volume/muted
//             guards untouched.
// 2026-07-02  Rewrote volume/muted with optional chaining + explicit
//             fallbacks (the NaN% fix).
// 2026-07-01  Initial service.
//
//=============================================================================

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.core

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink

    // Hardware output devices, hardware input devices, and active
    // application playback streams. All lists are rebuilt from the PipeWire
    // node model and bound by the tracker below before their volume metadata
    // is consumed by the UI. // GPT Rev 30
    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> playbackStreams: []
    property var playbackGroups: []

    // Track every audio node before attempting to classify application streams.
    // PwNode.properties is unavailable until a node is bound, and on this system
    // stream direction/classification also did not become dependable early enough
    // for the old filter-first approach. // GPT Rev 32
    property list<PwNode> trackedAudioNodes: []
    property int nodeRefreshAttempts: 0

    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: {
        const v = sink?.audio?.volume ?? 0;
        return Number.isFinite(v) ? v : 0;
    }

    readonly property bool muted: !!(sink?.audio?.muted ?? true)

    function setVolume(v: real): void {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function incrementVolume(): void {
        setVolume(volume + Settings.volumeStep);
    }

    function decrementVolume(): void {
        setVolume(volume - Settings.volumeStep);
    }

    function toggleMute(): void {
        if (!sink?.audio) return;
        sink.audio.muted = !sink.audio.muted;
    }

    function setSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    readonly property real sourceVolume: {
        const v = source?.audio?.volume ?? 0;
        return Number.isFinite(v) ? v : 0;
    }

    readonly property bool sourceMuted: !!(source?.audio?.muted ?? true)

    function setSourceVolume(v: real): void {
        if (!source?.audio) return;
        source.audio.muted = false;
        source.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleSourceMute(): void {
        if (!source?.audio) return;
        source.audio.muted = !source.audio.muted;
    }

    function setStreamVolume(node: PwNode, v: real): void {
        if (!node?.audio) return;
        node.audio.muted = false;
        node.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleStreamMute(node: PwNode): void {
        if (!node?.audio) return;
        node.audio.muted = !node.audio.muted;
    }

    function streamName(node: PwNode): string {
        const properties = node?.properties ?? {};
        const rawName = String(properties["application.name"]
            || properties["application.process.binary"]
            || node?.nickname
            || node?.description
            || node?.name
            || "Application");

        // MPD can expose itself as mpd, Music Player Daemon, or by the
        // pipewire client/node name depending on its output plugin. Keep the
        // menu human-facing and stable. // GPT Rev 31
        if (/\bmpd\b|music player daemon/i.test(rawName))
            return "Music";
        return rawName;
    }

    function streamDescription(node: PwNode): string {
        const properties = node?.properties ?? {};
        return properties["media.name"] || properties["media.title"] || "";
    }

    function streamIcon(node: PwNode): string {
        const properties = node?.properties ?? {};
        return properties["application.icon-name"] || "";
    }

    function streamGroupKey(node: PwNode): string {
        const properties = node?.properties ?? {};
        const binary = String(properties["application.process.binary"] || "").trim().toLowerCase();
        if (binary !== "")
            return binary;

        return streamName(node).trim().toLowerCase();
    }

    function buildPlaybackGroups(nodes: var): var {
        const byKey = {};
        const groups = [];

        for (const node of nodes) {
            const key = streamGroupKey(node);
            if (!byKey[key]) {
                const group = {
                    key: key,
                    name: streamName(node),
                    iconName: streamIcon(node),
                    nodes: []
                };
                byKey[key] = group;
                groups.push(group);
            }

            byKey[key].nodes.push(node);
            if (!byKey[key].iconName)
                byKey[key].iconName = streamIcon(node);
        }

        groups.sort((a, b) => a.name.localeCompare(b.name));
        return groups;
    }

    function groupDescription(group: var): string {
        if (!group?.nodes || group.nodes.length === 0)
            return "";

        if (group.nodes.length === 1)
            return streamDescription(group.nodes[0]);

        return group.nodes.length + " active streams";
    }

    function groupVolume(group: var): real {
        if (!group?.nodes || group.nodes.length === 0)
            return 0;

        let total = 0;
        let count = 0;
        for (const node of group.nodes) {
            const value = node?.audio?.volume;
            if (Number.isFinite(value)) {
                total += value;
                count++;
            }
        }
        return count > 0 ? total / count : 0;
    }

    function groupMuted(group: var): bool {
        if (!group?.nodes || group.nodes.length === 0)
            return false;

        for (const node of group.nodes) {
            if (!(node?.audio?.muted ?? false))
                return false;
        }
        return true;
    }

    function setGroupVolume(group: var, value: real): void {
        if (!group?.nodes)
            return;
        for (const node of group.nodes)
            setStreamVolume(node, value);
    }

    function toggleGroupMute(group: var): void {
        if (!group?.nodes)
            return;

        const shouldMute = !groupMuted(group);
        for (const node of group.nodes) {
            if (node?.audio)
                node.audio.muted = shouldMute;
        }
    }

    function refreshTrackedNodes(): void {
        const nodes = [];
        for (const node of Pipewire.nodes.values) {
            if (node.audio)
                nodes.push(node);
        }

        root.trackedAudioNodes = nodes;
        root.nodeRefreshAttempts = 0;
        nodeRefreshTimer.restart();
    }

    function allTrackedNodesReady(): bool {
        for (const node of root.trackedAudioNodes) {
            if (!node.ready)
                return false;
        }
        return true;
    }

    function rebuildNodes(): void {
        const newSinks = [];
        const newSources = [];
        const newPlaybackStreams = [];

        // Classify only after the tracker has had a chance to bind the nodes.
        // The user's PipeWire graph exposes MPD and Firefox as
        // Stream/Output/Audio nodes, confirmed by wpctl and pw-dump. // GPT Rev 32
        for (const node of root.trackedAudioNodes) {
            if (!node.audio)
                continue;

            const properties = node.properties ?? {};
            const mediaClass = String(properties["media.class"] || node.type || "");
            const explicitPlayback = /^Stream\/Output\/Audio$/i.test(mediaClass);
            const explicitCapture = /^Stream\/Input\/Audio$/i.test(mediaClass);

            if ((node.isStream && !explicitCapture) || explicitPlayback) {
                newPlaybackStreams.push(node);
            } else if (!node.isStream && node.isSink) {
                newSinks.push(node);
            } else if (!node.isStream) {
                newSources.push(node);
            }
        }

        newPlaybackStreams.sort((a, b) => streamName(a).localeCompare(streamName(b)));
        root.sinks = newSinks;
        root.sources = newSources;
        root.playbackStreams = newPlaybackStreams;
        root.playbackGroups = buildPlaybackGroups(newPlaybackStreams);
    }

    Component.onCompleted: refreshTrackedNodes()

    Timer {
        id: nodeRefreshTimer
        interval: 100
        repeat: true

        onTriggered: {
            root.rebuildNodes();
            root.nodeRefreshAttempts++;

            // Usually every node is ready on the first or second pass. Keep a
            // bounded retry window for clients that finish binding slightly later.
            if (root.allTrackedNodesReady() || root.nodeRefreshAttempts >= 20)
                stop();
        }
    }

    Connections {
        target: Pipewire.nodes

        function onValuesChanged(): void {
            root.refreshTrackedNodes();
        }
    }

    // Component.onCompleted can run before PipeWire's initial graph sync has
    // finished. Rebuild once the service becomes ready so applications that
    // were already playing before Quickshell started are not missed. // GPT Rev 31
    Connections {
        target: Pipewire

        function onReadyChanged(): void {
            if (Pipewire.ready)
                root.refreshTrackedNodes();
        }
    }

    // Binds the default sink and every listed sink so their properties
    // actually populate — see DESIGN NOTES.
    PwObjectTracker {
        // Bind first, filter second. This avoids the old chicken-and-egg bug
        // where application nodes were excluded before their properties became
        // available, so they were never tracked and could never become usable.
        objects: [root.sink, root.source, ...root.trackedAudioNodes]
    }
}
