//=============================================================================
// FILE: widgets/Settings/SettingsContext.qml
// GPT Rev 29: compatibility facade extracted from SettingsWindow.qml.
// Owns page-facing state, option models, overlay state, and the transaction
// controller. The FloatingWindow remains responsible only for lifecycle and
// native window behavior.
//=============================================================================

import QtQuick
import Quickshell
import qs.core

Item {
    id: context

    required property var window

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
    property alias stagedHyprAnimationPreset: settingsTransaction.stagedHyprAnimationPreset
    property alias stagedHyprWindowAnimationStyle: settingsTransaction.stagedHyprWindowAnimationStyle
    property alias stagedHyprWorkspaceAnimationStyle: settingsTransaction.stagedHyprWorkspaceAnimationStyle
    property alias stagedHyprLayerAnimationStyle: settingsTransaction.stagedHyprLayerAnimationStyle
    property alias stagedHyprFadeAnimationPreset: settingsTransaction.stagedHyprFadeAnimationPreset
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
    readonly property string shownHyprAnimationPreset: settingsTransaction.shownHyprAnimationPreset
    readonly property string shownHyprWindowAnimationStyle: settingsTransaction.shownHyprWindowAnimationStyle
    readonly property string shownHyprWorkspaceAnimationStyle: settingsTransaction.shownHyprWorkspaceAnimationStyle
    readonly property string shownHyprLayerAnimationStyle: settingsTransaction.shownHyprLayerAnimationStyle
    readonly property string shownHyprFadeAnimationPreset: settingsTransaction.shownHyprFadeAnimationPreset
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
        for (let j = 0; j < context.preferredFontOrder.length; j++)
            if (bases.indexOf(context.preferredFontOrder[j]) !== -1)
                pref.push(context.preferredFontOrder[j]);
        const rest = bases.filter(f => pref.indexOf(f) === -1);
        return [""].concat(pref).concat(rest);
    }

    function startSystemMove(): void {
        window.startSystemMove();
    }

    function close(): void {
        window.close();
    }

    function apply(): void {
        settingsTransaction.apply();
        themeDropdownOpen = false;
        fontFamilyDropdownOpen = false;
        wallpaperTransitionTypeDropdownOpen = false;
        closeColorPicker();
    }

    function resolvedHyprBorderForApply(): var {
        return settingsTransaction.resolvedHyprBorderForApply();
    }

    function reapplyCurrentHyprland(): bool {
        return settingsTransaction.reapplyCurrentHyprland();
    }
}
