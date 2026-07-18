//=============================================================================
// widgets/Settings/pages/AppearancePage.qml
//
// Appearance settings page extracted from SettingsWindow.qml.
// Owns presentation only; staged values, dropdown state, color-picker state,
// and Apply/Cancel behavior remain owned by SettingsWindow.qml.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page

    required property var settingsRoot

    // Card-level dropdown overlays remain in SettingsWindow.qml so they are
    // not clipped by the page Flickable. These aliases expose the three
    // anchor buttons without moving any overlay behavior.
    readonly property alias themeDropdownAnchor: themeDropdownButton
    readonly property alias fontDropdownAnchor: fontDropdownButton
    readonly property alias wallpaperTransitionTypeDropdownAnchor: wallpaperTransitionTypeDropdownButton

    Layout.fillWidth: true
    spacing: Theme.spacingMedium

// ---------------- Theme picker ----------------
Text {
    text: "Theme"
    color: Theme.colorForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
}

// Dropdown, not a flat list (2026-07-11, Sonnet 5) — a flat
// row-per-theme layout was fine at 2 themes but unusable at
// 20 (all 20 became selectable in this same session, see
// core/Theme.qml's revision history). Closed button + a
// fixed-height scrolling list on open, same recipe as the
// pending-changes ListView below (stable-geometry rule:
// grows downward, only on click).
Rectangle {
    id: themeDropdownButton
    Layout.fillWidth: true
    implicitHeight: themeButtonRow.implicitHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    bottomLeftRadius: settingsRoot.themeDropdownOpen ? 0 : -1
    bottomRightRadius: settingsRoot.themeDropdownOpen ? 0 : -1
    color: themeButtonMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
    border.width: 1
    border.color: Theme.colorMuted

    RowLayout {
        id: themeButtonRow
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingMedium

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: (settingsRoot.stagedTheme !== null ? "● " : "") + settingsRoot.shownTheme
            color: settingsRoot.stagedTheme !== null ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        Text {
            text: settingsRoot.themeDropdownOpen ? "▾" : "▸"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
    MouseArea {
        id: themeButtonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            settingsRoot.themeDropdownOpen = !settingsRoot.themeDropdownOpen;
            if (settingsRoot.themeDropdownOpen) {
                settingsRoot.fontFamilyDropdownOpen = false;
                settingsRoot.wallpaperTransitionTypeDropdownOpen = false;
            }
        }
    }
}

// (Dropdown list itself now lives at card level — see the
// "Dropdown overlays" section near the bottom of the file,
// rendered as a floating panel instead of an inline
// ListView so opening it doesn't grow this page.)

// ---------------- Font scale ----------------
Text {
    text: "Font Scale"
    Layout.topMargin: Theme.spacingLarge
    color: Theme.colorForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
}

SettingsComponents.StepperRow {
    valueText: settingsRoot.shownFontScale.toFixed(1) + "×"
    staged: settingsRoot.stagedFontScale !== null
    onMinus: settingsRoot.stagedFontScale =
        Math.max(0.8, Math.round((settingsRoot.shownFontScale - 0.1) * 10) / 10)
    onPlus: settingsRoot.stagedFontScale =
        Math.min(2.5, Math.round((settingsRoot.shownFontScale + 0.1) * 10) / 10)
}

// ---------------- Font family ----------------
// Same closed-button + fixed-height scrolling list recipe
// as the theme dropdown above — Qt.fontFamilies() can
// easily be 100+ entries, so a flat row-per-font layout
// was never on the table. "(Theme Default)" is the ""
// sentinel (follow the active theme's fontFamily token);
// everything else is a name straight out of
// Qt.fontFamilies(), so whatever gets picked is guaranteed
// to actually be installed.
Text {
    text: "Font Family"
    Layout.topMargin: Theme.spacingLarge
    color: Theme.colorForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
}

Rectangle {
    id: fontDropdownButton
    Layout.fillWidth: true
    implicitHeight: fontButtonRow.implicitHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    bottomLeftRadius: settingsRoot.fontFamilyDropdownOpen ? 0 : -1
    bottomRightRadius: settingsRoot.fontFamilyDropdownOpen ? 0 : -1
    color: fontButtonMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
    border.width: 1
    border.color: Theme.colorMuted

    RowLayout {
        id: fontButtonRow
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingMedium

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: (settingsRoot.stagedFontFamilyOverride !== null ? "● " : "")
                + (settingsRoot.shownFontFamilyOverride === "" ? "(Theme Default)" : settingsRoot.shownFontFamilyOverride)
            color: settingsRoot.stagedFontFamilyOverride !== null ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        Text {
            text: settingsRoot.fontFamilyDropdownOpen ? "▾" : "▸"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
    MouseArea {
        id: fontButtonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            settingsRoot.fontFamilyDropdownOpen = !settingsRoot.fontFamilyDropdownOpen;
            if (settingsRoot.fontFamilyDropdownOpen) {
                settingsRoot.themeDropdownOpen = false;
                settingsRoot.wallpaperTransitionTypeDropdownOpen = false;
            }
        }
    }
}

// (Dropdown list itself now lives at card level — see the
// "Dropdown overlays" section near the bottom of the file.)

// ---------------- Bar padding ----------------
// Per-edge overrides of the theme's single barMargin token
// (core/Theme.qml's barPaddingTop/Side/Bottom). "Sides"
// covers left AND right together. The toggle seeds all
// three overrides with their CURRENT effective pixel
// values at once, same reasoning as the Bar Border width
// toggle just below — nothing visibly jumps the moment
// it's switched on.
Text {
    text: "Bar Padding"
    Layout.topMargin: Theme.spacingLarge
    color: Theme.colorForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
}

SettingsComponents.ToggleSettingRow {
    label: "Custom padding"
    value: settingsRoot.shownBarPaddingTopOverride >= 0
    staged: settingsRoot.stagedBarPaddingTopOverride !== null
        || settingsRoot.stagedBarPaddingSideOverride !== null
        || settingsRoot.stagedBarPaddingBottomOverride !== null
    onToggled: {
        if (settingsRoot.shownBarPaddingTopOverride >= 0) {
            // Turning OFF: back to "follow theme" on all
            // three. Bottom's sentinel is NOT -1 (see
            // UserPrefs.barPaddingBottomOffSentinel) —
            // using -1 here would stage a real "-1px"
            // override instead of turning it off.
            settingsRoot.stagedBarPaddingTopOverride = -1;
            settingsRoot.stagedBarPaddingSideOverride = -1;
            settingsRoot.stagedBarPaddingBottomOverride = UserPrefs.barPaddingBottomOffSentinel;
        } else {
            // Turning ON: seed with the current effective
            // values (Theme.barPadding* already resolves
            // theme-vs-override, so this is just "what's
            // on screen right now" for all three edges).
            settingsRoot.stagedBarPaddingTopOverride = Theme.barPaddingTop;
            settingsRoot.stagedBarPaddingSideOverride = Theme.barPaddingSide;
            settingsRoot.stagedBarPaddingBottomOverride = Theme.barPaddingBottom;
        }
    }
}

// All three gate on TOP's state, not their own — Bottom in
// particular can legitimately sit at a negative px value
// once custom padding is on, so ">= 0" can't be used to
// mean "is custom padding active" for that row (see the
// toggle above; all three are always staged together).
SettingsComponents.StepperRow {
    visible: settingsRoot.shownBarPaddingTopOverride >= 0
    label: "Top"
    valueText: settingsRoot.shownBarPaddingTopOverride + " px"
    staged: settingsRoot.stagedBarPaddingTopOverride !== null
    onMinus: settingsRoot.stagedBarPaddingTopOverride =
        Math.max(0, settingsRoot.shownBarPaddingTopOverride - 1)
    onPlus: settingsRoot.stagedBarPaddingTopOverride =
        Math.min(200, settingsRoot.shownBarPaddingTopOverride + 1)
}

SettingsComponents.StepperRow {
    visible: settingsRoot.shownBarPaddingTopOverride >= 0
    label: "Sides"
    valueText: settingsRoot.shownBarPaddingSideOverride + " px"
    staged: settingsRoot.stagedBarPaddingSideOverride !== null
    onMinus: settingsRoot.stagedBarPaddingSideOverride =
        Math.max(0, settingsRoot.shownBarPaddingSideOverride - 1)
    onPlus: settingsRoot.stagedBarPaddingSideOverride =
        Math.min(200, settingsRoot.shownBarPaddingSideOverride + 1)
}

// Bottom is the one edge allowed to go negative — it's the
// maintainer's fix for the persistent gap under the bar
// even at 0 (Hyprland's own gaps_out reserves space on
// every screen edge independently of this shell's
// exclusiveZone; a negative value here cancels that out).
// Clamped to -100, generous enough to cancel any sane
// gaps_out without inviting the bar to overlap windows by
// a huge margin. TopBar.qml's exclusiveZone is separately
// clamped to never go below 0 regardless of this value.
SettingsComponents.StepperRow {
    visible: settingsRoot.shownBarPaddingTopOverride >= 0
    label: "Bottom"
    valueText: settingsRoot.shownBarPaddingBottomOverride + " px"
    staged: settingsRoot.stagedBarPaddingBottomOverride !== null
    onMinus: settingsRoot.stagedBarPaddingBottomOverride =
        Math.max(-100, settingsRoot.shownBarPaddingBottomOverride - 1)
    onPlus: settingsRoot.stagedBarPaddingBottomOverride =
        Math.min(200, settingsRoot.shownBarPaddingBottomOverride + 1)
}

// ---------------- Bar border ----------------
// Overrides that sit ABOVE the active theme's barBorder
// tokens (precedence chain in core/Theme.qml). Width off =
// the theme decides (which by default follows the Hyprland
// Border Size). Color off-theme = a hand-typed hex.
Text {
    text: "Bar Border"
    Layout.topMargin: Theme.spacingLarge
    color: Theme.colorForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
}

SettingsComponents.ToggleSettingRow {
    label: "Custom width"
    value: settingsRoot.shownBarBorderWidthOverride >= 0
    staged: settingsRoot.stagedBarBorderWidthOverride !== null
    // Turning ON seeds the override with the current
    // effective width so nothing visibly jumps; OFF is -1,
    // "follow theme".
    onToggled: settingsRoot.stagedBarBorderWidthOverride =
        settingsRoot.shownBarBorderWidthOverride >= 0 ? -1 : Theme.barBorderWidth
}

SettingsComponents.StepperRow {
    visible: settingsRoot.shownBarBorderWidthOverride >= 0
    label: "Width"
    valueText: settingsRoot.shownBarBorderWidthOverride + " px"
    staged: settingsRoot.stagedBarBorderWidthOverride !== null
    onMinus: settingsRoot.stagedBarBorderWidthOverride =
        Math.max(0, settingsRoot.shownBarBorderWidthOverride - 1)
    onPlus: settingsRoot.stagedBarBorderWidthOverride =
        Math.min(12, settingsRoot.shownBarBorderWidthOverride + 1)
}

SettingsComponents.ToggleSettingRow {
    label: "Use theme color"
    value: settingsRoot.shownBarBorderUseThemeColor
    staged: settingsRoot.stagedBarBorderUseThemeColor !== null
    onToggled: settingsRoot.stagedBarBorderUseThemeColor =
        !settingsRoot.shownBarBorderUseThemeColor
}

// Hex entry, shown only when the theme color is off. The
// HexColorRow component (extracted from what used to be an
// inline block here, 2026-07-11) only ever stages VALID
// hex — Apply can't submit garbage.
SettingsComponents.HexColorRow {
    colorPickerHost: settingsRoot
    visible: !settingsRoot.shownBarBorderUseThemeColor
    shownValue: settingsRoot.shownBarBorderCustomColor
    staged: settingsRoot.stagedBarBorderCustomColor !== null
    onHexStaged: t => settingsRoot.stagedBarBorderCustomColor = t
}

Text {
    visible: !settingsRoot.shownBarBorderUseThemeColor
    text: "#RRGGBB (8 digits = Qt #AARRGGBB, alpha first)"
    color: Theme.colorMuted
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(Theme.fontSize * 0.8)
}

// ---------------- Wallpaper library ----------------
Text {
    text: "Wallpaper Library"
    Layout.topMargin: Theme.spacingLarge
    color: Theme.colorForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
}

Text {
    Layout.fillWidth: true
    text: "Shared by the top-bar picker and the SDDM wallpaper chooser. Thumbnails remain in the library's .thumbs folder."
    wrapMode: Text.WordWrap
    color: Theme.colorMuted
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(Theme.fontSize * 0.9)
}

RowLayout {
    Layout.fillWidth: true
    spacing: Theme.spacingSmall

    TextField {
        id: wallpapersPathField
        Layout.fillWidth: true
        text: settingsRoot.shownWallpapersPath
        placeholderText: "~/Pictures/Wallpapers"
        color: Theme.colorForeground
        placeholderTextColor: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        selectByMouse: true
        onTextEdited: settingsRoot.stagedWallpapersPath = text.trim()

        background: Rectangle {
            radius: Theme.radiusMedium
            color: wallpapersPathField.activeFocus ? Theme.colorHover : Theme.colorSurface
            border.width: wallpapersPathField.activeFocus ? 2 : 1
            border.color: wallpapersPathField.activeFocus ? Theme.colorAccent : Theme.colorMuted
        }
    }

    Rectangle {
        implicitWidth: resetWallpaperPathText.implicitWidth + Theme.spacingMedium * 2
        implicitHeight: wallpapersPathField.implicitHeight
        radius: Theme.radiusMedium
        color: resetWallpaperPathMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
        border.width: 1
        border.color: Theme.colorMuted

        Text {
            id: resetWallpaperPathText
            anchors.centerIn: parent
            text: "Reset"
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        MouseArea {
            id: resetWallpaperPathMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: settingsRoot.stagedWallpapersPath = "~/Pictures/Wallpapers"
        }
    }
}

// ---------------- Settings window geometry ----------------
Text {
    text: "Settings Window"
    Layout.topMargin: Theme.spacingLarge
    color: Theme.colorForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
}

Text {
    Layout.fillWidth: true
    text: "Controls the size used the next time Settings opens. Manual resizing remains temporary."
    wrapMode: Text.WordWrap
    color: Theme.colorMuted
    font.family: Theme.fontFamily
    font.pixelSize: Math.round(Theme.fontSize * 0.9)
}

SettingsComponents.StepperRow {
    label: "Default width"
    valueText: settingsRoot.shownSettingsWindowDefaultWidth + " px"
    staged: settingsRoot.stagedSettingsWindowDefaultWidth !== null
    showReset: true
    onMinus: settingsRoot.stagedSettingsWindowDefaultWidth = Math.max(700, settingsRoot.shownSettingsWindowDefaultWidth - 50)
    onPlus: settingsRoot.stagedSettingsWindowDefaultWidth = Math.min(1800, settingsRoot.shownSettingsWindowDefaultWidth + 50)
    onReset: settingsRoot.stagedSettingsWindowDefaultWidth = 1036
}

SettingsComponents.StepperRow {
    label: "Default height"
    valueText: settingsRoot.shownSettingsWindowDefaultHeight + " px"
    staged: settingsRoot.stagedSettingsWindowDefaultHeight !== null
    showReset: true
    onMinus: settingsRoot.stagedSettingsWindowDefaultHeight = Math.max(500, settingsRoot.shownSettingsWindowDefaultHeight - 50)
    onPlus: settingsRoot.stagedSettingsWindowDefaultHeight = Math.min(1200, settingsRoot.shownSettingsWindowDefaultHeight + 50)
    onReset: settingsRoot.stagedSettingsWindowDefaultHeight = 616
}

// ---------------- Wallpaper Transition (2026-07-13) ----------------
// Migrated from core/Settings.qml — see that file's note.
// Same closed-button + floating-list recipe as the Theme
// dropdown above (14 options is too many for a segmented
// OptionPickerRow without it looking cramped — see
// AI-MAINTENANCE-GUIDE on spacing/crowding). Position only
// means anything for grow/outer (swww ignores it for every
// other type); angle only means anything for wipe/wave —
// both extra controls are hidden otherwise rather than
// shown-but-inert, so the page doesn't ask for input that
// would silently do nothing.
Text {
    text: "Wallpaper Transition"
    Layout.topMargin: Theme.spacingLarge
    color: Theme.colorForeground
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
}

Rectangle {
    id: wallpaperTransitionTypeDropdownButton
    Layout.fillWidth: true
    implicitHeight: wallpaperTransitionTypeButtonRow.implicitHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    bottomLeftRadius: settingsRoot.wallpaperTransitionTypeDropdownOpen ? 0 : -1
    bottomRightRadius: settingsRoot.wallpaperTransitionTypeDropdownOpen ? 0 : -1
    color: wallpaperTransitionTypeButtonMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
    border.width: 1
    border.color: Theme.colorMuted

    RowLayout {
        id: wallpaperTransitionTypeButtonRow
        anchors.fill: parent
        anchors.leftMargin: Theme.spacingMedium
        anchors.rightMargin: Theme.spacingMedium
        spacing: Theme.spacingMedium

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: (settingsRoot.stagedWallpaperTransitionType !== null ? "● " : "") + settingsRoot.shownWallpaperTransitionType
            color: settingsRoot.stagedWallpaperTransitionType !== null ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        Text {
            text: settingsRoot.wallpaperTransitionTypeDropdownOpen ? "▾" : "▸"
            color: Theme.colorMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }
    MouseArea {
        id: wallpaperTransitionTypeButtonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            settingsRoot.wallpaperTransitionTypeDropdownOpen = !settingsRoot.wallpaperTransitionTypeDropdownOpen;
            if (settingsRoot.wallpaperTransitionTypeDropdownOpen) {
                settingsRoot.themeDropdownOpen = false;
                settingsRoot.fontFamilyDropdownOpen = false;
            }
        }
    }
}
// (Dropdown list itself lives at card level, alongside the
// Theme/Font Family ones — see "Dropdown overlays" further
// down the file.)

SettingsComponents.OptionPickerRow {
    visible: settingsRoot.shownWallpaperTransitionType === "grow"
          || settingsRoot.shownWallpaperTransitionType === "outer"
    label: "Position"
    options: settingsRoot.wallpaperTransitionPosOptions
    shownValue: settingsRoot.shownWallpaperTransitionPos
    staged: settingsRoot.stagedWallpaperTransitionPos !== null
    onPicked: v => settingsRoot.stagedWallpaperTransitionPos = v
}

SettingsComponents.StepperRow {
    label: "Duration"
    valueText: settingsRoot.shownWallpaperTransitionDuration.toFixed(1) + "s"
    staged: settingsRoot.stagedWallpaperTransitionDuration !== null
    onMinus: settingsRoot.stagedWallpaperTransitionDuration =
        Math.max(0.1, Math.round((settingsRoot.shownWallpaperTransitionDuration - 0.1) * 10) / 10)
    onPlus: settingsRoot.stagedWallpaperTransitionDuration =
        Math.min(5.0, Math.round((settingsRoot.shownWallpaperTransitionDuration + 0.1) * 10) / 10)
}

SettingsComponents.StepperRow {
    label: "FPS"
    valueText: String(settingsRoot.shownWallpaperTransitionFps)
    staged: settingsRoot.stagedWallpaperTransitionFps !== null
    onMinus: settingsRoot.stagedWallpaperTransitionFps =
        Math.max(1, settingsRoot.shownWallpaperTransitionFps - 5)
    onPlus: settingsRoot.stagedWallpaperTransitionFps =
        Math.min(240, settingsRoot.shownWallpaperTransitionFps + 5)
}

SettingsComponents.StepperRow {
    visible: settingsRoot.shownWallpaperTransitionType === "wipe"
          || settingsRoot.shownWallpaperTransitionType === "wave"
    label: "Angle"
    valueText: Math.round(settingsRoot.shownWallpaperTransitionAngle) + "°"
    staged: settingsRoot.stagedWallpaperTransitionAngle !== null
    onMinus: settingsRoot.stagedWallpaperTransitionAngle =
        (((settingsRoot.shownWallpaperTransitionAngle - 15) % 360) + 360) % 360
    onPlus: settingsRoot.stagedWallpaperTransitionAngle =
        (((settingsRoot.shownWallpaperTransitionAngle + 15) % 360) + 360) % 360
}

}
