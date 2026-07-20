=================================================================
CURRENT PRIORITY ORDER — 2026-07-20 (GPT)
=================================================================

Completed structural checkpoints:
- Settings monolith split complete through Rev 29.
- UI Profiles restore point complete and live-tested through Rev 25.
- Hyprland animation presets complete and live-tested through Rev 39.
- Safe animation Apply uses generated files plus one ordinary `hyprctl reload`;
  `full-reset` and live-eval approaches are permanently rejected.
- Launcher/wallpaper dual presentation and notification bar attachment are
  complete and live-tested through notification Rev 64.

1. Add automated smoke checks and QML tooling.
   - `.qmlls.ini` setup instructions and `.gitignore`.
   - QML parse/import checks.
   - Missing-file checks.
   - Theme-contract validation.
   - Optional runtime log scanning.

2. Split `ConfigManager.qml` responsibilities and externalize long embedded
   shell scripts where practical. Preserve the tested generated-file contracts.

3. Continue small, low-risk requested features.
   - Launcher width and maximum results. Initial app-list behavior is complete.
   - Power menu Lock and Suspend.
   - Additional themes.

4. Resume larger deferred features deliberately.
   - Named UI Profiles / Save As.
   - MPD local-library music client.
   - Notification history.
   - Displays page only after a real display service and timed rollback exist.

5. Continue documentation cleanup.
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
- ConfigManager auto-prune: old auto/daily snapshots are swept
  automatically, retention lowered 30 -> 10. Routine sweeps now use a
  separate silent Process so they do not replace the Settings status line.
- Hyprland setup warning: the Hyprland page now checks this machine's
  ~/.config/hypr/user/look.lua and only shows the warning when an active
  active_border assignment still conflicts with generated/appearance.lua.
- Wallpaper Transition section (Appearance page): type picker
  (14 real awww/swww values incl. random), position picker
  (grow/outer only), duration/fps/angle steppers.
- Detached notification corner + X/Y controls were already present.
- Notification presentation expansion is now complete through Rev 64:
  detached or attached-to-bar mode, left/center/right attachment,
  horizontal offset, optional attached card borders, stacked growth,
  individual exits, final host retraction, and synchronized bar-border
  seam handoff. See docs/LAUNCHER_WALLPAPER_NOTIFICATION_PLAN.md.
- Launcher and wallpaper picker attached/centered presentation modes are
  complete, including offsets, shared content, launcher initial app list,
  favorites/usage/hidden apps, wallpaper Settings consolidation, and the
  approved transition list.
- SDDM login theme major customization block complete: safe temporary preview, alternate themes/fonts, shared-library wallpaper thumbnails, time/date colors and shadows, login-panel sizing, and hash-aware Apply. See docs/SDDM_THEME_PLAN.md.

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

- Hyprland animation control — docs/HYPR_ANIMATIONS_PLAN.md. Rev 30
  is a conversation (confirm ownership-transfer + preset names), not
  code — can happen anytime, doesn't need the machine.
- SDDM follow-up is now optional only: installed-status detail, deactivate/rollback UI, or a safely designed machine-specific monitor-layout UI. The major visual customization block is complete. See docs/SDDM_THEME_PLAN.md.

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

- [x] Add desktop clock shadow-strength control (0–100%).

- [x] Desktop clock: configurable shadow X/Y offsets (-20px to +20px).

- [x] SDDM major customization block: alternate theme/font, wallpaper thumbnail selector, date, custom colors/shadows, login-panel controls, and safe preview/apply.
- [x] Settings window draggable scrollbar and persisted default size.
