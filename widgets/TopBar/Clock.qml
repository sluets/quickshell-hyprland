//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/Clock.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Date and time in the bar (separated by the shared "|" divider), driven
// by UserPrefs.clockUse24Hour and UserPrefs.clockShowSeconds (persisted,
// configured from Settings → Desktop). Left-click opens a
// month calendar popout, with prev/today/next
// navigation and today highlighted.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick / QtQuick.Layouts
// QtQuick.Controls              (MonthGrid, DayOfWeekRow — see DESIGN NOTES)
// Quickshell                    (SystemClock)
// core/Theme.qml, core/UserPrefs.qml (singletons via `import qs.core`)
// widgets/TopBar/BarPopout.qml  (neighboring file)
// widgets/TopBar/Separator.qml  (neighboring file)
// widgets/TopBar/MenuButton.qml (neighboring file)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/TopBar.qml
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// TopBar loses the clock and calendar. Nothing else depends on this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// MonthGrid / DayOfWeekRow are part of QtQuick.Controls in Qt 6.3+
// (they graduated from the old Qt.labs.calendar) — verified in use in
// a maintained real-world Quickshell config with the same import. Their
// delegates are fully replaced below so nothing renders in platform
// style — every color/font is Theme's.
//
// The popout keeps its own displayedMonth/Year state, initialized from
// SystemClock each time it opens (so reopening it a week later never
// shows a stale month you'd navigated to).
//
// MonthGrid's model includes days from the adjacent months to fill the
// 6-week grid — those render in colorMuted so the current month reads
// clearly.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-09  (Fable 5) Swapped Settings.clockUse24Hour/clockShowSeconds
//             to UserPrefs.* — the properties moved to core/UserPrefs.qml
//             on 07-05 but this file was never updated, so both stale
//             references evaluated to undefined (silently: always
//             12-hour, never seconds) and the SettingsMenu clock toggles
//             had no visible effect. This was the known-deferred half of
//             the 07-05 "partial revert" finding in
//             docs/PROBLEMS_AND_FIXES.md; the Theme.qml/Appearance half
//             is STILL deferred — see that entry.
// 2026-07-04  flushToScreenEdge -> flushToBarEdge (BarPopout property
//             rename, no behavior change here).
// 2026-07-03  Added the calendar popout (MonthGrid + DayOfWeekRow,
//             prev/today/next). Bar display unchanged.
// 2026-07-02  clockUse24Hour default flip happened in Settings, not here.
// 2026-07-01  Initial clock.
//
//=============================================================================

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.core

Item {
    id: root

    implicitWidth: barRow.implicitWidth
    implicitHeight: barRow.implicitHeight

    SystemClock {
        id: sysClock
        // Only ask for second-level updates if seconds are shown.
        precision: UserPrefs.clockShowSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    function timeFormat(): string {
        if (UserPrefs.clockUse24Hour) {
            return UserPrefs.clockShowSeconds ? "HH:mm:ss" : "HH:mm";
        } else {
            return UserPrefs.clockShowSeconds ? "h:mm:ss AP" : "h:mm AP";
        }
    }

    RowLayout {
        id: barRow
        spacing: Theme.spacingSmall

        Text {
            text: Qt.formatDateTime(sysClock.date, "ddd, MMM d")
            color: (popout.open || barMouse.containsMouse) ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Separator {}

        Text {
            text: Qt.formatDateTime(sysClock.date, root.timeFormat())
            color: (popout.open || barMouse.containsMouse) ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: barMouse
        anchors.fill: barRow
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!popout.open)
                popout.resetToToday();
            popout.open = !popout.open;
        }
    }

    BarPopout {
        id: popout
        anchorItem: root
        alignment: "right"
        //flushToBarEdge: true

        // Which month the grid is showing — navigated by the buttons,
        // re-initialized from the real clock on every open.
        property int displayedMonth: sysClock.date.getMonth()
        property int displayedYear: sysClock.date.getFullYear()

        function resetToToday(): void {
            displayedMonth = sysClock.date.getMonth();
            displayedYear = sysClock.date.getFullYear();
        }

        function stepMonth(delta: int): void {
            let m = displayedMonth + delta;
            let y = displayedYear;
            if (m < 0)  { m = 11; y--; }
            if (m > 11) { m = 0;  y++; }
            displayedMonth = m;
            displayedYear = y;
        }

        // ---- Header: < Month Year > ----
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 340
            spacing: Theme.spacingSmall

            MenuButton {
                text: "‹"
                onClicked: popout.stepMonth(-1)
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(new Date(popout.displayedYear, popout.displayedMonth, 1), "MMMM yyyy")
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popout.resetToToday()
                }
            }

            MenuButton {
                text: "›"
                onClicked: popout.stepMonth(1)
            }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            spacing: 0

            delegate: Text {
                required property var model
                text: model.shortName
                horizontalAlignment: Text.AlignHCenter
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
            }
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            month: popout.displayedMonth
            year: popout.displayedYear
            spacing: 0

            delegate: Item {
                required property var model
                implicitWidth: dayText.implicitWidth + Theme.spacingMedium
                implicitHeight: dayText.implicitHeight + Theme.spacingSmall

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(parent.width, parent.height)
                    height: width
                    radius: width / 2
                    visible: model.today
                    color: Theme.colorAccent
                }

                Text {
                    id: dayText
                    anchors.centerIn: parent
                    text: model.day
                    color: model.today
                        ? Theme.colorBackground
                        : (model.month === grid.month ? Theme.colorForeground : Theme.colorMuted)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: model.today
                }
            }
        }
    }
}
