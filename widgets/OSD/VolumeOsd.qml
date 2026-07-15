//=============================================================================
// FILE
//=============================================================================
//
// widgets/OSD/VolumeOsd.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The volume OSD — a small pill that fades in at the bottom-center of
// the screen whenever the volume or mute state changes FROM ANY SOURCE
// (bar scroll, popout slider, media keys, `wpctl` from a terminal, an
// app changing its own sink volume), shows icon + bar + percentage,
// and fades out after Settings.osdHideDelay. Closes the "no OSD" gap
// called out in docs/REVISION_HISTORY.md (2026-07-03, "Explicitly NOT
// done yet").
//
// Volume-only, deliberately: this is a desktop (no laptop brightness
// keys), the bar has no brightness anything, and DDC monitor
// brightness is its own project (ddcutil bus probing, write
// throttling — a real service, not a widget tweak). Add a brightness
// row here IF that service ever gets built.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// Quickshell                 (PanelWindow, Region)
// core/Theme.qml, core/Settings.qml (singletons via `import qs.core`)
// services/Audio.qml         (volume/muted — via `import qs.services`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// shell.qml (instantiated once — it's a top-level window, not a
// bar module, so it does NOT live inside TopBar)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No OSD; volume changes are only visible in the bar widget. Nothing
// else references this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY A PanelWindow AND NOT A BarPopout:
//
// BarPopout is anchored UI that the user opened and will dismiss; an
// OSD is unsolicited, positioned relative to the SCREEN (bottom
// center), and must never steal input. Different animal, so it gets
// its own window: exclusiveZone 0 (reserves no space), and — the
// important one — `mask: Region {}`, an EMPTY input region, so clicks
// pass straight through it to whatever's underneath even while it's
// visible. (This OSD is deliberately not hoverable or clickable —
// it's a readout, not a control, and the bar's Volume widget already
// covers interaction.)
//
// THE STARTUP-FLASH GUARD:
//
// On shell start, PipeWire nodes bind asynchronously and
// Audio.volume goes 0 -> (real value) once the default sink
// populates. Without a guard that "change" would flash the OSD on
// every shell launch/reload. graceTimer swallows anything in the
// first 1500ms. (An alternative is snapshotting values in
// Component.onCompleted, but that can still flash on the first real
// bind on some setups; an explicit grace window is dumber and more
// predictable.)
//
// WHY visible IS BOUND TO reveal AND NOT TO shown:
//
// A window that goes visible:false the instant `shown` flips would
// cut the fade-out off — there'd be no window left to fade in. So
// `reveal` (0..1, animated) drives both the pill's opacity and the
// window's visibility (visible while reveal > 0), and `shown` only
// drives reveal's target. Binding `visible` declaratively is safe
// HERE because nothing external ever writes this window's visible —
// the grabFocus/PopupWindow trap documented in BarPopout.qml does not
// apply (no grabFocus, and Quickshell never auto-dismisses a
// PanelWindow).
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-04  Created. First PanelWindow besides the bar itself, first
//             click-through (empty Region mask) window in the project.
//             ⚠ Written offline, not yet run live; first-run bugs go
//             in docs/PROBLEMS_AND_FIXES.md.
//
//=============================================================================

import QtQuick
import Quickshell
import qs.core
import qs.services

PanelWindow {
    id: root

    // Fade state — see DESIGN NOTES ("WHY visible IS BOUND TO reveal").
    property bool shown: false
    property real reveal: shown ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.animationEasing
        }
    }

    anchors.bottom: true
    margins.bottom: Theme.barMargin * 2

    // Reserve nothing, steal nothing: no exclusive zone, and an EMPTY
    // input region so clicks pass through (see DESIGN NOTES).
    exclusiveZone: 0
    mask: Region {}

    color: "transparent"
    visible: reveal > 0.001

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    function show(): void {
        // Swallow the async PipeWire population on startup — see
        // DESIGN NOTES ("THE STARTUP-FLASH GUARD").
        if (graceTimer.running)
            return;
        shown = true;
        hideTimer.restart();
    }

    Timer {
        id: graceTimer
        running: true
        interval: 1500
    }

    Timer {
        id: hideTimer
        interval: Settings.osdHideDelay
        onTriggered: root.shown = false
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.show();
        }

        function onMutedChanged(): void {
            root.show();
        }
    }

    // ---- The pill ----
    Rectangle {
        id: pill
        anchors.fill: parent
        opacity: root.reveal
        radius: height / 2
        color: Theme.colorBackground

        implicitWidth: row.implicitWidth + Theme.spacingLarge * 2
        implicitHeight: row.implicitHeight + Theme.spacingMedium * 2

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.spacingMedium

            // Same Font Awesome glyphs + threshold as the bar's Volume
            // widget (f026 muted / f027 <50% / f028 >=50%) — those
            // three codepoints were verified against glyphnames.json
            // when Volume.qml was built; reuse, don't re-guess.
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "\uf026" : (Audio.volume < 0.5 ? "\uf027" : "\uf028")
                color: Audio.muted ? Theme.colorMuted : Theme.colorAccent
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.2)
            }

            // Non-interactive level bar — same track/fill shape as the
            // Volume popout's slider, minus the handle and MouseArea
            // (the OSD is a readout, not a control).
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: Settings.osdWidth
                height: 6

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.colorSurface
                }

                Rectangle {
                    width: parent.width * Audio.volume
                    height: parent.height
                    radius: height / 2
                    color: Audio.muted ? Theme.colorMuted : Theme.colorAccent

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animationDuration / 2
                            easing.type: Theme.animationEasing
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }
    }
}
