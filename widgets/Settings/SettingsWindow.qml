//=============================================================================
// FILE
//=============================================================================
//
// widgets/Settings/SettingsWindow.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The settings application (settings-manager plan, Phase 2, grown
// same-day and since): a floating window with page tabs — Appearance
// (theme, font scale, bar border), Notifications (card prefs +
// popup corner/offsets + test button), Desktop (the desktop clock:
// enabled, position, monitor, colors, shadow), Hyprland (gaps/border/
// rounding), UI Profiles, and SDDM — plus the full transaction UX the
// plan promised: changes are STAGED,
// a pending-changes panel shows
// the diff ("Theme: HoneycombTheme → DefaultTheme"), and nothing
// touches disk until Apply — which runs through
// ConfigManager.applyChanges (auto snapshot first, writes second, so
// every Apply is one `qs ipc call config restore ...` away from undo).
//
// Opened via the gear menu's "Open Settings…" entry
// (Signals.toggleSettingsWindow) or `qs ipc call settings toggle`.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell, Quickshell.Wayland, Quickshell.Hyprland, QtQuick,
// QtQuick.Layouts
// core/Theme.qml       (colors/fonts AND themes/themeNames — this is
//                       the first consumer of the rebuilt themes map)
// core/UserPrefs.qml   (current values; never written directly — all
//                       writes go through ConfigManager)
// core/Signals.qml     (toggleSettingsWindow)
// services/ConfigManager.qml  (applyChanges, busy/lastError/lastOutput)
//
//=============================================================================
// USED BY
//=============================================================================
//
// shell.qml (single top-level instance + the `settings` IpcHandler).
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No settings window. The gear menu's "Open Settings…" emits a signal
// nothing hears (harmless), the `settings` IPC target fails to
// resolve in shell.qml. Theme switching falls back to hand-editing
// user-prefs.json (Theme.qml reads UserPrefs.themeName either way).
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WINDOW MECHANICS: a compositor-managed FloatingWindow. Hyprland owns
// the outer border and rounding; the QML client stays opaque and does not
// draw a competing frame. The page viewport scrolls internally while the
// sidebar, title, pending panel, and Apply/Cancel controls remain fixed.
// The titlebar supports system move; Hyprland can also move/resize/toggle
// floating through normal compositor binds.
//
// STAGED, NOT LIVE: clicking a theme does NOT change the theme. It
// stages the choice; the row highlights, the pending panel gains a
// line, and Apply commits (Cancel or closing the window discards).
// This is deliberately DIFFERENT from the gear popout's quick toggles
// (instant, no ceremony) — the transient/durable split. If live
// preview is ever wanted, it's an "apply now, snapshot first, revert
// on Cancel" variant — decide then, don't drift into it.
//
// WHY CLOSING DISCARDS STAGED CHANGES: a settings window that
// remembers half-made changes invisibly across opens is a foot-gun
// (you reopen it days later, hit Apply for something else, and a
// forgotten staged theme change rides along). Close = clean slate.
//
// THE APPLY BUTTON DISABLES WHILE ConfigManager IS BUSY and the
// status line mirrors busy/lastError/lastOutput — the async pattern
// from BACKUPS.md, surfaced in UI instead of `status` calls.
//
// FONT SCALE uses −/+ steps of 0.1 (clamped 0.8–2.5, mirroring
// UserPrefs.setFontScale's own clamp) rather than a slider — exact,
// keyboardable later, and half the code of a hand-rolled slider. The
// staged value previews NOTHING (same staged-not-live rule; a font
// scale that live-previews while the theme doesn't would be
// inconsistent).
//
// STABLE GEOMETRY — WHY THE CARD DOESN'T RESIZE UNDER THE CURSOR
// (v0.6): live use found that staging a change grew the pending panel,
// which grew the card, which — being centerIn'd — shifted EVERY
// control by half the growth in both axes. Click "+" on Icon Size
// once and the second click lands on Body Lines. Three rules fix it:
//   1. FIXED WIDTH. The card is one width for every page
//      (root.contentWidth, scaled off Theme.fontSize so it tracks
//      font scale). Anything that can out-grow it elides instead of
//      widening the card.
//   2. TOP-ANCHORED, NOT CENTERED. A centered card distributes any
//      height change both ways; a top-anchored card only grows
//      DOWNWARD, so a control never moves unless something ABOVE it
//      changed — and the things that appear mid-interaction appear
//      BELOW the control that triggered them.
//   3. FIXED-HEIGHT PENDING PANEL. The pending area permanently
//      reserves pendingVisibleLines rows (a ListView — scrolls past
//      that) and the status line reserves its row even when empty, so
//      staging/unstaging a change resizes NOTHING. Apply/Cancel are
//      fixtures.
// Page height still differs per tab — that resize is fine (you asked
// for it by clicking the tab, and the tabs themselves sit above the
// pages so they never move). Do NOT "clean this up" back to
// anchors.centerIn or visible:-gated pending rows; the jumping
// buttons were the bug.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-19  (GPT) Rev 26 settings split: extracted the card-level
//             theme/font/wallpaper-transition dropdowns and shared color
//             picker into components/SettingsOverlays.qml. Overlay state
//             and existing page contracts remain compatible.
// 2026-07-18  (GPT) Rev 6 settings split: extracted the fixed-height
//             pending-changes panel and Apply/Cancel footer into
//             components/SettingsPendingFooter.qml. Transaction state and
//             behavior remain owned by SettingsWindow.qml.
// 2026-07-15  (GPT) Rev 5 settings split: extracted only the Hyprland
//             page into pages/HyprlandPage.qml. Staged state, config
//             generation, Apply/Cancel behavior, and setup-warning
//             behavior remain owned by SettingsWindow.qml.
// 2026-07-14  (GPT) Rev 4 settings split: extracted only the Notifications
//             page into pages/NotificationsPage.qml. All staged state,
//             Apply/Cancel behavior, and window/page geometry remain here.
// 2026-07-14  (GPT) Rev 1 settings split: extracted only the Appearance
//             page into pages/AppearancePage.qml. All staged state, dropdown
//             overlays, color-picker ownership, Apply/Cancel behavior, and
//             working viewport/scrollbar geometry remain in this file.
// 2026-07-14  (GPT) Floating-window geometry polish: made the client
//             surface opaque and removed the inner rounded card shape so
//             Hyprland is the sole owner of the visible frame/rounding;
//             matched the sidebar lower corner to the live Hyprland rounding;
//             widened the permanent scroll gutter and hard-capped dropdown
//             overlays before that gutter so controls cannot collide with
//             the scroll indicator.
// 2026-07-14  (GPT) Application-window redesign: converted the settings
//             overlay into a real FloatingWindow, added a draggable
//             titlebar, persistent left sidebar navigation, bounded
//             scrollable page viewport, fixed footer/pending controls,
//             and monitor-safe fixed outer geometry. Existing staging,
//             Apply/Cancel, dropdown, and color-picker behavior retained.
// 2026-07-13  Visual pass + new Wallpaper Transition section (Sonnet
//             5). Visual: removed the flat divider line under the tab
//             row (was reading as an underline beneath the active
//             tab); active tab now gets a 1px outline instead of just
//             a color fill; Theme/Font Family dropdowns (and the new
//             Wallpaper Transition Type one below) square off their
//             bottom corners while open and their list overlaps the
//             button by exactly the border width, so button+list read
//             as one connected shape instead of two floating boxes;
//             extra Layout.topMargin between control groups (Font
//             Scale/Font Family/Bar Padding/Bar Border on this page,
//             Position on Notifications, Colors on Desktop) so groups
//             separate from each other while a group's own label
//             stays snug to its control; pending-changes header/list/
//             status line now sit inside one bordered panel instead
//             of bare on the page. New: Wallpaper Transition section
//             (Appearance page) — type dropdown (14 real awww/swww
//             values incl. random), Position picker (grow/outer only),
//             Duration/FPS/Angle steppers (Angle only for wipe/wave).
//             Backing values migrated from core/Settings.qml to
//             UserPrefs.qml — see that file's own revision history.
// 2026-07-12  (Opus) Font picker + window-stability pass:
//             (1) FONT LIST NOW DERIVES FROM Qt.fontFamilies() at
//             runtime, filtered to base "... Nerd Font" families,
//             instead of a hardcoded name list. History of the bug:
//             the raw Qt dump was 150-300+ entries (unusable), so it
//             was trimmed to a hardcoded curated 10 — but those exact
//             strings did NOT match what Qt reports on a real machine
//             (an exact-match filter survived only CaskaydiaCove, the
//             theme default), so a pick set font.family to a name Qt
//             couldn't resolve and silently fell back to default
//             ("pick a font, nothing changes"). Fix: show the verbatim
//             strings Qt exposes, so any pick is guaranteed to render;
//             preferredFontOrder just floats the popular picks up top.
//             (See UserPrefs.qml same-day note — its setter had the
//             matching exact-match guard that also had to come out.)
//             (2) THEME + FONT DROPDOWNS render as card-level floating
//             overlays (mapToItem off their button, gated on the open
//             flag so it recomputes after layout settles) instead of
//             inline ListViews that grew the window on open.
//             (3) PAGES wrapped in a StackLayout so switching tabs no
//             longer resizes the card — it sizes to its largest page
//             up front (visible:false items were excluded from the old
//             ColumnLayout's implicit size, so the card tracked
//             whichever page was current).
// 2026-07-11  (Opus) v0.14: ROOT CAUSE FOUND — the whole
//             "custom-typed colors never persist" saga was a broken
//             validity check, not staging or persistence. The v0.13
//             keystroke log was decisive: typing "#00ff00" logged
//             text="#00ff00" valid=FALSE, and empty text logged
//             valid=TRUE — the check returned the exact opposite of
//             the truth. hexValid was a `readonly property bool` bound
//             to an INLINE regex LITERAL (/^#(...){6}...$/.test(text));
//             in a QML property-binding expression the literal's
//             brace-quantifiers get misparsed. (The IDENTICAL regex in
//             UserPrefs._validHex works because it's in a function
//             body, which is why swatch picks — validated only there —
//             always persisted while typed values — validated by the
//             broken binding — never did.) FIX: hexValid is now driven
//             by hexValidText(), a function that builds the pattern
//             from a STRING via new RegExp(...) (the same safe form
//             shell.qml already uses), verified in a JS engine to
//             accept #00ff00 / #c678dd and reject #c678d / empty.
//             onTextEdited computes validity fresh from that function
//             so it never depends on signal ordering. This is the fix
//             the previous four attempts were circling — they all
//             assumed the value was being lost downstream; it was
//             being rejected at the door. CONFIRMED live: typing
//             #00ff00 / #00ff01 / #011111 each staged and committed
//             exactly as typed. The temp console.logs (apply() +
//             onTextEdited) that pinned this down have been REMOVED.
// 2026-07-11  (Opus) v0.13: the apply() probe from v0.12 paid off —
//             a live test typing "#00ff00" committed
//             barBorderCustomColor = "#c678d" (the OLD value minus its
//             last char, an invalid 5-digit hex), proving the typed
//             value never reached staging and a corrupt intermediate
//             did. Most likely cause: the field pre-fills with the
//             current color, and editing INTO that pre-filled string
//             produced ambiguous half-valid intermediates that staged
//             instead of the intended new value. FIX: selectAll() on
//             focus so the first keystroke replaces the seed cleanly
//             ("click, type 00ff00" -> exactly "00ff00"). Added a
//             second TEMP console.log in onTextEdited logging the raw
//             field text + validity on every keystroke, so if this
//             still misbehaves the next run shows precisely what the
//             field receives. BOTH temp logs (here + apply()) come out
//             once persistence is confirmed.
// 2026-07-11  (Opus) v0.12: fixes the swatch-picker freezing the hex
//             field. SYMPTOM (live): after typing in the hex field,
//             clicking preset swatches no longer updated the field's
//             shown value (though Apply still committed them). CAUSE:
//             v0.11's syncFromShown() was guarded by `!activeFocus`,
//             but clicking a swatch in the card-level overlay does NOT
//             remove focus from the TextInput — so once focused, the
//             field ignored every external change. REPLACED the focus
//             guard with a `lastStagedByMe` comparison: the field
//             adopts shownValue whenever it differs from the value the
//             field itself last staged, so swatch picks / Cancel /
//             Apply-landings update it regardless of focus, while the
//             echo of the user's own typing is ignored (buffer left
//             alone mid-edit). Also added a TEMP console.log in apply()
//             to capture exactly what reaches ConfigManager, to settle
//             the still-unconfirmed typed-hex persistence bug on the
//             next live test. REMOVE that log once confirmed.
// 2026-07-11  (Opus) v0.11: TWO fixes after the swatch popup became
//             completely uninteractable in v0.10. ROOT CAUSE of that:
//             the popup was made a child of the 22px swatch icon, and
//             Qt only delivers clicks to a child within its parent's
//             bounds — a ~180px popup overflowing a 22px parent renders
//             but can't be clicked. (1) Popup is now ONE shared overlay
//             rendered at CARD level (root.colorPicker* state +
//             openColorPicker()), big/unclipped/on top, so it both
//             positions correctly under the swatch (mapToItem into card
//             space, clamped to the card) AND receives clicks. Also
//             gained click-outside-to-dismiss (the v1 limitation is
//             gone). (2) The hex TEXT field no longer binds `text:` to
//             shownValue — that declarative binding fought the user's
//             own typing (each valid keystroke stages -> shownValue
//             changes -> binding writes back). It's now seeded once and
//             re-seeded only on external changes via syncFromShown(),
//             guarded by !activeFocus so it never touches the field
//             mid-type. This is the robust replacement for the v0.10
//             activeFocus-on-the-binding attempt, which was still
//             fragile. NOTE: the typed-hex persistence bug needs one
//             more live confirm — see PROBLEMS_AND_FIXES.
// 2026-07-11  (Sonnet 5) v0.10 (second screen recording): TWO real
//             bugs found by comparing the hex FIELD text against the
//             PENDING CHANGES line frame-by-frame — they'd drifted
//             apart. (1) The root cause of "custom colors don't
//             stick": the resync Connections on hexField's
//             onShownValueChanged was firing on every change,
//             including the change caused by the user's OWN keystroke
//             a moment earlier, racing typing and occasionally
//             overwriting it mid-edit — so the value actually staged
//             for Apply could differ from what was visibly typed
//             (and could fail hex validation on write, which
//             ConfigManager silently no-ops with n++ still reported,
//             i.e. "applied 1 change(s)" printed even though nothing
//             wrote). Fixed by only resyncing when the field lacks
//             focus, so external changes (Cancel/Apply/page switch)
//             still sync but the field is never fought while the
//             person is actively editing it. (2) Swatch popup was
//             STILL opening far from the icon after the v0.9
//             mapToItem attempt (confirmed live) — rebuilt as a
//             direct CHILD of swatchIcon instead, so its position is
//             trivial local geometry with no cross-item coordinate
//             mapping to get wrong. Added a MouseArea over the popup
//             itself so clicking inside it doesn't fall through to
//             the swatch's own MouseArea and instantly re-close it.
// 2026-07-11  (Sonnet 5) v0.9 (live testing, thanks to a screen
//             recording + a screenshot from the maintainer): swatch
//             popup was positioned `x: 0` relative to the WHOLE hex
//             row (its far-left edge) instead of the swatch icon
//             itself (near the row's right edge, next to the hex
//             field) — fixed via mapToItem off a newly-added
//             `swatchIcon` id, so the popup now opens directly under
//             the icon you clicked regardless of label length. Also
//             expanded the preset palette 12 -> 24 colors (grayscale
//             ramp + a broader accent spread pulled from several of
//             the newly-registered themes) and widened the grid to 8
//             columns to fit them. Confirmed live: preset-swatch
//             clicks persist to user-prefs.json reliably. The
//             hand-typed-hex persistence bug (see PROBLEMS_AND_FIXES)
//             is UNRELATED to this popup and still open.
// 2026-07-11  (Sonnet 5) v0.8 (next_session.txt): Theme picker is now
//             a dropdown (closed button + fixed-height scrolling
//             ListView, same recipe as the pending-changes panel)
//             instead of a flat row-per-theme list — became necessary
//             the moment core/Theme.qml's missing-registration bug
//             was fixed and all 20 themes became selectable at once.
//             HexColorRow's live preview swatch is now clickable,
//             opening a small preset-palette popup (12 curated
//             colors); picking one stages exactly like typing a valid
//             hex. Hex field unchanged — still the fine-tune path.
//             Known v1 limit: no click-outside-to-close on the swatch
//             popup yet. New root property `themeDropdownOpen`
//             (UI-only, reset in discardStaged()).
// 2026-07-11  (Fable 5) v0.7 (thoughts_next_session.txt): Notification
//             position controls (corner picker + x/y offset steppers +
//             a Send Test Notification button — the test fires through
//             notify-send and deliberately previews APPLIED settings,
//             per the staged-not-live rule) and the new Desktop page
//             (desktop clock: enabled, corner incl. centered, x/y
//             offsets, monitor picker from live Quickshell.screens,
//             text color, shadow on/off + color). Two component
//             extractions: OptionPickerRow (segmented picker — corner
//             ×2 + monitor) and HexColorRow (the bar-border hex field,
//             generalized at its third use; its resync now watches the
//             shown value instead of one hardcoded UserPrefs signal).
//             Tab padding spacingLarge -> Medium so five tabs fit the
//             fixed width at fontScale 1.0.
// 2026-07-11  (Fable 5) v0.6: stable geometry — fixed card width,
//             top-anchored card, fixed-height pending panel (ListView,
//             scrolls past pendingVisibleLines) + always-reserved
//             status line, elide on every line that could widen the
//             card. Fixes controls drifting out from under the cursor
//             every time a change staged (see the new DESIGN NOTES
//             section). Inert Layout.minimumWidths removed (fillWidth
//             against the fixed-width column supersedes them).
// 2026-07-10  (Fable 5) v0.5b: the window's own card border uses the
//             shell-wide border tokens (was fixed 1px muted).
// 2026-07-10  (Fable 5) v0.5 (same day): Bar Border section on the
//             Appearance page — custom width toggle + stepper and
//             use-theme-color toggle + validated hex field (the
//             window's first TextInput; only well-formed hex ever
//             stages). Backed by the new UserPrefs barBorder*
//             overrides, precedence chain in core/Theme.qml.
// 2026-07-10  (Fable 5) v0.4: the Displays page (per-monitor enable /
//             mode / scale from live hyprctl state via the new
//             services/DisplayManager.qml). DELIBERATELY its own
//             transaction: display changes do NOT join the global
//             pending panel or Apply button — they apply immediately
//             through ConfigManager's new apply-with-revert-window
//             (auto snapshot, countdown, auto-revert unless
//             confirmed), because "staged until Apply" and "applied
//             but reverting in 15 s" are different promises and one
//             button can't honestly make both. Position editing is
//             NOT in v1 (see docs/DISPLAYS.md).
// 2026-07-09  (Fable 5) v0.2: page tabs (Appearance | Notifications),
//             the Notifications page (from the maintainer's
//             THOUGHTS.txt wishlist), StepperRow/ToggleSettingRow
//             inline components (the −/+ control appeared four times
//             — extraction earned its keep), daily-snapshot-on-open
//             wired (skipped silently if the engine is busy). Staged
//             changes deliberately SURVIVE tab switches — the pending
//             panel is global; only close/Cancel discards.
// 2026-07-09  (Fable 5) Created — Phase 2 of
//             notes/settings-manager-plan.md. Written offline against
//             PowerScreen's proven window recipe; the transaction path
//             beneath it (ConfigManager.applyChanges) is new and
//             live-untested. First-run bugs go in
//             docs/PROBLEMS_AND_FIXES.md.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.core
import qs.services
import "components" as SettingsComponents
import "pages" as SettingsPages

