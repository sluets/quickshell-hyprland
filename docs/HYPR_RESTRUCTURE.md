# Hyprland config restructure — one-time, by hand

Phase 3 of notes/settings-manager-plan.md: splitting hyprland.lua into
manager-owned `generated/` and untouchable `user/` files, so the
settings window's Hyprland page can regenerate the managed part
without ever parsing or rewriting anything you hand-wrote.

**This is done BY HAND, by you, once** — the config manager never
rewrites `hyprland.lua` or anything in `user/`, on principle, and that
includes during its own installation.

The ready-made files live in this repo at `notes/hypr-restructure/` —
they are your ACTUAL current config split apart (byte-faithful, audited
line-by-line during the split), not templates. Two deliberate changes
were made during the split, both flagged inline in the files:

1. **SUPER+Escape now opens the shell's power screen.** The docs had
   assumed SUPER+P since 07-05, but SUPER+P is your screen recorder —
   the power screen simply had no keybind at all. SUPER+Escape was
   free; rebind to taste in `user/keybinds.lua`.
2. **SUPER+M's fallback was broken and is fixed.** The old fallback
   `hyprctl dispatch 'hl.dsp.exit()'` isn't a dispatcher and silently
   did nothing if `hyprshutdown` was missing; it's now
   `hyprctl dispatch exit`.

## What goes where

```
~/.config/hypr/
  hyprland.lua        YOURS — just require() lines now. Never touched
                      by the manager.
  generated/          THE MANAGER'S — regenerated whole-file on Apply.
    appearance.lua      gaps in/out, border size, rounding (the
                        Hyprland settings page). Header says so.
    monitors.lua        static copy of your monitor layout for now; a
                        future Displays page takes it over.
  user/               YOURS — never touched by the manager.
    look.lua            border colors, blur, shadow, opacity, layout,
                        animations, curves (everything from the old
                        general/decoration blocks EXCEPT the four
                        managed values).
    startup.lua         autostart + env vars.
    rules.lua           input, gestures, layouts, misc, window rules.
    keybinds.lua        all binds (with its own program locals —
                        `local` doesn't cross require() boundaries).
```

`hl.config()` calls merge per-key, so general/decoration being split
across generated/appearance.lua and user/look.lua is safe — the same
key is never set in both (that's the ownership boundary).

## The procedure

```sh
# 1. Safety net (prefs snapshot + full hypr copy — the old hyprland.lua
#    is deliberately NOT a managed file, so copy it yourself):
qs ipc call config snapshot "before hypr restructure"
cp -r ~/.config/hypr ~/.config/hypr-before-split

# 2. Install the split (overwrites hyprland.lua, adds the two dirs):
cp -r ~/.config/quickshell/notes/hypr-restructure/* ~/.config/hypr/

# 3. Hyprland reloads automatically on save. Verify:
#    - both monitors still correct (modes/positions)
#    - gaps/borders/rounding look IDENTICAL (the generated file's
#      values match your old ones exactly)
#    - SUPER+Q opens kitty, SUPER+R launcher, SUPER+W wallpapers
#    - NEW: SUPER+Escape opens the power screen
```

If anything is wrong, rollback is one file:

```sh
cp ~/.config/hypr-before-split/hyprland.lua ~/.config/hypr/
```

(The old single-file root ignores the generated/ and user/ dirs
entirely — they can sit there inert while you retry.)

## After it's confirmed

- The settings window's **Hyprland page goes live**: Apply regenerates
  `generated/appearance.lua`, Hyprland picks it up instantly, and the
  auto-snapshot taken before every Apply now INCLUDES that file — so
  a bad-looking gap experiment is one `config restore` away from undone.
- **Hand-tweaks go in `user/`**, always. Anything you hand-edit in
  `generated/` is silently overwritten by the next Apply — the file
  headers say so, but it bears repeating once here.
- Keep `~/.config/hypr-before-split` until the Hyprland page has
  earned trust, then delete it.
- Remember the repo's copy of your compositor config
  (`notes/hyprland.lua`) is now the OLD single-file version — after
  the restructure, refresh the banked copies on your next sync
  (`cp -r ~/.config/hypr/hyprland.lua ~/.config/hypr/user ~/.config/hypr/generated ~/.config/quickshell/notes/hypr-live/`
  or simply re-copy the root file; exact freshness only matters when
  a session needs to reason about your binds).

## Until then

The Hyprland settings page works in degraded mode by design: Apply
persists the four prefs to user-prefs.json, and the status line
reports "hypr not restructured yet — generation skipped". Nothing
breaks; the values simply take effect the first Apply after the
restructure exists.
