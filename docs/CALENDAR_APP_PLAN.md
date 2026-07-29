# Quickshell Calendar App Plan

## Purpose

Build a local-first calendar inside the Clock Tools popout, with birthdays, recurring events, reminders, and later optional Google Calendar synchronization. The calendar must remain useful offline and must not depend on the Quickshell process staying alive for reminders.

## Phase 1 — Calendar UI and local events

- Month view using Qt Quick Controls `MonthGrid`, `DayOfWeekRow`, and `CalendarModel`.
- Selected-day agenda beneath or beside the month grid.
- Create, edit, and delete all-day and timed events.
- Event indicators on calendar days.
- Upcoming-events section in the Clock Tools popout.
- Reuse the new shared popout/card design language.

## Phase 2 — Storage, recurrence, and reminders

- Store events in SQLite or standards-compatible iCalendar data; prefer SQLite for indexed queries and recurrence bookkeeping.
- Support yearly birthdays and anniversaries, plus daily, weekly, monthly, and yearly recurrence.
- Support reminder offsets such as 10 minutes, 1 hour, 1 day, and 1 week.
- Run reminder checks through a `systemd --user` service/timer so reminders survive Quickshell restarts.
- Deliver through Quickshell IPC when available, with a normal desktop-notification fallback.

## Phase 3 — Google Calendar integration

- Add a small helper service rather than implementing OAuth and sync directly in QML.
- Use browser-based OAuth 2.0 and securely store refresh tokens outside QML.
- Read, create, update, and delete Google Calendar events.
- Maintain a local cache for offline use.
- Define conflict handling before enabling two-way sync.
- Keep Google integration optional; local calendars must continue working without an account.

## Proposed architecture

```text
ClockTools / Calendar QML UI
        ↓ IPC / JSON
Calendar helper service
        ↓
SQLite local store ── optional Google Calendar API
        ↓
systemd --user reminder timer
```

## Initial scope boundaries

- No contact synchronization in the first version.
- Birthdays begin as ordinary yearly recurring events.
- No shared-calendar permissions or meeting invitations in Phase 1.
- No reminder logic tied only to an open popup or live Quickshell instance.

## Implementation order

1. Static themed month view and selected-day panel.
2. Local event CRUD and storage.
3. Recurrence and reminder service.
4. Upcoming-events integration in Clock Tools.
5. Google OAuth and one-way import.
6. Two-way synchronization after conflict rules are tested.

— GPT
