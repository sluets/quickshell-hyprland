# Setup Guide — using this Quickshell config on your own machine

This is the **user-facing** setup guide: how to take this repository and
get it running as your own desktop shell, from a clean-ish Arch +
Hyprland install to a working, themeable bar with a settings window,
wallpaper picker, notifications, and the rest.

It is written to be read two ways:

- **By a human** who wants to install and use this — follow it top to
  bottom, it's a checklist.
- **By an AI** (Claude or similar) that someone has handed the whole
  repo to and asked "help me get this working" — every dependency,
  path, and external requirement the shell assumes is stated explicitly
  here, so you don't have to infer them from the QML.

> This guide is about **installing and running** the shell. If you want
> to understand or modify the code, read `docs/ARCHITECTURE.md` (how
> it's built) and `docs/AI-MAINTENANCE-GUIDE.md` (the rules for changing
> it). If something breaks, `docs/PROBLEMS_AND_FIXES.md` is the first
> stop.

---

## 0. What you're installing

A personal Hyprland desktop shell built with
[Quickshell](https://quickshell.org). It is **not** the caelestia shell
(that was reference/inspiration only) — it's a from-scratch config that
happens to cover similar ground. What you get:

- A floating, per-monitor top bar: workspaces, now-playing, and
  slide-out popouts for volume / wifi / bluetooth / clock+calendar /
  wallpapers / settings.
- A settings **window** (theme picker, font family + scale, bar
  border/padding, notification and desktop-clock options, Hyprland
  gaps/border/rounding) with a staged **Apply** and snapshot/undo.
- An app launcher, a centered power screen, a volume OSD, a desktop
  clock with weather, and the shell's **own** notification daemon.
- ~20 built-in themes, live-switchable.

### System context it was built on

You don't need to match this exactly, but it's the tested baseline:

- **Arch Linux + Hyprland (Wayland).** The Hyprland config on the
  author's machine is **`hyprland.lua`** — Hyprland deprecated the old
  `hyprlang` (`hyprland.conf`) in favor of Lua config in 0.55 (April
  2026). All bind/autostart examples in these docs are the Lua form. If
  you're still on `hyprland.conf`, the shell itself works fine; only the
  optional Hyprland-restructure step (§7) assumes Lua.
- **Quickshell 0.3.0+** (released 2026-05-04). Confirm yours with
  `quickshell --version`. Some APIs the shell uses (per-monitor
  `Variants`, `WlrLayershell`, `JsonAdapter`) want a reasonably current
  Quickshell — if you're on something old, update before debugging
  anything.
- Hardware is irrelevant to install; it's a Ryzen 7800X3D / RX 9070 XT
  box, mentioned only because a couple of docs reference it.

### A note on packages (please read)

This project **prefers official `pacman` repositories over the AUR**,
because of the [June 2026 AUR malware incident](https://archlinux.org)
(hundreds of orphaned packages compromised via `.install` hook
payloads). Where something is only in the AUR, that's called out
explicitly below. Widely-used, actively-maintained AUR packages (e.g.
`yay` itself) are treated as acceptable when there's no official
equivalent — but check before you paste an AUR command into a root
shell.

---

## 1. Dependencies

Install these first. They're grouped by what needs them so you can skip
the parts you don't want.

### 1a. Required — the shell will not work without these

```bash
sudo pacman -S quickshell networkmanager pipewire
```

- **quickshell** — the runtime that loads the config. If it's not in
  your official repos yet, it's on the AUR as `quickshell` /
  `quickshell-git`; the git version tracks features the shell may rely
  on. Verify with `quickshell --version` after installing.
- **networkmanager** — Quickshell's only supported network backend. The
  wifi popout drives `nmcli` under the hood; without NetworkManager
  running (`systemctl enable --now NetworkManager`) the wifi widget is
  dead.
- **pipewire** (+ `wireplumber`) — audio. The volume widget, OSD, and
  now-playing all read PipeWire.

### 1b. Wallpaper daemon — required if you want wallpapers to actually set

The wallpaper picker calls out to a wallpaper daemon to apply the
image. The shell shells out to **`awww`** (client) and expects
**`awww-daemon`** to be running — it runs `awww query` on open to find
the current wallpaper and `awww img` to set one. (`awww` is a
swww-family Wayland wallpaper daemon; if your system uses `swww`
instead, the commands are the same but you'd need to adjust the calls
in `widgets/TopBar/WallpaperPicker.qml`.) Make sure the daemon is
started by the compositor (see §5), **not** as a systemd unit.

```bash
sudo pacman -S awww    # official repo package; or swww, see note above
```

> If wallpapers show in the picker grid but clicking one doesn't change
> your background, `awww-daemon` isn't running (or a different daemon
> is). The picker detects a dead daemon — `awww query` exiting nonzero
> shows a warning row instead of the grid. This is the #1 wallpaper
> gotcha.

### 1c. Wallpaper thumbnails — required for a non-laggy picker

The picker shows a grid of **square thumbnails**. It does **not**
generate them — you do, with ImageMagick, via the bundled script
(§6). So:

```bash
sudo pacman -S imagemagick
```

Without thumbnails the picker still works, but each cell falls back to
decoding the full-size wallpaper — a folder of 4K images will make the
grid crawl. Generate thumbs once (§6) and it's smooth.

### 1d. Fonts — required for icons and the default look

The UI uses **Nerd Font** glyphs for icons throughout. At minimum
install the font the default theme expects plus a symbols fallback:

```bash
sudo pacman -S nerd-fonts        # group — pick fonts at the prompt
```

`nerd-fonts` on Arch is a **group**: running the above lets you select
individual `ttf-*-nerd` packages at the prompt (space-separated
numbers) instead of installing all 50+. The default theme's font is
**CaskaydiaCove Nerd Font** (`ttf-cascadia-code-nerd` /
`ttf-caskaydia-cove-nerd`), so install at least that one. The settings
window's **Font Family** picker offers whatever Nerd Font *base*
families you have installed (it reads them live from Qt), so grab a few
you like — common picks: JetBrainsMono, FiraCode, Hack, Iosevka,
MesloLGS, SourceCodePro (SauceCodePro), RobotoMono, UbuntuMono,
Inconsolata.

After installing fonts, refresh the cache:

```bash
fc-cache -f
```

> **Why the picker only shows *some* of your fonts:** it deliberately
> lists only families whose name ends in "Nerd Font" (the base variant),
> hiding the `... Nerd Font Mono` / `... Nerd Font Propo` spin-offs and
> weight variants to keep the list short. It reads the **exact strings
> Qt reports**, so any font it offers is guaranteed to render when
> picked. If a font you installed isn't showing, confirm Qt sees it:
> the names must contain "Nerd Font". (This was a genuine bug once — see
> `docs/PROBLEMS_AND_FIXES.md`, the font-picker entry.)

### 1e. Optional — nice-to-haves for specific widgets

- **Desktop clock weather:** no package needed — it fetches from free
  public APIs (`zippopotam.us` for ZIP→lat/long, then Open-Meteo). It
  does need a US ZIP set in config (§4). Non-US: weather is off unless
  you adapt `services/Weather.qml`.
- A **terminal / launcher target** for keybinds (the examples assume
  `kitty` and the shell's own launcher) — install whatever you actually
  bind.

---

## 2. Get the files into place

The shell's config root is `shell.qml`, and it expects to sit **directly
in `~/.config/quickshell/`** (not in a named subfolder). That placement
matters: it means the shell has **no config name**, so all IPC commands
are plain `qs ipc call <target> <function>` with **no `-c` flag**.

```bash
# Back up anything already there
mv ~/.config/quickshell ~/.config/quickshell.bak 2>/dev/null

# Clone this repo AS ~/.config/quickshell
git clone <this-repo-url> ~/.config/quickshell
```

If you cloned it somewhere else first, move its **contents** (so that
`shell.qml` lands at `~/.config/quickshell/shell.qml`, not
`~/.config/quickshell/repo-name/shell.qml`).

### First run

```bash
qs
```

You should see a floating bar appear across the top of your screen. If
you see **nothing**, or an error in the terminal, jump to §8.

To have it start automatically with Hyprland, add to your Hyprland
config (Lua form):

```lua
-- in hyprland.lua (or a file it require()s, e.g. user/startup.lua)
hl.exec_once("qs")
```

(`hyprland.conf` form: `exec-once = qs`.)

---

## 3. Directory & file assumptions (the stuff outside the repo)

The shell reads a few things from **outside** its own folder. Set these
up or the corresponding features sit idle:

| What | Default path | Used by | Set up how |
|---|---|---|---|
| Wallpapers | `~/Pictures/Wallpapers/` | Wallpaper picker | Drop image files in it |
| Thumbnails | `~/Pictures/Wallpapers/.thumbs/` | Wallpaper picker | Run the thumb script (§6) |
| Persisted prefs | `~/.local/state/quickshell/user-prefs.json` | Settings window | Auto-created on first Apply |
| Snapshots | (managed by ConfigManager) | Undo/restore | Auto |

The wallpaper path and thumb-dir name are configurable in
`core/Settings.qml` (`wallpapersPath`, `wallpapersThumbDir`) if you want
them elsewhere.

---

## 4. Configuration — the two kinds

There are **two** separate places settings live, on purpose:

### 4a. `core/Settings.qml` — hand-edit-the-file knobs

Behavior tuning with **no UI**: wallpaper path, transition style, OSD
timeouts, notification timeouts, launcher sizing, weather location,
default font scale, etc. You edit the file directly; there's no save
button because editing the file **is** the save. Open it, read the
comments (every knob is documented inline), change values, save. The
shell hot-reloads.

The one you most likely want on first setup is **weather location**:

```qml
// core/Settings.qml
property string weatherZipCode: "11735"      // <- your US ZIP, or "" for no weather
property string weatherUnits:   "fahrenheit" // or "celsius"
```

### 4b. The Settings **window** — live UI, persisted to disk

Theme, font family, font scale, bar border/padding, notification
options, desktop-clock options, Hyprland gaps/border/rounding. These are
changed from the on-screen settings window, **staged**, and only written
when you hit **Apply** (which snapshots first, so every Apply is one
undo away). They persist to `~/.local/state/quickshell/user-prefs.json`.

Open the settings window from the bar's gear/settings popout, or:

```bash
qs ipc call settings toggle
```

**Rule of thumb:** if it changes how the shell *behaves* and has no
button, it's in `Settings.qml`. If it changes how it *looks* and you'd
expect a control for it, it's in the settings window. (`docs/ARCHITECTURE.md`
explains why the split exists.)

---

## 5. Compositor integration (Hyprland)

The shell is just a Quickshell client — Hyprland needs to (a) start it,
(b) start the wallpaper daemon, and (c) optionally give it keybinds.

Minimal additions to your Hyprland config (Lua form; adapt the binds):

```lua
-- Start the wallpaper daemon and the shell on login
hl.exec_once("awww-daemon")   -- your wallpaper daemon (or swww-daemon)
hl.exec_once("qs")

-- Example keybinds (all optional — the shell also has bar buttons)
hl.bind("SUPER", "space",  "global", "quickshell:launcher")   -- app launcher
hl.bind("SUPER", "W",      "global", "quickshell:wallpaper")  -- wallpaper picker
hl.bind("SUPER", "Escape", "global", "quickshell:power")      -- power screen
```

> The exact global-shortcut names come from the shell's `GlobalShortcut`
> registrations in `shell.qml`. If a bind does nothing, check the name
> there. IPC equivalents exist for everything
> (`qs ipc call <target> <function>`) — run `qs ipc` targets to explore,
> or grep `IpcHandler` in `shell.qml`.

If your screen **flickers**, it's usually VRR — try `misc { vrr = 0 }`
in your Hyprland config.

---

## 6. Wallpaper thumbnails

The picker needs square thumbnails to be fast. Generate them with the
bundled script (requires ImageMagick, §1c):

```bash
# The script lives in the repo. From the repo root:
bash make-square-thumbs.sh
```

What it does: for every `.jpg/.jpeg/.png` in `~/Pictures/Wallpapers/`,
it creates a 400×400 center-cropped thumbnail in
`~/Pictures/Wallpapers/.thumbs/`, skipping any that already exist. Run
it again whenever you add wallpapers — it only processes new ones.

If your wallpapers live elsewhere, edit `WALLPAPER_DIR` at the top of
the script (and match `wallpapersPath` in `core/Settings.qml`).

> Thumbnails are matched to wallpapers by **basename without
> extension**, so `sunset.jpg` pairs with `.thumbs/sunset.jpg`,
> `.thumbs/sunset.png`, or `.thumbs/sunset.webp` — handy since
> ImageMagick sometimes changes the extension. A wallpaper with no
> thumb isn't hidden; its cell just falls back to the full image.

Set your profile picture (shown in some UI) by copying an image to
`~/.face`.

---

## 7. Optional: the Hyprland config restructure

**Skip this unless you want the settings window's Hyprland page to
actually write your gaps/border/rounding.** Everything else works
without it.

The settings window can regenerate Hyprland appearance values, but on
principle it **never** rewrites `hyprland.lua` or anything you
hand-wrote. To make that safe, your Hyprland config gets split once, by
hand, into a manager-owned `generated/` part and an untouchable `user/`
part. The full step-by-step (with the exact commands and a verification
checklist) is in **`docs/HYPR_RESTRUCTURE.md`**. It's a one-time,
by-hand procedure — do it only if you want that feature, and read that
doc in full before running it.

Until you do the restructure, the Hyprland page still *stages and
persists* its values; it just reports that file generation was skipped.

---

## 8. When it doesn't work — first moves

In rough order of likelihood:

1. **Nothing appears at all.** Run `qs` from a terminal and read the
   error. A syntax error in any loaded QML stops the whole shell.
2. **"Only one instance" / notifications missing.** The shell runs its
   **own** notification daemon and owns `org.freedesktop.Notifications`.
   If you have `dunst`/`mako`/`swaync` running, they conflict — stop
   them. Also check for a second shell instance: `pgrep -af quickshell`.
3. **Wallpapers don't apply.** `awww-daemon` not running (or a
   different daemon) — see §1b.
