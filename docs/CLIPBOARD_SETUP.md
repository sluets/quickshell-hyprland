# Clipboard persistence and history setup

The top-bar clipboard popout is implemented, but it depends on three external session processes. Quickshell is only the themed UI and history client.

## Required packages

```bash
sudo pacman -S wl-clipboard wl-clip-persist cliphist
```

- `wl-clip-persist` keeps the active clipboard alive after the source application exits.
- `wl-paste --watch cliphist store` records text and image clipboard changes.
- `cliphist` stores, lists, restores, deletes, and wipes entries.

## Hyprland Lua startup

Add the processes to the existing startup block:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("setsid -f wl-clip-persist --clipboard regular")
    hl.exec_cmd("setsid -f sh -c 'wl-paste --type text --watch cliphist store'")
    hl.exec_cmd("setsid -f sh -c 'wl-paste --type image --watch cliphist store'")
end)
```

`hyprctl reload` does **not** fire `hyprland.start`. Log out/in or restart the Hyprland session when testing this block. `setsid -f` detaches the long-running watchers from a terminal or launching process group.

## Immediate manual start

```bash
setsid -f wl-clip-persist --clipboard regular
setsid -f sh -c 'wl-paste --type text --watch cliphist store'
setsid -f sh -c 'wl-paste --type image --watch cliphist store'
```

## Dependency-health checks

Run these **before revising Quickshell** when history appears empty or stale:

```bash
pgrep -af 'wl-clip-persist|wl-paste.*cliphist'
cliphist list
```

Expected result: one `wl-clip-persist` process, two `wl-paste ... cliphist store` watchers, and stored entries after copying text or an image.

## Implemented Quickshell behavior

- clickable top-bar clipboard icon;
- refresh once when the popout opens;
- newest entries first;
- hard cap of 25 entries;
- click to restore through `cliphist decode | wl-copy`;
- delete one item without rebuilding the whole visible list;
- clear all;
- text previews;
- sequential image decoding and thumbnails;
- stable runtime thumbnail paths under `$XDG_RUNTIME_DIR/qs-clipboard-thumbs/`;
- no Settings page.

Clipboard history may contain passwords, tokens, customer data, and terminal commands. Use Clear All when appropriate.

## Manual commands

```bash
cliphist list
cliphist wipe
```
