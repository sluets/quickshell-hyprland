// Wallpaper picker presentation settings. Content stays in WallpaperPickerContent. // GPT Rev 47
import QtQuick.Controls
import QtQuick
import QtQuick.Layouts
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page

    required property var settingsRoot
    readonly property alias wallpaperTransitionTypeDropdownAnchor: wallpaperTransitionTypeDropdownButton
    Layout.fillWidth: true
    spacing: Theme.spacingMedium

    SettingsComponents.OptionPickerRow {
        label: "Placement"
        options: settingsRoot.wallpaperPickerPlacementOptions
        shownValue: settingsRoot.shownWallpaperPickerPlacement
        staged: settingsRoot.stagedWallpaperPickerPlacement !== null
        onPicked: value => settingsRoot.stagedWallpaperPickerPlacement = value
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingSmall
        enabled: settingsRoot.shownWallpaperPickerPlacement === "centered"
        opacity: enabled ? 1.0 : 0.45

        Text {
            text: "Horizontal Offset"
            color: settingsRoot.stagedWallpaperPickerOffsetX !== null ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        SettingsComponents.StepperRow {
            label: ""
            labelColumnWidth: 0
            valueColumnWidth: 72
            valueText: settingsRoot.shownWallpaperPickerOffsetX + " px"
            staged: settingsRoot.stagedWallpaperPickerOffsetX !== null
            onMinus: settingsRoot.stagedWallpaperPickerOffsetX = Math.max(-500, settingsRoot.shownWallpaperPickerOffsetX - 5)
            onPlus: settingsRoot.stagedWallpaperPickerOffsetX = Math.min(2000, settingsRoot.shownWallpaperPickerOffsetX + 5)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.spacingSmall
        enabled: settingsRoot.shownWallpaperPickerPlacement === "centered"
        opacity: enabled ? 1.0 : 0.45

        Text {
            text: "Vertical Offset"
            color: settingsRoot.stagedWallpaperPickerOffsetY !== null ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        SettingsComponents.StepperRow {
            label: ""
            labelColumnWidth: 0
            valueColumnWidth: 72
            valueText: settingsRoot.shownWallpaperPickerOffsetY + " px"
            staged: settingsRoot.stagedWallpaperPickerOffsetY !== null
            onMinus: settingsRoot.stagedWallpaperPickerOffsetY = Math.max(-500, settingsRoot.shownWallpaperPickerOffsetY - 5)
            onPlus: settingsRoot.stagedWallpaperPickerOffsetY = Math.min(2000, settingsRoot.shownWallpaperPickerOffsetY + 5)
        }
    }

    Text {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: "Attached preserves the existing bar-grown picker. Centered uses the same wallpaper library, shuffle, keyboard navigation, thumbnails, and apply behavior in a screen-centered surface."
        color: Theme.colorMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
    }

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

    SettingsComponents.ToggleSettingRow {
        label: "Cache thumbnails"
        value: settingsRoot.shownWallpaperCachingEnabled
        staged: settingsRoot.stagedWallpaperCachingEnabled !== null
        onToggled: settingsRoot.stagedWallpaperCachingEnabled = !settingsRoot.shownWallpaperCachingEnabled
    }

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
        onMinus: settingsRoot.stagedWallpaperTransitionDuration = Math.max(0.1, Math.round((settingsRoot.shownWallpaperTransitionDuration - 0.1) * 10) / 10)
        onPlus: settingsRoot.stagedWallpaperTransitionDuration = Math.min(5.0, Math.round((settingsRoot.shownWallpaperTransitionDuration + 0.1) * 10) / 10)
    }

    SettingsComponents.StepperRow {
        label: "FPS"
        valueText: String(settingsRoot.shownWallpaperTransitionFps)
        staged: settingsRoot.stagedWallpaperTransitionFps !== null
        onMinus: settingsRoot.stagedWallpaperTransitionFps = Math.max(1, settingsRoot.shownWallpaperTransitionFps - 5)
        onPlus: settingsRoot.stagedWallpaperTransitionFps = Math.min(240, settingsRoot.shownWallpaperTransitionFps + 5)
    }

    SettingsComponents.StepperRow {
        visible: settingsRoot.shownWallpaperTransitionType === "wipe"
              || settingsRoot.shownWallpaperTransitionType === "wave"
        label: "Angle"
        valueText: Math.round(settingsRoot.shownWallpaperTransitionAngle) + "°"
        staged: settingsRoot.stagedWallpaperTransitionAngle !== null
        onMinus: settingsRoot.stagedWallpaperTransitionAngle = (((settingsRoot.shownWallpaperTransitionAngle - 15) % 360) + 360) % 360
        onPlus: settingsRoot.stagedWallpaperTransitionAngle = (((settingsRoot.shownWallpaperTransitionAngle + 15) % 360) + 360) % 360
    }

}
