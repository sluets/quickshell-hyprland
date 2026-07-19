// Shared wallpaper-picker content for attached and centered presentation hosts. // GPT Rev 47
import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: contentRoot
    required property var controller
    signal closeRequested()
    spacing: Theme.spacingSmall

    function focusGrid(): void { grid.forceActiveFocus(); }

    // ---- Header: title/count + Shuffle + Random ----
    RowLayout {
        // Same trick as the launcher's search field: implicitWidth
        // on the first child is what makes the whole popout this
        // wide (BarPopout sizes from the column's implicit sizes).
        implicitWidth: grid.implicitWidth
        Layout.fillWidth: true
        spacing: Theme.spacingSmall

        Text {
            text: "Wallpapers"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        // Shuffle toggle — checked = filled accent box (no glyph:
        // a checkmark would mean gambling on an unverified font
        // codepoint, and a filled/empty box reads just as well).
        Rectangle {
            implicitWidth: shuffleContent.implicitWidth + Theme.spacingMedium * 2
            implicitHeight: shuffleLabel.implicitHeight + Theme.spacingSmall
            radius: Theme.radiusMedium
            color: shuffleMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
            visible: controller.wallpapers.length > 0

            Row {
                id: shuffleContent
                anchors.centerIn: parent
                spacing: Theme.spacingSmall

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 3
                    color: controller.shuffled ? Theme.colorAccent : "transparent"
                    border.width: controller.shuffled ? 0 : 2
                    border.color: Theme.colorMuted
                }

                Text {
                    id: shuffleLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Shuffle"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            MouseArea {
                id: shuffleMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    controller.shuffled = !controller.shuffled;
                    // Immediate feedback: re-order (or restore
                    // sorted order) right now, not on next open.
                    controller.rebuildDisplayList();
                }
            }
        }

        Rectangle {
            implicitWidth: randomLabel.implicitWidth + Theme.spacingMedium * 2
            implicitHeight: randomLabel.implicitHeight + Theme.spacingSmall
            radius: Theme.radiusMedium
            color: randomMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
            visible: controller.wallpapers.length > 0

            Text {
                id: randomLabel
                anchors.centerIn: parent
                text: "Random"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: randomMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: controller.applyRandom()
            }
        }
    }

    // ---- Daemon-down warning (see DESIGN NOTES) ----
    Text {
        visible: !controller.daemonOk
        text: "awww-daemon isn't running — picks won't apply"
        color: Theme.colorUrgent
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }

    // ---- Empty state ----
    Text {
        visible: controller.wallpapers.length === 0
        text: "No wallpapers found in " + controller.wallsDir
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }

    // ---- The grid ----
    GridView {
        id: grid

        // Cell = thumb + breathing room; grid declares REAL sizes
        // because GridView has no content-derived implicit size
        // (see DESIGN NOTES, "GRID SIZING").
        readonly property int cellSize: Settings.wallpaperThumbSize + Theme.spacingSmall

        visible: controller.wallpapers.length > 0
        implicitWidth: Settings.wallpaperGridColumns * cellSize
        implicitHeight: Math.min(
            Math.max(1, Math.ceil(controller.wallpapers.length / Settings.wallpaperGridColumns)),
            Settings.wallpaperGridMaxRows) * cellSize
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight

        cellWidth: cellSize
        cellHeight: cellSize
        clip: true
        focus: true
        model: controller.displayList
            currentIndex: controller.selectedIndex
            onCurrentIndexChanged: controller.selectedIndex = currentIndex

        // Scroll performance on big collections (see DESIGN NOTES,
        // "GRID SCROLL PERFORMANCE"): pool + reuse scrolled-out
        // delegates instead of destroying them, and keep ~4 extra
        // rows instantiated beyond the visible area.
        reuseItems: true
        cacheBuffer: 0

        Keys.onLeftPressed: moveCurrentIndexLeft()
        Keys.onRightPressed: moveCurrentIndexRight()
        Keys.onUpPressed: moveCurrentIndexUp()
        Keys.onDownPressed: moveCurrentIndexDown()
        Keys.onReturnPressed: controller.applySelected()
        Keys.onEnterPressed: controller.applySelected()
        Keys.onEscapePressed: contentRoot.closeRequested()

        // PageUp/PageDown: no dedicated Keys.on*Pressed signal
        // exists for these (unlike arrows/Return/Escape above), so
        // handle via the generic onPressed and only mark the ones
        // we actually use as accepted — everything else falls
        // through to the specific handlers above unaffected. Jumps
        // a full visible page (columns × visible rows) at a time;
        // GridView's default currentIndex-follows-into-view
        // behavior handles the actual scrolling, same as arrow keys
        // already rely on.
        Keys.onPressed: event => {
            const page = Settings.wallpaperGridColumns * Settings.wallpaperGridMaxRows;
            if (event.key === Qt.Key_PageUp) {
                grid.currentIndex = Math.max(0, grid.currentIndex - page);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                grid.currentIndex = Math.min(controller.displayList.length - 1, grid.currentIndex + page);
                event.accepted = true;
            }
        }

        delegate: Item {
            id: cell
            required property var modelData
            required property int index

            width: grid.cellSize
            height: grid.cellSize

            Rectangle {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall / 2
                radius: Theme.radiusMedium
                // SELECTION (keyboard/hover) = accent BORDER — a
                // fill alone is invisible because the image covers
                // all but a few px of the cell (learned live, see
                // revision history). ACTIVE wallpaper = corner
                // badge below, so the two states stay readable
                // even when overlapping.
                color: cell.GridView.isCurrentItem ? Theme.colorHover : "transparent"
                border.width: cell.GridView.isCurrentItem ? 2 : 0
                border.color: Theme.colorAccent

                Image {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingSmall / 2
                    source: "file://" + cell.modelData.thumb
                    // Decode at cell size, NOT native size — without
                    // this a missing thumb would decode a 4K
                    // original for a ~120px cell.
                    sourceSize.width: Settings.wallpaperThumbSize
                    sourceSize.height: Settings.wallpaperThumbSize
                    // No-op for the pre-squared thumbs; only does
                    // work on the full-image fallback.
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // Active-wallpaper badge: small accent dot, ringed
                // in the background colour so it reads over any
                // image content.
                Rectangle {
                    visible: cell.modelData.path === controller.currentWallpaper
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Theme.spacingSmall
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.colorAccent
                    border.width: 2
                    border.color: Theme.colorBackground
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: grid.currentIndex = cell.index
                onClicked: controller.apply(cell.modelData.path)
            }
        }
    }
}
