import QtQuick
import qs.core
import qs.services

// GPT Rev 21: global staged-settings transaction controller.
Item {
    id: transaction

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
    property var stagedHyprAnimationPreset: null
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
    readonly property string shownHyprAnimationPreset: stagedHyprAnimationPreset !== null ? stagedHyprAnimationPreset : UserPrefs.hyprAnimationPreset
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
            ["hyprRounding", "Rounding", UserPrefs.hyprRounding, stagedHyprRounding],
            ["hyprAnimationPreset", "Animation Preset", UserPrefs.hyprAnimationPreset, stagedHyprAnimationPreset]
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
        stagedHyprAnimationPreset = null;
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
    }

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

    // GPT Rev 24: profile restore replaces UserPrefs on disk, but Hyprland's
    // generated appearance.lua is a separate side effect. Re-submit the
    // restored Hyprland values as a no-op settings transaction so the normal
    // generator path runs without requiring the user to jiggle a slider.
    function reapplyCurrentHyprland(): bool {
        if (ConfigManager.busy !== "")
            return false;
        const restoredHyprChanges = [
            { key: "hyprGapsIn", value: UserPrefs.hyprGapsIn },
            { key: "hyprGapsOut", value: UserPrefs.hyprGapsOut },
            { key: "hyprBorderSize", value: UserPrefs.hyprBorderSize },
            { key: "hyprRounding", value: UserPrefs.hyprRounding },
            { key: "hyprAnimationPreset", value: UserPrefs.hyprAnimationPreset },
            { key: "hyprActiveBorderUseThemeColor", value: UserPrefs.hyprActiveBorderUseThemeColor },
            { key: "hyprActiveBorderCustomColor", value: UserPrefs.hyprActiveBorderCustomColor }
        ];
        return ConfigManager.applyChanges(restoredHyprChanges,
                                          "UI profile Hyprland restore",
                                          resolvedHyprBorderForApply());
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

}