FloatingWindow {
    id: root

    title: "Quickshell Settings"
    // Let Hyprland own the window shape and border. The client surface
    // itself is opaque so there is no transparent inset that can read as
    // a second inner frame when the compositor border is made very thick.
    color: Theme.colorBackground
    implicitWidth: UserPrefs.settingsWindowDefaultWidth
    implicitHeight: UserPrefs.settingsWindowDefaultHeight
    // Small enough for 1080p laptop panels and scaled displays while
    // preserving the larger default/implicit desktop size.
    minimumSize: Qt.size(Math.round(Theme.fontSize * 48), Math.round(Theme.fontSize * 34))
    maximumSize: Qt.size(1800, 1200)

    property bool shown: false
    property real reveal: shown ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.animationEasing
        }
    }

    // Which page the card shows. Adding a page = one entry here, one
    // ColumnLayout below gated on it.
    property string currentPage: "Appearance"
    // UI-only (not staged/persisted) — open/closed state of the theme
    // dropdown, added 2026-07-11 (Sonnet 5) alongside the fix that
    // made all 20 themes actually selectable. Reset in discardStaged()
    // so it doesn't stay stuck open across Cancel/Apply/close.
    property bool themeDropdownOpen: false
    property bool fontFamilyDropdownOpen: false
    property bool wallpaperTransitionTypeDropdownOpen: false
    // Displays remains a future feature. Its disabled prototype was removed
    // in Rev 25; rebuild it around a real services/DisplayManager.qml.
    readonly property var pages: ["Appearance", "Notifications", "Desktop", "Hyprland", "UI Profiles", "SDDM"]

    // ---- Shared preset-color-picker overlay state (2026-07-11, Opus) ----
    // The swatch popup can't live inside its HexColorRow: the popup is
    // ~180px and hangs BELOW a ~30px row, and Qt only delivers clicks to
    // a child within its parent's bounds — so a popup overflowing the
    // row was visible but dead (the exact "not interactable" bug). The
    // fix is ONE popup rendered at card level (big, unclipped, on top),
    // driven by whichever row asked to open it. A row calls
    // openColorPicker(); the overlay maps the swatch's position into
    // card space, shows the grid, and calls the row's staging callback
    // when a color is chosen. Only one picker open at a time — which is
    // also the correct UX (opening one closes another).
    property bool colorPickerOpen: false
    property Item colorPickerAnchor: null      // the swatch icon that opened it
    property var colorPickerCallback: null     // function(hexString) to stage
    property var colorPickerSwatches: []       // palette to show

    function openColorPicker(anchor, swatches, callback) {
        // Toggle off if the same anchor asks again (click swatch twice).
        if (colorPickerOpen && colorPickerAnchor === anchor) {
            closeColorPicker();
            return;
        }
        colorPickerAnchor = anchor;
        colorPickerSwatches = swatches;
        colorPickerCallback = callback;
        colorPickerOpen = true;
    }
    function closeColorPicker() {
        colorPickerOpen = false;
        colorPickerAnchor = null;
        colorPickerCallback = null;
    }

    // ---- Stable geometry (see DESIGN NOTES) ----
    // One content width for every page, scaled off the font token so
    // it tracks font scale (≈504 px at the default 14 px). Wide
    // enough for the widest current page; anything longer elides rather
    // than widening the card.
    readonly property int contentWidth: Math.round(Theme.fontSize * 52)
    readonly property int sidebarWidth: Math.round(Theme.fontSize * 14)
    // Reserved space beside scrollable pages so full-width controls and
    // their card-level dropdown overlays never sit beneath the scroll thumb.
    readonly property int pageScrollGutter: Math.max(24, Math.round(Theme.fontSize * 1.5))
    // How many diff rows the pending panel shows before it scrolls.
    // The panel reserves exactly this many rows at ALL times — that
    // fixed reservation is the whole point.
    readonly property int pendingVisibleLines: 4

    // GPT Rev 21: staged settings now live in a dedicated transaction controller.
    SettingsTransaction {
        id: settingsTransaction
    }

    property alias stagedTheme: settingsTransaction.stagedTheme
    property alias stagedFontScale: settingsTransaction.stagedFontScale
    property alias stagedNotifShowAppName: settingsTransaction.stagedNotifShowAppName
    property alias stagedNotifIconSize: settingsTransaction.stagedNotifIconSize
    property alias stagedNotifBodyLines: settingsTransaction.stagedNotifBodyLines
    property alias stagedNotifFontScale: settingsTransaction.stagedNotifFontScale
    property alias stagedHyprGapsIn: settingsTransaction.stagedHyprGapsIn
    property alias stagedHyprGapsOut: settingsTransaction.stagedHyprGapsOut
    property alias stagedHyprBorderSize: settingsTransaction.stagedHyprBorderSize
    property alias stagedHyprRounding: settingsTransaction.stagedHyprRounding
    property alias stagedHyprActiveBorderUseThemeColor: settingsTransaction.stagedHyprActiveBorderUseThemeColor
    property alias stagedHyprActiveBorderCustomColor: settingsTransaction.stagedHyprActiveBorderCustomColor
    property alias stagedBarBorderWidthOverride: settingsTransaction.stagedBarBorderWidthOverride
    property alias stagedBarBorderUseThemeColor: settingsTransaction.stagedBarBorderUseThemeColor
    property alias stagedBarBorderCustomColor: settingsTransaction.stagedBarBorderCustomColor
    property alias stagedBarPaddingTopOverride: settingsTransaction.stagedBarPaddingTopOverride
    property alias stagedBarPaddingSideOverride: settingsTransaction.stagedBarPaddingSideOverride
    property alias stagedBarPaddingBottomOverride: settingsTransaction.stagedBarPaddingBottomOverride
    property alias stagedFontFamilyOverride: settingsTransaction.stagedFontFamilyOverride
    property alias stagedWallpaperTransitionType: settingsTransaction.stagedWallpaperTransitionType
    property alias stagedWallpaperTransitionDuration: settingsTransaction.stagedWallpaperTransitionDuration
    property alias stagedWallpaperTransitionFps: settingsTransaction.stagedWallpaperTransitionFps
    property alias stagedWallpaperTransitionAngle: settingsTransaction.stagedWallpaperTransitionAngle
    property alias stagedWallpaperTransitionPos: settingsTransaction.stagedWallpaperTransitionPos
    property alias stagedWallpapersPath: settingsTransaction.stagedWallpapersPath
    property alias stagedSettingsWindowDefaultWidth: settingsTransaction.stagedSettingsWindowDefaultWidth
    property alias stagedSettingsWindowDefaultHeight: settingsTransaction.stagedSettingsWindowDefaultHeight
    property alias stagedNotifCorner: settingsTransaction.stagedNotifCorner
    property alias stagedNotifOffsetX: settingsTransaction.stagedNotifOffsetX
    property alias stagedNotifOffsetY: settingsTransaction.stagedNotifOffsetY
    property alias stagedDesktopClockEnabled: settingsTransaction.stagedDesktopClockEnabled
    property alias stagedDesktopClockCorner: settingsTransaction.stagedDesktopClockCorner
    property alias stagedDesktopClockOffsetX: settingsTransaction.stagedDesktopClockOffsetX
    property alias stagedDesktopClockOffsetY: settingsTransaction.stagedDesktopClockOffsetY
    property alias stagedDesktopClockMonitor: settingsTransaction.stagedDesktopClockMonitor
    property alias stagedDesktopClockUseThemeColor: settingsTransaction.stagedDesktopClockUseThemeColor
    property alias stagedDesktopClockCustomColor: settingsTransaction.stagedDesktopClockCustomColor
    property alias stagedDesktopClockShadowEnabled: settingsTransaction.stagedDesktopClockShadowEnabled
    property alias stagedDesktopClockShadowUseThemeColor: settingsTransaction.stagedDesktopClockShadowUseThemeColor
    property alias stagedDesktopClockShadowCustomColor: settingsTransaction.stagedDesktopClockShadowCustomColor
    property alias stagedDesktopClockShowWeatherIcon: settingsTransaction.stagedDesktopClockShowWeatherIcon
    property alias stagedDesktopClockShowTemperature: settingsTransaction.stagedDesktopClockShowTemperature
    property alias stagedDesktopClockScale: settingsTransaction.stagedDesktopClockScale
    property alias stagedDesktopClockShadowStrength: settingsTransaction.stagedDesktopClockShadowStrength
    property alias stagedDesktopClockShadowOffsetX: settingsTransaction.stagedDesktopClockShadowOffsetX
    property alias stagedDesktopClockShadowOffsetY: settingsTransaction.stagedDesktopClockShadowOffsetY

    readonly property string shownTheme: settingsTransaction.shownTheme
    readonly property real shownFontScale: settingsTransaction.shownFontScale
    readonly property int shownBarBorderWidthOverride: settingsTransaction.shownBarBorderWidthOverride
    readonly property bool shownBarBorderUseThemeColor: settingsTransaction.shownBarBorderUseThemeColor
    readonly property string shownBarBorderCustomColor: settingsTransaction.shownBarBorderCustomColor
    readonly property int shownBarPaddingTopOverride: settingsTransaction.shownBarPaddingTopOverride
    readonly property int shownBarPaddingSideOverride: settingsTransaction.shownBarPaddingSideOverride
    readonly property int shownBarPaddingBottomOverride: settingsTransaction.shownBarPaddingBottomOverride
    readonly property string shownFontFamilyOverride: settingsTransaction.shownFontFamilyOverride
    readonly property string shownWallpaperTransitionType: settingsTransaction.shownWallpaperTransitionType
    readonly property real shownWallpaperTransitionDuration: settingsTransaction.shownWallpaperTransitionDuration
    readonly property int shownWallpaperTransitionFps: settingsTransaction.shownWallpaperTransitionFps
    readonly property real shownWallpaperTransitionAngle: settingsTransaction.shownWallpaperTransitionAngle
    readonly property string shownWallpaperTransitionPos: settingsTransaction.shownWallpaperTransitionPos
    readonly property string shownWallpapersPath: settingsTransaction.shownWallpapersPath
    readonly property int shownSettingsWindowDefaultWidth: settingsTransaction.shownSettingsWindowDefaultWidth
    readonly property int shownSettingsWindowDefaultHeight: settingsTransaction.shownSettingsWindowDefaultHeight
    readonly property bool shownNotifShowAppName: settingsTransaction.shownNotifShowAppName
    readonly property int shownNotifIconSize: settingsTransaction.shownNotifIconSize
    readonly property int shownNotifBodyLines: settingsTransaction.shownNotifBodyLines
    readonly property real shownNotifFontScale: settingsTransaction.shownNotifFontScale
    readonly property int shownHyprGapsIn: settingsTransaction.shownHyprGapsIn
    readonly property int shownHyprGapsOut: settingsTransaction.shownHyprGapsOut
    readonly property int shownHyprBorderSize: settingsTransaction.shownHyprBorderSize
    readonly property int shownHyprRounding: settingsTransaction.shownHyprRounding
    readonly property bool shownHyprActiveBorderUseThemeColor: settingsTransaction.shownHyprActiveBorderUseThemeColor
    readonly property string shownHyprActiveBorderCustomColor: settingsTransaction.shownHyprActiveBorderCustomColor
    readonly property string shownNotifCorner: settingsTransaction.shownNotifCorner
    readonly property int shownNotifOffsetX: settingsTransaction.shownNotifOffsetX
    readonly property int shownNotifOffsetY: settingsTransaction.shownNotifOffsetY
    readonly property bool shownDesktopClockEnabled: settingsTransaction.shownDesktopClockEnabled
    readonly property string shownDesktopClockCorner: settingsTransaction.shownDesktopClockCorner
    readonly property int shownDesktopClockOffsetX: settingsTransaction.shownDesktopClockOffsetX
    readonly property int shownDesktopClockOffsetY: settingsTransaction.shownDesktopClockOffsetY
    readonly property string shownDesktopClockMonitor: settingsTransaction.shownDesktopClockMonitor
    readonly property bool shownDesktopClockUseThemeColor: settingsTransaction.shownDesktopClockUseThemeColor
    readonly property string shownDesktopClockCustomColor: settingsTransaction.shownDesktopClockCustomColor
    readonly property bool shownDesktopClockShadowEnabled: settingsTransaction.shownDesktopClockShadowEnabled
    readonly property bool shownDesktopClockShadowUseThemeColor: settingsTransaction.shownDesktopClockShadowUseThemeColor
    readonly property string shownDesktopClockShadowCustomColor: settingsTransaction.shownDesktopClockShadowCustomColor
    readonly property bool shownDesktopClockShowWeatherIcon: settingsTransaction.shownDesktopClockShowWeatherIcon
    readonly property bool shownDesktopClockShowTemperature: settingsTransaction.shownDesktopClockShowTemperature
    readonly property real shownDesktopClockScale: settingsTransaction.shownDesktopClockScale
    readonly property int shownDesktopClockShadowStrength: settingsTransaction.shownDesktopClockShadowStrength
    readonly property int shownDesktopClockShadowOffsetX: settingsTransaction.shownDesktopClockShadowOffsetX
    readonly property int shownDesktopClockShadowOffsetY: settingsTransaction.shownDesktopClockShadowOffsetY
    readonly property var changes: settingsTransaction.changes

    function discardStaged(): void {
        themeDropdownOpen = false;
        fontFamilyDropdownOpen = false;
        wallpaperTransitionTypeDropdownOpen = false;
        closeColorPicker();
        settingsTransaction.discardStaged();
    }

    // Segmented-picker option lists. Corners are plain-unicode arrows
    // (project convention: plain unicode over Nerd glyphs where
    // possible) — self-evident for corners, compact enough that five
    // cells + a label fit the fixed content width at fontScale 1.0.
    readonly property var notifCornerOptions: [
        { value: "top-left", text: "↖" }, { value: "top-right", text: "↗" },
        { value: "bottom-left", text: "↙" }, { value: "bottom-right", text: "↘" }
    ]
    readonly property var clockCornerOptions: [
        { value: "top-left", text: "↖" }, { value: "top-right", text: "↗" },
        { value: "bottom-left", text: "↙" }, { value: "bottom-right", text: "↘" },
        { value: "centered", text: "◎" }
    ]
    // Full awww/swww --transition-type set (verified against swww
    // source — see UserPrefs.qml's DESIGN NOTES on this same list).
    // Flat string array, same shape as Theme.themeNames — the dropdown
    // recipe below was written generically enough to reuse as-is.
    readonly property var wallpaperTransitionTypeOptions: [
        "simple", "fade", "wipe", "wave", "grow", "outer", "any", "random",
        "left", "right", "top", "bottom", "center", "none"
    ]
    // Same 5-symbol vocabulary as clockCornerOptions (center included,
    // since grow/outer's circle can start dead-center same as any
    // corner) — only shown when the transition type is grow/outer.
    readonly property var wallpaperTransitionPosOptions: [
        { value: "center", text: "◎" },
        { value: "top-left", text: "↖" }, { value: "top-right", text: "↗" },
        { value: "bottom-left", text: "↙" }, { value: "bottom-right", text: "↘" }
    ]
    // "All" + one option per live monitor. Quickshell.screens is a
    // list property — index/length work in JS, array methods (map)
    // are not guaranteed, hence the loop. A saved name for a monitor
    // that's currently unplugged still applies (UserPrefs allows it);
    // it just won't show as a cell here until the monitor is back.
    readonly property var monitorOptions: {
        const opts = [{ value: "", text: "All" }];
        const scr = Quickshell.screens;
        for (let i = 0; i < scr.length; i++)
            opts.push({ value: scr[i].name, text: scr[i].name });
        return opts;
    }

    // Font list is DERIVED from Qt.fontFamilies() at runtime, not
    // hardcoded (2026-07-12, Opus). Two earlier approaches failed:
    // (1) the raw Qt.fontFamilies() dump was 150-300+ entries,
    // unusable; (2) a hardcoded curated list of nice names rendered
    // NOTHING when picked, because the exact strings I typed
    // ("JetBrainsMono Nerd Font", etc.) did not match whatever Qt
    // actually reports on this machine — so font.family was set to a
    // name Qt couldn't resolve and silently fell back to default (the
    // "pick a font, nothing changes" bug). The tell was an exact-match
    // filter surviving only ONE family (CaskaydiaCove, the theme
    // default). The robust fix: take the strings Qt REALLY exposes and
    // just trim them. We keep families whose name ends in "Nerd Font"
    // (the base variant — this drops the "... Nerd Font Mono" and
    // "... Nerd Font Propo" spin-offs and every weight-suffixed
    // sub-family like "FiraCode Nerd Font Med"). Because every entry
    // shown is a verbatim Qt string, selecting it is guaranteed to
    // resolve and render. If the base-variant filter ever hides
    // something you want, widen the regex below.
    //
    // preferredOrder just floats the popular rice picks to the top;
    // anything installed but not listed here still shows, alphabetically,
    // after the preferred block.
    readonly property var preferredFontOrder: [
        "CaskaydiaCove Nerd Font",
        "JetBrainsMono Nerd Font",
        "FiraCode Nerd Font",
        "Hack Nerd Font",
        "Iosevka Nerd Font",
        "MesloLGS Nerd Font",
        "SauceCodePro Nerd Font",
        "RobotoMono Nerd Font",
        "UbuntuMono Nerd Font",
        "Inconsolata Nerd Font"
    ]

    readonly property var fontFamilyOptions: {
        const all = Qt.fontFamilies().slice();   // real array (list-property caveat)
        const bases = [];
        for (let i = 0; i < all.length; i++) {
            const f = String(all[i]);
            // Base Nerd Font variant only: ends in "Nerd Font".
            if (/Nerd Font$/.test(f) && bases.indexOf(f) === -1)
                bases.push(f);
        }
        bases.sort();
        // Stable-partition into preferred-first, then the rest.
        const pref = [];
        for (let j = 0; j < root.preferredFontOrder.length; j++)
            if (bases.indexOf(root.preferredFontOrder[j]) !== -1)
                pref.push(root.preferredFontOrder[j]);
        const rest = bases.filter(f => pref.indexOf(f) === -1);
        return [""].concat(pref).concat(rest);
    }

    // Displays is intentionally deferred until a real DisplayManager service exists.

    // GPT: Captured creation geometry lets shell.qml determine whether this
    // hidden window must be recreated before the next open. ProxyFloatingWindow
    // owns its real size; setting width/height directly is deprecated.
    property int createdDefaultWidth: 0
    property int createdDefaultHeight: 0

    Component.onCompleted: {
        createdDefaultWidth = UserPrefs.settingsWindowDefaultWidth;
        createdDefaultHeight = UserPrefs.settingsWindowDefaultHeight;
    }

    function open(): void {
        shown = true;
        // Daily snapshot on settings open (plan's retention design).
        // Skipped silently if the engine is mid-op (e.g. the Original
        // Backup on a fresh first launch) — tomorrow's open gets it.
        if (ConfigManager.busy === "")
            ConfigManager.dailySnapshotIfNeeded();
    }

    function close(): void {
        shown = false;
        discardStaged();          // close discards — see DESIGN NOTES
    }
    function toggle(): void { if (shown) close(); else open(); }

    // GPT Rev 21: Apply is delegated to SettingsTransaction.
    function resolvedHyprBorderForApply(): var {
        return settingsTransaction.resolvedHyprBorderForApply();
    }

    // GPT Rev 24: used by UI Profiles after restoring UserPrefs from disk.
    function reapplyCurrentHyprland(): bool {
        return settingsTransaction.reapplyCurrentHyprland();
    }

    function apply(): void {
        settingsTransaction.apply();
        themeDropdownOpen = false;
        fontFamilyDropdownOpen = false;
        wallpaperTransitionTypeDropdownOpen = false;
        closeColorPicker();
    }

    visible: shown

    onShownChanged: {
        if (shown)
            keyCatcher.forceActiveFocus();
    }
    onClosed: {
        if (shown)
            close();
    }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
    }

    SettingsComponents.SettingsView {
        anchors.fill: parent
        settingsRoot: root
    }

}
