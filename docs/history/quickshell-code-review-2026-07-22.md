# Quickshell Project — Second-Opinion Code Review

Reviewed: 2026-07-14

Scope: 108 files, 60 QML files, approximately 22,280 lines of QML/docs/scripts. Static review only; Quickshell was not installed in the review environment, so this is not a live runtime or visual test.

## Overall verdict

This is a genuinely good personal desktop-shell codebase. It is far beyond a pile of generated snippets. The folder boundaries, explicit ownership of machine-global resources, singleton strategy, multi-monitor routing, persistent preferences, snapshot/restore design, and problem log all show deliberate engineering.

The code does not look like “Claude generated random QML and somehow it runs.” It looks like a small application developed iteratively with AI. The main concern is no longer basic correctness. It is controlling complexity as the project grows.

Current assessment:

- Architecture: strong
- Documentation: unusually strong, occasionally excessive
- Maintainability today: good
- Maintainability after another 20 features without refactoring: poor
- Runtime safety: thoughtful, especially config snapshots and monitor revert planning
- Automated verification: weak / effectively absent
- Largest risk: settings subsystem becoming a monolith and duplicating its schema across files

## What is done well

### 1. The project has real boundaries

`core/`, `services/`, `widgets/`, `themes/`, and `assets/` are meaningful divisions rather than decorative folders. System integration is mostly kept out of visual components. Global state is centralized instead of being passed through long widget trees.

### 2. Global ownership is handled thoughtfully

Hoisting shortcuts and IPC handlers to `shell.qml`, then routing launcher and wallpaper actions to the focused monitor, is a strong design. It avoids duplicate registrations and multi-monitor mirrored-popout behavior.

### 3. Failure history is preserved

`PROBLEMS_AND_FIXES.md` and the revision notes contain valuable context, especially around lazy singleton initialization and cold-start-only failures. This is excellent for AI-assisted maintenance because it records failed approaches, not just the final answer.

### 4. Configuration changes are treated as transactions

The snapshot-before-apply design in `ConfigManager.qml` is much safer than directly writing configuration. The planned revert window for dangerous monitor changes is also the correct kind of defensive thinking.

### 5. External processes mostly use argument arrays

Most commands avoid shell interpolation. The wallpaper scan uses positional shell arguments rather than embedding user paths directly into script text, which is the right pattern.

### 6. Theme contracts are consistent

The themes appear to implement a shared property contract and `Theme.qml` serves as a stable forwarding layer. This is much better than scattering color literals throughout widgets.

## Highest-priority changes

### P1 — Split `SettingsWindow.qml`

At 3,080 lines, this file is the biggest structural problem.

It currently owns:

- window behavior
- navigation
- staged state for many unrelated domains
- change calculation
- apply/discard logic
- color parsing
- display-page dormant code
- reusable setting controls
- every settings page's visual implementation

A change to notification positioning should not require editing the same file that contains monitor configuration, theme selection, wallpaper transitions, and generic controls.

Recommended target structure:

```text
widgets/Settings/
  SettingsWindow.qml
  SettingsStore.qml            # staging/diff/discard/apply orchestration
  components/
    StepperRow.qml
    ToggleSettingRow.qml
    OptionPickerRow.qml
    HexColorRow.qml
    SectionHeader.qml
  pages/
    AppearancePage.qml
    BarPage.qml
    NotificationsPage.qml
    DesktopPage.qml
    WallpaperPage.qml
    GeneralPage.qml
    DisplaysPage.qml           # only when DisplayManager exists
```

`SettingsWindow.qml` should ideally fall below 500–700 lines and mostly coordinate navigation, page loading, window state, and Apply/Discard buttons.

### P1 — Replace duplicated settings plumbing with a schema

The same setting currently tends to exist in several forms:

1. a persisted property in `UserPrefs.qml`
2. a setter in `UserPrefs.qml`
3. a `stagedFoo` property in `SettingsWindow.qml`
4. shown-value logic
5. a diff entry
6. a reset in `discardStaged()`
7. a switch case in `ConfigManager._performStagedWrites()`
8. sometimes a generated Hyprland write path

This repetition is the project's biggest source of future “one location was forgotten” bugs.

Introduce a central settings schema/model containing, at minimum:

- key
- current value getter
- validator/coercer
- persistence setter
- label
- whether changing it dirties generated Hyprland config

Even if QML makes a fully generic implementation awkward, reducing eight touch points to three would be a large improvement.

### P1 — Add an automated smoke-check command