4. **Wallpaper grid is laggy.** No thumbnails — run §6.
5. **Icons are boxes/tofu.** Nerd Font not installed or cache stale —
   §1d, then `fc-cache -f`.
6. **Font picker shows almost nothing / a picked font doesn't apply.**
   Fonts not installed under a "Nerd Font" family name Qt can see —
   §1d. (There's a full write-up of this exact class of bug in
   `docs/PROBLEMS_AND_FIXES.md`.)
7. **Settings won't persist / Apply does nothing.** Check
   `~/.local/state/quickshell/` exists and is writable;
   see `services/ConfigManager.qml` and the relevant
   `PROBLEMS_AND_FIXES.md` entries.
8. **Wifi widget dead.** NetworkManager not running —
   `systemctl enable --now NetworkManager`.

For anything deeper, `docs/PROBLEMS_AND_FIXES.md` is organized
newest-first and most bugs here are reruns of documented ones.

---

## 9. Handing this repo to an AI for help

This project is designed to be maintained across separate AI chat
sessions with no shared memory. If you're dropping the files into a
Claude Project (or similar) and asking for help:

- The `flatten-for-kb.sh` script flattens the whole tree into a single
  folder of uniquely-named files (Claude Projects don't preserve folder
  structure). Run it, then upload the flattened output. Its header
  explains the naming convention (`services/README.md` →
  `services-README.md`, etc.).
