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

    // Every available output device. Rebuilt on any node change —
    // see DESIGN NOTES.
    property list<PwNode> sinks: []

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

    Connections {
        target: Pipewire.nodes

        function onValuesChanged(): void {
            const newSinks = [];
            for (const node of Pipewire.nodes.values) {
                // Not a stream (app audio), is a sink (output) — see
                // DESIGN NOTES for where this filter is verified.
                if (!node.isStream && node.isSink)
                    newSinks.push(node);
            }
            root.sinks = newSinks;
        }
    }

    // Binds the default sink and every listed sink so their properties
    // actually populate — see DESIGN NOTES.
    PwObjectTracker {
        objects: [root.sink, ...root.sinks]
    }
}
