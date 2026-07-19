//=============================================================================
// FILE: widgets/Settings/components/SettingsOverlays.qml
// PURPOSE: Card-level dropdown and color-picker overlays for Settings.
//
// Extracted from SettingsWindow.qml by GPT in Rev 26. This component owns only
// overlay presentation. SettingsWindow remains the compatibility host for open
// state, staging callbacks, options, and page contracts. Keeping these overlays
// at card level preserves unclipped positioning and click handling.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core

Item {
    id: overlayRoot

    required property var settingsRoot
    required property Item appearancePage

    anchors.fill: parent
    z: 100

    // ---- Dropdown overlays: Theme + Font Family (2026-07-12) ----
// These used to be inline ListViews inside the Appearance page's
// ColumnLayout — that added their height straight to `content`'s
// implicitHeight, so opening either dropdown grew the whole
// settings window, and it shrank back the instant you picked
// something or closed it. Same fix as the swatch popup below:
// render ONE floating panel per dropdown at CARD level (big,
// unclipped, on top), positioned via mapToItem off the button
// that opened it. `themeDropdownButton`/`fontDropdownButton`
// are plain fixed items (not Repeater delegates), so they can
// be referenced directly by id from here — no anchor-property
// indirection needed like the color picker uses for its
// per-row swatches. Click-outside-to-dismiss via a full-card
// catcher underneath, same as the color picker. Only one
// dropdown (and never the color picker at the same time in
// practice) is expected open at once — the button handlers
// enforce that themeDropdownOpen/fontFamilyDropdownOpen are
// mutually exclusive.

MouseArea {
    anchors.fill: parent
    z: 149
    visible: settingsRoot.themeDropdownOpen || settingsRoot.fontFamilyDropdownOpen || settingsRoot.wallpaperTransitionTypeDropdownOpen
    enabled: settingsRoot.themeDropdownOpen || settingsRoot.fontFamilyDropdownOpen || settingsRoot.wallpaperTransitionTypeDropdownOpen
    onClicked: {
        settingsRoot.themeDropdownOpen = false;
        settingsRoot.fontFamilyDropdownOpen = false;
        settingsRoot.wallpaperTransitionTypeDropdownOpen = false;
    }
}

Rectangle {
    id: themeDropdownOverlay
    z: 150
    visible: settingsRoot.themeDropdownOpen

    // Gated on the open flag so mapToItem RE-EVALUATES each
    // time the dropdown opens. Ungated, it fired once at load
    // — before the StackLayout had positioned this button —
    // and cached that stale (near-top) result forever, which
    // is why the panel landed on top of / above the button.
    readonly property point anchorPos: settingsRoot.themeDropdownOpen
        ? appearancePage.themeDropdownAnchor.mapToItem(overlayRoot, 0, 0)
        : Qt.point(0, 0)
    readonly property int rowHeight: Theme.fontSize + Theme.spacingSmall * 2 + 2
    readonly property int visibleRows: Math.min(Theme.themeNames.length, 6)

    x: anchorPos.x
    // Overlaps the button by exactly its border width, so the
    // button's bottom edge and this panel's top edge coincide
    // as ONE line instead of two separate outlines with a gap.
    y: anchorPos.y + appearancePage.themeDropdownAnchor.height - 1
    width: Math.min(appearancePage.themeDropdownAnchor.width, overlayRoot.width - x - settingsRoot.pageScrollGutter - Theme.spacingLarge)
    height: visibleRows * rowHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    topLeftRadius: 0
    topRightRadius: 0
    color: Theme.colorSurface
    border.width: 1
    border.color: Theme.colorMuted

    // Swallow clicks on the panel body so they don't fall
    // through to the dismiss-catcher underneath.
    MouseArea { anchors.fill: parent }

    ListView {
        anchors.fill: parent
        anchors.margins: Theme.spacingSmall
        clip: true
        spacing: 2
        interactive: contentHeight > height
        model: Theme.themeNames

        delegate: Rectangle {
            id: themeRow
            required property string modelData
            readonly property bool isShown: settingsRoot.shownTheme === modelData
            readonly property bool isLive: UserPrefs.themeName === modelData

            width: ListView.view.width
            implicitHeight: themeRowText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: themeRowMouse.containsMouse ? Theme.colorHover
                 : isShown ? Theme.colorSurface : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMedium
                anchors.rightMargin: Theme.spacingMedium
                spacing: Theme.spacingMedium

                Text {
                    id: themeRowText
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: (themeRow.isShown ? "● " : "○ ") + themeRow.modelData
                    color: themeRow.isShown ? Theme.colorAccent : Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    visible: themeRow.isLive && !themeRow.isShown
                    text: "current"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.8)
                }
            }

            MouseArea {
                id: themeRowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    settingsRoot.stagedTheme = themeRow.modelData;
                    settingsRoot.themeDropdownOpen = false;
                }
            }
        }
    }
}

