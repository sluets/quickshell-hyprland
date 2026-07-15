=================================================================
CURRENT PRIORITY ORDER — 2026-07-15 (GPT)
=================================================================

1. Continue splitting the Settings menu one page/component at a time.
   - Rev 2 HyprlandPage extraction is live-tested and approved.
   - Preserve behavior during each extraction.
   - Test each page before continuing.

2. Make requested Settings adjustments and fix known bugs one at a time.
   - Border-color coupling is the first major bug.
   - Desktop clock center-position X/Y offsets remain deferred.
   - Replace the permanent Hyprland setup warning with a machine-specific
     one-time readiness check.
   - Backup pruning should run silently in the background.

3. Before adding major features, perform a controlled structural cleanup.
   - Rename vague or inconsistent files/components.
   - Split oversized files by responsibility.
   - Establish predictable folders and naming.
   - Add small folder README maps where useful.
   - Do not refactor everything at once.

4. Add automated smoke checks and QML tooling.
   - `.qmlls.ini` setup instructions and `.gitignore`.
   - QML parse/import checks.
   - Missing-file checks.
   - Theme-contract validation.
   - Optional runtime log scanning.

5. Reduce duplicated settings plumbing with a central schema/model where
   practical, then move staging/diff/apply orchestration toward a
   `SettingsStore`-style component.

6. Split `ConfigManager.qml` responsibilities, externalize long shell
   scripts, add managed-path allowlisting, and improve explicit service
   state handling.

7. Resume deferred feature work only after the structure is safer.
   - SDDM next phase.
   - Hyprland animation presets, beginning with Phase 0 ownership decisions.
   - Weather icon on/off toggle.
   - MPD local-library music client plan.

8. Continue documentation cleanup.
   - Remove or archive stale one-time migration/session documents.
   - Consolidate overlapping docs.
   - GPT signs documentation and in-file comments it adds or changes.

Git setup is complete. Canonical repository:
https://github.com/sluets/quickshell-hyprland

=================================================================
HISTORICAL / EARLIER BACKLOG CONTENT
=================================================================

=================================================================
FILE
=================================================================

docs/FEATURE_BACKLOG.md

=================================================================
PURPOSE
=================================================================

Consolidated list of everything discussed across the 2026-07-13
session(s) — what's done, what's small and ready to build, what's
bigger and has its own plan doc, and what's still just an idea. This
doesn't replace notes/SONNET_QUEUE.md (that's the older, more
detailed backlog with exact implementation notes per item) — think of
this as the index that also captures the NEWER stuff that came up
this session and isn't in that file yet.

=================================================================
DONE THIS SESSION — no action needed
=================================================================

- Weather icons (7 SVGs, assets/icons/weather/) — built, confirmed
  rendering correctly.
- Settings window visual pass: tab-line removed, active tab outline,
  Theme/Font/Wallpaper-Transition-Type dropdowns "connect" to their
  open list instead of floating separately, extra spacing between
  control groups, pending-changes panel boxed.
- ConfigManager auto-prune: old auto/daily snapshots now actually get
  swept automatically (they weren't before — pruneAutos() existed but
  nothing called it), retention lowered 30 -> 10.
- Wallpaper Transition section (Appearance page): type picker
  (14 real awww/swww values incl. random), position picker
  (grow/outer only), duration/fps/angle steppers.
- Notification position/corner + offset X/Y — turned out to already
  be built (2026-07-11, before this session) — see
  NotificationPopups.qml. Flagged here only because it came up as if
  it might still be missing; it isn't.
- SDDM login theme — Phase 0 (skeleton, test-mode confirmed working)
  built and delivered as sddm-rev0. See docs/SDDM_THEME_PLAN.md for
  Phases 1+.

=================================================================
SMALL, READY TO BUILD (recipe exists, low risk)
=================================================================

- More themes — zero-risk per ARCHITECTURE.md's own recipe (copy a
  theme file, tweak values, one instance + one map line in
  core/Theme.qml). Appears in the picker automatically.
- assets-README.md is stale — still says "Empty as of 2026-07-01...
  nothing needed here yet," which is now false (weather icons + your
  own power icons are both in there). One-line doc fix.
- Lock / Suspend on the power screen — loginctl lock-session
  (fallback hyprlock) + systemctl suspend. Hibernate explicitly
  excluded unless swap is confirmed configured for it. See
  SONNET_QUEUE.md Q3.
- Launcher settings page — width + max results as steppers. Terminal
  command stays a hand-edit (no text-input pattern exists yet outside
  the launcher itself). See SONNET_QUEUE.md Q6.
- Audio settings page — ONLY volume scroll-step + OSD duration; sink
  switching deliberately stays in the bar popout. See SONNET_QUEUE.md
  Q7.

=================================================================
BIGGER — HAS ITS OWN PLAN DOC, START THERE
=================================================================

- Hyprland animation control — docs/HYPR_ANIMATIONS_PLAN.md. Phase 0
  is a conversation (confirm ownership-transfer + preset names), not
  code — can happen anytime, doesn't need the machine.
- SDDM theme, Phases 1+ (real wallpaper, hand-copied palette, the
  standalone settings tool, live wallpaper sync, weather, real color
  sync from core/Theme.qml) — docs/SDDM_THEME_PLAN.md.

=================================================================
NEEDS A SYSTEM PACKAGE, NOT CODE
=================================================================

- Notification icons occasionally failing to resolve — needs a real
  icon theme installed (e.g. papirus-icon-theme, pacman-official).
  Nothing in NotificationPopups.qml can fix a missing system icon
  theme.

=================================================================
PARKED — EXPLICITLY NOT NOW (per SONNET_QUEUE.md's own list)
=================================================================

- Displays / monitor-config settings page (blocked on a safer
  apply-with-revert pattern — black-screen risk if done carelessly)
- Notification history (bell icon + popout of past notifications) —
  services/Notifs.qml was pre-designed with this in mind, just not
  built. See SONNET_QUEUE.md Q4.
- Workspace click-to-switch
- Wallpaper-driven color scheme (dynamic theme extracted from the
  current wallpaper, à la Material You)

=================================================================
IDEAS — NOT SCOPED, NOT COMMITTED TO ANYTHING YET
=================================================================

- CPU/GPU/RAM system-stats widget — lm-sensors has been a declared
  dependency since day one but nothing in the bar actually uses it.
  Given the 7800X3D + 9070 XT, this seems like an obvious gap more
  than a nice-to-have.
- Idle inhibitor toggle ("caffeine" style) — prevents screen lock
  during video/gaming.
- Clipboard history via cliphist — pairs naturally with the existing
  launcher pattern.
- Per-monitor refresh-rate switcher — you've got a 240Hz and a 144Hz
  monitor in monitors.lua; a quick toggle for dropping the 240Hz panel
  down (power/heat) could be a small, real win.

=================================================================
REVISION HISTORY
=================================================================

2026-07-13  Initial list, consolidating everything discussed this
            session plus the still-open items from SONNET_QUEUE.md.
