//=============================================================================
// FILE
//=============================================================================
//
// widgets/PowerMenu/PowerScreen.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Replaces the old SystemMenu dropdown. A centered floating card with
// three icon buttons — Restart Hyprland, Restart, Shut Down — over the
// desktop. No fullscreen
// dim (see DESIGN NOTES, "WHY NO DIM ANYMORE"); the card itself provides
// the visual grounding instead. Opened by clicking the arch icon in the
// bar (SystemMenu.qml) OR the SUPER+P global shortcut (see shell.qml) OR
// `qs ipc call power toggle`.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// Quickshell                    (PanelWindow, execDetached)
// Quickshell.Hyprland           (HyprlandFocusGrab — see DESIGN NOTES)
// Quickshell.Wayland            (WlrLayershell, WlrLayer — see DESIGN
//                                 NOTES, "LAYER ORDERING")
// core/Theme.qml, core/Settings.qml, core/Signals.qml
//                                (singletons via `import qs.core`)
// assets/icons/power/*.svg      (see DESIGN NOTES, "ICON FILES")
//
//=============================================================================
// USED BY
//=============================================================================
//
// shell.qml (single top-level instance, same as VolumeOsd/
// NotificationPopups). widgets/TopBar/SystemMenu.qml triggers it via
// Signals.togglePowerScreen() — see core/Signals.qml.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No power screen anywhere — SystemMenu's icon click and the SUPER+P
// keybind both silently do nothing (Signals.togglePowerScreen() would have
// no listener). shell.qml's instantiation and the GlobalShortcut/IpcHandler
// referencing it would need removing too.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY A FULLSCREEN PanelWindow AND NOT A BarPopout:
//
// The requirement is a centered screen, not something hanging off the bar
// — same category as VolumeOsd (screen-relative, not bar-relative), so it
// gets its own top-level window under widgets/, per ARCHITECTURE.md's
// "top-level windows vs bar modules" split. Unlike VolumeOsd this DOES take
// input (it's a menu, not a readout). The window itself STILL spans the
// full screen (anchored to all four edges) even though it renders nothing
// full-screen anymore — see "WHY NO DIM ANYMORE" below for why that's kept.
//
// WHY NO DIM ANYMORE:
//
// The original design rendered a black Rectangle across the whole
// window at `Settings.powerScreenDimOpacity`, intended to grey out the
// entire screen including the bar. Pinning the window to
// `WlrLayer.Overlay` (see "LAYER ORDERING" below) was A correct fix for
// one real cause of the dim not covering the bar — but it didn't fully
// resolve the reported behavior, and there's a second plausible cause
// that WASN'T chased down: TopBar likely reserves screen space via its
// own exclusive zone, and wlr-layer-shell's anchored-region math can
// compress an edge-anchored surface around another surface's exclusive
// zone independent of which layer either one is on — this is
// compositor behavior neither confirmed nor ruled out here. Rather than
// keep debugging layer-shell internals blind, the fullscreen dim was
// dropped entirely in favor of a centered floating CARD (below) that
// doesn't depend on covering the whole screen at all — the card
// provides its own visual grounding (background fill, border, elevated
// above the desktop), so there's nothing left that NEEDS
// whole-screen coverage to look right. `Settings.powerScreenDimOpacity`
// is consequently unused by this file now; it's still defined in
// Settings.qml (harmless dead config for the moment — see that file's
// own notes on whether to remove it).
//
// The window itself STAYS fullscreen-anchored regardless — that part
// was never the problem, and it's what makes `anchors.centerIn: parent`
// trivially center the card and lets a single MouseArea over the whole
// window catch "clicked outside the card" for free.
//
// LAYER ORDERING — STILL RELEVANT WITHOUT THE DIM:
//
// Every PanelWindow defaults to Wayland layer-shell's `Top` layer
// (verified against Quickshell source, src/window/panelinterface.hpp —
// the simplified `aboveWindows: true` boolean maps to exactly this).
// TopBar is ALSO a PanelWindow, so it defaults to `Top` too. Even
// without a fullscreen dim to worry about, the CARD itself should
// still reliably render above the bar (it can appear near/behind the
// bar's screen region depending on card height and screen size), so
// this window stays pinned to `WlrLayershell.layer: WlrLayer.Overlay`
// — wlr-layer-shell defines four layers with STRICT compositor-
// guaranteed ordering (Background < Bottom < Top < Overlay, confirmed
// against Quickshell source, src/wayland/wlr_layershell/
// wlr_layershell.hpp), so Overlay reliably renders above Top
// regardless of creation order or which compositor is running. Also
// the semantically correct choice independent of any bar interaction:
// wlr-layer-shell's own doc comment describes Overlay as "usually
// renders over fullscreen windows" — appropriate for a shutdown
// confirmation, which should interrupt everything, fullscreen
// video/games included.
//
// DISMISSAL — REUSES BarPopout's HyprlandFocusGrab FIX, NOT grabFocus:
//
// Same class of window as BarPopout (needs real keyboard input for Escape,
// real pointer input for click-outside), so it reuses the exact fix
// documented there: HyprlandFocusGrab instead of PopupWindow's native
// grabFocus (which has the cold-start "not an xdg_popup" failure under Qt
// Wayland 6.9.1+ — see BarPopout.qml's 2026-07-05 REVISION HISTORY). Same
// rule applies here too: `focusGrab.active` is pushed IMPERATIVELY from
// `onShownChanged`, never bound declaratively to `shown`/`visible` — a
// declarative binding gets silently destroyed the first time Quickshell
// itself writes `active = false` on grab-cleared, and every open after
// that stops dismissing (the exact bug BarPopout hit and fixed). Escape is
// still handled by a plain `Keys.onEscapePressed` on a focused Item inside
// — HyprlandFocusGrab makes that reachable at all.
//
// CLICK-OUTSIDE: a MouseArea fills the whole (invisible) window and
// calls close() on any click. The card sits above it in declaration
// order — later siblings paint on top and win the hit-test — and has
// its OWN empty MouseArea just to swallow the click before it reaches
// the one behind it; a click anywhere on the card (including its
// padding, not just the buttons) is correctly treated as "inside,"
// not dismissed. Same z-order reasoning as every other overlapping-
// MouseArea case in this project.
//
// ICON FILES — NOT YET PRESENT, PLACEHOLDER GLYPHS IN USE:
//
// Expects six SVGs in assets/icons/power/ (see notes/power_icons.txt):
//     restarthyprland-black.svg   restarthyprland-white.svg
//     restart-black.svg           restart-white.svg
//     shutdown-black.svg          shutdown-white.svg
// Until those exist on disk, `iconSource()` below falls back to the same
// Unicode glyphs SystemMenu used to show (⟳ ↻ ⏻) so the screen still works
// with nothing missing. Once the SVGs are in place, delete the two
// `Text { visible: !root.useIconFiles ... }` fallback glyphs and their
// guard, or just leave them — the guard is `Qt.resolvedUrl` existence-free
// (Image doesn't error on a missing file at parse time, only at load time,
// which onStatusChanged below turns into a fallback flag automatically).
//
// BLACK VS WHITE VARIANT — AUTOMATIC, NOT A SETTING:
//
// `iconVariant()` picks black/white by relative luminance of
// Theme.colorSurface (the button circles' fill) rather than hardcoding one
// — if a future theme swaps colorSurface for something light, the icons
// switch automatically instead of silently becoming invisible. If a
// second widget ever needs this same black/white choice, promote the
// function to Theme.qml; not done yet since this is the only consumer
// (see Settings.qml's own "don't add speculatively" rule, same idea).
//
// SIGNALS.QML — FIRST REAL USE:
//
// core/Signals.qml existed as an unused placeholder since 2026-07-01,
// reserved for exactly this: two widgets (SystemMenu, a per-monitor bar
// module, and this file, a single top-level window) that need to react to
// one event without a direct reference to each other. `togglePowerScreen`
// is the first signal declared on it — see that file's own updated STATUS
// section.
//
// SINGLE INSTANCE, DEFAULT OUTPUT ONLY (like VolumeOsd):
//
// Doesn't set `screen:`, so it renders on Quickshell's default output —
// same known multi-monitor limitation VolumeOsd already has. A shutdown/
// restart action affects the whole machine regardless of which screen
// shows the confirmation, so this matters less here than it would for
// something you're reading (unlike the OSD), but worth remembering if a
// later session makes this per-focused-monitor like the launcher.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-10  (Fable 5) Card border now the shell-wide border tokens
//             (was a fixed 1px muted hairline).
//
// 2026-07-05  Dropped the fullscreen dim entirely in favor of a
//             centered floating card — see DESIGN NOTES ("WHY NO DIM
//             ANYMORE"). The Overlay-layer fix from the entry below
//             wasn't sufficient on its own; rather than keep chasing
//             an unconfirmed second cause (likely TopBar's exclusive
//             zone interacting with anchored-region math — never
//             verified), the design changed to not need whole-screen
//             coverage at all. Window stays fullscreen-anchored
//             (unchanged) purely for free centering + click-outside
//             dismiss; nothing renders across that full area anymore.
// 2026-07-05  Fixed the dimmed backdrop not covering the bar: pinned to
//             WlrLayer.Overlay (was implicitly Top, same layer as
//             TopBar — same-layer stacking order isn't controllable).
//             Verified against Quickshell source; see DESIGN NOTES
//             ("LAYER ORDERING").
// 2026-07-09  (Fable 5) Card scale refactor: the maintainer had
//             hand-edited `scale: 1.6 + reveal * 0.1` to make the card
//             bigger — which worked, but baked the size into the
//             animation math. Now a separate `cardScale` knob (1.7,
//             preserving the exact final size they chose) multiplied by
//             the standard 0.94->1.0 grow-in. Resize the card by
//             changing cardScale only.
// 2026-07-05  Created. Replaces SystemMenu.qml's dropdown menu (see that
//             file's own REVISION HISTORY). First activation of
//             core/Signals.qml.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core