Rectangle {
    id: fontDropdownOverlay
    z: 150
    visible: settingsRoot.fontFamilyDropdownOpen

    readonly property point anchorPos: settingsRoot.fontFamilyDropdownOpen
        ? appearancePage.fontDropdownAnchor.mapToItem(overlayRoot, 0, 0)
        : Qt.point(0, 0)
    readonly property int rowHeight: Theme.fontSize + Theme.spacingSmall * 2 + 2
    readonly property int visibleRows: Math.min(settingsRoot.fontFamilyOptions.length, 6)

    x: anchorPos.x
    y: anchorPos.y + appearancePage.fontDropdownAnchor.height - 1
    width: Math.min(appearancePage.fontDropdownAnchor.width, overlayRoot.width - x - settingsRoot.pageScrollGutter - Theme.spacingLarge)
    height: visibleRows * rowHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    topLeftRadius: 0
    topRightRadius: 0
    color: Theme.colorSurface
    border.width: 1
    border.color: Theme.colorMuted

    MouseArea { anchors.fill: parent }

    ListView {
        anchors.fill: parent
        anchors.margins: Theme.spacingSmall
        clip: true
        spacing: 2
        interactive: contentHeight > height
        model: settingsRoot.fontFamilyOptions

        delegate: Rectangle {
            id: fontRow
            required property string modelData
            readonly property bool isShown: settingsRoot.shownFontFamilyOverride === modelData
            readonly property bool isLive: UserPrefs.fontFamilyOverride === modelData
            readonly property string displayText: modelData === "" ? "(Theme Default)" : modelData

            width: ListView.view.width
            implicitHeight: fontRowText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: fontRowMouse.containsMouse ? Theme.colorHover
                 : isShown ? Theme.colorSurface : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMedium
                anchors.rightMargin: Theme.spacingMedium
                spacing: Theme.spacingMedium

                Text {
                    id: fontRowText
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: (fontRow.isShown ? "● " : "○ ") + fontRow.displayText
                    color: fontRow.isShown ? Theme.colorAccent : Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    visible: fontRow.isLive && !fontRow.isShown
                    text: "current"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.8)
                }
            }

            MouseArea {
                id: fontRowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    settingsRoot.stagedFontFamilyOverride = fontRow.modelData;
                    settingsRoot.fontFamilyDropdownOpen = false;
                }
            }
        }
    }
}

