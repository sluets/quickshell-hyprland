# AI Maintenance Guide

Written for AI models (Claude, Grok, or any capable successor)
maintaining or extending this project — by one of them (Claude
Fable 5, 2026-07-09), from direct experience maintaining it. The
maintainer's intent (see docs/PROJECT_VISION.md): this project must be
self-sustaining. Treat every session as if the human may not be
available to help. Your job is to keep it running and improve it
responsibly.

## Start of EVERY session, in order

1. Read `docs/REVISION_HISTORY.md` from the top — the newest entries
   are the project's short-term memory. Its "Session workflow" section
   is binding.
2. Skim the newest `docs/PROBLEMS_AND_FIXES.md` entries. Most bugs in
   this project are re-run reruns of documented ones.
3. If the maintainer hand-edited anything since the last session,
   DIFF IT against expectations before building on it. Every manual
   file operation in this project's history except one introduced a
   silent problem (misplaced files, duplicated folders, a widget left
   uninstantiated). The changelog says what was BUILT; only the files
   say what currently EXISTS.
4. If the work touches configuration: snapshot first
   (`qs ipc call config snapshot "before <thing>"` or
   ConfigManager.createSnapshot). This is not optional. The snapshot
   engine exists because a Theme.qml change without one cost 1.5
   hours and the root cause was never found.

## Core principles (never violate)

1. **Never write to user-owned files.** `hyprland.lua`, everything in
   `hypr/user/`, and anything the maintainer hand-wrote are
   read-only to you and to all code you write. The manager owns ONLY
   `hypr/generated/`, `user-prefs.json`, and files this repo creates.
   This holds even during installation/migration — restructures are
   designed as by-hand procedures the human executes
   (docs/HYPR_RESTRUCTURE.md is the model).
2. **One source of truth.** Settings live in `user-prefs.json` via
   UserPrefs/ConfigManager. Do not create a second store, a cache of
   it, or a file pair that must agree (a dir-name pair that had to
   agree once silently broke thumbnails for days).
3. **Snapshot before change; health-check after.** Apply-style
   changes go through ConfigManager.applyChanges, which does this
   automatically. Anything else that could break the desktop gets a
   manual snapshot first.
4. **Structure:** `core/` shared infrastructure singletons,
   `services/` system integration, `widgets/` visual components,
   `themes/` data, `docs/` documentation, `notes/` scratch (never
   loaded), `testing/` isolation experiments. Full map + reasoning:
   `docs/ARCHITECTURE.md`.
5. **Documentation discipline — every session, no exceptions:** the
   touched files' header REVISION HISTORY blocks, a
   `docs/REVISION_HISTORY.md` entry **signed with your model name in
   the title**, and a `PROBLEMS_AND_FIXES.md` entry for any new
   gotcha. Sessions that skipped this cost a later session hours of
   forensics.

## Verified behaviors — do not re-derive these the hard way

- **Stale QML property references fail SILENTLY** (undefined, not an
  error). After moving/renaming any property, grep every consumer.
  This exact bug shipped twice in one week (both clocks).
- **A file nothing instantiates is invisible**, not broken — after
  any structural change, USE every documented feature once; audits
  catch misplaced files, only usage catches unreferenced ones.
- **JsonAdapter fed corrupt JSON** logs one WARN and keeps in-memory
  values (last-known-good). Self-heals on next write; malformed
  hand-edits get clobbered.
- **Hyprland's Lua config auto-reloads on save**, REFUSES a
  syntactically broken file (keeps last good, shows a popup), and
  emergency binds survive. `hl.config()` calls merge per-key —
  that's the generated/user ownership boundary.
- **Quickshell singletons are lazy** — pragma Singleton AND
  Singleton root type, both; force-instantiate at launch if a
  service must be alive from boot (shell.qml reads
  ConfigManager.ready for exactly this).
- **Check for first-party Quickshell modules before building a
  service.** This lesson was learned twice (Hyprland, Bluetooth).
- **Don't trust plausible snippets** — verify against Quickshell
  docs/source or a maintained real-world config before shipping.

## The offline-build pattern

Most of this project was written without machine access: build
against verified APIs and these docs, mark headers/changelog
"⚠ written offline — NOT yet run live" with a concrete test
checklist, and let the next live session confirm. Where logic can be
exercised without the shell (sh scripts, algorithms), TEST IT in your
sandbox before delivery — extracting and sandbox-running the snapshot
engine's scripts caught two would-be-fatal bugs pre-boot.

## Failure scenarios → where to look

- Theming broken → `core/Theme.qml` (read its DESIGN NOTES first;
  this file has history), `themes/*`
- Settings not persisting → `services/ConfigManager.qml`,
  `core/UserPrefs.qml`, `~/.local/state/quickshell/user-prefs.json`
- Bar/widgets missing → `shell.qml`, `widgets/TopBar/TopBar.qml` —
  and check whether the widget is actually INSTANTIATED
- Notifications missing → another process owns the D-Bus name
  (`services/Notifs.qml` DESIGN NOTES) — including a second shell
  instance (`pgrep -af quickshell`)
- Hyprland config issues → `docs/HYPRLAND_INFO.md`,
  `hypr/generated/*` (managed), never blame `user/` first
- Desktop broken after an experiment → `docs/BACKUPS.md`; snapshots
  are hand-restorable via each one's manifest.tsv even if the shell
  won't start
- After a Quickshell update → check deprecations around singletons,
  PopupWindow, and WlrLayershell first

## Working with the human's setup

- The maintainer syncs this repo to a Claude Project knowledge base
  with `scripts/flatten-for-kb.sh` (wipe-and-drag replace — correct;
  see README). Files living OUTSIDE the repo don't survive that —
  anything you need long-term gets banked INTO the repo (compositor
  config: `notes/hyprland.lua`).
- No knowledge base? The repo is self-sufficient: README's "Working
  with Claude" section + REVISION_HISTORY + this guide are the
  bootstrap path.
- Prefer official pacman packages over AUR (June 2026 AUR malware
  incident); widely-used AUR packages acceptable when unavoidable.

## Best practices

- Read a file's DESIGN NOTES before editing it. They record WHY, and
  the whys here are load-bearing.
- Simple and readable beats clever. Every line should be explainable
  to the maintainer.
- One feature/category per session; live-confirm before stacking the
  next layer on top.
- When genuinely uncertain about intent, ask — but bring a
  recommendation ("lean") with reasons, so the human can decide in
  one word. Decisions the human delegates get made decisively and
  DOCUMENTED as decisions.
- Correct the human's diagnosis when the evidence disagrees — kindly,
  with the evidence — and record the corrected diagnosis. (Precedent:
  "2 lines" was really a row-width steal; the fix was right, the
  mechanism wasn't.)

## Final rule

Leave the project more maintainable than you found it: books
balanced, traps documented, nothing that only you understand.