PanelWindow {
    id: root

    // Explicit layer, ABOVE the bar (see DESIGN NOTES, "LAYER
    // ORDERING") — ensures the card reliably renders above TopBar
    // even without a fullscreen dim to establish stacking.
    WlrLayershell.layer: WlrLayer.Overlay

    // ---- Fade state (same pattern as VolumeOsd) ----
    property bool shown: false
    property real reveal: shown ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.animationEasing
        }
    }

    function open(): void {
        shown = true;
    }

    function close(): void {
        shown = false;
    }

    function toggle(): void {
        shown = !shown;
    }

    // Cross-file trigger — see DESIGN NOTES ("SIGNALS.QML").
    Connections {
        target: Signals
        function onTogglePowerScreen(): void {
            root.toggle();
        }
    }

    // ---- Fullscreen input-catching layer, transparent (see DESIGN
    // NOTES, "WHY NO DIM ANYMORE") — still anchored edge-to-edge so
    // centering the card and catching outside-clicks stay trivial,
    // it just renders nothing itself.
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: 0
    color: "transparent"
    visible: reveal > 0.001

    // ---- Keyboard grab (see DESIGN NOTES) ----
    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: root.shown = false
    }
    onShownChanged: {
        // Imperative push, not a binding — see DESIGN NOTES and
        // BarPopout.qml's identical fix for why.
        focusGrab.active = shown;
        if (shown)
            keyCatcher.forceActiveFocus();
    }

    // ---- Invisible click-outside dismiss ----
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // ---- Keyboard: Escape dismisses ----
    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
    }

    // ---- Luminance-based icon variant (see DESIGN NOTES) ----
    function iconVariant(): string {
        const c = Theme.colorSurface;
        const luminance = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
        return luminance < 0.5 ? "white" : "black";
    }

    function iconSource(base: string): string {
        return "../../assets/icons/power/" + base + "-" + root.iconVariant() + ".svg";
    }

    readonly property var actions: [
        { label: "Hyprland", iconBase: "restarthyprland", fallbackGlyph: "⟳", command: ["hyprctl", "reload"] },
        { label: "Restart",          iconBase: "restart",          fallbackGlyph: "↻", command: ["systemctl", "reboot"] },
        { label: "Power",        iconBase: "shutdown",         fallbackGlyph: "⏻", command: ["systemctl", "poweroff"] }
    ]

    // ---- The floating card (see DESIGN NOTES, "WHY NO DIM ANYMORE")
    // ---- animates opacity+scale together, same reveal-driven pattern
    // BarPopout/VolumeOsd already use.
    Rectangle {
        id: card
        anchors.centerIn: parent
        implicitWidth: buttonRow.implicitWidth + Theme.spacingLarge * 2
        implicitHeight: buttonRow.implicitHeight + Theme.spacingLarge * 2
        radius: Theme.radiusMedium * 2
        color: Theme.colorBackground
        // Shell-wide border tokens (2026-07-10) — replaces the old
        // fixed 1px muted hairline; width 0 = borderless, same as
        // everywhere else. The dim scrim still separates the card.
        border.width: Theme.barBorderWidth
        border.color: Theme.barBorderColor
        // How big the card renders overall — a maintainer size tweak
        // (1.0 = the original design size). Kept separate from the
        // open animation below so changing one never breaks the other.
        readonly property real cardScale: 1.7

        opacity: root.reveal
        // Grow-in on open: animates from 94% to 100% of cardScale as
        // reveal goes 0 -> 1 (same reveal-driven pattern as opacity).
        scale: card.cardScale * (0.94 + root.reveal * 0.06)

        // Swallows clicks so they never reach the fullscreen dismiss-
        // catcher behind — this Rectangle paints after it (later
        // siblings win the hit-test), so this MouseArea just needs to
        // exist with no handler; that alone stops the click event from
        // being interpreted as "clicked outside the card."
        MouseArea {
            anchors.fill: parent
        }

        RowLayout {
            id: buttonRow
            anchors.centerIn: parent
            spacing: Theme.spacingLarge * 2

            Repeater {
                model: root.actions

                ColumnLayout {
                    id: button
                    required property var modelData

                    spacing: Theme.spacingMedium

                    Rectangle {
                        id: circle
                        Layout.alignment: Qt.AlignHCenter
                        width: Settings.powerScreenIconSize + Theme.spacingLarge * 2
                        height: width
                        radius: width / 2
                        color: buttonMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                        border.color: Theme.colorAccent
                        border.width: buttonMouse.containsMouse ? 2 : 0

                        Image {
                            id: iconImage
                            anchors.centerIn: parent
                            width: Settings.powerScreenIconSize
                            height: Settings.powerScreenIconSize
                            sourceSize.width: Settings.powerScreenIconSize
                            sourceSize.height: Settings.powerScreenIconSize
                            source: root.iconSource(button.modelData.iconBase)
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        // Fallback glyph — see DESIGN NOTES ("ICON FILES").
                        // Shows only if the real SVG failed to load (missing
                        // file, wrong name) so this screen works today and
                        // upgrades silently once the assets are dropped in.
                        Text {
                            anchors.centerIn: parent
                            visible: iconImage.status !== Image.Ready
                            text: button.modelData.fallbackGlyph
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Settings.powerScreenIconSize
                        }

                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.close();
                                Quickshell.execDetached(button.modelData.command);
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: button.modelData.label
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }
    }
}
