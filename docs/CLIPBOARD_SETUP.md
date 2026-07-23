# Clipboard persistence and history setup

Place this file in the Quickshell base folder:

    ~/.config/quickshell/CLIPBOARD_SETUP.md

## Goal

- Keep copied text/images available after the source application closes.
- Store a small clipboard history.
- Later add a Quickshell top-bar clipboard icon and popout.
- No Settings page.

## Required packages

Install from the official Arch repositories:

```bash
sudo pacman -S wl-clip-persist cliphist
```

`wl-clipboard` is already installed and provides `wl-copy` / `wl-paste`.

## Hyprland startup

Add these commands to the existing `hl.on("hyprland.start", ...)` block:

```lua
hl.exec_cmd("wl-clip-persist --clipboard regular")
hl.exec_cmd("wl-paste --type text --watch cliphist store")
hl.exec_cmd("wl-paste --type image --watch cliphist store")
```

Keep them inside the existing startup block rather than creating duplicate startup handlers unless the current config structure requires a separate file.

After editing, restart Hyprland or log out/in. For immediate testing, run:

```bash
pkill -x wl-clip-persist 2>/dev/null
pkill -f 'wl-paste.*cliphist store' 2>/dev/null

wl-clip-persist --clipboard regular &
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
```

## Quick tests

Copy text, close the source application, then paste somewhere else.

List stored history:

```bash
cliphist list
```

Restore one entry manually:

```bash
cliphist list | fuzzel --dmenu | cliphist decode | wl-copy
```

The `fuzzel` test is optional and only useful if it is installed. The final UI will be native Quickshell.

Clear all history:

```bash
cliphist wipe
```

## Planned Quickshell clipboard UI

Add a clickable clipboard icon to the top bar.

The popout should:

- show newest entries first;
- support text and image entries;
- show short previews, not full sensitive content by default;
- click an entry to restore it through `cliphist decode | wl-copy`;
- allow deleting one entry;
- provide a clear-all button;
- close after restoring an item;
- show a small item-count badge on the bar icon;
- use a hard cap of about 25 recent unique entries;
- avoid a Settings page.

Privacy behavior:

- clipboard history may contain passwords, tokens, customer data, and terminal commands;
- prefer session-oriented history;
- wipe old history when Quickshell starts unless we deliberately decide to keep it across sessions;
- keep only a small bounded number of entries.

## Notes

`wl-clip-persist` solves the current problem where the clipboard disappears after closing the application that owned it.

`cliphist` supplies history storage. Quickshell will only be the themed UI and interaction layer.
