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
import qs.services
import "." as SettingsComponents
import "../pages" as SettingsPages

Item {
    id: viewRoot

    required property var settingsRoot

    // Rev 2 density rule: Settings pages are form-like UI, not dashboards.
    // Keep the working column compact when the toplevel is maximized instead
    // of allowing every row/card to stretch across the monitor. Extra width
    // remains intentional ground space to the right.
    readonly property int maximumContentWidth: 760
    property bool applyReviewOpen: false

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

        Rectangle {
            id: sidebar
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.topMargin: Theme.spacingLarge
            anchors.bottomMargin: Theme.spacingLarge
            anchors.leftMargin: Theme.spacingMedium
            width: settingsRoot.sidebarWidth - Theme.spacingMedium
            radius: Theme.radiusLarge
            color: Theme.colorCard
            border.width: 1
            border.color: Theme.colorCardBorder

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
                        color: isCurrent ? Theme.colorSelected
                             : sideMouse.containsMouse ? Theme.colorHover : "transparent"

                        Rectangle {
                            visible: sideItem.isCurrent
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: parent.height - Theme.spacingSmall * 2
                            radius: 2
                            color: Theme.colorAccent
                        }
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
            }
        }

        ColumnLayout {
            id: content
            // Rev 2: left-aligned, tighter capped form column. At normal window sizes
            // this consumes all available room; when maximized it stops at a
            // practical width instead of turning controls into long tracks.
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: sidebar.right
            anchors.topMargin: Theme.spacingLarge
            anchors.bottomMargin: Theme.spacingLarge
            anchors.leftMargin: Theme.spacingLarge
            width: Math.max(0, Math.min(
                viewRoot.maximumContentWidth,
                card.width - sidebar.width - Theme.spacingLarge * 2
            ))
            spacing: Theme.spacingMedium

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: settingsRoot.currentPage
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 1.55)
                    font.bold: true
                }
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
                        && !settingsRoot.themeDropdownOpen
                        && !settingsRoot.fontFamilyDropdownOpen
                        && !settingsRoot.wallpaperTransitionTypeDropdownOpen

                    StackLayout {
                        id: pageStack
                        width: pageFlick.width
                        currentIndex: Math.max(0, settingsRoot.pages.indexOf(settingsRoot.currentPage))

            // ================ APPEARANCE PAGE ================
            SettingsPages.AppearancePage {
                id: appearancePage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ CUSTOM THEME PAGE ================
            SettingsPages.CustomThemePage {
                id: customThemePage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ LAUNCHER PAGE ================
            SettingsPages.LauncherPage {
                id: launcherPage
                settingsRoot: viewRoot.settingsRoot
            }

            // ================ WALLPAPER PAGE ================
            SettingsPages.WallpaperPage {
                id: wallpaperPage
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

            // ================ MUSIC PAGE ================
            SettingsPages.MusicPage {
                id: musicPage
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
                onCancelRequested: settingsRoot.discardStaged()
                onApplyRequested: viewRoot.applyReviewOpen = true
            }
        }

        SettingsComponents.SettingsOverlays {
            anchors.fill: parent
            settingsRoot: viewRoot.settingsRoot
            appearancePage: appearancePage
            wallpaperPage: wallpaperPage
        }

        // Rev 6: Apply opens a compact review instead of permanently reserving
        // a large pending-changes panel at the bottom of every Settings page.
        Rectangle {
            id: applyReviewOverlay
            anchors.fill: parent
            visible: viewRoot.applyReviewOpen
            z: 1000
            color: "#99000000"

            MouseArea {
                anchors.fill: parent
                onClicked: viewRoot.applyReviewOpen = false
            }

            Rectangle {
                id: applyReviewCard
                anchors.centerIn: parent
                width: Math.min(560, parent.width - Theme.spacingLarge * 4)
                height: Math.min(520, parent.height - Theme.spacingLarge * 4)
                radius: Theme.radiusLarge
                color: Theme.colorCard
                border.width: 1
                border.color: Theme.colorCardBorder

                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingLarge
                    spacing: Theme.spacingMedium

                    Text {
                        text: "Apply changes?"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 1.25)
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: settingsRoot.changes.length + " setting" + (settingsRoot.changes.length === 1 ? "" : "s") + " will be written:"
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 0.85)
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusMedium
                        color: Theme.colorSurface
                        border.width: 1
                        border.color: Theme.colorDivider

                        ListView {
                            id: applyReviewList
                            anchors.fill: parent
                            anchors.margins: Theme.spacingMedium
                            clip: true
                            spacing: Theme.spacingSmall
                            model: settingsRoot.changes

                            delegate: Column {
                                required property var modelData
                                width: ListView.view.width
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: modelData.label
                                    elide: Text.ElideRight
                                    color: Theme.colorForeground
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize
                                    font.bold: true
                                }
                                Text {
                                    width: parent.width
                                    text: modelData.from + "  →  " + modelData.to
                                    elide: Text.ElideRight
                                    color: Theme.colorAccent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Math.round(Theme.fontSize * 0.85)
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingMedium
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: reviewCancelText.implicitWidth + Theme.spacingLarge * 2
                            implicitHeight: reviewCancelText.implicitHeight + Theme.spacingSmall * 2
                            radius: Theme.radiusMedium
                            color: reviewCancelMouse.containsMouse ? Theme.colorHover : Theme.colorControl
                            Text {
                                id: reviewCancelText
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: Theme.colorForeground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                            }
                            MouseArea {
                                id: reviewCancelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: viewRoot.applyReviewOpen = false
                            }
                        }

                        Rectangle {
                            readonly property bool enabled_: settingsRoot.changes.length > 0 && ConfigManager.busy === ""
                            implicitWidth: reviewApplyText.implicitWidth + Theme.spacingLarge * 2
                            implicitHeight: reviewApplyText.implicitHeight + Theme.spacingSmall * 2
                            radius: Theme.radiusMedium
                            color: reviewApplyMouse.containsMouse && enabled_ ? Theme.colorHover : Theme.colorAccent
                            opacity: enabled_ ? 1.0 : 0.4
                            Text {
                                id: reviewApplyText
                                anchors.centerIn: parent
                                text: "Apply changes"
                                color: Theme.colorBackground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.bold: true
                            }
                            MouseArea {
                                id: reviewApplyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: parent.enabled_ ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (!parent.enabled_) return;
                                    viewRoot.applyReviewOpen = false;
                                    settingsRoot.apply();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
