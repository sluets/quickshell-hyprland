// Single left-to-right audio spectrum for the music window header.
// GPT — 2026-07-25

import QtQuick
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: 360
    implicitHeight: 150
    property int barCount: 32

    RowLayout {
        anchors.fill: parent
        spacing: Math.max(2, Theme.spacingSmall / 2)

        Repeater {
            model: root.barCount

            Item {
                required property int index
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.max(2, parent.height * (AudioVisualizer.bands[index] || 0))
                    radius: Math.min(width / 2, 3)
                    color: Theme.colorAccent
                    opacity: 0.9

                }
            }
        }
    }
}
