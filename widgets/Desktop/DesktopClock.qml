//=============================================================================
// FILE
//=============================================================================
//
// widgets/Desktop/DesktopClock.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A borderless clock + date + weather readout sitting directly on the
// desktop, over the wallpaper — no card, no fill, no border, just text
// and (optionally) a weather icon. Fully user-configurable from the
// settings window's Desktop page (2026-07-11): on/off, corner + x/y
// offsets, which monitor(s), text color, and the shadow effect
// (on/off + color). Sits BEHIND normal windows (opens covered when you
// open an app over it, like conky or any traditional desktop-widget
// clock) and never intercepts a click.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// Quickshell                    (Scope, Variants, PanelWindow, Region,
//                                 Quickshell.screens)
// Quickshell.Wayland            (WlrLayershell, WlrLayer — see DESIGN
//                                 NOTES, "LAYER")
// core/Theme.qml, core/Settings.qml, core/UserPrefs.qml
//                                (singletons via `import qs.core` —
//                                 UserPrefs owns position/colors/
//                                 shadow/monitor/enabled as of
//                                 2026-07-11; Settings keeps only
//                                 desktopClockFontSize)
// services/Weather.qml          (singleton via `import qs.services`)
// SystemClock                   (built-in Quickshell/QtQuick type —
//                                 same reactive, no-polling approach
//                                 the bar's Clock.qml already uses;
//                                 see docs/PROBLEMS_AND_FIXES.md,
//                                 "Almost built the clock by shelling
//                                 out to date")
// assets/icons/weather/*.svg    (OPTIONAL — see DESIGN NOTES, "ICON
//                                 FILES")
//
//=============================================================================
// USED BY
//=============================================================================
//
// shell.qml (single top-level instance — the per-monitor fan-out lives
// INSIDE this file, so shell.qml still declares one `DesktopClock {}`)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No desktop clock. `services/Weather.qml` still runs (nothing else
// currently references it) but nothing displays what it fetches. The
// settings window's Desktop page still edits the prefs — they just
// control nothing.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// LAYER — THE OPPOSITE DIRECTION FROM PowerScreen:
//
// PowerScreen.qml needed `WlrLayer.Overlay` (render ABOVE everything,
// including fullscreen apps — see that file's DESIGN NOTES). This
// widget wants the reverse: `WlrLayer.Background`, so it renders
// BEHIND normal application windows — visible on bare desktop, covered
// the instant something's opened over it. That's the traditional
// desktop-widget/conky behavior "on my desktop" implies, as distinct
// from an always-on-top HUD.
//
// CLICK-THROUGH: same `mask: Region {}` trick VolumeOsd.qml already
// uses — an EMPTY input region means clicks pass straight through to
// whatever's beneath. This widget is a readout, never a control, so it
// should never be capable of eating a click, same reasoning as the OSD.
//
// PER-MONITOR (2026-07-11): the old single-instance/default-output
// limitation is gone — a Variants block over Quickshell.screens (the
// same pattern shell.qml uses for TopBar) creates one window per
// monitor, and UserPrefs.desktopClockMonitor decides which are
// visible: "" = all of them, otherwise exactly the named screen
// (e.g. "DP-1"). A name for a monitor that's currently unplugged is
// legal — the clock just isn't anywhere until it's back. NOTE THE
// DEFAULT CHANGED with this: "" (all monitors) replaces the old
// "whatever Quickshell considers the default output".
//
// POSITIONING: `UserPrefs.desktopClockCorner` picks which two edges to
// anchor to (top+left, top+right, bottom+left, bottom+right, or all
// four + centerIn for "centered") — UserPrefs.desktopClockOffsetX/Y
// are the distance from the chosen corner's edges (the old single
// desktopClockMargin, split per-axis for fine-tuning; both default to
// the old 32). For "centered" the offsets shift nothing (they're
// applied symmetrically). Content-sized, not fullscreen, except in
// centered mode — see the next note.
//
// COLORS + SHADOW (2026-07-11): text color follows the theme's
// foreground unless desktopClockUseThemeColor is off, in which case
// desktopClockCustomColor (validated hex) applies — the same
// theme-or-custom pattern as the bar border overrides. The shadow is
// the old always-on `Text.Raised` embossing, now switchable
// (desktopClockShadowEnabled) with its own theme-or-custom color
// (theme = colorBackground, exactly what was hardcoded). The custom
// colors are how you match a wallpaper by hand; AUTOMATIC
// wallpaper-derived colors (matugen-style palette extraction) is a
// future project, noted in thoughts, not attempted here.
//
// WINDOW GEOMETRY: the transparent PanelWindow spans the full screen in
// every position mode. Only the visual Column moves between the four
// corners or center. Earlier code made corner modes content-sized and
// anchored the layer-shell surface itself; on some outputs those
// right/bottom/corner surfaces vanished. A full-screen click-through
// background surface is stable and has no visual or input cost here.
//
// WEATHER IS FULLY OPTIONAL AT EVERY LAYER: `Settings.weatherZipCode`
// empty (the default) means `Weather.available` stays false forever,
// and this file hides the entire weather row — clock+date show with
// or without it configured. No error, no placeholder text, just a
// smaller widget.
//
// ICON FILES — NOT YET PRESENT, GRACEFUL WITHOUT THEM:
//
// Expects up to 7 SVGs in assets/icons/weather/, matching
// services/Weather.qml's `condition` categories exactly:
//     clear.svg  partly-cloudy.svg  cloudy.svg  fog.svg
//     rain.svg   snow.svg           thunderstorm.svg
// Until a given file exists, that Image simply fails to load —
// `visible: iconImage.status === Image.Ready` means a missing icon
// just leaves a gap where it would be (temperature text still shows),
// never a broken-image glyph. Any consistent, flat, single-color-ish
// SVG set works — this file doesn't attempt to recolor them (no
// tint/colorize effect), so an icon that works on any background will
// read best sitting directly over a wallpaper.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-15  (GPT-5.6) Rev 4: removed content-sized implicit window dimensions
//             and calculate placement from ShellScreen width/height instead
//             of the window content item. Opposite PanelWindow anchors own the
//             full-screen surface; implicitWidth/implicitHeight were fighting
//             that geometry during live position changes and could collapse the
//             coordinate space to the clock's own size, pinning it top-left.
// 2026-07-15  (GPT-5.6) Rev 3: replaced dynamic content anchors with
//             explicit x/y bindings. Dynamic anchor removal could leave the
//             previous corner visually stuck until a Quickshell restart even
//             though UserPrefs had saved the new position.
// 2026-07-15  (GPT-5.6) Rev 2: fixed non-centered positions disappearing by
//             keeping the transparent PanelWindow full-screen and
//             anchoring only the content Column inside it. Weather icon
//             tint from Rev 1 retained.
// 2026-07-11  (Fable 5) The Desktop-page rework
//             (thoughts_next_session.txt): root is now Scope +
//             Variants over Quickshell.screens (per-monitor, with
//             UserPrefs.desktopClockMonitor selecting "" = all or one
//             by name); position moved to UserPrefs (corner incl.
//             centered + per-axis offsets, replacing
//             Settings.desktopClockCorner/Margin — removed there);
//             enabled toggle; text color and shadow (on/off + color)
//             each theme-or-custom-hex, the bar-border pattern.
//             Defaults reproduce the old look exactly EXCEPT the
//             clock now shows on all monitors instead of the default
//             output only (documented above).
// 2026-07-09  (Fable 5) Fixed the 24-hour format check: read
//             UserPrefs.clockUse24Hour, not Settings.clockUse24Hour —
//             that property was moved out of Settings on 07-05 (see
//             core/UserPrefs.qml), so the old reference silently
//             evaluated to undefined and this clock was stuck 12-hour
//             regardless of the SettingsMenu toggle. Same bug class,
//             same fix as widgets/TopBar/Clock.qml this session.
// 2026-07-05  Created.
//
//=============================================================================

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

