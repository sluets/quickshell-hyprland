// Configurable audio spectrum renderer for the music window header.
// CAVA supplies band values; all style/color work stays in QML.
// GPT — 2026-07-25

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: 360
    implicitHeight: 150

    readonly property int barCount: UserPrefs.musicVisualizerBars
    readonly property string renderStyle: UserPrefs.musicVisualizerStyle
    readonly property string colorMode: UserPrefs.musicVisualizerColorMode
    readonly property color baseColor: UserPrefs.musicVisualizerUseThemeColor
        ? Theme.colorAccent : UserPrefs.musicVisualizerCustomColor
    readonly property int segmentCount: UserPrefs.musicVisualizerLedSegments
    readonly property int segmentGap: UserPrefs.musicVisualizerLedGap
    readonly property real unlitOpacity: UserPrefs.musicVisualizerLedUnlitOpacity / 100.0

    function mixColor(a, b, amount): color {
        const t = Math.max(0, Math.min(1, amount));
        return Qt.rgba(
            a.r + (b.r - a.r) * t,
            a.g + (b.g - a.g) * t,
            a.b + (b.b - a.b) * t,
            a.a + (b.a - a.a) * t);
    }

    function fadeTarget(): color {
        const strength = UserPrefs.musicVisualizerFadeStrength / 100.0;
        return UserPrefs.musicVisualizerFadeDarkerTop
            ? mixColor(baseColor, Qt.rgba(0, 0, 0, baseColor.a), strength)
            : mixColor(baseColor, Qt.rgba(1, 1, 1, baseColor.a), strength);
    }

    // ratio is 0 at the bottom and 1 at the top.
    function colorAt(ratio): color {
        const y = Math.max(0, Math.min(1, ratio));
        if (colorMode === "zones") {
            if (y < 0.55)
                return UserPrefs.musicVisualizerLowColor;
            if (y < 0.82)
                return UserPrefs.musicVisualizerMidColor;
            return UserPrefs.musicVisualizerHighColor;
        }
        if (colorMode === "fade") {
            return UserPrefs.musicVisualizerFadeDarkerTop
                ? mixColor(baseColor, fadeTarget(), y)
                : mixColor(fadeTarget(), baseColor, y);
        }
        return baseColor;
    }

    RowLayout {
        anchors.fill: parent
        spacing: Math.max(2, Theme.spacingSmall / 2)

        Repeater {
            model: root.barCount

            Item {
                id: band
                required property int index
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property real level: Math.max(0, Math.min(1,
                    AudioVisualizer.bands[index] || 0))

                // Current smooth bar renderer.
                Rectangle {
                    visible: root.renderStyle === "solid"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.max(2, parent.height * band.level)
                    radius: Math.min(width / 2, 3)
                    opacity: 0.9

                    gradient: Gradient {
                        // Gradient positions run top to bottom, while colorAt()
                        // uses bottom to top.
                        GradientStop { position: 0.0; color: root.colorAt(1.0) }
                        GradientStop { position: 0.5; color: root.colorAt(0.5) }
                        GradientStop { position: 1.0; color: root.colorAt(0.0) }
                    }
                }

                // Old-school stacked LEDs and a smaller square dot variant.
                Repeater {
                    model: root.renderStyle === "solid" ? 0 : root.segmentCount

                    Rectangle {
                        id: segment
                        required property int index

                        readonly property real ratio: (index + 0.5) / root.segmentCount
                        readonly property bool lit: ratio <= band.level
                        readonly property real cellHeight: Math.max(1,
                            (band.height - root.segmentGap * (root.segmentCount - 1))
                                / root.segmentCount)

                        height: cellHeight
                        width: root.renderStyle === "dots"
                            ? Math.max(2, Math.min(band.width * 0.48, cellHeight * 0.62))
                            : band.width
                        x: root.renderStyle === "dots" ? (band.width - width) / 2 : 0
                        y: band.height - (index + 1) * cellHeight - index * root.segmentGap
                            + (root.renderStyle === "dots" ? (cellHeight - height) / 2 : 0)
                        radius: root.renderStyle === "dots"
                            ? width / 2
                            : Math.min(2, height / 3)
                        color: root.colorAt(ratio)
                        opacity: lit ? 0.95 : root.unlitOpacity
                    }
                }
            }
        }
    }
}