- Point the AI at **`docs/AI-MAINTENANCE-GUIDE.md` first** — it's the
  binding ruleset for changing anything here (what's off-limits, the
  snapshot-before-config rule, the documentation-every-session rule).
- **`docs/REVISION_HISTORY.md`** (newest entries first) is the project's
  short-term memory — what was built recently and whether it's been
  live-tested.
- Tell the AI up front whether the knowledge base is **synced** and
  whether the last session's files **actually run** on your machine.
  The changelog says what was *built*; only the files say what currently
  *exists*, and manual file moves have silently broken things before.

---

## Quick reference — the whole install in one block

```bash
# 1. Deps (adjust font picks at the nerd-fonts prompt; swap wallpaper daemon if needed)
sudo pacman -S quickshell networkmanager pipewire wireplumber imagemagick nerd-fonts awww
systemctl enable --now NetworkManager
fc-cache -f

# 2. Files
mv ~/.config/quickshell ~/.config/quickshell.bak 2>/dev/null
git clone <this-repo-url> ~/.config/quickshell

# 3. Wallpapers + thumbs
mkdir -p ~/Pictures/Wallpapers
# (drop images in, then:)
bash ~/.config/quickshell/make-square-thumbs.sh
cp your-avatar.png ~/.face      # optional profile picture

# 4. Compositor (add to hyprland.lua): hl.exec_once("awww-daemon"); hl.exec_once("qs")

# 5. Run
qs
```

Then set your weather ZIP in `core/Settings.qml`, and open the settings
window (`qs ipc call settings toggle`) to pick a theme and font.
