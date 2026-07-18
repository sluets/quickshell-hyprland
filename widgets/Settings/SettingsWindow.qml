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
// rounding), Displays (per-monitor mode/scale, its own transaction —
// DISABLED 2026-07-12, block-commented pending a real
// services/DisplayManager.qml; see the `pages` property) —
// and the full transaction UX the plan promised: changes are STAGED,
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
//      changed — and the things that appear mid-interaction (revealed
//      rows, the Displays diff) all appear BELOW the control that
//      triggered them.
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
    // "Displays" temporarily removed (2026-07-12) — DisplayManager.qml
    // was never actually wired up/written, so the page has always
    // thrown ReferenceErrors at runtime. Page body + supporting
    // functions are still below, block-commented rather than
    // deleted — re-add "Displays" here once DisplayManager exists.
    readonly property var pages: ["Appearance", "Notifications", "Desktop", "Hyprland", "SDDM"]

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
    // enough for the widest page (Displays, formerly minimum 420);
    // anything longer elides rather than widening the card.
    readonly property int contentWidth: Math.round(Theme.fontSize * 52)
    readonly property int sidebarWidth: Math.round(Theme.fontSize * 14)
    // Reserved space beside scrollable pages so full-width controls and
    // their card-level dropdown overlays never sit beneath the scroll thumb.
    readonly property int pageScrollGutter: Math.max(24, Math.round(Theme.fontSize * 1.5))
    // How many diff rows the pending panel shows before it scrolls.
    // The panel reserves exactly this many rows at ALL times — that
    // fixed reservation is the whole point.
    readonly property int pendingVisibleLines: 4

    // Live monitor state is re-read every time the Displays page comes
    // into view (it can change under us — cables, games flipping
    // modes), not once per window open.
    onCurrentPageChanged: {
        // Displays page disabled (see `pages` above) — DisplayManager
        // doesn't exist yet.
        // if (currentPage === "Displays")
        //     DisplayManager.refresh();
    }

    // ---- Staged (uncommitted) values. null = not staged. ----
    property var stagedTheme: null
    property var stagedFontScale: null
    property var stagedNotifShowAppName: null
    property var stagedNotifIconSize: null
    property var stagedNotifBodyLines: null
    property var stagedNotifFontScale: null
    property var stagedHyprGapsIn: null
    property var stagedHyprGapsOut: null
    property var stagedHyprBorderSize: null
    property var stagedHyprRounding: null
    property var stagedHyprActiveBorderUseThemeColor: null
    property var stagedHyprActiveBorderCustomColor: null
    property var stagedBarBorderWidthOverride: null
    property var stagedBarBorderUseThemeColor: null
    property var stagedBarBorderCustomColor: null
    property var stagedBarPaddingTopOverride: null
    property var stagedBarPaddingSideOverride: null
    property var stagedBarPaddingBottomOverride: null
    property var stagedFontFamilyOverride: null
    property var stagedWallpaperTransitionType: null
    property var stagedWallpaperTransitionDuration: null
    property var stagedWallpaperTransitionFps: null
    property var stagedWallpaperTransitionAngle: null
    property var stagedWallpaperTransitionPos: null
    property var stagedWallpapersPath: null
    property var stagedSettingsWindowDefaultWidth: null
    property var stagedSettingsWindowDefaultHeight: null
    property var stagedNotifCorner: null
    property var stagedNotifOffsetX: null
    property var stagedNotifOffsetY: null
    property var stagedDesktopClockEnabled: null
    property var stagedDesktopClockCorner: null
    property var stagedDesktopClockOffsetX: null
    property var stagedDesktopClockOffsetY: null
    property var stagedDesktopClockMonitor: null
    property var stagedDesktopClockUseThemeColor: null
    property var stagedDesktopClockCustomColor: null
    property var stagedDesktopClockShadowEnabled: null
    property var stagedDesktopClockShadowUseThemeColor: null
    property var stagedDesktopClockShadowCustomColor: null
    property var stagedDesktopClockShowWeatherIcon: null
    property var stagedDesktopClockShowTemperature: null
    property var stagedDesktopClockScale: null
    property var stagedDesktopClockShadowStrength: null
    property var stagedDesktopClockShadowOffsetX: null
    property var stagedDesktopClockShadowOffsetY: null

    // Effective values the UI highlights: staged if present, else live.
    readonly property string shownTheme: stagedTheme !== null ? stagedTheme : UserPrefs.themeName
    readonly property real shownFontScale: stagedFontScale !== null ? stagedFontScale : UserPrefs.fontScale
    readonly property int shownBarBorderWidthOverride: stagedBarBorderWidthOverride !== null ? stagedBarBorderWidthOverride : UserPrefs.barBorderWidthOverride
    readonly property bool shownBarBorderUseThemeColor: stagedBarBorderUseThemeColor !== null ? stagedBarBorderUseThemeColor : UserPrefs.barBorderUseThemeColor
    readonly property string shownBarBorderCustomColor: stagedBarBorderCustomColor !== null ? stagedBarBorderCustomColor : UserPrefs.barBorderCustomColor
    readonly property int shownBarPaddingTopOverride: stagedBarPaddingTopOverride !== null ? stagedBarPaddingTopOverride : UserPrefs.barPaddingTopOverride
    readonly property int shownBarPaddingSideOverride: stagedBarPaddingSideOverride !== null ? stagedBarPaddingSideOverride : UserPrefs.barPaddingSideOverride
    readonly property int shownBarPaddingBottomOverride: stagedBarPaddingBottomOverride !== null ? stagedBarPaddingBottomOverride : UserPrefs.barPaddingBottomOverride
    readonly property string shownFontFamilyOverride: stagedFontFamilyOverride !== null ? stagedFontFamilyOverride : UserPrefs.fontFamilyOverride
    readonly property string shownWallpaperTransitionType: stagedWallpaperTransitionType !== null ? stagedWallpaperTransitionType : UserPrefs.wallpaperTransitionType
    readonly property real shownWallpaperTransitionDuration: stagedWallpaperTransitionDuration !== null ? stagedWallpaperTransitionDuration : UserPrefs.wallpaperTransitionDuration
    readonly property int shownWallpaperTransitionFps: stagedWallpaperTransitionFps !== null ? stagedWallpaperTransitionFps : UserPrefs.wallpaperTransitionFps
    readonly property real shownWallpaperTransitionAngle: stagedWallpaperTransitionAngle !== null ? stagedWallpaperTransitionAngle : UserPrefs.wallpaperTransitionAngle
    readonly property string shownWallpaperTransitionPos: stagedWallpaperTransitionPos !== null ? stagedWallpaperTransitionPos : UserPrefs.wallpaperTransitionPos
    readonly property string shownWallpapersPath: stagedWallpapersPath !== null ? stagedWallpapersPath : UserPrefs.wallpapersPath
    readonly property int shownSettingsWindowDefaultWidth: stagedSettingsWindowDefaultWidth !== null ? stagedSettingsWindowDefaultWidth : UserPrefs.settingsWindowDefaultWidth
    readonly property int shownSettingsWindowDefaultHeight: stagedSettingsWindowDefaultHeight !== null ? stagedSettingsWindowDefaultHeight : UserPrefs.settingsWindowDefaultHeight
    readonly property bool shownNotifShowAppName: stagedNotifShowAppName !== null ? stagedNotifShowAppName : UserPrefs.notifShowAppName
    readonly property int shownNotifIconSize: stagedNotifIconSize !== null ? stagedNotifIconSize : UserPrefs.notifIconSize
    readonly property int shownNotifBodyLines: stagedNotifBodyLines !== null ? stagedNotifBodyLines : UserPrefs.notifBodyLines
    readonly property real shownNotifFontScale: stagedNotifFontScale !== null ? stagedNotifFontScale : UserPrefs.notifFontScale
    readonly property int shownHyprGapsIn: stagedHyprGapsIn !== null ? stagedHyprGapsIn : UserPrefs.hyprGapsIn
    readonly property int shownHyprGapsOut: stagedHyprGapsOut !== null ? stagedHyprGapsOut : UserPrefs.hyprGapsOut
    readonly property int shownHyprBorderSize: stagedHyprBorderSize !== null ? stagedHyprBorderSize : UserPrefs.hyprBorderSize
    readonly property int shownHyprRounding: stagedHyprRounding !== null ? stagedHyprRounding : UserPrefs.hyprRounding
    readonly property bool shownHyprActiveBorderUseThemeColor: stagedHyprActiveBorderUseThemeColor !== null ? stagedHyprActiveBorderUseThemeColor : UserPrefs.hyprActiveBorderUseThemeColor
    readonly property string shownHyprActiveBorderCustomColor: stagedHyprActiveBorderCustomColor !== null ? stagedHyprActiveBorderCustomColor : UserPrefs.hyprActiveBorderCustomColor
    readonly property string shownNotifCorner: stagedNotifCorner !== null ? stagedNotifCorner : UserPrefs.notifCorner
    readonly property int shownNotifOffsetX: stagedNotifOffsetX !== null ? stagedNotifOffsetX : UserPrefs.notifOffsetX
    readonly property int shownNotifOffsetY: stagedNotifOffsetY !== null ? stagedNotifOffsetY : UserPrefs.notifOffsetY
    readonly property bool shownDesktopClockEnabled: stagedDesktopClockEnabled !== null ? stagedDesktopClockEnabled : UserPrefs.desktopClockEnabled
    readonly property string shownDesktopClockCorner: stagedDesktopClockCorner !== null ? stagedDesktopClockCorner : UserPrefs.desktopClockCorner
    readonly property int shownDesktopClockOffsetX: stagedDesktopClockOffsetX !== null ? stagedDesktopClockOffsetX : UserPrefs.desktopClockOffsetX
    readonly property int shownDesktopClockOffsetY: stagedDesktopClockOffsetY !== null ? stagedDesktopClockOffsetY : UserPrefs.desktopClockOffsetY
    readonly property string shownDesktopClockMonitor: stagedDesktopClockMonitor !== null ? stagedDesktopClockMonitor : UserPrefs.desktopClockMonitor
    readonly property bool shownDesktopClockUseThemeColor: stagedDesktopClockUseThemeColor !== null ? stagedDesktopClockUseThemeColor : UserPrefs.desktopClockUseThemeColor
    readonly property string shownDesktopClockCustomColor: stagedDesktopClockCustomColor !== null ? stagedDesktopClockCustomColor : UserPrefs.desktopClockCustomColor
    readonly property bool shownDesktopClockShadowEnabled: stagedDesktopClockShadowEnabled !== null ? stagedDesktopClockShadowEnabled : UserPrefs.desktopClockShadowEnabled
    readonly property bool shownDesktopClockShadowUseThemeColor: stagedDesktopClockShadowUseThemeColor !== null ? stagedDesktopClockShadowUseThemeColor : UserPrefs.desktopClockShadowUseThemeColor
    readonly property string shownDesktopClockShadowCustomColor: stagedDesktopClockShadowCustomColor !== null ? stagedDesktopClockShadowCustomColor : UserPrefs.desktopClockShadowCustomColor
    readonly property bool shownDesktopClockShowWeatherIcon: stagedDesktopClockShowWeatherIcon !== null ? stagedDesktopClockShowWeatherIcon : UserPrefs.desktopClockShowWeatherIcon
    readonly property bool shownDesktopClockShowTemperature: stagedDesktopClockShowTemperature !== null ? stagedDesktopClockShowTemperature : UserPrefs.desktopClockShowTemperature
    readonly property real shownDesktopClockScale: stagedDesktopClockScale !== null ? stagedDesktopClockScale : UserPrefs.desktopClockScale
    readonly property int shownDesktopClockShadowStrength: stagedDesktopClockShadowStrength !== null ? stagedDesktopClockShadowStrength : UserPrefs.desktopClockShadowStrength
    readonly property int shownDesktopClockShadowOffsetX: stagedDesktopClockShadowOffsetX !== null ? stagedDesktopClockShadowOffsetX : UserPrefs.desktopClockShadowOffsetX
    readonly property int shownDesktopClockShadowOffsetY: stagedDesktopClockShadowOffsetY !== null ? stagedDesktopClockShadowOffsetY : UserPrefs.desktopClockShadowOffsetY

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

    // The diff — what the pending panel lists and Apply commits.
    readonly property var changes: {
        const c = [];
        if (stagedTheme !== null && stagedTheme !== UserPrefs.themeName)
            c.push({ key: "themeName", label: "Theme",
                     from: UserPrefs.themeName, to: stagedTheme,
                     value: stagedTheme });
        if (stagedFontScale !== null
                && Math.abs(stagedFontScale - UserPrefs.fontScale) > 0.001)
            c.push({ key: "fontScale", label: "Font Scale",
                     from: UserPrefs.fontScale.toFixed(1),
                     to: stagedFontScale.toFixed(1),
                     value: stagedFontScale });
        if (stagedBarBorderWidthOverride !== null
                && stagedBarBorderWidthOverride !== UserPrefs.barBorderWidthOverride)
            c.push({ key: "barBorderWidthOverride", label: "Bar Border Width",
                     from: UserPrefs.barBorderWidthOverride < 0 ? "theme"
                           : UserPrefs.barBorderWidthOverride + " px",
                     to: stagedBarBorderWidthOverride < 0 ? "theme"
                         : stagedBarBorderWidthOverride + " px",
                     value: stagedBarBorderWidthOverride });
        if (stagedBarBorderUseThemeColor !== null
                && stagedBarBorderUseThemeColor !== UserPrefs.barBorderUseThemeColor)
            c.push({ key: "barBorderUseThemeColor", label: "Bar Border Color",
                     from: UserPrefs.barBorderUseThemeColor ? "theme" : "custom",
                     to: stagedBarBorderUseThemeColor ? "theme" : "custom",
                     value: stagedBarBorderUseThemeColor });
        if (stagedBarBorderCustomColor !== null
                && stagedBarBorderCustomColor !== UserPrefs.barBorderCustomColor)
            c.push({ key: "barBorderCustomColor", label: "Bar Border Hex",
                     from: UserPrefs.barBorderCustomColor,
                     to: stagedBarBorderCustomColor,
                     value: stagedBarBorderCustomColor });
        const barPadPairs = [
            ["barPaddingTopOverride", "Bar Padding Top", UserPrefs.barPaddingTopOverride, stagedBarPaddingTopOverride, -1],
            ["barPaddingSideOverride", "Bar Padding Sides", UserPrefs.barPaddingSideOverride, stagedBarPaddingSideOverride, -1],
            ["barPaddingBottomOverride", "Bar Padding Bottom", UserPrefs.barPaddingBottomOverride, stagedBarPaddingBottomOverride, UserPrefs.barPaddingBottomOffSentinel]
        ];
        for (let i = 0; i < barPadPairs.length; i++) {
            const [key, label, live, staged, offSentinel] = barPadPairs[i];
            if (staged !== null && staged !== live)
                c.push({ key: key, label: label,
                         from: live <= offSentinel ? "theme" : live + " px",
                         to: staged <= offSentinel ? "theme" : staged + " px",
                         value: staged });
        }
        if (stagedFontFamilyOverride !== null
                && stagedFontFamilyOverride !== UserPrefs.fontFamilyOverride)
            c.push({ key: "fontFamilyOverride", label: "Font Family",
                     from: UserPrefs.fontFamilyOverride === "" ? "theme" : UserPrefs.fontFamilyOverride,
                     to: stagedFontFamilyOverride === "" ? "theme" : stagedFontFamilyOverride,
                     value: stagedFontFamilyOverride });
        if (stagedNotifShowAppName !== null
                && stagedNotifShowAppName !== UserPrefs.notifShowAppName)
            c.push({ key: "notifShowAppName", label: "Notif App Name",
                     from: UserPrefs.notifShowAppName ? "shown" : "hidden",
                     to: stagedNotifShowAppName ? "shown" : "hidden",
                     value: stagedNotifShowAppName });
        if (stagedNotifIconSize !== null
                && stagedNotifIconSize !== UserPrefs.notifIconSize)
            c.push({ key: "notifIconSize", label: "Notif Icon Size",
                     from: UserPrefs.notifIconSize + " px",
                     to: stagedNotifIconSize + " px",
                     value: stagedNotifIconSize });
        if (stagedNotifBodyLines !== null
                && stagedNotifBodyLines !== UserPrefs.notifBodyLines)
            c.push({ key: "notifBodyLines", label: "Notif Body Lines",
                     from: String(UserPrefs.notifBodyLines),
                     to: String(stagedNotifBodyLines),
                     value: stagedNotifBodyLines });
        if (stagedNotifFontScale !== null
                && Math.abs(stagedNotifFontScale - UserPrefs.notifFontScale) > 0.001)
            c.push({ key: "notifFontScale", label: "Notif Font Scale",
                     from: UserPrefs.notifFontScale.toFixed(1),
                     to: stagedNotifFontScale.toFixed(1),
                     value: stagedNotifFontScale });
        const hyprPairs = [
            ["hyprGapsIn", "Gaps In", UserPrefs.hyprGapsIn, stagedHyprGapsIn],
            ["hyprGapsOut", "Gaps Out", UserPrefs.hyprGapsOut, stagedHyprGapsOut],
            ["hyprBorderSize", "Border Size", UserPrefs.hyprBorderSize, stagedHyprBorderSize],
            ["hyprRounding", "Rounding", UserPrefs.hyprRounding, stagedHyprRounding]
        ];
        for (let i = 0; i < hyprPairs.length; i++) {
            const [key, label, live, staged] = hyprPairs[i];
            if (staged !== null && staged !== live)
                c.push({ key: key, label: label,
                         from: String(live), to: String(staged),
                         value: staged });
        }
        if (stagedHyprActiveBorderUseThemeColor !== null
                && stagedHyprActiveBorderUseThemeColor !== UserPrefs.hyprActiveBorderUseThemeColor)
            c.push({ key: "hyprActiveBorderUseThemeColor", label: "Active Border Color",
                     from: UserPrefs.hyprActiveBorderUseThemeColor ? "theme" : "custom",
                     to: stagedHyprActiveBorderUseThemeColor ? "theme" : "custom",
                     value: stagedHyprActiveBorderUseThemeColor });
        if (stagedHyprActiveBorderCustomColor !== null
                && stagedHyprActiveBorderCustomColor !== UserPrefs.hyprActiveBorderCustomColor)
            c.push({ key: "hyprActiveBorderCustomColor", label: "Active Border Hex",
                     from: UserPrefs.hyprActiveBorderCustomColor,
                     to: stagedHyprActiveBorderCustomColor,
                     value: stagedHyprActiveBorderCustomColor });
        // Notif position + desktop clock (2026-07-11): same pattern as
        // hyprPairs, with a per-row formatter for the mixed types.
        const fmtPx = v => v + " px";
        const fmtOnOff = v => v ? "on" : "off";
        const fmtThemeCustom = v => v ? "theme" : "custom";
        const fmtMonitor = v => v === "" ? "all" : v;
        const fmtRaw = v => String(v);
        const fmtSecs = v => v.toFixed(1) + "s";
        const fmtFps = v => v + " fps";
        const fmtDeg = v => Math.round(v) + "°";
        const fmtPairs = [
            ["notifCorner", "Notif Corner", UserPrefs.notifCorner, stagedNotifCorner, fmtRaw],
            ["notifOffsetX", "Notif Offset X", UserPrefs.notifOffsetX, stagedNotifOffsetX, fmtPx],
            ["notifOffsetY", "Notif Offset Y", UserPrefs.notifOffsetY, stagedNotifOffsetY, fmtPx],
            ["desktopClockEnabled", "Clock Enabled", UserPrefs.desktopClockEnabled, stagedDesktopClockEnabled, fmtOnOff],
            ["desktopClockCorner", "Clock Corner", UserPrefs.desktopClockCorner, stagedDesktopClockCorner, fmtRaw],
            ["desktopClockOffsetX", "Clock Offset X", UserPrefs.desktopClockOffsetX, stagedDesktopClockOffsetX, fmtPx],
            ["desktopClockOffsetY", "Clock Offset Y", UserPrefs.desktopClockOffsetY, stagedDesktopClockOffsetY, fmtPx],
            ["desktopClockMonitor", "Clock Monitor", UserPrefs.desktopClockMonitor, stagedDesktopClockMonitor, fmtMonitor],
            ["desktopClockUseThemeColor", "Clock Color", UserPrefs.desktopClockUseThemeColor, stagedDesktopClockUseThemeColor, fmtThemeCustom],
            ["desktopClockCustomColor", "Clock Hex", UserPrefs.desktopClockCustomColor, stagedDesktopClockCustomColor, fmtRaw],
            ["desktopClockShadowEnabled", "Clock Shadow", UserPrefs.desktopClockShadowEnabled, stagedDesktopClockShadowEnabled, fmtOnOff],
            ["desktopClockShadowUseThemeColor", "Shadow Color", UserPrefs.desktopClockShadowUseThemeColor, stagedDesktopClockShadowUseThemeColor, fmtThemeCustom],
            ["desktopClockShadowCustomColor", "Shadow Hex", UserPrefs.desktopClockShadowCustomColor, stagedDesktopClockShadowCustomColor, fmtRaw],
            ["desktopClockShowWeatherIcon", "Weather Icon", UserPrefs.desktopClockShowWeatherIcon, stagedDesktopClockShowWeatherIcon, fmtOnOff],
            ["desktopClockShowTemperature", "Temperature", UserPrefs.desktopClockShowTemperature, stagedDesktopClockShowTemperature, fmtOnOff],
            ["desktopClockScale", "Clock Scale", UserPrefs.desktopClockScale, stagedDesktopClockScale, v => v.toFixed(2) + "x"],
            ["desktopClockShadowStrength", "Shadow Strength", UserPrefs.desktopClockShadowStrength, stagedDesktopClockShadowStrength, v => v + "%"],
            ["desktopClockShadowOffsetX", "Shadow X Offset", UserPrefs.desktopClockShadowOffsetX, stagedDesktopClockShadowOffsetX, v => v + " px"],
            ["desktopClockShadowOffsetY", "Shadow Y Offset", UserPrefs.desktopClockShadowOffsetY, stagedDesktopClockShadowOffsetY, v => v + " px"],
            ["wallpaperTransitionType", "Transition Type", UserPrefs.wallpaperTransitionType, stagedWallpaperTransitionType, fmtRaw],
            ["wallpaperTransitionDuration", "Transition Duration", UserPrefs.wallpaperTransitionDuration, stagedWallpaperTransitionDuration, fmtSecs],
            ["wallpaperTransitionFps", "Transition FPS", UserPrefs.wallpaperTransitionFps, stagedWallpaperTransitionFps, fmtFps],
            ["wallpaperTransitionAngle", "Transition Angle", UserPrefs.wallpaperTransitionAngle, stagedWallpaperTransitionAngle, fmtDeg],
            ["wallpaperTransitionPos", "Transition Position", UserPrefs.wallpaperTransitionPos, stagedWallpaperTransitionPos, fmtRaw],
            ["wallpapersPath", "Wallpaper Library", UserPrefs.wallpapersPath, stagedWallpapersPath, fmtRaw],
            ["settingsWindowDefaultWidth", "Settings Default Width", UserPrefs.settingsWindowDefaultWidth, stagedSettingsWindowDefaultWidth, fmtPx],
            ["settingsWindowDefaultHeight", "Settings Default Height", UserPrefs.settingsWindowDefaultHeight, stagedSettingsWindowDefaultHeight, fmtPx]
        ];
        for (let i = 0; i < fmtPairs.length; i++) {
            const [key, label, live, staged, fmt] = fmtPairs[i];
            if (staged !== null && staged !== live)
                c.push({ key: key, label: label,
                         from: fmt(live), to: fmt(staged),
                         value: staged });
        }
        return c;
    }

    function discardStaged(): void {
        themeDropdownOpen = false;
        fontFamilyDropdownOpen = false;
        wallpaperTransitionTypeDropdownOpen = false;
        closeColorPicker();
        stagedTheme = null;
        stagedFontScale = null;
        stagedBarPaddingTopOverride = null;
        stagedBarPaddingSideOverride = null;
        stagedBarPaddingBottomOverride = null;
        stagedFontFamilyOverride = null;
        stagedNotifShowAppName = null;
        stagedNotifIconSize = null;
        stagedNotifBodyLines = null;
        stagedNotifFontScale = null;
        stagedHyprGapsIn = null;
        stagedHyprGapsOut = null;
        stagedHyprBorderSize = null;
        stagedHyprRounding = null;
        stagedHyprActiveBorderUseThemeColor = null;
        stagedHyprActiveBorderCustomColor = null;
        stagedBarBorderWidthOverride = null;
        stagedBarBorderUseThemeColor = null;
        stagedBarBorderCustomColor = null;
        stagedNotifCorner = null;
        stagedNotifOffsetX = null;
        stagedNotifOffsetY = null;
        stagedDesktopClockEnabled = null;
        stagedDesktopClockCorner = null;
        stagedDesktopClockOffsetX = null;
        stagedDesktopClockOffsetY = null;
        stagedDesktopClockMonitor = null;
        stagedDesktopClockUseThemeColor = null;
        stagedDesktopClockCustomColor = null;
        stagedDesktopClockShadowEnabled = null;
        stagedDesktopClockShadowUseThemeColor = null;
        stagedDesktopClockShadowCustomColor = null;
        stagedDesktopClockShowWeatherIcon = null;
        stagedDesktopClockShowTemperature = null;
        stagedDesktopClockScale = null;
        stagedDesktopClockShadowStrength = null;
        stagedDesktopClockShadowOffsetX = null;
        stagedDesktopClockShadowOffsetY = null;
        stagedWallpaperTransitionType = null;
        stagedWallpaperTransitionDuration = null;
        stagedWallpaperTransitionFps = null;
        stagedWallpaperTransitionAngle = null;
        stagedWallpaperTransitionPos = null;
        stagedWallpapersPath = null;
        stagedSettingsWindowDefaultWidth = null;
        stagedSettingsWindowDefaultHeight = null;
        stagedDisplays = ({});
        displayError = "";
    }

    // ---- Displays page state (see the page's comment for why this
    // is a SEPARATE transaction from the global Apply) ----
    // Map: monitor name -> { mode?, scale?, disabled? }. Always
    // REASSIGNED (never mutated in place) so bindings re-evaluate.
    property var stagedDisplays: ({})
    property string displayError: ""

    // DISPLAYS PAGE DISABLED (2026-07-12) — DisplayManager.qml was
    // never actually written, so every function below threw
    // ReferenceError at runtime the moment the page (or even just
    // `pages`, for the tab) referenced it. Block-commented rather
    // than deleted: the logic is believed correct and ready to go
    // the moment services/DisplayManager.qml exists — see
    // notes/SONNET_QUEUE.md. Un-comment this block AND the page UI
    // further down AND re-add "Displays" to `pages` above, together.
    /*
    function stageDisplay(name: string, field: string, value: var): void {
        const m = {};
        for (const k in stagedDisplays)
            m[k] = stagedDisplays[k];
        const e = m[name] ? Object.assign({}, m[name]) : {};
        e[field] = value;
        m[name] = e;
        stagedDisplays = m;
    }

    function shownDispMode(mon: var): string {
        const s = stagedDisplays[mon.name];
        return (s && s.mode !== undefined) ? s.mode : mon.currentMode;
    }
    function shownDispScale(mon: var): real {
        const s = stagedDisplays[mon.name];
        return (s && s.scale !== undefined) ? s.scale : mon.scale;
    }
    function shownDispDisabled(mon: var): bool {
        const s = stagedDisplays[mon.name];
        return (s && s.disabled !== undefined) ? s.disabled : mon.disabled;
    }

    // The Displays page's own diff (NOT part of root.changes — display
    // applies go through the revert-window transaction, not the
    // staged-prefs one).
    readonly property var displayChanges: {
        const c = [];
        const mons = DisplayManager.monitors;
        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            const s = stagedDisplays[m.name];
            if (!s)
                continue;
            if (s.disabled !== undefined && s.disabled !== m.disabled)
                c.push({ label: m.name + " Enabled",
                         from: m.disabled ? "off" : "on",
                         to: s.disabled ? "off" : "on" });
            if (s.mode !== undefined && s.mode !== m.currentMode)
                c.push({ label: m.name + " Mode",
                         from: m.currentMode, to: s.mode });
            if (s.scale !== undefined && Math.abs(s.scale - m.scale) > 0.001)
                c.push({ label: m.name + " Scale",
                         from: DisplayManager.fmtScale(m.scale),
                         to: DisplayManager.fmtScale(s.scale) });
        }
        return c;
    }

    function applyDisplays(): void {
        if (displayChanges.length === 0 || ConfigManager.busy !== ""
                || ConfigManager.revertPending)
            return;
        const mons = DisplayManager.monitors;
        const cfgs = [];
        for (let i = 0; i < mons.length; i++) {
            const m = mons[i];
            cfgs.push({
                output: m.name,
                mode: shownDispMode(m),
                // Enabled monitors keep their exact live position; a
                // monitor that was DISABLED at refresh reports garbage
                // coordinates, so on re-enable it gets "auto" (right
                // edge of the layout) — see DisplayManager's notes.
                position: m.disabled ? "auto" : (m.x + "x" + m.y),
                scale: shownDispScale(m),
                disabled: shownDispDisabled(m)
            });
        }
        if (DisplayManager.apply(cfgs)) {
            displayError = "";
            stagedDisplays = ({});
        } else {
            displayError = DisplayManager.lastError !== ""
                ? DisplayManager.lastError : ConfigManager.lastError;
        }
    }
    */
    // Stand-ins so any leftover binding elsewhere still resolves to
    // something harmless while the block above is commented out.
    readonly property var displayChanges: []
    function applyDisplays(): void {}

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
        // Displays page disabled (see `pages` above).
        // if (currentPage === "Displays")
        //     DisplayManager.refresh();
    }

    function close(): void {
        shown = false;
        discardStaged();          // close discards — see DESIGN NOTES
    }
    function toggle(): void { if (shown) close(); else open(); }

    // Capture the FINAL border appearance before the async Apply transaction
    // starts. Apply takes a snapshot first, so staged values are cleared long
    // before ConfigManager performs the writes. Passing this immutable object
    // prevents the Hyprland generator from falling back to the old saved
    // Appearance values during that gap.
    function resolvedHyprBorderForApply(): var {
        const selectedTheme = Theme.themes[shownTheme] || Theme.active;
        const followsAppearance = shownHyprActiveBorderUseThemeColor;
        const secondary = selectedTheme.barBorderColor2;
        const gradient = followsAppearance && shownBarBorderUseThemeColor
            && secondary.a > 0.001;
        return {
            useTheme: followsAppearance,
            primaryHex: shownBarBorderUseThemeColor
                ? _qColorToHyprHex(selectedTheme.barBorderColor)
                : _settingsHexToHyprHex(shownBarBorderCustomColor),
            secondaryHex: gradient ? _qColorToHyprHex(secondary) : "",
            gradient: gradient,
            angle: selectedTheme.barBorderGradientAngle,
            customHex: shownHyprActiveBorderCustomColor
        };
    }

    function apply(): void {
        if (changes.length === 0 || ConfigManager.busy !== "")
            return;
        ConfigManager.applyChanges(changes, "settings apply",
                                   resolvedHyprBorderForApply());
        // Staged values clear immediately; the resolved border object above
        // remains attached to the transaction until its writes complete.
        discardStaged();
    }

    // ---- Hyprland border conversion helpers ----
    // Theme selection and Appearance overrides are resolved synchronously by
    // resolvedHyprBorderForApply() and travel with the Apply transaction. Do
    // not restore page-local/live Bindings here: staged values are deliberately
    // discarded while ConfigManager is still taking its pre-write snapshot.
    function _chanHex(v) {
        const n = Math.round(Math.max(0, Math.min(1, v)) * 255);
        const h = n.toString(16);
        return h.length < 2 ? "0" + h : h;
    }
    function _qColorToHyprHex(c) {
        return _chanHex(c.r) + _chanHex(c.g) + _chanHex(c.b) + _chanHex(c.a);
    }
    function _settingsHexToHyprHex(hex) {
        return hex.length === 9
            ? hex.slice(3) + hex.slice(1, 3)   // #AARRGGBB -> RRGGBBAA
            : hex.slice(1) + "ff";             // #RRGGBB -> RRGGBBff
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

    // ---- Reusable page controls (QML inline components) ----

    // A −/+ value stepper. The four numeric prefs all use it.

    // A staged on/off row (■/□ like the gear popout, but staged-not-live).

    // A label + row of mutually-exclusive cells (segmented control).
    // Used for corner pickers and the clock's monitor selector — same
    // visual language as the page tabs (surface = selected, accent
    // text), but staged-not-live like every other page control.

    // A validated hex-color entry row with live swatch — extracted
    // 2026-07-11 from the Appearance page's bar-border field (the
    // window's first TextInput) when the Desktop page brought the
    // count to three; the extraction threshold this project uses.
    // Only well-formed hex ever emits hexStaged (Apply can't submit
    // garbage); border and swatch go urgent-red until the text
    // parses. RESYNC: a TextInput's `text` binding dies on the first
    // keystroke, so the Connections below puts truth back whenever
    // the shown (staged-or-live) value changes underneath — covers
    // Cancel (staged cleared -> live) and Apply (write lands ->
    // UserPrefs updates). One known cosmetic wrinkle vs. the old
    // per-pref version: during Apply's brief async window the field
    // shows the pre-Apply value until the write lands.

    // ---- The card ----
    Rectangle {
        id: card
        anchors.fill: parent
        // The compositor performs the actual rounded clipping. Keeping this
        // full-surface container square/transparent avoids creating a second
        // rounded rectangle just inside Hyprland's border.
        radius: 0
        color: "transparent"
        // No QML-drawn outer border here. This is a real FloatingWindow,
        // so Hyprland alone owns the visible window border and applies the
        // configured active/inactive border colors without a second line
        // being drawn inside it.

        // Swallow clicks so the fullscreen close-MouseArea doesn't
        // fire when clicking inside the card.
        MouseArea { anchors.fill: parent }

        // Application-style titlebar. Drag anywhere in the empty header
        // area; Super+drag also works because this is a real toplevel.
        Rectangle {
            id: titlebar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.round(Theme.fontSize * 3.2)
            color: "transparent"
            z: 20

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: root.startSystemMove()
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacingLarge
                anchors.verticalCenter: parent.verticalCenter
                width: closeText.implicitHeight + Theme.spacingMedium * 2
                height: width
                radius: Theme.radiusMedium
                color: closeMouse.containsMouse ? Theme.colorHover : "transparent"
                z: 2
                Text {
                    id: closeText
                    anchors.centerIn: parent
                    text: "×"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 1.25)
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        Rectangle {
            id: sidebar
            anchors.top: titlebar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: root.sidebarWidth
            color: Qt.darker(Theme.colorBackground, 1.08)
            bottomLeftRadius: Math.max(0, UserPrefs.hyprRounding)

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Theme.colorMuted
                opacity: 0.5
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingSmall

                Text {
                    text: "SETTINGS"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.75)
                    Layout.leftMargin: Theme.spacingSmall
                    Layout.bottomMargin: Theme.spacingSmall
                }

                Repeater {
                    model: root.pages
                    Rectangle {
                        id: sideItem
                        required property string modelData
                        readonly property bool isCurrent: root.currentPage === modelData
                        Layout.fillWidth: true
                        implicitHeight: sideText.implicitHeight + Theme.spacingMedium * 1.5
                        radius: Theme.radiusMedium
                        color: isCurrent ? Theme.colorSurface
                             : sideMouse.containsMouse ? Theme.colorHover : "transparent"

                        Text {
                            id: sideText
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingMedium
                            anchors.verticalCenter: parent.verticalCenter
                            text: sideItem.modelData
                            color: sideItem.isCurrent ? Theme.colorAccent : Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: sideItem.isCurrent
                        }
                        MouseArea {
                            id: sideMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentPage = sideItem.modelData;
                                root.themeDropdownOpen = false;
                                root.fontFamilyDropdownOpen = false;
                                root.wallpaperTransitionTypeDropdownOpen = false;
                                pageFlick.contentY = 0;
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Text {
                    text: root.changes.length > 0
                        ? root.changes.length + " unapplied change" + (root.changes.length === 1 ? "" : "s")
                        : "All changes applied"
                    color: root.changes.length > 0 ? Theme.colorAccent : Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.75)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        ColumnLayout {
            id: content
            // Fixed width + pinned to the card's top-left padding —
            // centerIn here would re-center the column every time the
            // card's height changed, undoing the top-anchor above.
            anchors.top: titlebar.bottom
            anchors.bottom: parent.bottom
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.margins: Theme.spacingLarge
            spacing: Theme.spacingMedium

            Text {
                text: root.currentPage
                color: Theme.colorForeground
                font.family: Theme.fontFamily
                font.pixelSize: Math.round(Theme.fontSize * 1.35)
                font.bold: true
            }

            // ---------------- Page tabs ----------------
            RowLayout {
                visible: false
                Layout.preferredHeight: 0
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                Repeater {
                    model: root.pages

                    Rectangle {
                        id: tab
                        required property string modelData
                        readonly property bool isCurrent: root.currentPage === modelData

                        // spacingMedium, not Large (2026-07-11): the
                        // fifth tab (Desktop) overflowed the fixed
                        // content width at fontScale 1.0 with the old
                        // padding. contentWidth scales with the font,
                        // so if it fits at 1.0 it fits everywhere.
                        implicitWidth: tabText.implicitWidth + Theme.spacingMedium * 2
                        implicitHeight: tabText.implicitHeight + Theme.spacingSmall * 2
                        radius: Theme.radiusMedium
                        color: isCurrent ? Theme.colorSurface
                             : tabMouse.containsMouse ? Theme.colorHover : "transparent"
                        border.width: isCurrent ? 1 : 0
                        border.color: Theme.colorMuted

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: tab.modelData
                            color: tab.isCurrent ? Theme.colorAccent : Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: tab.isCurrent
                        }
                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            // Staged changes SURVIVE tab switches (the
                            // pending panel is global) — only close/
                            // Cancel discards.
                            onClicked: {
                                root.currentPage = tab.modelData;
                                root.themeDropdownOpen = false;
                                root.fontFamilyDropdownOpen = false;
                                root.wallpaperTransitionTypeDropdownOpen = false;
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }

            // ---- Page stack (2026-07-12) ----
            // StackLayout instead of four separate visible-toggled
            // ColumnLayouts. The old approach resized the whole window
            // on every tab click — QtQuick.Layouts excludes
            // visible:false items from a ColumnLayout's implicit size,
            // so `content`'s implicitHeight (and therefore the card's
            // height, see below) tracked WHICHEVER page happened to be
            // current. StackLayout sizes itself to its LARGEST child
            // up front, no matter which one is showing, so the card
            // now has one stable height across every tab. currentIndex
            // is driven off root.pages so tab order and page order
            // stay in sync automatically.
            Item {
                id: pageViewport
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Math.round(Theme.fontSize * 18)
                clip: true

                Flickable {
                    id: pageFlick
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: root.pageScrollGutter
                    clip: true
                    contentWidth: width
                    contentHeight: pageStack.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    StackLayout {
                        id: pageStack
                        width: pageFlick.width
                        currentIndex: Math.max(0, root.pages.indexOf(root.currentPage))

            // ================ APPEARANCE PAGE ================
            SettingsPages.AppearancePage {
                id: appearancePage
                settingsRoot: root
            }

            // ================ NOTIFICATIONS PAGE ================
            SettingsPages.NotificationsPage {
                id: notificationsPage
                settingsRoot: root
            }

            // ================ DESKTOP PAGE ================
            SettingsPages.DesktopPage {
                id: desktopPage
                settingsRoot: root
            }

            // ================ HYPRLAND PAGE ================
            SettingsPages.HyprlandPage {
                id: hyprlandPage
                settingsRoot: root
            }

            // ================ SDDM PAGE ================
            SettingsPages.SddmPage {
                id: sddmPage
                settingsRoot: root
            }

                    } // ---- end page stack ----
                } // ---- end page flickable ----

                // Draggable themed scrollbar. The earlier 3px indicator was
                // visual-only, which made long SDDM pages miserable in a
                // compact window. This thumb has a real hit target and maps
                // pointer movement directly to Flickable.contentY.
                Rectangle {
                    id: pageScrollThumb
                    visible: pageFlick.contentHeight > pageFlick.height
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    y: pageFlick.visibleArea.yPosition * pageFlick.height
                    width: pageScrollMouse.containsMouse || pageScrollMouse.pressed ? 12 : 8
                    height: Math.max(32, pageFlick.visibleArea.heightRatio * pageFlick.height)
                    radius: width / 2
                    color: pageScrollMouse.containsMouse || pageScrollMouse.pressed
                        ? Theme.colorAccent : Theme.colorMuted
                    opacity: pageScrollMouse.containsMouse || pageScrollMouse.pressed ? 1.0 : 0.75

                    Behavior on width { NumberAnimation { duration: 90 } }

                    MouseArea {
                        id: pageScrollMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        property real pressMouseY: 0
                        property real pressContentY: 0

                        onPressed: mouse => {
                            pressMouseY = mapToItem(pageViewport, mouse.x, mouse.y).y;
                            pressContentY = pageFlick.contentY;
                        }
                        onPositionChanged: mouse => {
                            if (!pressed) return;
                            const currentY = mapToItem(pageViewport, mouse.x, mouse.y).y;
                            const track = Math.max(1, pageViewport.height - pageScrollThumb.height);
                            const contentRange = Math.max(0, pageFlick.contentHeight - pageFlick.height);
                            pageFlick.contentY = Math.max(0, Math.min(contentRange,
                                pressContentY + (currentY - pressMouseY) * contentRange / track));
                        }
                    }
                }
            } // ---- end page viewport ----

            // ================ DISPLAYS PAGE (DISABLED 2026-07-12) ============
            // Block-commented, not deleted — DisplayManager.qml doesn't
            // exist yet, so this whole page threw ReferenceErrors at
            // runtime (see the state-block comment above `open()` for
            // the restore steps). NOT part of the staged/Apply
            // transaction below — display changes apply IMMEDIATELY
            // via its own button, wrapped in ConfigManager's revert
            // window (auto snapshot -> write -> countdown; unconfirmed
            // changes revert on their own). Mixing "staged until
            // Apply" and "applied with a revert timer" into one button
            // would make both semantics — and Cancel — ambiguous, so
            // this page owns its transaction, the same way the future
            // Backups page's restore is live (notes/SONNET_QUEUE.md
            // Q2, the transient/durable split).
            /*
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.currentPage === "Displays"
                spacing: Theme.spacingMedium

                Text {
                    visible: DisplayManager.monitors.length === 0
                    text: DisplayManager.refreshing ? "Reading monitors…"
                        : (DisplayManager.lastError !== ""
                            ? DisplayManager.lastError : "No monitors found")
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }

                Repeater {
                    model: DisplayManager.monitors

                    ColumnLayout {
                        id: monBlock
                        required property var modelData
                        readonly property var mon: modelData

                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall

                        Text {
                            text: monBlock.mon.name
                                  + (monBlock.mon.focused ? "  (focused)" : "")
                                  + (monBlock.mon.disabled ? "  (disabled)" : "")
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }

                        Text {
                            visible: monBlock.mon.description !== ""
                            text: monBlock.mon.description
                            // Elide, don't widen — the card is fixed
                            // width (v0.6) and EDID descriptions can
                            // be long.
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.8)
                        }

                        SettingsComponents.ToggleSettingRow {
                            label: "Enabled"
                            value: !root.shownDispDisabled(monBlock.mon)
                            staged: root.stagedDisplays[monBlock.mon.name] !== undefined
                                    && root.stagedDisplays[monBlock.mon.name].disabled !== undefined
                            onToggled: root.stageDisplay(monBlock.mon.name,
                                "disabled", !root.shownDispDisabled(monBlock.mon))
                        }

                        // Mode steps through availableModes verbatim —
                        // every value the stepper can land on is one
                        // the monitor advertised.
                        SettingsComponents.StepperRow {
                            label: "Mode"
                            valueText: root.shownDispMode(monBlock.mon)
                            staged: root.stagedDisplays[monBlock.mon.name] !== undefined
                                    && root.stagedDisplays[monBlock.mon.name].mode !== undefined
                            onMinus: {
                                const modes = monBlock.mon.availableModes;
                                const idx = modes.indexOf(root.shownDispMode(monBlock.mon));
                                if (idx > 0)
                                    root.stageDisplay(monBlock.mon.name, "mode", modes[idx - 1]);
                                else if (idx === -1 && modes.length > 0)
                                    root.stageDisplay(monBlock.mon.name, "mode", modes[0]);
                            }
                            onPlus: {
                                const modes = monBlock.mon.availableModes;
                                const idx = modes.indexOf(root.shownDispMode(monBlock.mon));
                                if (idx !== -1 && idx < modes.length - 1)
                                    root.stageDisplay(monBlock.mon.name, "mode", modes[idx + 1]);
                                else if (idx === -1 && modes.length > 0)
                                    root.stageDisplay(monBlock.mon.name, "mode", modes[0]);
                            }
                        }

                        // Scale steps through only the LEGAL scales
                        // for the shown mode's resolution (integer
                        // logical pixels — see DisplayManager).
                        SettingsComponents.StepperRow {
                            label: "Scale"
                            valueText: DisplayManager.fmtScale(root.shownDispScale(monBlock.mon)) + "×"
                            staged: root.stagedDisplays[monBlock.mon.name] !== undefined
                                    && root.stagedDisplays[monBlock.mon.name].scale !== undefined
                            onMinus: {
                                const p = DisplayManager.parseMode(root.shownDispMode(monBlock.mon));
                                if (!p) return;
                                const scales = DisplayManager.validScalesFor(
                                    p.w, p.h, root.shownDispScale(monBlock.mon));
                                const cur = root.shownDispScale(monBlock.mon);
                                for (let i = scales.length - 1; i >= 0; i--) {
                                    if (scales[i] < cur - 0.001) {
                                        root.stageDisplay(monBlock.mon.name, "scale", scales[i]);
                                        break;
                                    }
                                }
                            }
                            onPlus: {
                                const p = DisplayManager.parseMode(root.shownDispMode(monBlock.mon));
                                if (!p) return;
                                const scales = DisplayManager.validScalesFor(
                                    p.w, p.h, root.shownDispScale(monBlock.mon));
                                const cur = root.shownDispScale(monBlock.mon);
                                for (let i = 0; i < scales.length; i++) {
                                    if (scales[i] > cur + 0.001) {
                                        root.stageDisplay(monBlock.mon.name, "scale", scales[i]);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }

                // The page's own diff + apply (see the page comment).
                // These rows still appear/disappear as you step — but
                // they sit BELOW the steppers, and the card is
                // top-anchored (v0.6), so stepping never moves the
                // stepper itself; only the buttons below shift, once.
                Repeater {
                    model: root.displayChanges

                    Text {
                        required property var modelData
                        text: "  " + modelData.label + ":  "
                              + modelData.from + "  →  " + modelData.to
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: Theme.colorAccent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                }

                Text {
                    visible: root.displayError !== ""
                    text: "Error: " + root.displayError
                    color: Theme.colorUrgent
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.8)
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingMedium

                    Text {
                        visible: ConfigManager.revertPending
                        text: "Reverting in " + Math.max(0, ConfigManager.revertSecondsLeft) + " s…"
                        color: Theme.colorAccent
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        visible: ConfigManager.revertPending
                        implicitWidth: dispRevertText.implicitWidth + Theme.spacingLarge * 2
                        implicitHeight: dispRevertText.implicitHeight + Theme.spacingSmall * 2
                        radius: Theme.radiusMedium
                        color: dispRevertMouse.containsMouse ? Theme.colorHover : Theme.colorSurface
                        Text {
                            id: dispRevertText
                            anchors.centerIn: parent
                            text: "Revert Now"
                            color: Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                        MouseArea {
                            id: dispRevertMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ConfigManager.revertNow()
                        }
                    }

                    Rectangle {
                        visible: ConfigManager.revertPending
                        implicitWidth: dispKeepText.implicitWidth + Theme.spacingLarge * 2
                        implicitHeight: dispKeepText.implicitHeight + Theme.spacingSmall * 2
                        radius: Theme.radiusMedium
                        color: dispKeepMouse.containsMouse ? Theme.colorHover : Theme.colorAccent
                        Text {
                            id: dispKeepText
                            anchors.centerIn: parent
                            text: "Keep"
                            color: Theme.colorBackground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }
                        MouseArea {
                            id: dispKeepMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ConfigManager.confirmKeep()
                        }
                    }

                    Rectangle {
                        readonly property bool enabled_: root.displayChanges.length > 0
                                                         && ConfigManager.busy === ""
                                                         && !ConfigManager.revertPending
                        visible: !ConfigManager.revertPending
                        implicitWidth: dispApplyText.implicitWidth + Theme.spacingLarge * 2
                        implicitHeight: dispApplyText.implicitHeight + Theme.spacingSmall * 2
                        radius: Theme.radiusMedium
                        color: dispApplyMouse.containsMouse && enabled_ ? Theme.colorHover : Theme.colorAccent
                        opacity: enabled_ ? 1.0 : 0.4
                        Text {
                            id: dispApplyText
                            anchors.centerIn: parent
                            text: "Apply Displays"
                            color: Theme.colorBackground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                        }
                        MouseArea {
                            id: dispApplyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: parent.enabled_ ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (parent.enabled_) root.applyDisplays()
                        }
                    }
                }

                Text {
                    text: "Applies immediately with an auto-revert countdown — unless you\nconfirm Keep (on any monitor, or `qs ipc call displays keep`),\nthe previous settings come back on their own."
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 0.8)
                }
            } // ================ end Displays ================
            */

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.colorMuted
            }

            // ---------------- Pending changes + Apply/Cancel ----------------
            // FIXED-HEIGHT panel (v0.6, see DESIGN NOTES: stable
            // geometry). The header, the diff area, and the status
            // line are ALWAYS present at a constant size — staging or
            // unstaging a change changes what they say, never how much
            // room they take, so nothing below or above them ever
            // moves. Past pendingVisibleLines rows the list scrolls.
            // Boxed panel (2026-07-13) — the header, diff list, and
            // status line live inside one bordered container instead
            // of sitting bare on the page, so "things about to be
            // applied" reads as its own contained section rather than
            // blending into the page content above it. Purely visual:
            // the fixed-height rules from the DESIGN NOTES above are
            // unchanged, just wrapped.
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: pendingColumn.implicitHeight + Theme.spacingMedium * 2
                radius: Theme.radiusMedium
                color: Theme.colorSurface
                border.width: 1
                border.color: Theme.colorMuted

                ColumnLayout {
                    id: pendingColumn
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingMedium

                    Text {
                        text: root.changes.length > 0
                              ? "Pending changes (" + root.changes.length + "):"
                              : "Pending changes: none"
                        color: root.changes.length > 0 ? Theme.colorForeground : Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }

                    // Invisible one-line probe — same font as the diff rows,
                    // so the reserved height tracks font scale exactly
                    // (hidden items are skipped by ColumnLayout, so this
                    // costs no space itself).
                    Text {
                        id: pendingProbe
                        visible: false
                        text: "Xg"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    ListView {
                        id: pendingList
                        Layout.fillWidth: true
                        // Exactly pendingVisibleLines rows, whether 0 or 13
                        // changes are staged. This constant is the fix.
                        Layout.preferredHeight: pendingProbe.implicitHeight * root.pendingVisibleLines
                                                + spacing * (root.pendingVisibleLines - 1)
                        spacing: 2
                        clip: true
                        interactive: contentHeight > height
                        model: root.changes

                        delegate: Text {
                            required property var modelData
                            width: ListView.view.width
                            text: "  " + modelData.label + ":  "
                                  + modelData.from + "  →  " + modelData.to
                            elide: Text.ElideRight
                            color: Theme.colorAccent
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }

                        // Muted hint filling the reserved space when empty.
                        Text {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingMedium
                            visible: root.changes.length === 0
                            text: "Nothing staged — changes made on any tab collect\nhere, and nothing touches disk until Apply."
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.8)
                        }
                    }

                    // Status line — the async ConfigManager surfaced in UI.
                    // Falls back to a single space (not ""), so the line
                    // reserves its row even when idle — an appearing status
                    // line was one more thing nudging the buttons (v0.6).
                    Text {
                        Layout.fillWidth: true
                        text: ConfigManager.busy !== "" ? "Working (" + ConfigManager.busy + ")…"
                            : ConfigManager.lastError !== "" ? "Error: " + ConfigManager.lastError
                            : ConfigManager.lastOutput !== "" ? ConfigManager.lastOutput
                            : " "
                        elide: Text.ElideRight
                        color: ConfigManager.lastError !== "" ? Theme.colorUrgent : Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 0.8)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingMedium

                Item { Layout.fillWidth: true }

                Rectangle {
                    readonly property bool enabled_: root.changes.length > 0
                    implicitWidth: cancelText.implicitWidth + Theme.spacingLarge * 2
                    implicitHeight: cancelText.implicitHeight + Theme.spacingSmall * 2
                    radius: Theme.radiusMedium
                    color: cancelMouse.containsMouse && enabled_ ? Theme.colorHover : Theme.colorSurface
                    opacity: enabled_ ? 1.0 : 0.4
                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: parent.enabled_ ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.discardStaged()
                    }
                }

                Rectangle {
                    readonly property bool enabled_: root.changes.length > 0
                                                     && ConfigManager.busy === ""
                    implicitWidth: applyText.implicitWidth + Theme.spacingLarge * 2
                    implicitHeight: applyText.implicitHeight + Theme.spacingSmall * 2
                    radius: Theme.radiusMedium
                    color: applyMouse.containsMouse && enabled_ ? Theme.colorHover : Theme.colorAccent
                    opacity: enabled_ ? 1.0 : 0.4
                    Text {
                        id: applyText
                        anchors.centerIn: parent
                        text: "Apply"
                        color: Theme.colorBackground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                    MouseArea {
                        id: applyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: parent.enabled_ ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (parent.enabled_) root.apply()
                    }
                }
            }
        }

        // ---- Dropdown overlays: Theme + Font Family (2026-07-12) ----
        // These used to be inline ListViews inside the Appearance page's
        // ColumnLayout — that added their height straight to `content`'s
        // implicitHeight, so opening either dropdown grew the whole
        // settings window, and it shrank back the instant you picked
        // something or closed it. Same fix as the swatch popup below:
        // render ONE floating panel per dropdown at CARD level (big,
        // unclipped, on top), positioned via mapToItem off the button
        // that opened it. `themeDropdownButton`/`fontDropdownButton`
        // are plain fixed items (not Repeater delegates), so they can
        // be referenced directly by id from here — no anchor-property
        // indirection needed like the color picker uses for its
        // per-row swatches. Click-outside-to-dismiss via a full-card
        // catcher underneath, same as the color picker. Only one
        // dropdown (and never the color picker at the same time in
        // practice) is expected open at once — the button handlers
        // enforce that themeDropdownOpen/fontFamilyDropdownOpen are
        // mutually exclusive.

        MouseArea {
            anchors.fill: parent
            z: 149
            visible: root.themeDropdownOpen || root.fontFamilyDropdownOpen || root.wallpaperTransitionTypeDropdownOpen
            enabled: root.themeDropdownOpen || root.fontFamilyDropdownOpen || root.wallpaperTransitionTypeDropdownOpen
            onClicked: {
                root.themeDropdownOpen = false;
                root.fontFamilyDropdownOpen = false;
                root.wallpaperTransitionTypeDropdownOpen = false;
            }
        }

        Rectangle {
            id: themeDropdownOverlay
            z: 150
            visible: root.themeDropdownOpen

            // Gated on the open flag so mapToItem RE-EVALUATES each
            // time the dropdown opens. Ungated, it fired once at load
            // — before the StackLayout had positioned this button —
            // and cached that stale (near-top) result forever, which
            // is why the panel landed on top of / above the button.
            readonly property point anchorPos: root.themeDropdownOpen
                ? appearancePage.themeDropdownAnchor.mapToItem(card, 0, 0)
                : Qt.point(0, 0)
            readonly property int rowHeight: Theme.fontSize + Theme.spacingSmall * 2 + 2
            readonly property int visibleRows: Math.min(Theme.themeNames.length, 6)

            x: anchorPos.x
            // Overlaps the button by exactly its border width, so the
            // button's bottom edge and this panel's top edge coincide
            // as ONE line instead of two separate outlines with a gap.
            y: anchorPos.y + appearancePage.themeDropdownAnchor.height - 1
            width: Math.min(appearancePage.themeDropdownAnchor.width, card.width - x - root.pageScrollGutter - Theme.spacingLarge)
            height: visibleRows * rowHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            topLeftRadius: 0
            topRightRadius: 0
            color: Theme.colorSurface
            border.width: 1
            border.color: Theme.colorMuted

            // Swallow clicks on the panel body so they don't fall
            // through to the dismiss-catcher underneath.
            MouseArea { anchors.fill: parent }

            ListView {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                clip: true
                spacing: 2
                interactive: contentHeight > height
                model: Theme.themeNames

                delegate: Rectangle {
                    id: themeRow
                    required property string modelData
                    readonly property bool isShown: root.shownTheme === modelData
                    readonly property bool isLive: UserPrefs.themeName === modelData

                    width: ListView.view.width
                    implicitHeight: themeRowText.implicitHeight + Theme.spacingSmall * 2
                    radius: Theme.radiusMedium
                    color: themeRowMouse.containsMouse ? Theme.colorHover
                         : isShown ? Theme.colorSurface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingMedium
                        anchors.rightMargin: Theme.spacingMedium
                        spacing: Theme.spacingMedium

                        Text {
                            id: themeRowText
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: (themeRow.isShown ? "● " : "○ ") + themeRow.modelData
                            color: themeRow.isShown ? Theme.colorAccent : Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                        Text {
                            visible: themeRow.isLive && !themeRow.isShown
                            text: "current"
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.8)
                        }
                    }

                    MouseArea {
                        id: themeRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.stagedTheme = themeRow.modelData;
                            root.themeDropdownOpen = false;
                        }
                    }
                }
            }
        }

        Rectangle {
            id: fontDropdownOverlay
            z: 150
            visible: root.fontFamilyDropdownOpen

            readonly property point anchorPos: root.fontFamilyDropdownOpen
                ? appearancePage.fontDropdownAnchor.mapToItem(card, 0, 0)
                : Qt.point(0, 0)
            readonly property int rowHeight: Theme.fontSize + Theme.spacingSmall * 2 + 2
            readonly property int visibleRows: Math.min(root.fontFamilyOptions.length, 6)

            x: anchorPos.x
            y: anchorPos.y + appearancePage.fontDropdownAnchor.height - 1
            width: Math.min(appearancePage.fontDropdownAnchor.width, card.width - x - root.pageScrollGutter - Theme.spacingLarge)
            height: visibleRows * rowHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            topLeftRadius: 0
            topRightRadius: 0
            color: Theme.colorSurface
            border.width: 1
            border.color: Theme.colorMuted

            MouseArea { anchors.fill: parent }

            ListView {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                clip: true
                spacing: 2
                interactive: contentHeight > height
                model: root.fontFamilyOptions

                delegate: Rectangle {
                    id: fontRow
                    required property string modelData
                    readonly property bool isShown: root.shownFontFamilyOverride === modelData
                    readonly property bool isLive: UserPrefs.fontFamilyOverride === modelData
                    readonly property string displayText: modelData === "" ? "(Theme Default)" : modelData

                    width: ListView.view.width
                    implicitHeight: fontRowText.implicitHeight + Theme.spacingSmall * 2
                    radius: Theme.radiusMedium
                    color: fontRowMouse.containsMouse ? Theme.colorHover
                         : isShown ? Theme.colorSurface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingMedium
                        anchors.rightMargin: Theme.spacingMedium
                        spacing: Theme.spacingMedium

                        Text {
                            id: fontRowText
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: (fontRow.isShown ? "● " : "○ ") + fontRow.displayText
                            color: fontRow.isShown ? Theme.colorAccent : Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                        Text {
                            visible: fontRow.isLive && !fontRow.isShown
                            text: "current"
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.8)
                        }
                    }

                    MouseArea {
                        id: fontRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.stagedFontFamilyOverride = fontRow.modelData;
                            root.fontFamilyDropdownOpen = false;
                        }
                    }
                }
            }
        }

        Rectangle {
            id: wallpaperTransitionTypeDropdownOverlay
            z: 150
            visible: root.wallpaperTransitionTypeDropdownOpen

            readonly property point anchorPos: root.wallpaperTransitionTypeDropdownOpen
                ? appearancePage.wallpaperTransitionTypeDropdownAnchor.mapToItem(card, 0, 0)
                : Qt.point(0, 0)
            readonly property int rowHeight: Theme.fontSize + Theme.spacingSmall * 2 + 2
            readonly property int visibleRows: Math.min(root.wallpaperTransitionTypeOptions.length, 6)

            x: anchorPos.x
            y: anchorPos.y + appearancePage.wallpaperTransitionTypeDropdownAnchor.height - 1
            width: Math.min(appearancePage.wallpaperTransitionTypeDropdownAnchor.width, card.width - x - root.pageScrollGutter - Theme.spacingLarge)
            height: visibleRows * rowHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            topLeftRadius: 0
            topRightRadius: 0
            color: Theme.colorSurface
            border.width: 1
            border.color: Theme.colorMuted

            MouseArea { anchors.fill: parent }

            ListView {
                anchors.fill: parent
                anchors.margins: Theme.spacingSmall
                clip: true
                spacing: 2
                interactive: contentHeight > height
                model: root.wallpaperTransitionTypeOptions

                delegate: Rectangle {
                    id: wtRow
                    required property string modelData
                    readonly property bool isShown: root.shownWallpaperTransitionType === modelData
                    readonly property bool isLive: UserPrefs.wallpaperTransitionType === modelData

                    width: ListView.view.width
                    implicitHeight: wtRowText.implicitHeight + Theme.spacingSmall * 2
                    radius: Theme.radiusMedium
                    color: wtRowMouse.containsMouse ? Theme.colorHover
                         : isShown ? Theme.colorSurface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingMedium
                        anchors.rightMargin: Theme.spacingMedium
                        spacing: Theme.spacingMedium

                        Text {
                            id: wtRowText
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: (wtRow.isShown ? "● " : "○ ") + wtRow.modelData
                            color: wtRow.isShown ? Theme.colorAccent : Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                        }
                        Text {
                            visible: wtRow.isLive && !wtRow.isShown
                            text: "current"
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.8)
                        }
                    }

                    MouseArea {
                        id: wtRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.stagedWallpaperTransitionType = wtRow.modelData;
                            root.wallpaperTransitionTypeDropdownOpen = false;
                        }
                    }
                }
            }
        }

        // ---- Shared preset-color-picker overlay (2026-07-11, Opus) ----
        // Rendered here, at CARD level, so it's large, unclipped, on top
        // of every row, and — critically — actually receives clicks
        // (the previous per-row popups were trapped inside a 22px swatch
        // and were visible-but-dead). Driven entirely by root.colorPicker*
        // state; a HexColorRow's swatch calls root.openColorPicker(...).

        // Full-card click-catcher: any click outside the grid closes the
        // picker (click-outside-to-dismiss — the v1 limitation is gone).
        // Only present while open, so it never eats clicks otherwise.
        MouseArea {
            anchors.fill: parent
            z: 199
            visible: root.colorPickerOpen
            enabled: root.colorPickerOpen
            onClicked: root.closeColorPicker()
        }

        Rectangle {
            id: colorPickerPopup
            z: 200
            visible: root.colorPickerOpen && root.colorPickerAnchor !== null

            // Map the opening swatch's top-left into card coordinates,
            // then place the popup just under it. Clamped so it can't
            // spill past the card's padding on either side.
            readonly property point anchorPos: root.colorPickerAnchor
                ? root.colorPickerAnchor.mapToItem(card, 0, 0)
                : Qt.point(0, 0)
            readonly property int pad: Theme.spacingLarge
            readonly property int idealX: anchorPos.x + (root.colorPickerAnchor
                ? root.colorPickerAnchor.width : 0) - width
            x: Math.max(pad, Math.min(idealX, card.width - width - pad))
            y: anchorPos.y + (root.colorPickerAnchor
                ? root.colorPickerAnchor.height : 0) + 4

            width: pickerGrid.implicitWidth + Theme.spacingSmall * 2
            height: pickerGrid.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: Theme.colorSurface
            border.width: 1
            border.color: Theme.colorMuted

            // Swallow clicks on the popup body so they don't reach the
            // dismiss-catcher underneath and close it before a swatch
            // registers.
            MouseArea { anchors.fill: parent }

            Grid {
                id: pickerGrid
                anchors.centerIn: parent
                columns: 8
                spacing: 4
                Repeater {
                    model: root.colorPickerSwatches
                    Rectangle {
                        required property var modelData
                        width: 20
                        height: 20
                        radius: 4
                        color: modelData
                        border.width: 1
                        border.color: Theme.colorMuted
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.colorPickerCallback)
                                    root.colorPickerCallback(parent.modelData);
                                root.closeColorPicker();
                            }
                        }
                    }
                }
            }
        }
    }
}
