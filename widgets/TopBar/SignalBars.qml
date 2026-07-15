//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/SignalBars.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A 4-bar Wi-Fi signal strength indicator (ascending-height bars,
// filled up to the current strength, dimmed above it) — replaces
// showing signal strength as a plain "73%" number in the network list.
// Faster to scan a list of networks by eye, same idea as a phone's
// status bar signal icon.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// core/Theme.qml (singleton, via `import qs.core`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/Wifi.qml (network list rows, via DeviceRow's
// `showSignal`/`signalStrength` properties)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// DeviceRow's showSignal path fails to resolve. Wifi.qml would need
// reverting to a plain percentage Text.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// FOUR BARS, THRESHOLDS AT 25/50/75/100%: matches the everyday mental
// model from phone/laptop status bars — nothing invented here, this is
// the standard signal-bar convention, chosen specifically so it needs
// no explanation.
//
// PLAIN Rectangles, NOT Canvas: four small rectangles of increasing
// height is simpler and cheaper than a Canvas path for the same
// visual result, and stays consistent with this project's "plain
// QtQuick primitives over anything heavier" convention (see
// MenuButton.qml's DESIGN NOTES on avoiding Qt Quick Controls for the
// same reasoning, one level down).
//
// UNFILLED BARS use Theme.colorSurface, not fully transparent — a
// ghost/outline of all 4 bars is always visible so the eye reads
// "4-bar meter, X filled" rather than "some floating rectangles,"
// which is what a fully-transparent unfilled state would look like.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Created as part of the Wi-Fi/Bluetooth menu visual
//             refresh.
//
//=============================================================================

import QtQuick
import qs.core

Row {
    id: root

    // 0..1, same shape as Network.wifiNetworks[].signalStrength.
    property real strength: 0

    readonly property int barCount: 4
    readonly property real barWidth: 3
    readonly property real barMaxHeight: Theme.fontSize
    readonly property real barSpacing: 2

    spacing: barSpacing
    height: barMaxHeight

    Repeater {
        model: root.barCount

        Rectangle {
            id: bar
            required property int index

            readonly property real barHeight:
                root.barMaxHeight * ((index + 1) / root.barCount)
            readonly property bool filled:
                root.strength >= (index + 1) / root.barCount

            width: root.barWidth
            height: barHeight
            y: root.barMaxHeight - barHeight
            radius: 1
            color: filled ? Theme.colorAccent : Theme.colorSurface

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.animationEasing
                }
            }
        }
    }
}
