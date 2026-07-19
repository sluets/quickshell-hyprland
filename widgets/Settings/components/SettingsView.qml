//=============================================================================
// FILE: widgets/Settings/components/SettingsView.qml
// PURPOSE: Main Settings window chrome, navigation, page stack, footer, and overlays.
//
// Extracted from SettingsWindow.qml by GPT in Rev 27. The FloatingWindow remains
// the lifecycle and transaction compatibility host; this component owns the
// visible card structure and delegates all state/actions through settingsRoot.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core
import "." as SettingsComponents
import "../pages" as SettingsPages

Item {
    id: viewRoot

    required property var settingsRoot

    // ---- The card ----
    Rectangle {
        id: card
        anchors.fill: parent
        // The compositor performs the actual rounded clipping. Keeping this
        // full-surface container square/transparent avoids creating a second
        // rounded rectangle just inside Hyprland's border.
        radius: 0
        color: "transparent"
        // No QML-drawn outer border here. This is a real FloatingWindow,
        // so Hyprland alone owns the visible window border and applies the
        // configured active/inactive border colors without a second line
        // being drawn inside it.

        // Swallow clicks so the fullscreen close-MouseArea doesn't
        // fire when clicking inside the card.
        MouseArea { anchors.fill: parent }

        // Application-style titlebar. Drag anywhere in the empty header
        // area; Super+drag also works because this is a real toplevel.
        Rectangle {
            id: titlebar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.round(Theme.fontSize * 3.2)
            color: "transparent"
            z: 20

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: settingsRoot.startSystemMove()
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingLarge
                anchors.verticalCenter: parent.verticalCenter
                width: closeText.implicitHeight + Theme.spacingMedium * 2
                height: width
                radius: Theme.radiusMedium
                color: closeMouse.containsMouse ? Theme.colorHover : "transparent"
                z: 2
                Text {
                    id: closeText
                    anchors.centerIn: parent
                    text: "×"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 1.25)
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsRoot.close()
                }
            }
        }

        Rectangle {
            id: sidebar
            anchors.top: titlebar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: settingsRoot.sidebarWidth
            color: Qt.darker(Theme.colorBackground, 1.08)
            bottomLeftRadius: Math.max(0, UserPrefs.hyprRounding)

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Theme.colorMuted
                opacity: 0.5
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingSmall

                Text {
                    text: "SETTINGS"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.75)
                    Layout.leftMargin: Theme.spacingSmall
                    Layout.bottomMargin: Theme.spacingSmall
                }

                Repeater {
                    model: settingsRoot.pages
                    Rectangle {
                        id: sideItem
                        required property string modelData
                        readonly property bool isCurrent: settingsRoot.currentPage === modelData
                        Layout.fillWidth: true
                        implicitHeight: sideText.implicitHeight + Theme.spacingMedium * 1.5
                        radius: Theme.radiusMedium
                        color: isCurrent ? Theme.colorSurface
                             : sideMouse.containsMouse ? Theme.colorHover : "transparent"

                        Text {
                            id: sideText
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingMedium
                            anchors.verticalCenter: parent.verticalCenter
                            text: sideItem.modelData
                            color: sideItem.isCurrent ? Theme.colorAccent : Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: sideItem.isCurrent
                        }
                        MouseArea {
                            id: sideMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsRoot.currentPage = sideItem.modelData;
                                settingsRoot.themeDropdownOpen = false;
                                settingsRoot.fontFamilyDropdownOpen = false;
                                settingsRoot.wallpaperTransitionTypeDropdownOpen = false;
                                pageFlick.contentY = 0;
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Text {
                    text: settingsRoot.changes.length > 0
                        ? settingsRoot.changes.length + " unapplied change" + (settingsRoot.changes.length === 1 ? "" : "s")
                        : "All changes applied"
                    color: settingsRoot.changes.length > 0 ? Theme.colorAccent : Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.75)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        ColumnLayout {
            id: content
            // Fixed width + pinned to the card's top-left padding —
            // centerIn here would re-center the column every time the
            // card's height changed, undoing the top-anchor above.
            anchors.top: titlebar.bottom
            anchors.bottom: parent.bottom
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            Text {
                text: settingsRoot.currentPage
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.35)
                font.bold: true
            }

            // ---------------- Page tabs ----------------
            RowLayout {
                visible: false
                Layout.preferredHeight: 0
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Repeater {
                    model: settingsRoot.pages

                    Rectangle {
                        id: tab
                        required property string modelData
                        readonly property bool isCurrent: settingsRoot.currentPage === modelData

                        // spacingMedium, not Large (2026-07-11): the
                        // fifth tab (Desktop) overflowed the fixed
                        // content width at fontScale 1.0 with the old
                        // padding. contentWidth scales with the font,
                        // so if it fits at 1.0 it fits everywhere.
                        implicitWidth: tabText.implicitWidth + Theme.spacingMedium * 2
                        implicitHeight: tabText.implicitHeight + Theme.spacingSmall * 2
                        radius: Theme.radiusMedium
                        color: isCurrent ? Theme.colorSurface
                             : tabMouse.containsMouse ? Theme.colorHover : "transparent"
                        border.width: isCurrent ? 1 : 0
                        border.color: Theme.colorMuted

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: tab.modelData
                            color: tab.isCurrent ? Theme.colorAccent : Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: tab.isCurrent
                        }
                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // Staged changes SURVIVE tab switches (the
                            // pending panel is global) — only close/
                            // Cancel discards.
                            onClicked: {
                                settingsRoot.currentPage = tab.modelData;
                                settingsRoot.themeDropdownOpen = false;
                                settingsRoot.fontFamilyDropdownOpen = false;
                                settingsRoot.wallpaperTransitionTypeDropdownOpen = false;
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            // ---- Page stack (2026-07-12) ----
            // StackLayout instead of four separate visible-toggled
            // ColumnLayouts. The old approach resized the whole window
            // on every tab click — QtQuick.Layouts excludes
            // visible:false items from a ColumnLayout's implicit size,
            // so `content`'s implicitHeight (and therefore the card's
            // height, see below) tracked WHICHEVER page happened to be
            // current. StackLayout sizes itself to its LARGEST child
            // up front, no matter which one is showing, so the card
            // now has one stable height across every tab. currentIndex
            // is driven off settingsRoot.pages so tab order and page order
            // stay in sync automatically.
            Item {
                id: pageViewport
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Math.round(Theme.fontSize * 18)
                clip: true

                Flickable {
                    id: pageFlick
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: settingsRoot.pageScrollGutter
                    clip: true
                    contentWidth: width
                    contentHeight: pageStack.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    StackLayout {
                        id: pageStack
                        width: pageFlick.width
                        currentIndex: Math.max(0, settingsRoot.pages.indexOf(settingsRoot.currentPage))

            // ================ APPEARANCE PAGE ================
            SettingsPages.AppearancePage {
                id: appearancePage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ LAUNCHER PAGE ================
            SettingsPages.LauncherPage {
                id: launcherPage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ NOTIFICATIONS PAGE ================
            SettingsPages.NotificationsPage {
                id: notificationsPage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ DESKTOP PAGE ================
            SettingsPages.DesktopPage {
                id: desktopPage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ HYPRLAND PAGE ================
            SettingsPages.HyprlandPage {
                id: hyprlandPage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ UI PROFILES PAGE ================
            SettingsPages.UiProfilesPage {
                id: uiProfilesPage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ SDDM PAGE ================
            SettingsPages.SddmPage {
                id: sddmPage
                settingsRoot: viewRoot.settingsRoot
            }

                    } // ---- end page stack ----
                } // ---- end page flickable ----

                // Draggable themed scrollbar. The earlier 3px indicator was
                // visual-only, which made long SDDM pages miserable in a
                // compact window. This thumb has a real hit target and maps
                // pointer movement directly to Flickable.contentY.
                Rectangle {
                    id: pageScrollThumb
                    visible: pageFlick.contentHeight > pageFlick.height
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    y: pageFlick.visibleArea.yPosition * pageFlick.height
                    width: pageScrollMouse.containsMouse || pageScrollMouse.pressed ? 12 : 8
                    height: Math.max(32, pageFlick.visibleArea.heightRatio * pageFlick.height)
                    radius: width / 2
                    color: pageScrollMouse.containsMouse || pageScrollMouse.pressed
                        ? Theme.colorAccent : Theme.colorMuted
                    opacity: pageScrollMouse.containsMouse || pageScrollMouse.pressed ? 1.0 : 0.75

                    Behavior on width { NumberAnimation { duration: 90 } }

                    MouseArea {
                        id: pageScrollMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        property real pressMouseY: 0
                        property real pressContentY: 0

                        onPressed: mouse => {
                            pressMouseY = mapToItem(pageViewport, mouse.x, mouse.y).y;
                            pressContentY = pageFlick.contentY;
                        }
                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            const currentY = mapToItem(pageViewport, mouse.x, mouse.y).y;
                            const track = Math.max(1, pageViewport.height - pageScrollThumb.height);
                            const contentRange = Math.max(0, pageFlick.contentHeight - pageFlick.height);
                            pageFlick.contentY = Math.max(0, Math.min(contentRange,
                                pressContentY + (currentY - pressMouseY) * contentRange / track));
                        }
                    }
                }
            } // ---- end page viewport ----

            SettingsComponents.SettingsPendingFooter {
                Layout.fillWidth: true
                changes: settingsRoot.changes
                pendingVisibleLines: settingsRoot.pendingVisibleLines
                onCancelRequested: settingsRoot.discardStaged()
                onApplyRequested: settingsRoot.apply()
            }
        }

        SettingsComponents.SettingsOverlays {
            anchors.fill: parent
            settingsRoot: viewRoot.settingsRoot
            appearancePage: appearancePage
        }
    }
}
