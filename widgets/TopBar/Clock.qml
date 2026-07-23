// Date and time bar widget. Date opens the calendar; time opens runtime-only
// timer, stopwatch, and alarm tools. // GPT 2026-07-23

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.services

Item {
    id: root

    implicitWidth: barRow.implicitWidth
    implicitHeight: barRow.implicitHeight

    property int toolsTab: 0 // 0 timer, 1 stopwatch, 2 alarm
    property int timerMinutes: 5

    SystemClock {
        id: sysClock
        precision: (UserPrefs.clockShowSeconds || ClockTools.anyActive)
            ? SystemClock.Seconds : SystemClock.Minutes
    }

    function timeFormat(): string {
        if (UserPrefs.clockUse24Hour)
            return UserPrefs.clockShowSeconds ? "HH:mm:ss" : "HH:mm";
        return UserPrefs.clockShowSeconds ? "h:mm:ss AP" : "h:mm AP";
    }

    component SmallButton: Rectangle {
        id: button
        property string label: ""
        signal clicked
        implicitWidth: Math.max(44, labelText.implicitWidth + Theme.spacingMedium * 2)
        implicitHeight: labelText.implicitHeight + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: mouse.containsMouse ? Theme.colorHover : Theme.colorSurface
        border.width: 1
        border.color: Theme.colorMuted
        Text {
            id: labelText
            anchors.centerIn: parent
            text: button.label
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    component TabButton: Rectangle {
        id: tab
        property string label: ""
        property bool selected: false
        signal clicked
        implicitWidth: tabText.implicitWidth + Theme.spacingLarge * 2
        implicitHeight: tabText.implicitHeight + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: selected ? Theme.colorAccent : (tabMouse.containsMouse ? Theme.colorHover : "transparent")
        Text {
            id: tabText
            anchors.centerIn: parent
            text: tab.label
            color: tab.selected ? Theme.colorBackground : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: tab.selected
        }
        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tab.clicked()
        }
    }

    RowLayout {
        id: barRow
        spacing: Theme.spacingSmall

        Item {
            id: dateHit
            implicitWidth: dateText.implicitWidth
            implicitHeight: dateText.implicitHeight
            Text {
                id: dateText
                anchors.centerIn: parent
                text: Qt.formatDateTime(sysClock.date, "ddd, MMM d")
                color: (calendarPopout.open || dateMouse.containsMouse) ? Theme.colorAccent : Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
            MouseArea {
                id: dateMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    toolsPopout.open = false;
                    if (!calendarPopout.open) calendarPopout.resetToToday();
                    calendarPopout.open = !calendarPopout.open;
                }
            }
        }

        Separator {}

        Item {
            id: timeHit
            implicitWidth: timeRow.implicitWidth
            implicitHeight: timeRow.implicitHeight
            RowLayout {
                id: timeRow
                anchors.centerIn: parent
                spacing: Theme.spacingSmall
                Text {
                    text: Qt.formatDateTime(sysClock.date, root.timeFormat())
                    color: (toolsPopout.open || timeMouse.containsMouse) ? Theme.colorAccent : Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    visible: ClockTools.timerRunning || ClockTools.timerPaused
                    text: "· " + ClockTools.formatDuration(ClockTools.timerRemainingMs, false)
                    color: Theme.colorAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
                Text {
                    visible: !ClockTools.timerRunning && !ClockTools.timerPaused && ClockTools.stopwatchRunning
                    text: "· " + ClockTools.formatDuration(ClockTools.stopwatchElapsedMs, false)
                    color: Theme.colorAccent
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
            MouseArea {
                id: timeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    calendarPopout.open = false;
                    toolsPopout.open = !toolsPopout.open;
                }
            }
        }
    }

    BarPopout {
        id: calendarPopout
        anchorItem: dateHit
        alignment: "right"
        property int displayedMonth: sysClock.date.getMonth()
        property int displayedYear: sysClock.date.getFullYear()
        function resetToToday() {
            displayedMonth = sysClock.date.getMonth();
            displayedYear = sysClock.date.getFullYear();
        }
        function stepMonth(delta) {
            let m = displayedMonth + delta;
            let y = displayedYear;
            if (m < 0) { m = 11; y--; }
            if (m > 11) { m = 0; y++; }
            displayedMonth = m; displayedYear = y;
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 340
            spacing: Theme.spacingSmall
            MenuButton { text: "‹"; onClicked: calendarPopout.stepMonth(-1) }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(new Date(calendarPopout.displayedYear, calendarPopout.displayedMonth, 1), "MMMM yyyy")
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.bold: true
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: calendarPopout.resetToToday() }
            }
            MenuButton { text: "›"; onClicked: calendarPopout.stepMonth(1) }
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
            month: calendarPopout.displayedMonth
            year: calendarPopout.displayedYear
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
                    color: model.today ? Theme.colorBackground : (model.month === grid.month ? Theme.colorForeground : Theme.colorMuted)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: model.today
                }
            }
        }
    }

    BarPopout {
        id: toolsPopout
        anchorItem: timeHit
        alignment: "right"

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 390
            spacing: Theme.spacingSmall
            TabButton { label: "Timer"; selected: root.toolsTab === 0; onClicked: root.toolsTab = 0 }
            TabButton { label: "Stopwatch"; selected: root.toolsTab === 1; onClicked: root.toolsTab = 1 }
            TabButton { label: "Alarm"; selected: root.toolsTab === 2; onClicked: root.toolsTab = 2 }
            Item { Layout.fillWidth: true }
        }

        MenuDivider { Layout.fillWidth: true }

        ColumnLayout {
            visible: root.toolsTab === 0
            Layout.fillWidth: true
            spacing: Theme.spacingMedium
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: ClockTools.formatDuration(ClockTools.timerRemainingMs > 0 ? ClockTools.timerRemainingMs : ClockTools.timerDurationMs, false)
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 2.2)
                font.bold: true
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingSmall
                Repeater {
                    model: [1, 5, 10, 15, 30, 60]
                    SmallButton {
                        required property var modelData
                        label: modelData + "m"
                        onClicked: {
                            root.timerMinutes = modelData;
                            ClockTools.setTimerMinutes(modelData);
                        }
                    }
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingSmall
                SmallButton {
                    label: ClockTools.timerRunning ? "Pause" : (ClockTools.timerPaused ? "Resume" : "Start")
                    onClicked: ClockTools.timerRunning ? ClockTools.pauseTimer() : ClockTools.startTimer()
                }
                SmallButton { label: "Reset"; onClicked: ClockTools.resetTimer() }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Notifies at 1 minute remaining and when finished."
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 0.82)
            }
        }

        ColumnLayout {
            visible: root.toolsTab === 1
            Layout.fillWidth: true
            spacing: Theme.spacingMedium
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: ClockTools.formatDuration(ClockTools.stopwatchElapsedMs, true)
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 2.2)
                font.bold: true
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingSmall
                SmallButton { label: ClockTools.stopwatchRunning ? "Pause" : "Start"; onClicked: ClockTools.toggleStopwatch() }
                SmallButton { label: "Lap"; onClicked: ClockTools.addLap() }
                SmallButton { label: "Reset"; onClicked: ClockTools.resetStopwatch() }
            }
            Text {
                text: "Interval alerts"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingSmall
                Repeater {
                    model: [0, 1, 5, 10, 15, 30]
                    SmallButton {
                        required property var modelData
                        label: modelData === 0 ? "Off" : modelData + "m"
                        border.color: ClockTools.stopwatchIntervalMinutes === modelData ? Theme.colorAccent : Theme.colorMuted
                        onClicked: {
                            ClockTools.stopwatchIntervalMinutes = modelData;
                            ClockTools.stopwatchLastInterval = modelData > 0 ? Math.floor(ClockTools.stopwatchElapsedMs / (modelData * 60000)) : 0;
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                visible: ClockTools.laps.length > 0
                spacing: Theme.spacingSmall
                Text { text: "Laps"; color: Theme.colorMuted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSize }
                Repeater {
                    model: ClockTools.laps.slice(0, 6)
                    Text {
                        required property int index
                        required property var modelData
                        Layout.fillWidth: true
                        text: "Lap " + (ClockTools.laps.length - index) + "    " + ClockTools.formatDuration(modelData, true)
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }
            }
        }

        ColumnLayout {
            visible: root.toolsTab === 2
            Layout.fillWidth: true
            spacing: Theme.spacingMedium
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: ClockTools.two(ClockTools.alarmHour) + ":" + ClockTools.two(ClockTools.alarmMinute)
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 2.2)
                font.bold: true
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingSmall
                SmallButton { label: "Hour −"; onClicked: ClockTools.alarmHour = (ClockTools.alarmHour + 23) % 24 }
                SmallButton { label: "Hour +"; onClicked: ClockTools.alarmHour = (ClockTools.alarmHour + 1) % 24 }
                SmallButton { label: "Min −"; onClicked: ClockTools.alarmMinute = (ClockTools.alarmMinute + 55) % 60 }
                SmallButton { label: "Min +"; onClicked: ClockTools.alarmMinute = (ClockTools.alarmMinute + 5) % 60 }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.spacingSmall
                SmallButton {
                    label: ClockTools.alarmEnabled ? "Disable" : "Set alarm"
                    onClicked: ClockTools.alarmEnabled ? ClockTools.disableAlarm() : ClockTools.enableAlarm()
                }
                Text {
                    text: ClockTools.alarmLabel()
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }
        }

        MenuDivider { Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingSmall
            Text {
                text: "Alert sound"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
            Item { Layout.fillWidth: true }
            SmallButton {
                label: ClockTools.alertSoundEnabled ? "Sound on" : "Sound off"
                border.color: ClockTools.alertSoundEnabled ? Theme.colorAccent : Theme.colorMuted
                onClicked: ClockTools.alertSoundEnabled = !ClockTools.alertSoundEnabled
            }
            Repeater {
                model: ClockTools.soundChoices
                SmallButton {
                    required property var modelData
                    label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    border.color: ClockTools.alertSoundEnabled && ClockTools.alertSound === modelData
                        ? Theme.colorAccent : Theme.colorMuted
                    onClicked: {
                        ClockTools.alertSound = modelData;
                        ClockTools.alertSoundEnabled = true;
                        ClockTools.playAlert(true);
                    }
                }
            }
        }
    }
}
