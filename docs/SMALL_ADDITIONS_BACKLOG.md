# Small Desktop Additions Backlog

Updated: 2026-07-23  
Owner: GPT

This list is for small, self-contained Quickshell utilities that improve the desktop without adding Settings pages or large architectural commitments.

## Immediate checkpoint

Before starting another feature:

1. Finish live-testing the calculator, clock tools, and clipboard history.
2. Merge the approved revisions into the canonical project tree.
3. Update documentation and revision history.
4. Commit and push from the desktop.
5. Restore/pull the clean canonical tree on the work laptop.

## 1. Calculator unit converter

Add a compact **Converter** view to the existing Quickshell calculator.

Primary manufacturing units:

- mil / thou
- inch
- millimeter
- micrometer / micron

Behavior:

- One editable input value.
- Choose the source unit.
- Show every converted value simultaneously.
- Click any result to copy it.
- Preserve calculator history separately from conversion history.
- Keyboard-friendly.
- No Settings page.
- No external process or web lookup.

Useful relationships:

- 1 inch = 1000 mil
- 1 inch = 25.4 mm
- 1 mil = 0.0254 mm
- 1 mm = 39.37007874 mil
- 1 mm = 1000 µm
- 1 mil = 25.4 µm

Possible later convenience presets:

- common stencil thicknesses;
- common PCB dimensions;
- Mydata/Mycronic coordinate entry helper.

## 2. Screenshot and screen-recording bar control

Add a small bar icon and popout that wraps the user's existing screenshot and `wf-recorder` commands.

Screenshot actions:

- select region and copy;
- select region and save;
- current monitor;
- all monitors;
- active window, if the existing command supports it.

Recording actions:

- select a region and start `wf-recorder`;
- stop the active recording;
- show an active-recording indicator;
- open the output folder.

Rules:

- Reuse the exact commands already proven by the user's keybinds.
- Do not replace or remove the keybinds.
- One persistent popout.
- No Settings page.
- Do not invent a second recording backend.

## 3. Quick notes

A bar icon opens a small scratchpad.

- Autosave one plain-text note.
- Useful for part numbers, dimensions, commands, and temporary reminders.
- Clear button and copy-all button.
- Store under Quickshell user state.
- No formatting and no Settings page.

## 4. Color picker and color history

- Pick a color from the screen.
- Show HEX, RGB, and optionally HSL.
- Click any representation to copy.
- Keep the most recent 10–20 colors.
- Use a bounded runtime/state file.
- No Settings page.

## 5. Do Not Disturb toggle

- Bar bell state toggles notification presentation.
- Continue recording notification history while presentation is muted.
- Make the muted state obvious.
- Reuse the current notification service rather than launching an external daemon.

## 6. Audio device quick picker

Extend the current volume popout:

- choose output device;
- choose input device;
- microphone mute;
- show the current default devices.

Do not create a separate Settings page unless the existing popout becomes unmanageable.

## 7. Launcher calculator expressions

Examples:

```text
calc 55 * 1.06
calc 4in to mm
calc 125mil to microns
```

- Show the result directly in launcher results.
- Enter copies the result or opens the calculator with the expression loaded.
- Reuse the calculator parser and converter logic.
- Never use JavaScript `eval()`.

## 8. Network quick information

Extend the current network popout with:

- interface name;
- local IP;
- gateway;
- connection type;
- copy buttons.

Keep diagnostics lightweight and avoid turning it into a full network manager.

## 9. Microphone activity indicator

- Appear only while an application is recording.
- Show the active input device and, where available, the client/application.
- Click to open audio controls.

## 10. Recent files / downloads

- Show a short bounded list of recent files.
- Click to open.
- Secondary action reveals the file in Dolphin.
- Avoid filesystem-wide indexing.

## 11. Trash indicator

- Hidden when Trash is empty.
- Click to open Trash.
- Explicit secondary action to empty it with confirmation.

## 12. Removable-drive popout

- List removable drives.
- Mount, open, unmount, or safely eject.
- Use a real system API or established CLI with structured output.
- Do not poll aggressively.

## Features completed during the current work block

These are implemented in test revisions but are not canonical until merged, documented, committed, and pushed:

- Quickshell calculator opened from launcher as an internal app;
- calculator favorites and launcher usage ranking;
- split date and time click targets;
- timer, stopwatch, alarm, notifications, and alert sounds;
- clipboard persistence/history bar popout;
- bounded clipboard history;
- image thumbnails in clipboard history.