Rectangle {
    id: wallpaperTransitionTypeDropdownOverlay
    z: 150
    visible: settingsRoot.wallpaperTransitionTypeDropdownOpen

    readonly property point anchorPos: settingsRoot.wallpaperTransitionTypeDropdownOpen
        ? appearancePage.wallpaperTransitionTypeDropdownAnchor.mapToItem(overlayRoot, 0, 0)
        : Qt.point(0, 0)
    readonly property int rowHeight: Theme.fontSize + Theme.spacingSmall * 2 + 2
    readonly property int visibleRows: Math.min(settingsRoot.wallpaperTransitionTypeOptions.length, 6)

    x: anchorPos.x
    y: anchorPos.y + appearancePage.wallpaperTransitionTypeDropdownAnchor.height - 1
    width: Math.min(appearancePage.wallpaperTransitionTypeDropdownAnchor.width, overlayRoot.width - x - settingsRoot.pageScrollGutter - Theme.spacingLarge)
    height: visibleRows * rowHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    topLeftRadius: 0
    topRightRadius: 0
    color: Theme.colorSurface
    border.width: 1
    border.color: Theme.colorMuted

    MouseArea { anchors.fill: parent }

    ListView {
        anchors.fill: parent
        anchors.margins: Theme.spacingSmall
        clip: true
        spacing: 2
        interactive: contentHeight > height
        model: settingsRoot.wallpaperTransitionTypeOptions

        delegate: Rectangle {
            id: wtRow
            required property string modelData
            readonly property bool isShown: settingsRoot.shownWallpaperTransitionType === modelData
            readonly property bool isLive: UserPrefs.wallpaperTransitionType === modelData

            width: ListView.view.width
            implicitHeight: wtRowText.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: wtRowMouse.containsMouse ? Theme.colorHover
                 : isShown ? Theme.colorSurface : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingMedium
                anchors.rightMargin: Theme.spacingMedium
                spacing: Theme.spacingMedium

                Text {
                    id: wtRowText
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: (wtRow.isShown ? "● " : "○ ") + wtRow.modelData
                    color: wtRow.isShown ? Theme.colorAccent : Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    visible: wtRow.isLive && !wtRow.isShown
                    text: "current"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.8)
                }
            }

            MouseArea {
                id: wtRowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    settingsRoot.stagedWallpaperTransitionType = wtRow.modelData;
                    settingsRoot.wallpaperTransitionTypeDropdownOpen = false;
                }
            }
        }
    }
}

// ---- Shared preset-color-picker overlay (2026-07-11, Opus) ----
// Rendered here, at CARD level, so it's large, unclipped, on top
// of every row, and — critically — actually receives clicks
// (the previous per-row popups were trapped inside a 22px swatch
// and were visible-but-dead). Driven entirely by settingsRoot.colorPicker*
// state; a HexColorRow's swatch calls settingsRoot.openColorPicker(...).

// Full-card click-catcher: any click outside the grid closes the
// picker (click-outside-to-dismiss — the v1 limitation is gone).
// Only present while open, so it never eats clicks otherwise.
MouseArea {
    anchors.fill: parent
    z: 199
    visible: settingsRoot.colorPickerOpen
    enabled: settingsRoot.colorPickerOpen
    onClicked: settingsRoot.closeColorPicker()
}

Rectangle {
    id: colorPickerPopup
    z: 200
    visible: settingsRoot.colorPickerOpen && settingsRoot.colorPickerAnchor !== null

    // Map the opening swatch's top-left into card coordinates,
    // then place the popup just under it. Clamped so it can't
    // spill past the card's padding on either side.
    readonly property point anchorPos: settingsRoot.colorPickerAnchor
        ? settingsRoot.colorPickerAnchor.mapToItem(overlayRoot, 0, 0)
        : Qt.point(0, 0)
    readonly property int pad: Theme.spacingLarge
    readonly property int idealX: anchorPos.x + (settingsRoot.colorPickerAnchor
        ? settingsRoot.colorPickerAnchor.width : 0) - width
    x: Math.max(pad, Math.min(idealX, overlayRoot.width - width - pad))
    y: anchorPos.y + (settingsRoot.colorPickerAnchor
        ? settingsRoot.colorPickerAnchor.height : 0) + 4

    width: pickerGrid.implicitWidth + Theme.spacingSmall * 2
    height: pickerGrid.implicitHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    color: Theme.colorSurface
    border.width: 1
    border.color: Theme.colorMuted

    // Swallow clicks on the popup body so they don't reach the
    // dismiss-catcher underneath and close it before a swatch
    // registers.
    MouseArea { anchors.fill: parent }

    Grid {
        id: pickerGrid
        anchors.centerIn: parent
        columns: 8
        spacing: 4
        Repeater {
            model: settingsRoot.colorPickerSwatches
            Rectangle {
                required property var modelData
                width: 20
                height: 20
                radius: 4
                color: modelData
                border.width: 1
                border.color: Theme.colorMuted
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (settingsRoot.colorPickerCallback)
                            settingsRoot.colorPickerCallback(parent.modelData);
                        settingsRoot.closeColorPicker();
                    }
                }
            }
        }
    }
}
}