Scope {
    id: root

    // One shared clock source for every monitor's window — the date is
    // the same everywhere; no reason for N tickers.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData
            screen: modelData

            // Off entirely, or filtered to one named monitor — see
            // DESIGN NOTES ("PER-MONITOR").
            visible: UserPrefs.desktopClockEnabled
                     && (UserPrefs.desktopClockMonitor === ""
                         || UserPrefs.desktopClockMonitor === modelData.name)

            // Behind normal windows — see DESIGN NOTES ("LAYER").
            WlrLayershell.layer: WlrLayer.Background

            exclusiveZone: 0
            color: "transparent"
            // Click-through — see DESIGN NOTES ("CLICK-THROUGH").
            mask: Region {}

            // ---- Effective colors (see DESIGN NOTES, "COLORS + SHADOW") ----
            readonly property color _textColor:
                UserPrefs.desktopClockUseThemeColor
                ? Theme.colorForeground : UserPrefs.desktopClockCustomColor
            readonly property int _textStyle:
                UserPrefs.desktopClockShadowEnabled ? Text.Raised : Text.Normal
            readonly property color _shadowColor:
                UserPrefs.desktopClockShadowUseThemeColor
                ? Theme.colorBackground : UserPrefs.desktopClockShadowCustomColor

            // ---- Corner positioning (see DESIGN NOTES, "POSITIONING") ----
            // Keep the layer-shell surface full-screen in every mode and move
            // only the visual content inside it. Content-sized PanelWindows
            // anchored to right/bottom edges could disappear on some outputs;
            // a stable full-screen transparent surface avoids that compositor
            // geometry edge case while remaining click-through.
            readonly property string _corner: UserPrefs.desktopClockCorner
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            Column {
                id: content
                spacing: Theme.spacingSmall

                // Do not switch anchors dynamically here. Qt can retain an old
                // anchor relationship until the item/window is recreated, which
                // caused the first live move to work and every later move to stay
                // visually stuck until Quickshell restarted. Explicit x/y bindings
                // are deterministic and re-evaluate for every corner change.
                // Use the monitor geometry directly instead of parent.width/
                // parent.height. The PanelWindow is stretched by opposite shell
                // anchors, but its content item's size could temporarily retain
                // the old content-sized implicit geometry during a live setting
                // change. In that state, right/bottom calculations went negative
                // and Wayland/Qt effectively pinned the clock to top-left.
                x: {
                    const screenWidth = win.modelData.width
                    if (win._corner === "centered")
                        return Math.max(0, Math.round((screenWidth - width) / 2))
                    if (win._corner === "top-right" || win._corner === "bottom-right")
                        return Math.max(0, Math.round(screenWidth - width - UserPrefs.desktopClockOffsetX))
                    return Math.max(0, Math.round(UserPrefs.desktopClockOffsetX))
                }
                y: {
                    const screenHeight = win.modelData.height
                    if (win._corner === "centered")
                        return Math.max(0, Math.round((screenHeight - height) / 2))
                    if (win._corner === "bottom-left" || win._corner === "bottom-right")
                        return Math.max(0, Math.round(screenHeight - height - UserPrefs.desktopClockOffsetY))
                    return Math.max(0, Math.round(UserPrefs.desktopClockOffsetY))
                }

                Text {
                    text: Qt.formatTime(clock.date, UserPrefs.clockUse24Hour ? "HH:mm" : "h:mm AP")
                    color: win._textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Settings.desktopClockFontSize
                    font.bold: true
                    style: win._textStyle
                    styleColor: win._shadowColor
                }

                Text {
                    text: Qt.formatDate(clock.date, "dddd, MMMM d")
                    color: win._textColor
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Settings.desktopClockFontSize * 0.32)
                    style: win._textStyle
                    styleColor: win._shadowColor
                }

                // ---- Weather (optional — see DESIGN NOTES) ----
                Row {
                    visible: Weather.available
                    spacing: Theme.spacingSmall

                    Item {
                        id: weatherIconContainer
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property int size: Math.round(Settings.desktopClockFontSize * 0.4)
                        width: size
                        height: size
                        visible: weatherIcon.status === Image.Ready

                        // Keep the SVG as the alpha mask, then colorize the
                        // rendered pixels with the same effective color as the
                        // clock text. This preserves transparent portions and
                        // makes theme/custom text-color changes affect the icon.
                        Image {
                            id: weatherIcon
                            anchors.fill: parent
                            source: Weather.condition
                                ? "../../assets/icons/weather/" + Weather.condition + ".svg"
                                : ""
                            asynchronous: true
                            visible: false
                            sourceSize.width: weatherIconContainer.size
                            sourceSize.height: weatherIconContainer.size
                        }

                        MultiEffect {
                            anchors.fill: parent
                            source: weatherIcon
                            colorization: 1.0
                            colorizationColor: win._textColor
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(Weather.temperature) + "°" +
                              (Settings.weatherUnits === "celsius" ? "C" : "F")
                        color: win._textColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Settings.desktopClockFontSize * 0.32)
                        style: win._textStyle
                        styleColor: win._shadowColor
                    }
                }
            }
        }
    }
}