The project has extensive prose about regressions but no automatic gate preventing them.

Add a script such as `scripts/check.sh` that performs what is available locally:

- runs `qmllint` or the Quickshell-provided QML language tooling
- checks all QML files for parse/import errors
- verifies every theme exposes the expected contract
- finds references to missing project files
- checks shell scripts with `shellcheck` when installed
- optionally launches a separate test config with a timeout and scans logs for `ReferenceError`, `TypeError`, and unexpected `undefined`

Quickshell's official setup guide recommends enabling `qmlls` with a `.qmlls.ini`; this project should adopt that immediately. The generated `.qmlls.ini` should be ignored by Git because it is machine-specific.

### P2 — Break up `ConfigManager.qml`

At 866 lines, `ConfigManager.qml` is doing several jobs:

- snapshot creation/list/restore/prune
- original backup
- staged preference transaction
- generated Hyprland appearance output
- risky file writes with countdown rollback
- stale rollback recovery
- shell-script storage and process execution

Suggested split:

```text
services/config/
  SnapshotManager.qml
  PreferenceApplyManager.qml
  HyprAppearanceWriter.qml
  RevertTransaction.qml
```

A thin `ConfigManager.qml` can remain as the public facade if keeping one API is useful.

### P2 — Move long embedded shell scripts into real script files

The embedded scripts are defensible, but they make `ConfigManager.qml` harder to inspect, lint, test, and reuse. External scripts under `scripts/config-manager/` would gain:

- shellcheck support
- direct terminal testing
- clearer diffs
- less QML quoting noise
- simpler process code

Continue passing all dynamic paths as positional arguments.

### P2 — Improve Wi-Fi secret handling

`Network.qml` passes a new Wi-Fi password as a command-line argument to `nmcli`. That is a documented way to use `nmcli`, but command-line secrets can be exposed to process inspection or logs while the command runs. Prefer a supported secret-agent, prompt, or controlled input mechanism rather than including the password in the process argument list.

Also consider using Quickshell's native `Quickshell.Networking` APIs as they mature, instead of maintaining an `nmcli` text parser. The current Quickshell 0.3 documentation exposes Wi-Fi device/scanner types. This is not necessarily an immediate rewrite—the current code may support connection operations that the native API does not yet cover—but it should be tracked as a future simplification.

### P2 — Remove dormant display implementation from the production file

The display page is currently disabled correctly, and the documentation honestly records why. However, hundreds of lines of commented implementation remain inside the 3,080-line settings file.

Move that code to one of:

- `notes/DisplaysPage-draft.qml`
- a feature branch
- a dedicated design document

Commented-out production code does not receive syntax checking and adds noise to every future AI edit.

### P2 — Define service state machines explicitly

Several services use booleans and pending strings to represent operations, for example Wi-Fi connection state and `ConfigManager` transaction chains. This works, but explicit state properties are easier to reason about:

```qml
readonly property int Idle: 0
readonly property int TryingSavedProfile: 1
readonly property int CreatingProfile: 2
readonly property int Connected: 3
readonly property int Failed: 4
property int connectionState: Idle
```

This prevents impossible combinations such as “pending password but not connecting” and improves UI messaging.

## Medium-priority improvements

### Reduce header size

The file headers are useful, but some are longer than the implementation itself. For example:

- `shell.qml`: 413 total lines, about 231 comment lines
- `UserPrefs.qml`: 635 total lines, about 345 comment lines
- `ConfigManager.qml`: 866 total lines, about 370 comment lines

Keep local comments for invariants and traps. Move historical narratives and old architecture decisions to docs. A file header generally needs:

- purpose
- ownership/lifetime
- important invariants
- dependencies
- links to deeper documentation

Revision-by-revision history belongs primarily in version control and `REVISION_HISTORY.md`.

### Add a machine-readable theme contract test

Every theme must expose the same properties. This is a perfect automated check. Parse each theme file and compare declared property names/types against `DefaultTheme.qml`. Fail on missing or extra properties unless explicitly allowed.

### Add capability detection and user-facing errors

At startup or when opening relevant UI, detect missing dependencies such as:

- `awww`
- `nmcli`
- `bluetoothctl`
- required D-Bus services

A dead button or generic process failure is less helpful than “NetworkManager/nmcli is unavailable.”

### Avoid relying on text output where structured APIs exist

Text parsing appears in wallpaper queries and NetworkManager operations. It is acceptable for a personal shell, but output formats are soft dependencies. Prefer Quickshell APIs or D-Bus interfaces when they provide equivalent functionality.

