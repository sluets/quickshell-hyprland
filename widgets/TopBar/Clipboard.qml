// Clickable top-bar clipboard history backed by cliphist. // GPT 2026-07-23
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: iconRow.implicitWidth
    implicitHeight: iconRow.implicitHeight

    RowLayout {
        id: iconRow
        spacing: 3

        Text {
            text: "\uf328"
            color: (popout.open || hit.containsMouse) ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popout.open = !popout.open
    }

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "right"

        onOpenChanged: {
            if (open)
                openRefresh.restart();
        }

        Timer {
            id: openRefresh
            interval: 50
            repeat: false
            onTriggered: ClipboardHistory.refresh()
        }

        RowLayout {
            Layout.preferredWidth: 430
            Layout.fillWidth: true

            Text {
                text: "Clipboard History"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: clearLabel.implicitWidth + Theme.spacingMedium * 2
                implicitHeight: clearLabel.implicitHeight + Theme.spacingSmall * 2
                radius: Theme.radiusMedium
                color: clearMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                opacity: ClipboardHistory.count > 0 ? 1.0 : 0.45

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    enabled: ClipboardHistory.count > 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ClipboardHistory.clearAll()
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 430
            Layout.preferredHeight: 390
            radius: Theme.radiusMedium
            color: Theme.colorSurface
            clip: true

            Text {
                anchors.centerIn: parent
                visible: ClipboardHistory.count === 0
                text: ClipboardHistory.lastError.length > 0
                    ? ClipboardHistory.lastError
                    : "Clipboard history is empty"
                color: ClipboardHistory.lastError.length > 0
                    ? Theme.colorUrgent : Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                width: parent.width - Theme.spacingLarge * 2
            }

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                visible: ClipboardHistory.count > 0
                model: ClipboardHistory.entries
                clip: true
                spacing: Theme.spacingSmall
                reuseItems: true

                ScrollBar.vertical: ScrollBar {}

                delegate: Rectangle {
                    required property string clipId
                    required property string preview
                    required property bool binary
                    required property string thumbSource
                    required property int index

                    width: list.width - (list.ScrollBar.vertical.visible ? list.ScrollBar.vertical.width : 0)
                    height: binary ? 88 : Math.max(54, previewText.implicitHeight + Theme.spacingMedium * 2)
                    radius: Theme.radiusMedium
                    color: rowMouse.containsMouse ? Theme.colorHover : Theme.colorBackground

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingSmall
                        spacing: Theme.spacingSmall

                        Item {
                            Layout.preferredWidth: binary ? 96 : 20
                            Layout.preferredHeight: binary ? 72 : 24
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                id: thumbnail
                                anchors.fill: parent
                                visible: binary && thumbSource.length > 0 && status === Image.Ready
                                source: thumbSource
                                asynchronous: true
                                cache: true
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: 96
                                sourceSize.height: 72
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: binary && !thumbnail.visible
                                radius: Theme.radiusMedium
                                color: Theme.colorSurface

                                Text {
                                    anchors.centerIn: parent
                                    text: "▣"
                                    color: Theme.colorAccent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize + 4
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !binary
                                text: "¶"
                                color: Theme.colorAccent
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                        }

                        Text {
                            id: previewText
                            Layout.fillWidth: true
                            text: binary ? (thumbnail.visible ? "Image clipboard item" : "Image or binary clipboard item") : preview
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }

                        Rectangle {
                            implicitWidth: 30
                            implicitHeight: 30
                            radius: Theme.radiusMedium
                            color: deleteMouse.containsMouse ? Theme.colorUrgent : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: deleteMouse.containsMouse ? Theme.colorBackground : Theme.colorMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize + 2
                            }

                            MouseArea {
                                id: deleteMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    mouse.accepted = true;
                                    ClipboardHistory.remove(clipId);
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        anchors.rightMargin: 38
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ClipboardHistory.restore(clipId);
                            popout.open = false;
                        }
                    }
                }
            }
        }

        Text {
            Layout.preferredWidth: 430
            visible: ClipboardHistory.lastError.length > 0 && ClipboardHistory.count > 0
            text: ClipboardHistory.lastError
            color: Theme.colorUrgent
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(10, Theme.fontSize - 2)
            wrapMode: Text.Wrap
        }

        Text {
            Layout.preferredWidth: 430
            text: "Newest first · capped at " + ClipboardHistory.maxEntries + " items"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(10, Theme.fontSize - 2)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
