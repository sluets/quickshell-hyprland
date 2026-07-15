# Backups & snapshots — user guide

Quick reference for the snapshot engine (services/ConfigManager.qml).
Everything runs through IPC — no UI yet (that's Phase 2). All commands
work from any terminal while the shell is running.

## The commands

```sh
qs ipc call config snapshot "before blur experiment"   # take a manual snapshot
qs ipc call config list                                # show all snapshots, newest first
qs ipc call config restore <name>                      # put a snapshot's files back
qs ipc call config prune                               # trim old auto/daily snapshots
qs ipc call config status                              # result of the last operation
```

**Every operation is async** — the command returns "started"
immediately. Run `status` right after to see the actual result:

```
idle. last: created 2026-07-09T21-54-21_manual_before-blur-experiment (1 file(s))
idle. last: restored 1 file(s) from ...
error: no manifest in ...          ← restore of a name that doesn't exist
busy: snapshot                     ← still running (rare; ops take <1s)
```

`list` may also lag one call behind for the same reason — if it says
"refreshing", just call it again.

## The normal workflow

Before doing anything risky to the config:

```sh
qs ipc call config snapshot "before <what you're about to do>"
```

If it goes wrong:

```sh
qs ipc call config list          # copy the exact snapshot name
qs ipc call config restore 2026-07-09T21-54-21_manual_before-...
qs ipc call config status        # confirm "restored N file(s)"
```

That's it. No shell reload needed — the shell watches its files and
picks restored content up live (you'll see the gear-menu toggles snap
back to their snapshot-time states).

## What a snapshot actually contains

Snapshots capture the MANAGED file set only — `user-prefs.json` (all
settings-window values) and, once the Hyprland restructure is done
(docs/HYPR_RESTRUCTURE.md), `hypr/generated/appearance.lua`. They do
NOT capture QML files, themes, wallpapers, or your user-owned
Hyprland files. As the
settings project grows (settings.json, generated Hyprland modules),
those files join the set automatically and restore keeps working —
each snapshot records what it captured and restore replays exactly
that, nothing more.

## Snapshot kinds and retention

Names look like `<timestamp>_<kind>_<label>`:

- `_manual_` — yours, taken with the snapshot command. **Never
  auto-deleted.** Delete by hand if you want them gone.
- `_daily_` — one per day, taken automatically when the settings
  window opens (wired in a later phase). Pruned past the newest 30.
- `_auto_` — taken automatically by the settings window's Apply
  before every change (live as of Phase 2) — so every Apply is one
  restore away from undo. Same 30-cap pool as dailies.

`prune` only ever touches `_daily_`/`_auto_`. The cap lives in
`core/Settings.qml` → `configAutoSnapshotKeep`.

## Where everything lives on disk

```
~/.local/state/quickshell/
  user-prefs.json                     the live prefs file itself
  original/                           one-time full backup (see below)
    config-quickshell/  config-hypr/
  snapshots/<name>/
    manifest.tsv                      stored-file → original-path map
    files/                            the copies
```

## The Original Backup

Created automatically ONCE, on the engine's first ever launch: a full
copy of `~/.config/quickshell` and `~/.config/hypr`. Never modified,
never pruned. It's the "before the config manager existed" restore
point — but note it was born on 2026-07-09, so it means "Phase-1 day
zero," not pre-Phase-1 (the manually made `quickshell-before phase1`
folder is the only true pre-Phase-1 copy). There's no IPC restore for
it yet (that's the Phase-2+ Restore page); restoring it today is a
manual `cp -a` from `original/config-quickshell/` back into place.

## Recovering WITHOUT the tool

Deliberate design: snapshots are plain directories, restorable by
hand if the shell won't even start. Open the snapshot's
`manifest.tsv` — each line is `stored-name <TAB> original-absolute-
path` — and `cp -a snapshots/<name>/files/<stored-name> <that path>`
for each line.

## Good to know

- Corrupt `user-prefs.json` (bad hand-edit, whatever): the shell logs
  one WARN and keeps running on its in-memory values — nothing breaks.
  Restore a snapshot, or just flip any gear-menu toggle and the shell
  rewrites the file valid. Flip side: a malformed hand-edit gets
  silently overwritten by the next toggle flip, so hand-edit that
  file only with valid JSON.
- One operation runs at a time; a second command while one is running
  returns `busy`. Ops finish in well under a second.
- Snapshot labels get slugified into the name (lowercase, dashes,
  max 40 chars) — that's normal.