### Separate stable docs from session handoff notes

`NEXT SESSION.txt`, `SONNET_QUEUE.md`, project vision, backlog, revision history, and in-file revision histories overlap. Establish a clearer hierarchy:

- `README.md`: current user-facing overview
- `ARCHITECTURE.md`: current design only
- `PROBLEMS_AND_FIXES.md`: durable traps and solutions
- `CHANGELOG.md`: chronological changes
- `BACKLOG.md`: future work
- `notes/`: temporary AI/session handoff material

### Add logging categories

Instead of scattered `console.warn`, create a small logger helper or naming convention so logs can be filtered by service. Avoid logging secret values, paths that may be sensitive, or full command arguments for password-bearing operations.

## Specific observations

### `shell.qml`

Good: correct place for machine-global shortcut and IPC ownership; clear per-monitor versus singleton distinction.

Improve: the header is much larger than the active implementation. Move the historical multi-monitor narrative into architecture docs and leave a concise invariant comment near the routing function.

### `UserPrefs.qml`

Good: strong validation boundaries and one persisted source of truth.

Improve: many manually repeated getters/setters and sentinel values. The `-1` / `-9999` override pattern works but is easy to misuse. A structured override object such as `{ enabled, value }`, or a documented common helper, would be safer.

### `Theme.qml`

Good: forwarding through one stable singleton gives widgets a consistent interface.

Improve: enforce the theme interface automatically. Silent `undefined` theme properties are exactly the kind of problem a tiny test can eliminate.

### `ConfigManager.qml`

Good: snapshot-first transactions, serialized operations, argument-safe shell invocation, crash recovery thinking.

Improve: too many responsibilities and complex callback chaining through one `Process`. The state flow should be split or represented by an explicit transaction state enum.

Potential hardening: `applyFileWithRevert(path, ...)` accepts an arbitrary path from its caller. Today the caller is trusted, but the service itself should restrict writes to an allowlist of managed paths. Defense should live at the write boundary.

### `Network.qml`

Good: simple process calls, avoids constant background scanning, distinguishes saved-profile activation from new connection creation.

Improve: password in argv, generic error guesses, and SSID-as-profile-ID assumptions. A saved connection's profile ID is often the SSID but is not guaranteed to be. Mapping access points to actual connection profiles would make reconnect/forget behavior more correct.

### `WallpaperPicker.qml`

Good: dynamic paths are passed as shell positional arguments; symlink canonicalization is considered; rescanning only on open is sensible.

Improve: GNU-specific `xargs -d '\n'` is fine on Arch but should be documented as intentionally non-portable. Newline-containing filenames still cannot be represented safely in line-oriented parsing. This is low risk for wallpapers, but NUL-delimited scanning would be technically correct.

### `SettingsWindow.qml`

Good: transactional Apply/Discard behavior, staged state, reusable row components, honest disabling of unfinished display functionality.

Improve: split immediately before adding substantial new settings. This is the clearest point where “working generated code” is becoming hard-to-maintain application code.

## Suggested refactor order

1. Add `.qmlls.ini` setup instructions, `.gitignore`, and `scripts/check.sh`.
2. Extract the four inline settings components into separate files without changing behavior.
3. Extract each settings page one at a time.
4. Move staging/diff/apply logic into `SettingsStore.qml`.
5. Add a theme-contract check.
6. Add an allowlist to `ConfigManager.applyFileWithRevert()`.
7. Split snapshot/revert/Hyprland-writing responsibilities.
8. Revisit native Quickshell networking versus `nmcli`.
9. Implement `DisplayManager` only after the settings split, not before.

## What I would not rewrite

I would not replace the singleton architecture merely because dependency injection is fashionable. For a personal QML shell, these are genuine application-global services and the current approach is practical.

I would not remove the snapshot manager. It is one of the strongest parts of the project.

I would not adopt a large existing shell framework or prebuilt config. This code already has coherent design and is tailored to the owner.

I would not chase theoretical portability beyond Arch/Hyprland unless public distribution becomes a real goal.

## Bottom line

The project is good. The AI did not merely produce attractive output; it produced several solid architectural decisions and documented real failure modes. The criticism is that the code is now at the transition point from “personal config” to “maintained application.”

The next major feature should not be another page. The next major feature should be a smaller settings architecture plus an automatic smoke-test. Those two changes will make every future Claude/ChatGPT edit safer and easier to review.
