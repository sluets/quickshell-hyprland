//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/MenuButton.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// A single clickable row for use inside a dropdown menu (e.g.
// SystemMenu.qml's power options) — optional leading icon, left-aligned
// label, full-width hover highlight, themed via Theme.colorHover/
// colorForeground/radiusMedium. Sized entirely from its own content, so
// the menu it sits in can size itself to fit ("as wide as the text
// needs") instead of using a hardcoded width. Meant to be reused by
// every future dropdown menu (Wifi, Bluetooth, Volume), not just
// SystemMenu — see ARCHITECTURE.md's "Dropdown menu pattern" section.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// QtQuick.Layouts (for the internal icon+label RowLayout)
// core/Theme.qml (singleton, via `import qs.core`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/SystemMenu.qml (neighboring file, no import needed).
// Intended for future dropdown menus (Wifi, Bluetooth, Volume) too.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Anything instantiating `MenuButton {}` fails to resolve the type.
// SystemMenu.qml's three power options would need reimplementing inline.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// Exposes plain `text`/`icon` properties and a `clicked()` signal rather
// than wrapping Qt Quick Controls' `Button` or `MenuItem` — those pull in
// their own styling system (QQC2 styles) that would fight with this
// project's own Theme singleton instead of cooperating with it. A plain
// Rectangle + RowLayout + MouseArea is a few more lines but stays
// entirely within the theme pattern already used everywhere else in
// this project.
//
// `icon` IS A PLAIN STRING, NOT A NERD FONT GLYPH SPECIFICALLY:
// Whatever's passed in renders through the same `fontFamily` as the
// label, so Nerd Font glyphs work, but so do plain Unicode symbols (see
// SystemMenu.qml — its icons are standard Unicode arrows/power symbols,
// not Nerd Font PUA codepoints, on purpose). The icon column has a fixed
// width (`Theme.fontSize`) regardless of the glyph's natural width, so
// labels across multiple rows stay aligned even if one icon is visually
// narrower than another.
//
// implicitWidth IS CONTENT-DRIVEN ON PURPOSE:
// This used to have no implicit width of its own, relying on whatever
// hardcoded width the popup around it used. That popup ended up too
// narrow to fit "Restart Hyprland" without clipping. Now
// `implicitWidth` is computed from the icon+label row's own natural
// size, so a `ColumnLayout` of these (each with `Layout.fillWidth:
// true`) reports the WIDEST row's width as the column's own implicit
// width — which is what SystemMenu.qml uses to size the popup itself.
// One consequence: adding a longer label to any row grows the whole
// menu automatically, no manual width tuning needed anywhere.
//
// `Layout.fillWidth: true` is expected to be set by whoever instantiates
// this inside a ColumnLayout (see SystemMenu.qml) — this file doesn't
// set it itself since it isn't always used inside a ColumnLayout.
//
// HOVER FADE + PRESS SCALE (added 2026-07-05, part of the wider
// dropdown-menu visual refresh — see DeviceRow.qml/ToggleRow.qml/
// SectionLabel.qml/SignalBars.qml, all added the same pass): previously
// hover was an instant, unanimated color swap. `Behavior on color`
// (Theme.animationDuration, the same shared timing every popout-open
// animation already uses) and a subtle `scale: 0.98` on press are
// small, cheap additions that every existing MenuButton consumer
// (SystemMenu, SettingsMenu, etc.) gets automatically, no call-site
// changes needed — this is the one component in the refresh that
// improves things project-wide just by being edited once.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-05  Added hover color Behavior (fade instead of instant swap)
//             and a subtle press-scale. Part of the wider dropdown-menu
//             visual refresh — see this file's DESIGN NOTES.
// 2026-07-01  Added optional `icon` property (fixed-width column so
//             multiple rows' labels stay aligned). implicitWidth is now
//             computed from content instead of being unset/hardcoded
//             elsewhere — fixes SystemMenu's popup being too narrow for
//             "Restart Hyprland".
// 2026-07-01  Initial version.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property string text: ""
    property string icon: ""
    signal clicked()

    implicitWidth: content.implicitWidth + Theme.spacingSmall * 2
    implicitHeight: content.implicitHeight + Theme.spacingSmall * 2
    radius: Theme.radiusMedium
    color: mouseArea.containsMouse ? Theme.colorHover : "transparent"
    scale: mouseArea.pressed ? 0.98 : 1.0

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.animationEasing
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animationDuration / 2
            easing.type: Theme.animationEasing
        }
    }

    RowLayout {
        id: content
        anchors.left: parent.left
        anchors.leftMargin: Theme.spacingSmall
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacingSmall

        Text {
            text: root.icon
            visible: root.icon.length > 0
            Layout.preferredWidth: Theme.fontSize
            horizontalAlignment: Text.AlignHCenter
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: root.text
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
