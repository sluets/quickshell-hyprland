//=============================================================================
// widgets/TopBar/Clock.qml
//
// Date/time bar widget + the "Clock Tools" popout: calendar card, timer
// with preset chips and a progress ring, side-by-side stopwatch and
// alarm cards, and an alert-sound row. Matches the SectionLabel +
// section-card design language used by the redesigned Audio
// (Volume.qml) and Connectivity (Wifi.qml) popouts.
//
// Tool STATE lives in services/ClockTools.qml (unchanged) — this file is
// presentation only.
//
//=============================================================================
// SIZING NOTES (read before "it looks cramped" — 2026-07-29)
//=============================================================================
//
// BarPopout's width is CONTENT-DRIVEN (contentColumn.implicitWidth +
// margins), and Theme.fontSize is the theme's base size multiplied by
// the user's fontScale. So a popout laid out at one font size gets tight
// at a larger one unless three things hold, all of which this file now
// does deliberately:
//
//   1. The minimum width SCALES WITH THE FONT rather than being a fixed
//      pixel number. But it is only a JITTER FLOOR, not a target: it sits
//      just under what the widest row naturally needs, so the CONTENT
//      decides the width and the floor only stops the popout resizing
//      between states (idle timer field vs running timer row). The first
//      pass set it to fontSize * 34, which at the maintainer's scale was
//      ~180 px of dead space — a floor above the natural content width
//      doesn't make a popout roomier, it makes it empty. fontSize * 23.
//      The widest row is the alert-sound row, which is why its chips got
//      a `compact` mode; trim that row before raising the floor.
//   2. Numbers that change while running (stopwatch elapsed, timer
//      remaining) DO NOT ELIDE and carry Layout.minimumWidth:
//      implicitWidth. A layout will happily crush a Text to "00:0…"
//      before it will widen its own parent — the minimum is what makes
//      the popout grow instead. Elide is for labels, never for a
//      readout.
//   3. Fixed-size controls (IconButton, the ring) are MULTIPLES OF
//      Theme.fontSize, not px constants, so they stay in proportion at
//      every scale.
//
// If a section crowds at large scales, find the row that is actually
// setting the width and slim IT down — raising the floor only adds empty
// space to every other row.
//
//=============================================================================
// ⚠ WRITTEN OFFLINE — NOT YET RUN LIVE. Test checklist:
//   - Popout opens/closes from date and time text; today highlighted;
//     month nav + clicking the month name (reset to today) work.
//   - Preset chips start a timer immediately; ring + bottom bar fill;
//     pause/resume/reset work; bar's "· mm:ss" tail still appears.
//   - Timer field accepts "90", "1:30", "0:0:45"; invalid input turns
//     the border urgent until edited.
//   - Stopwatch: reset button appears only once time has elapsed;
//     readout never truncates at any font scale (test fontScale 1.4).
//   - Alarm: type "7:30 AM" (or bare "19:30" with the 24-hour clock on)
//     and flip the switch — sub-line reads "Next: …"; bad input shows an
//     urgent hint and snaps the switch back off.
//   - Sound chips preview + select; bell button mutes/unmutes.
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-29  (Claude Fable 5) Width correction: the fontSize * 34 floor
//             from the pass below was well ABOVE the natural content
//             width, so the popout was mostly empty space at the
//             maintainer's font scale. Floor lowered to fontSize * 23
//             (jitter guard only — content now decides), and the
//             alert-sound row, which was the widest thing in the popout,
//             slimmed via a new compact Chip mode.
// 2026-07-29  (Claude Fable 5) Maintainer review pass: world clocks
//             removed (with them the `date`-offset Process, so no
//             Quickshell.Io import), date footer removed, timer
//             placeholder shortened, stopwatch de-crowded (reset button
//             appears only when there's something to reset), alarm
//             AM/PM chip folded INTO the time field ("7:30 AM" parses,
//             as does 24-hour "19:30" — one control instead of two, and
//             it reads like the mockup). Added the SIZING NOTES above
//             after the first live screenshot showed font-scale
//             crowding rather than a layout error.
// 2026-07-29  (Claude Fable 5) Full popout redesign to the maintainer's
//             mockup: section cards, preset chips, progress ring,
//             ToggleSwitch alarm (imperative `checked` sync — never
//             bind a property the control itself writes; see
//             BarPopout's design notes).
// 2026-07-23  (GPT) Split date/time targets; timer/stopwatch/alarm tools.
//=============================================================================

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

    // Canonical alarm text, in whichever clock format the user prefers.
    function alarmText(): string {
        return Qt.formatDateTime(
            new Date(2000, 0, 1, ClockTools.alarmHour, ClockTools.alarmMinute),
            UserPrefs.clockUse24Hour ? "HH:mm" : "h:mm AP");
    }

    // ---- Small building blocks shared by the popout sections --------------

    // Selectable pill — timer presets, Start, sound choices.
    // `compact` trims the padding and type size for secondary rows (the
    // alert-sound choices), which were the widest thing in the popout and
    // therefore what set its width.
    component Chip: Rectangle {
        id: chip
        property string label: ""
        property bool selected: false
        property bool compact: false
        signal clicked
        readonly property int hPad: compact ? Theme.spacingSmall : Theme.spacingMedium
        implicitWidth: Math.max(Theme.fontSize * (compact ? 2.2 : 2.8),
                                chipText.implicitWidth + hPad * 2)
        implicitHeight: chipText.implicitHeight + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: selected
            ? Theme.colorSelected
            : (chipMouse.containsMouse ? Theme.colorHover : Theme.colorControl)
        border.width: 1
        border.color: selected ? Theme.colorAccent : Theme.colorDivider

        Behavior on color {
            ColorAnimation {
                duration: Theme.animationDuration
                easing.type: Theme.animationEasing
            }
        }

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(11, Math.round(
                Theme.fontSize * (chip.compact ? 0.82 : 0.92)))
            font.bold: chip.selected
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    // Square glyph button — play/pause/reset, month nav, bell mute.
    // Sized off the font so it stays in proportion at every fontScale.
    component IconButton: Rectangle {
        id: iconButton
        property string glyph: ""
        property bool accent: false
        signal clicked
        implicitWidth: Math.max(28, Math.round(Theme.fontSize * 2.1))
        implicitHeight: implicitWidth
        Layout.minimumWidth: implicitWidth
        radius: Theme.radiusMedium
        color: iconMouse.containsMouse ? Theme.colorHover : Theme.colorControl
        border.width: 1
        border.color: Theme.colorDivider
        scale: iconMouse.pressed ? 0.94 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.animationDuration / 2
                easing.type: Theme.animationEasing
            }
        }

        Text {
            anchors.centerIn: parent
            text: iconButton.glyph
            color: iconButton.accent ? Theme.colorAccent : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Math.round(Theme.fontSize * 0.85)
        }

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: iconButton.clicked()
        }
    }

    // ---- Bar widget --------------------------------------------------------

    RowLayout {
        id: barRow
        spacing: Theme.spacingMedium

        Text {
            text: Qt.formatDateTime(sysClock.date, "ddd, MMM d")
            color: (clockPopout.open || barMouse.containsMouse)
                ? Theme.colorAccent
                : Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }

        Text {
            text: Qt.formatDateTime(sysClock.date, root.timeFormat())
            color: (clockPopout.open || barMouse.containsMouse)
                ? Theme.colorAccent
                : Theme.colorForeground
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
            visible: !ClockTools.timerRunning
                && !ClockTools.timerPaused
                && ClockTools.stopwatchRunning
            text: "· " + ClockTools.formatDuration(ClockTools.stopwatchElapsedMs, false)
            color: Theme.colorAccent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        id: barMouse
        anchors.fill: barRow
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: clockPopout.open = !clockPopout.open
    }

    // ---- Popout ------------------------------------------------------------

    BarPopout {
        detached: UserPrefs.popoutPresentation === "detached"
        id: clockPopout
        anchorItem: root
        alignment: "right"

        property int displayedMonth: sysClock.date.getMonth()
        property int displayedYear: sysClock.date.getFullYear()
        property bool alarmInvalid: false

        onOpenChanged: {
            if (open) {
                resetToToday();
                alarmInvalid = false;
                alarmTimeField.text = root.alarmText();
            }
        }

        function resetToToday() {
            displayedMonth = sysClock.date.getMonth();
            displayedYear = sysClock.date.getFullYear();
        }

        function stepMonth(delta) {
            let month = displayedMonth + delta;
            let year = displayedYear;
            if (month < 0) {
                month = 11;
                year--;
            } else if (month > 11) {
                month = 0;
                year++;
            }
            displayedMonth = month;
            displayedYear = year;
        }

        // Accepts "90" (minutes), "1:30" (h:mm), "0:0:45" (h:mm:ss).
        // Returns seconds, or 0 for anything it doesn't understand.
        function parseTimerInput(value) {
            const text = String(value || "").trim();
            if (!text.length)
                return 0;

            const parts = text.split(":");
            if (parts.length > 3)
                return 0;

            for (let i = 0; i < parts.length; ++i) {
                if (!/^\d+$/.test(parts[i]))
                    return 0;
            }

            if (parts.length === 1)
                return Number(parts[0]) * 60;

            if (parts.length === 2) {
                const hours = Number(parts[0]);
                const minutes = Number(parts[1]);
                if (minutes > 59)
                    return 0;
                return hours * 3600 + minutes * 60;
            }

            const hours = Number(parts[0]);
            const minutes = Number(parts[1]);
            const seconds = Number(parts[2]);
            if (minutes > 59 || seconds > 59)
                return 0;
            return hours * 3600 + minutes * 60 + seconds;
        }

        // One field for the whole alarm time, AM/PM included — "7:30 AM",
        // "7:30 A", or bare 24-hour "19:30". Replaced the separate AM/PM
        // chip, which cost width the half-size card didn't have.
        function applyAlarmInput(value) {
            const s = String(value || "").trim().toUpperCase();
            const m = s.match(/^(\d{1,2}):(\d{2}) ?(AM|PM|A|P)?$/);
            if (!m)
                return false;

            let hours = Number(m[1]);
            const minutes = Number(m[2]);
            if (minutes > 59)
                return false;

            const suffix = m[3] || "";
            if (suffix.length > 0) {
                if (hours < 1 || hours > 12)
                    return false;
                hours = hours % 12;
                if (suffix.charAt(0) === "P")
                    hours += 12;
            } else if (hours > 23) {
                return false;
            }

            ClockTools.alarmHour = hours;
            ClockTools.alarmMinute = minutes;
            return true;
        }

        // Width floor scales with the font — see SIZING NOTES up top.
        Item {
            Layout.minimumWidth: Math.max(360, Math.round(Theme.fontSize * 23))
            implicitHeight: 0
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            Text {
                text: "\uf073"
                color: Theme.colorAccent
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.2)
            }

            Text {
                text: "Clock Tools"
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.35)
                font.bold: true
            }
        }

        // ---- Calendar ------------------------------------------------------
        ClockSectionCard {
            contentSpacing: Theme.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(
                        new Date(clockPopout.displayedYear,
                                 clockPopout.displayedMonth, 1),
                        "MMMM yyyy")
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 1.08)
                    font.bold: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clockPopout.resetToToday()
                    }
                }

                IconButton {
                    glyph: "\uf053"
                    onClicked: clockPopout.stepMonth(-1)
                }

                IconButton {
                    glyph: "\uf054"
                    onClicked: clockPopout.stepMonth(1)
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
                    font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.85))
                    font.capitalization: Font.AllUppercase
                    font.bold: true
                }
            }

            MonthGrid {
                id: monthGrid
                Layout.fillWidth: true
                month: clockPopout.displayedMonth
                year: clockPopout.displayedYear
                spacing: 0

                delegate: Item {
                    required property var model
                    implicitWidth: dayText.implicitWidth + Theme.spacingLarge
                    implicitHeight: dayText.implicitHeight + Theme.spacingMedium

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 4,
                                        dayText.implicitWidth + Theme.spacingMedium * 1.5)
                        height: Math.min(parent.height - 2,
                                         dayText.implicitHeight + Theme.spacingSmall * 1.4)
                        radius: Theme.radiusMedium
                        visible: model.today
                        color: Theme.colorAccent
                    }

                    Text {
                        id: dayText
                        anchors.centerIn: parent
                        text: model.day
                        color: model.today
                            ? Theme.colorBackground
                            : (model.month === monthGrid.month
                                ? Theme.colorForeground
                                : Theme.colorMuted)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: model.today
                    }
                }
            }
        }

        // ---- Timer ---------------------------------------------------------
        SectionLabel { text: "TIMER" }
        ClockSectionCard {
            contentSpacing: Theme.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Repeater {
                    model: [5, 15, 30]

                    Chip {
                        required property int modelData
                        Layout.fillWidth: true
                        label: modelData + " min"
                        selected: ClockTools.timerDurationMs === modelData * 60000
                        onClicked: {
                            ClockTools.setTimerMinutes(modelData);
                            ClockTools.startTimer();
                        }
                    }
                }
            }

            // Idle: free-form duration entry.
            RowLayout {
                Layout.fillWidth: true
                visible: !ClockTools.timerRunning && !ClockTools.timerPaused
                spacing: Theme.spacingSmall

                TextField {
                    id: timerInputField
                    Layout.fillWidth: true
                    property bool invalid: false
                    placeholderText: "Minutes or H:MM"
                    selectByMouse: true
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: RegularExpressionValidator {
                        regularExpression: /^\d{0,3}(:\d{0,2})?(:\d{0,2})?$/
                    }
                    onTextEdited: invalid = false
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Theme.colorForeground
                    placeholderTextColor: Theme.colorMuted
                    background: Rectangle {
                        radius: Theme.radiusMedium
                        color: Theme.colorControl
                        border.width: 1
                        border.color: timerInputField.invalid
                            ? Theme.colorUrgent
                            : (timerInputField.activeFocus
                                ? Theme.colorAccent : Theme.colorDivider)
                    }
                    onAccepted: startChip.clicked()
                }

                Chip {
                    id: startChip
                    label: "Start"
                    selected: true
                    onClicked: {
                        const totalSeconds = clockPopout.parseTimerInput(
                            timerInputField.text);
                        if (totalSeconds <= 0) {
                            timerInputField.invalid =
                                timerInputField.text.trim().length > 0;
                            return;
                        }
                        ClockTools.setTimerMinutes(totalSeconds / 60.0);
                        ClockTools.startTimer();
                    }
                }
            }

            // Active: progress ring, remaining, controls.
            RowLayout {
                Layout.fillWidth: true
                visible: ClockTools.timerRunning || ClockTools.timerPaused
                spacing: Theme.spacingMedium

                Canvas {
                    id: timerRing
                    implicitWidth: Math.max(32, Math.round(Theme.fontSize * 2.6))
                    implicitHeight: implicitWidth
                    Layout.minimumWidth: implicitWidth
                    property real progress: 1 - ClockTools.timerRemainingMs
                        / Math.max(1, ClockTools.timerDurationMs)
                    property color trackColor: Theme.colorControl
                    property color fillColor: Theme.colorAccent
                    onProgressChanged: requestPaint()
                    onTrackColorChanged: requestPaint()
                    onFillColorChanged: requestPaint()
                    onVisibleChanged: if (visible) requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const cx = width / 2, cy = height / 2;
                        const r = Math.min(cx, cy) - 3;
                        ctx.lineWidth = 3;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = trackColor;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                        ctx.stroke();
                        if (progress > 0.001) {
                            ctx.strokeStyle = fillColor;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, -Math.PI / 2,
                                    -Math.PI / 2 + 2 * Math.PI
                                        * Math.min(1, progress));
                            ctx.stroke();
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        // A readout: no elide, and it holds its own width
                        // so the popout widens instead of truncating it.
                        Layout.minimumWidth: implicitWidth
                        text: ClockTools.formatDuration(
                            ClockTools.timerRemainingMs, false)
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 1.12)
                        font.bold: true
                    }

                    Text {
                        text: ClockTools.timerPaused ? "Paused" : "Remaining"
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.8))
                    }
                }

                IconButton {
                    glyph: ClockTools.timerRunning ? "\uf04c" : "\uf04b"
                    accent: true
                    onClicked: ClockTools.timerRunning
                        ? ClockTools.pauseTimer()
                        : ClockTools.startTimer()
                }

                IconButton {
                    glyph: "\uf021"
                    onClicked: ClockTools.resetTimer()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                visible: ClockTools.timerRunning || ClockTools.timerPaused
                implicitHeight: 3
                radius: 1.5
                color: Theme.colorControl

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: Theme.colorAccent
                    width: parent.width * (1 - ClockTools.timerRemainingMs
                        / Math.max(1, ClockTools.timerDurationMs))
                }
            }
        }

        // ---- Stopwatch + alarm, side by side ------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingMedium

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: Theme.spacingSmall

                SectionLabel { text: "STOPWATCH" }

                ClockSectionCard {
                    contentSpacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall

                        Text {
                            // Readout: minimum = implicit, no elide.
                            Layout.fillWidth: true
                            Layout.minimumWidth: implicitWidth
                            text: ClockTools.formatDuration(
                                ClockTools.stopwatchElapsedMs, true)
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 1.12)
                            font.bold: true
                        }

                        IconButton {
                            glyph: ClockTools.stopwatchRunning ? "\uf04c" : "\uf04b"
                            accent: true
                            onClicked: ClockTools.toggleStopwatch()
                        }

                        // Nothing to reset at zero, and hiding it keeps the
                        // idle card uncrowded (matches the mockup, which
                        // shows a lone play button).
                        IconButton {
                            glyph: "\uf021"
                            visible: ClockTools.stopwatchElapsedMs > 0
                            onClicked: ClockTools.resetStopwatch()
                        }
                    }

                    Text {
                        text: ClockTools.stopwatchRunning
                            ? "Running"
                            : (ClockTools.stopwatchElapsedMs > 0 ? "Paused" : "Ready")
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.8))
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                spacing: Theme.spacingSmall

                SectionLabel { text: "ALARM" }

                ClockSectionCard {
                    contentSpacing: 2

                    // Measured, not guessed — the field has to hold the
                    // longest alarm string in the user's actual font.
                    TextMetrics {
                        id: alarmMetrics
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        text: "12:00 AM"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall

                        TextField {
                            id: alarmTimeField
                            Layout.preferredWidth: Math.ceil(alarmMetrics.width)
                                + Theme.spacingMedium * 2
                            Layout.minimumWidth: Layout.preferredWidth
                            text: root.alarmText()
                            selectByMouse: true
                            horizontalAlignment: Text.AlignHCenter
                            inputMethodHints: Qt.ImhTime
                            validator: RegularExpressionValidator {
                                regularExpression: /^\d{0,2}:?\d{0,2} ?[APap]?[Mm]?$/
                            }
                            onTextEdited: clockPopout.alarmInvalid = false
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: Theme.colorForeground
                            background: Rectangle {
                                radius: Theme.radiusMedium
                                color: Theme.colorControl
                                border.width: 1
                                border.color: clockPopout.alarmInvalid
                                    ? Theme.colorUrgent
                                    : (alarmTimeField.activeFocus
                                        ? Theme.colorAccent : Theme.colorDivider)
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ToggleSwitch {
                            id: alarmToggle
                            // Never bound — ToggleSwitch writes its own
                            // `checked` on click, and a declarative binding
                            // would be silently destroyed the first time it
                            // did (same class of bug as BarPopout's
                            // grabFocus story). Synced imperatively from
                            // the Connections below.
                            Component.onCompleted: checked = ClockTools.alarmEnabled
                            onToggled: value => {
                                if (!value) {
                                    ClockTools.disableAlarm();
                                    clockPopout.alarmInvalid = false;
                                    return;
                                }
                                if (clockPopout.applyAlarmInput(alarmTimeField.text)) {
                                    clockPopout.alarmInvalid = false;
                                    ClockTools.enableAlarm();
                                    alarmTimeField.text = root.alarmText();
                                } else {
                                    clockPopout.alarmInvalid = true;
                                    checked = false;
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: clockPopout.alarmInvalid
                            ? "Try 7:30 AM"
                            : (ClockTools.alarmEnabled
                                ? ClockTools.alarmLabel() : "No alarm set")
                        color: clockPopout.alarmInvalid
                            ? Theme.colorUrgent : Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.8))
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // The service can clear alarmEnabled on its own (it fires, or IPC) —
        // keep the switch honest without ever binding `checked`.
        Connections {
            target: ClockTools
            function onAlarmEnabledChanged() {
                alarmToggle.checked = ClockTools.alarmEnabled;
            }
        }

        // ---- Alert sound ---------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingSmall
            spacing: Theme.spacingSmall

            IconButton {
                glyph: ClockTools.alertSoundEnabled ? "\uf0f3" : "\uf1f6"
                accent: ClockTools.alertSoundEnabled
                onClicked: ClockTools.alertSoundEnabled =
                    !ClockTools.alertSoundEnabled
            }

            Text {
                text: "Alert sound"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Math.max(10, Math.round(Theme.fontSize * 0.85))
            }

            Item { Layout.fillWidth: true }

            Repeater {
                model: ClockTools.soundChoices

                Chip {
                    required property var modelData
                    compact: true
                    label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                    selected: ClockTools.alertSoundEnabled
                        && ClockTools.alertSound === modelData
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
