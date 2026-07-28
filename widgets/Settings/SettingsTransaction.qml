import QtQuick
import qs.core
import qs.services

// GPT Rev 21: global staged-settings transaction controller.
Item {
    id: transaction

    // ---- Staged (uncommitted) values. null = not staged. ----
    property var stagedTheme: null
    property var stagedFontScale: null
    property var stagedCustomThemeBaseName: null
    property var stagedCustomThemeBackground: null
    property var stagedCustomThemeForeground: null
    property var stagedCustomThemeAccent: null
    property var stagedCustomThemeUrgent: null
    property var stagedCustomThemeMuted: null
    property var stagedCustomThemeSurface: null
    property var stagedCustomThemeHover: null
    property var stagedCustomThemeBorder: null
    property var stagedCustomThemeBorder2: null
    property var stagedCustomThemeBorderAngle: null
    property var stagedNotifPresentation: null
    property var stagedNotifBarPosition: null
    property var stagedNotifBarOffsetX: null
    property var stagedNotifBarShowCardBorders: null
    property var stagedNotifShowAppName: null
    property var stagedNotifIconSize: null
    property var stagedNotifBodyLines: null
    property var stagedNotifFontScale: null
    property var stagedLauncherPlacement: null
    property var stagedLauncherOffsetX: null
    property var stagedLauncherOffsetY: null
    property var stagedLauncherShowAppsOnOpen: null
    property var stagedWallpaperPickerPlacement: null
    property var stagedWallpaperPickerOffsetX: null
    property var stagedWallpaperPickerOffsetY: null
    property var stagedWallpaperCachingEnabled: null
    property var stagedClockUse24Hour: null
    property var stagedClockShowSeconds: null
    property var stagedHyprGapsIn: null
    property var stagedHyprGapsOut: null
    property var stagedHyprBorderSize: null
    property var stagedHyprRounding: null
    property var stagedHyprAnimationPreset: null
    property var stagedHyprWindowAnimationStyle: null
    property var stagedHyprWorkspaceAnimationStyle: null
    property var stagedHyprLayerAnimationStyle: null
    property var stagedHyprFadeAnimationPreset: null
    property var stagedHyprCustomAnimationSpeedsEnabled: null
    property var stagedHyprWindowSpeed: null
    property var stagedHyprWindowInSpeed: null
    property var stagedHyprWindowOutSpeed: null
    property var stagedHyprWorkspaceSpeed: null
    property var stagedHyprLayerSpeed: null
    property var stagedHyprFadeSpeed: null
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
    property var stagedMusicVisualizerEnabled: null
    property var stagedMusicVisualizerSource: null
    property var stagedMusicVisualizerBars: null
    property var stagedMusicVisualizerFramerate: null
    property var stagedMusicVisualizerSensitivity: null
    property var stagedMusicVisualizerAutosens: null
    property var stagedMusicVisualizerLowerCutoff: null
    property var stagedMusicVisualizerHigherCutoff: null
    property var stagedMusicVisualizerSleepTimer: null
    property var stagedMusicVisualizerReverse: null
    property var stagedMusicVisualizerNoiseReduction: null
    property var stagedMusicVisualizerStyle: null
    property var stagedMusicVisualizerUseThemeColor: null
    property var stagedMusicVisualizerCustomColor: null
    property var stagedMusicVisualizerColorMode: null
    property var stagedMusicVisualizerFadeDarkerTop: null
    property var stagedMusicVisualizerFadeStrength: null
    property var stagedMusicVisualizerLowColor: null
    property var stagedMusicVisualizerMidColor: null
    property var stagedMusicVisualizerHighColor: null
    property var stagedMusicVisualizerLedSegments: null
    property var stagedMusicVisualizerLedGap: null
    property var stagedMusicVisualizerLedUnlitOpacity: null

    // Effective values the UI highlights: staged if present, else live.
    readonly property string shownTheme: stagedTheme !== null ? stagedTheme : UserPrefs.themeName
    readonly property real shownFontScale: stagedFontScale !== null ? stagedFontScale : UserPrefs.fontScale
    readonly property string shownCustomThemeBaseName: stagedCustomThemeBaseName !== null ? stagedCustomThemeBaseName : UserPrefs.customThemeBaseName
    readonly property string shownCustomThemeBackground: stagedCustomThemeBackground !== null ? stagedCustomThemeBackground : UserPrefs.customThemeBackground
    readonly property string shownCustomThemeForeground: stagedCustomThemeForeground !== null ? stagedCustomThemeForeground : UserPrefs.customThemeForeground
    readonly property string shownCustomThemeAccent: stagedCustomThemeAccent !== null ? stagedCustomThemeAccent : UserPrefs.customThemeAccent
    readonly property string shownCustomThemeUrgent: stagedCustomThemeUrgent !== null ? stagedCustomThemeUrgent : UserPrefs.customThemeUrgent
    readonly property string shownCustomThemeMuted: stagedCustomThemeMuted !== null ? stagedCustomThemeMuted : UserPrefs.customThemeMuted
    readonly property string shownCustomThemeSurface: stagedCustomThemeSurface !== null ? stagedCustomThemeSurface : UserPrefs.customThemeSurface
    readonly property string shownCustomThemeHover: stagedCustomThemeHover !== null ? stagedCustomThemeHover : UserPrefs.customThemeHover
    readonly property string shownCustomThemeBorder: stagedCustomThemeBorder !== null ? stagedCustomThemeBorder : UserPrefs.customThemeBorder
    readonly property string shownCustomThemeBorder2: stagedCustomThemeBorder2 !== null ? stagedCustomThemeBorder2 : UserPrefs.customThemeBorder2
    readonly property real shownCustomThemeBorderAngle: stagedCustomThemeBorderAngle !== null ? stagedCustomThemeBorderAngle : UserPrefs.customThemeBorderAngle
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
    readonly property string shownNotifPresentation: stagedNotifPresentation !== null ? stagedNotifPresentation : UserPrefs.notifPresentation
    readonly property string shownNotifBarPosition: stagedNotifBarPosition !== null ? stagedNotifBarPosition : UserPrefs.notifBarPosition
    readonly property int shownNotifBarOffsetX: stagedNotifBarOffsetX !== null ? stagedNotifBarOffsetX : UserPrefs.notifBarOffsetX
    readonly property bool shownNotifBarShowCardBorders: stagedNotifBarShowCardBorders !== null ? stagedNotifBarShowCardBorders : UserPrefs.notifBarShowCardBorders
    readonly property bool shownNotifShowAppName: stagedNotifShowAppName !== null ? stagedNotifShowAppName : UserPrefs.notifShowAppName
    readonly property int shownNotifIconSize: stagedNotifIconSize !== null ? stagedNotifIconSize : UserPrefs.notifIconSize
    readonly property int shownNotifBodyLines: stagedNotifBodyLines !== null ? stagedNotifBodyLines : UserPrefs.notifBodyLines
    readonly property real shownNotifFontScale: stagedNotifFontScale !== null ? stagedNotifFontScale : UserPrefs.notifFontScale
    readonly property string shownLauncherPlacement: stagedLauncherPlacement !== null ? stagedLauncherPlacement : UserPrefs.launcherPlacement
    readonly property int shownLauncherOffsetX: stagedLauncherOffsetX !== null ? stagedLauncherOffsetX : UserPrefs.launcherOffsetX
    readonly property int shownLauncherOffsetY: stagedLauncherOffsetY !== null ? stagedLauncherOffsetY : UserPrefs.launcherOffsetY
    readonly property bool shownLauncherShowAppsOnOpen: stagedLauncherShowAppsOnOpen !== null ? stagedLauncherShowAppsOnOpen : UserPrefs.launcherShowAppsOnOpen
    readonly property string shownWallpaperPickerPlacement: stagedWallpaperPickerPlacement !== null ? stagedWallpaperPickerPlacement : UserPrefs.wallpaperPickerPlacement
    readonly property int shownWallpaperPickerOffsetX: stagedWallpaperPickerOffsetX !== null ? stagedWallpaperPickerOffsetX : UserPrefs.wallpaperPickerOffsetX
    readonly property int shownWallpaperPickerOffsetY: stagedWallpaperPickerOffsetY !== null ? stagedWallpaperPickerOffsetY : UserPrefs.wallpaperPickerOffsetY
    readonly property bool shownWallpaperCachingEnabled: stagedWallpaperCachingEnabled !== null ? stagedWallpaperCachingEnabled : UserPrefs.wallpaperCachingEnabled
    readonly property bool shownClockUse24Hour: stagedClockUse24Hour !== null ? stagedClockUse24Hour : UserPrefs.clockUse24Hour
    readonly property bool shownClockShowSeconds: stagedClockShowSeconds !== null ? stagedClockShowSeconds : UserPrefs.clockShowSeconds
    readonly property int shownHyprGapsIn: stagedHyprGapsIn !== null ? stagedHyprGapsIn : UserPrefs.hyprGapsIn
    readonly property int shownHyprGapsOut: stagedHyprGapsOut !== null ? stagedHyprGapsOut : UserPrefs.hyprGapsOut
    readonly property int shownHyprBorderSize: stagedHyprBorderSize !== null ? stagedHyprBorderSize : UserPrefs.hyprBorderSize
    readonly property int shownHyprRounding: stagedHyprRounding !== null ? stagedHyprRounding : UserPrefs.hyprRounding
    readonly property string shownHyprAnimationPreset: stagedHyprAnimationPreset !== null ? stagedHyprAnimationPreset : UserPrefs.hyprAnimationPreset
    readonly property string shownHyprWindowAnimationStyle: stagedHyprWindowAnimationStyle !== null ? stagedHyprWindowAnimationStyle : UserPrefs.hyprWindowAnimationStyle
    readonly property string shownHyprWorkspaceAnimationStyle: stagedHyprWorkspaceAnimationStyle !== null ? stagedHyprWorkspaceAnimationStyle : UserPrefs.hyprWorkspaceAnimationStyle
    readonly property string shownHyprLayerAnimationStyle: stagedHyprLayerAnimationStyle !== null ? stagedHyprLayerAnimationStyle : UserPrefs.hyprLayerAnimationStyle
    readonly property string shownHyprFadeAnimationPreset: stagedHyprFadeAnimationPreset !== null ? stagedHyprFadeAnimationPreset : UserPrefs.hyprFadeAnimationPreset
    readonly property bool shownHyprCustomAnimationSpeedsEnabled: stagedHyprCustomAnimationSpeedsEnabled !== null ? stagedHyprCustomAnimationSpeedsEnabled : UserPrefs.hyprCustomAnimationSpeedsEnabled
    readonly property real shownHyprWindowSpeed: stagedHyprWindowSpeed !== null ? stagedHyprWindowSpeed : UserPrefs.hyprWindowSpeed
    readonly property real shownHyprWindowInSpeed: stagedHyprWindowInSpeed !== null ? stagedHyprWindowInSpeed : UserPrefs.hyprWindowInSpeed
    readonly property real shownHyprWindowOutSpeed: stagedHyprWindowOutSpeed !== null ? stagedHyprWindowOutSpeed : UserPrefs.hyprWindowOutSpeed
    readonly property real shownHyprWorkspaceSpeed: stagedHyprWorkspaceSpeed !== null ? stagedHyprWorkspaceSpeed : UserPrefs.hyprWorkspaceSpeed
    readonly property real shownHyprLayerSpeed: stagedHyprLayerSpeed !== null ? stagedHyprLayerSpeed : UserPrefs.hyprLayerSpeed
    readonly property real shownHyprFadeSpeed: stagedHyprFadeSpeed !== null ? stagedHyprFadeSpeed : UserPrefs.hyprFadeSpeed
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
    readonly property bool shownMusicVisualizerEnabled: stagedMusicVisualizerEnabled !== null ? stagedMusicVisualizerEnabled : UserPrefs.musicVisualizerEnabled
    readonly property string shownMusicVisualizerSource: stagedMusicVisualizerSource !== null ? stagedMusicVisualizerSource : UserPrefs.musicVisualizerSource
    readonly property int shownMusicVisualizerBars: stagedMusicVisualizerBars !== null ? stagedMusicVisualizerBars : UserPrefs.musicVisualizerBars
    readonly property int shownMusicVisualizerFramerate: stagedMusicVisualizerFramerate !== null ? stagedMusicVisualizerFramerate : UserPrefs.musicVisualizerFramerate
    readonly property int shownMusicVisualizerSensitivity: stagedMusicVisualizerSensitivity !== null ? stagedMusicVisualizerSensitivity : UserPrefs.musicVisualizerSensitivity
    readonly property int shownMusicVisualizerAutosens: stagedMusicVisualizerAutosens !== null ? stagedMusicVisualizerAutosens : UserPrefs.musicVisualizerAutosens
    readonly property int shownMusicVisualizerLowerCutoff: stagedMusicVisualizerLowerCutoff !== null ? stagedMusicVisualizerLowerCutoff : UserPrefs.musicVisualizerLowerCutoff
    readonly property int shownMusicVisualizerHigherCutoff: stagedMusicVisualizerHigherCutoff !== null ? stagedMusicVisualizerHigherCutoff : UserPrefs.musicVisualizerHigherCutoff
    readonly property int shownMusicVisualizerSleepTimer: stagedMusicVisualizerSleepTimer !== null ? stagedMusicVisualizerSleepTimer : UserPrefs.musicVisualizerSleepTimer
    readonly property bool shownMusicVisualizerReverse: stagedMusicVisualizerReverse !== null ? stagedMusicVisualizerReverse : UserPrefs.musicVisualizerReverse
    readonly property int shownMusicVisualizerNoiseReduction: stagedMusicVisualizerNoiseReduction !== null ? stagedMusicVisualizerNoiseReduction : UserPrefs.musicVisualizerNoiseReduction
    readonly property string shownMusicVisualizerStyle: stagedMusicVisualizerStyle !== null ? stagedMusicVisualizerStyle : UserPrefs.musicVisualizerStyle
    readonly property bool shownMusicVisualizerUseThemeColor: stagedMusicVisualizerUseThemeColor !== null ? stagedMusicVisualizerUseThemeColor : UserPrefs.musicVisualizerUseThemeColor
    readonly property string shownMusicVisualizerCustomColor: stagedMusicVisualizerCustomColor !== null ? stagedMusicVisualizerCustomColor : UserPrefs.musicVisualizerCustomColor
    readonly property string shownMusicVisualizerColorMode: stagedMusicVisualizerColorMode !== null ? stagedMusicVisualizerColorMode : UserPrefs.musicVisualizerColorMode
    readonly property bool shownMusicVisualizerFadeDarkerTop: stagedMusicVisualizerFadeDarkerTop !== null ? stagedMusicVisualizerFadeDarkerTop : UserPrefs.musicVisualizerFadeDarkerTop
    readonly property int shownMusicVisualizerFadeStrength: stagedMusicVisualizerFadeStrength !== null ? stagedMusicVisualizerFadeStrength : UserPrefs.musicVisualizerFadeStrength
    readonly property string shownMusicVisualizerLowColor: stagedMusicVisualizerLowColor !== null ? stagedMusicVisualizerLowColor : UserPrefs.musicVisualizerLowColor
    readonly property string shownMusicVisualizerMidColor: stagedMusicVisualizerMidColor !== null ? stagedMusicVisualizerMidColor : UserPrefs.musicVisualizerMidColor
    readonly property string shownMusicVisualizerHighColor: stagedMusicVisualizerHighColor !== null ? stagedMusicVisualizerHighColor : UserPrefs.musicVisualizerHighColor
    readonly property int shownMusicVisualizerLedSegments: stagedMusicVisualizerLedSegments !== null ? stagedMusicVisualizerLedSegments : UserPrefs.musicVisualizerLedSegments
    readonly property int shownMusicVisualizerLedGap: stagedMusicVisualizerLedGap !== null ? stagedMusicVisualizerLedGap : UserPrefs.musicVisualizerLedGap
    readonly property int shownMusicVisualizerLedUnlitOpacity: stagedMusicVisualizerLedUnlitOpacity !== null ? stagedMusicVisualizerLedUnlitOpacity : UserPrefs.musicVisualizerLedUnlitOpacity

    // The diff — what the pending panel lists and Apply commits.
    readonly property var changes: {
        const c = [];
        const musicPairs = [
            ["musicVisualizerEnabled", "Visualizer", UserPrefs.musicVisualizerEnabled, stagedMusicVisualizerEnabled, v => v ? "on" : "off"],
            ["musicVisualizerSource", "Visualizer Source", UserPrefs.musicVisualizerSource, stagedMusicVisualizerSource, v => v === "mpd" ? "MPD only" : "all system audio"],
            ["musicVisualizerBars", "Visualizer Bars", UserPrefs.musicVisualizerBars, stagedMusicVisualizerBars, v => String(v)],
            ["musicVisualizerFramerate", "Visualizer FPS", UserPrefs.musicVisualizerFramerate, stagedMusicVisualizerFramerate, v => String(v)],
            ["musicVisualizerSensitivity", "Visualizer Sensitivity", UserPrefs.musicVisualizerSensitivity, stagedMusicVisualizerSensitivity, v => String(v)],
            ["musicVisualizerAutosens", "Visualizer Autosens", UserPrefs.musicVisualizerAutosens, stagedMusicVisualizerAutosens, v => String(v)],
            ["musicVisualizerLowerCutoff", "Visualizer Low Cutoff", UserPrefs.musicVisualizerLowerCutoff, stagedMusicVisualizerLowerCutoff, v => v + " Hz"],
            ["musicVisualizerHigherCutoff", "Visualizer High Cutoff", UserPrefs.musicVisualizerHigherCutoff, stagedMusicVisualizerHigherCutoff, v => v + " Hz"],
            ["musicVisualizerSleepTimer", "Visualizer Sleep", UserPrefs.musicVisualizerSleepTimer, stagedMusicVisualizerSleepTimer, v => v === 0 ? "off" : v + " s"],
            ["musicVisualizerReverse", "Visualizer Direction", UserPrefs.musicVisualizerReverse, stagedMusicVisualizerReverse, v => v ? "high to low" : "low to high"],
            ["musicVisualizerNoiseReduction", "Visualizer Smoothing", UserPrefs.musicVisualizerNoiseReduction, stagedMusicVisualizerNoiseReduction, v => String(v)],
            ["musicVisualizerStyle", "Visualizer Style", UserPrefs.musicVisualizerStyle, stagedMusicVisualizerStyle, v => v],
            ["musicVisualizerUseThemeColor", "Visualizer Theme Color", UserPrefs.musicVisualizerUseThemeColor, stagedMusicVisualizerUseThemeColor, v => v ? "on" : "off"],
            ["musicVisualizerCustomColor", "Visualizer Color", UserPrefs.musicVisualizerCustomColor, stagedMusicVisualizerCustomColor, v => v],
            ["musicVisualizerColorMode", "Visualizer Color Mode", UserPrefs.musicVisualizerColorMode, stagedMusicVisualizerColorMode, v => v],
            ["musicVisualizerFadeDarkerTop", "Visualizer Fade Direction", UserPrefs.musicVisualizerFadeDarkerTop, stagedMusicVisualizerFadeDarkerTop, v => v ? "darker top" : "lighter top"],
            ["musicVisualizerFadeStrength", "Visualizer Fade Strength", UserPrefs.musicVisualizerFadeStrength, stagedMusicVisualizerFadeStrength, v => v + "%"],
            ["musicVisualizerLowColor", "Visualizer Low Color", UserPrefs.musicVisualizerLowColor, stagedMusicVisualizerLowColor, v => v],
            ["musicVisualizerMidColor", "Visualizer Mid Color", UserPrefs.musicVisualizerMidColor, stagedMusicVisualizerMidColor, v => v],
            ["musicVisualizerHighColor", "Visualizer High Color", UserPrefs.musicVisualizerHighColor, stagedMusicVisualizerHighColor, v => v],
            ["musicVisualizerLedSegments", "Visualizer Segments", UserPrefs.musicVisualizerLedSegments, stagedMusicVisualizerLedSegments, v => String(v)],
            ["musicVisualizerLedGap", "Visualizer Segment Gap", UserPrefs.musicVisualizerLedGap, stagedMusicVisualizerLedGap, v => v + " px"],
            ["musicVisualizerLedUnlitOpacity", "Visualizer Unlit Opacity", UserPrefs.musicVisualizerLedUnlitOpacity, stagedMusicVisualizerLedUnlitOpacity, v => v + "%"]
        ];
        for (let i = 0; i < musicPairs.length; ++i) {
            const [key, label, live, staged, format] = musicPairs[i];
            if (staged !== null && staged !== live)
                c.push({ key: key, label: label, from: format(live), to: format(staged), value: staged });
        }
        const customPairs = [
            ["customThemeBaseName", "Custom Base", UserPrefs.customThemeBaseName, stagedCustomThemeBaseName],
            ["customThemeBackground", "Custom Background", UserPrefs.customThemeBackground, stagedCustomThemeBackground],
            ["customThemeForeground", "Custom Foreground", UserPrefs.customThemeForeground, stagedCustomThemeForeground],
            ["customThemeAccent", "Custom Accent", UserPrefs.customThemeAccent, stagedCustomThemeAccent],
            ["customThemeUrgent", "Custom Urgent", UserPrefs.customThemeUrgent, stagedCustomThemeUrgent],
            ["customThemeMuted", "Custom Muted", UserPrefs.customThemeMuted, stagedCustomThemeMuted],
            ["customThemeSurface", "Custom Surface", UserPrefs.customThemeSurface, stagedCustomThemeSurface],
            ["customThemeHover", "Custom Hover", UserPrefs.customThemeHover, stagedCustomThemeHover],
            ["customThemeBorder", "Custom Border", UserPrefs.customThemeBorder, stagedCustomThemeBorder],
            ["customThemeBorder2", "Custom Border 2", UserPrefs.customThemeBorder2, stagedCustomThemeBorder2],
            ["customThemeBorderAngle", "Custom Border Angle", UserPrefs.customThemeBorderAngle, stagedCustomThemeBorderAngle]
        ];
        for (let i = 0; i < customPairs.length; ++i) {
            const [key, label, live, staged] = customPairs[i];
            if (staged !== null && staged !== live)
                c.push({ key: key, label: label, from: String(live), to: String(staged), value: staged });
        }
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
        if (stagedLauncherPlacement !== null && stagedLauncherPlacement !== UserPrefs.launcherPlacement)
            c.push({ key: "launcherPlacement", label: "Launcher Placement", from: UserPrefs.launcherPlacement, to: stagedLauncherPlacement, value: stagedLauncherPlacement });
        if (stagedLauncherOffsetX !== null && stagedLauncherOffsetX !== UserPrefs.launcherOffsetX)
            c.push({ key: "launcherOffsetX", label: "Launcher Offset X", from: UserPrefs.launcherOffsetX + " px", to: stagedLauncherOffsetX + " px", value: stagedLauncherOffsetX });
        if (stagedLauncherOffsetY !== null && stagedLauncherOffsetY !== UserPrefs.launcherOffsetY)
            c.push({ key: "launcherOffsetY", label: "Launcher Offset Y", from: UserPrefs.launcherOffsetY + " px", to: stagedLauncherOffsetY + " px", value: stagedLauncherOffsetY });
        if (stagedLauncherShowAppsOnOpen !== null && stagedLauncherShowAppsOnOpen !== UserPrefs.launcherShowAppsOnOpen)
            c.push({ key: "launcherShowAppsOnOpen", label: "Show Apps on Open", from: UserPrefs.launcherShowAppsOnOpen ? "on" : "off", to: stagedLauncherShowAppsOnOpen ? "on" : "off", value: stagedLauncherShowAppsOnOpen });
        if (stagedWallpaperPickerPlacement !== null && stagedWallpaperPickerPlacement !== UserPrefs.wallpaperPickerPlacement)
            c.push({ key: "wallpaperPickerPlacement", label: "Wallpaper Picker Placement", from: UserPrefs.wallpaperPickerPlacement, to: stagedWallpaperPickerPlacement, value: stagedWallpaperPickerPlacement });
        if (stagedWallpaperPickerOffsetX !== null && stagedWallpaperPickerOffsetX !== UserPrefs.wallpaperPickerOffsetX)
            c.push({ key: "wallpaperPickerOffsetX", label: "Wallpaper Picker Offset X", from: UserPrefs.wallpaperPickerOffsetX + " px", to: stagedWallpaperPickerOffsetX + " px", value: stagedWallpaperPickerOffsetX });
        if (stagedWallpaperPickerOffsetY !== null && stagedWallpaperPickerOffsetY !== UserPrefs.wallpaperPickerOffsetY)
            c.push({ key: "wallpaperPickerOffsetY", label: "Wallpaper Picker Offset Y", from: UserPrefs.wallpaperPickerOffsetY + " px", to: stagedWallpaperPickerOffsetY + " px", value: stagedWallpaperPickerOffsetY });
        if (stagedNotifPresentation !== null && stagedNotifPresentation !== UserPrefs.notifPresentation)
            c.push({ key: "notifPresentation", label: "Notification Presentation", from: UserPrefs.notifPresentation, to: stagedNotifPresentation, value: stagedNotifPresentation });
        if (stagedNotifBarPosition !== null && stagedNotifBarPosition !== UserPrefs.notifBarPosition)
            c.push({ key: "notifBarPosition", label: "Notification Bar Position", from: UserPrefs.notifBarPosition, to: stagedNotifBarPosition, value: stagedNotifBarPosition });
        if (stagedNotifBarOffsetX !== null && stagedNotifBarOffsetX !== UserPrefs.notifBarOffsetX)
            c.push({ key: "notifBarOffsetX", label: "Notification Bar Offset X", from: UserPrefs.notifBarOffsetX + " px", to: stagedNotifBarOffsetX + " px", value: stagedNotifBarOffsetX });
        if (stagedNotifBarShowCardBorders !== null && stagedNotifBarShowCardBorders !== UserPrefs.notifBarShowCardBorders)
            c.push({ key: "notifBarShowCardBorders", label: "Attached Notification Card Borders", from: UserPrefs.notifBarShowCardBorders ? "shown" : "hidden", to: stagedNotifBarShowCardBorders ? "shown" : "hidden", value: stagedNotifBarShowCardBorders });
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
            ["hyprAnimationPreset", "Animation Feel", UserPrefs.hyprAnimationPreset, stagedHyprAnimationPreset],
            ["hyprWindowAnimationStyle", "Window Animation", UserPrefs.hyprWindowAnimationStyle, stagedHyprWindowAnimationStyle],
            ["hyprWorkspaceAnimationStyle", "Workspace Animation", UserPrefs.hyprWorkspaceAnimationStyle, stagedHyprWorkspaceAnimationStyle],
            ["hyprLayerAnimationStyle", "Layer Animation", UserPrefs.hyprLayerAnimationStyle, stagedHyprLayerAnimationStyle],
            ["hyprFadeAnimationPreset", "Fade Animation", UserPrefs.hyprFadeAnimationPreset, stagedHyprFadeAnimationPreset],
            ["hyprCustomAnimationSpeedsEnabled", "Custom Animation Speeds", UserPrefs.hyprCustomAnimationSpeedsEnabled, stagedHyprCustomAnimationSpeedsEnabled],
            ["hyprWindowSpeed", "Window Speed", UserPrefs.hyprWindowSpeed, stagedHyprWindowSpeed],
            ["hyprWindowInSpeed", "Window Open Speed", UserPrefs.hyprWindowInSpeed, stagedHyprWindowInSpeed],
            ["hyprWindowOutSpeed", "Window Close Speed", UserPrefs.hyprWindowOutSpeed, stagedHyprWindowOutSpeed],
            ["hyprWorkspaceSpeed", "Workspace Speed", UserPrefs.hyprWorkspaceSpeed, stagedHyprWorkspaceSpeed],
            ["hyprLayerSpeed", "Layer Speed", UserPrefs.hyprLayerSpeed, stagedHyprLayerSpeed],
            ["hyprFadeSpeed", "Fade Speed", UserPrefs.hyprFadeSpeed, stagedHyprFadeSpeed]
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
            ["wallpaperCachingEnabled", "Cache Thumbnails", UserPrefs.wallpaperCachingEnabled, stagedWallpaperCachingEnabled, fmtOnOff],
            ["clockUse24Hour", "24-Hour Time", UserPrefs.clockUse24Hour, stagedClockUse24Hour, fmtOnOff],
            ["clockShowSeconds", "Show Seconds", UserPrefs.clockShowSeconds, stagedClockShowSeconds, fmtOnOff],
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
        stagedCustomThemeBaseName = null;
        stagedCustomThemeBackground = null;
        stagedCustomThemeForeground = null;
        stagedCustomThemeAccent = null;
        stagedCustomThemeUrgent = null;
        stagedCustomThemeMuted = null;
        stagedCustomThemeSurface = null;
        stagedCustomThemeHover = null;
        stagedCustomThemeBorder = null;
        stagedCustomThemeBorder2 = null;
        stagedCustomThemeBorderAngle = null;
        stagedBarPaddingTopOverride = null;
        stagedBarPaddingSideOverride = null;
        stagedBarPaddingBottomOverride = null;
        stagedFontFamilyOverride = null;
        stagedNotifPresentation = null;
        stagedNotifBarPosition = null;
        stagedNotifBarOffsetX = null;
        stagedNotifBarShowCardBorders = null;
        stagedNotifShowAppName = null;
        stagedNotifIconSize = null;
        stagedNotifBodyLines = null;
        stagedNotifFontScale = null;
        stagedLauncherPlacement = null;
        stagedLauncherOffsetX = null;
        stagedLauncherOffsetY = null;
        stagedLauncherShowAppsOnOpen = null;
        stagedWallpaperPickerPlacement = null;
        stagedWallpaperPickerOffsetX = null;
        stagedWallpaperPickerOffsetY = null;
        stagedWallpaperCachingEnabled = null;
        stagedClockUse24Hour = null;
        stagedClockShowSeconds = null;
        stagedHyprGapsIn = null;
        stagedHyprGapsOut = null;
        stagedHyprBorderSize = null;
        stagedHyprRounding = null;
        stagedHyprAnimationPreset = null;
        stagedHyprWindowAnimationStyle = null;
        stagedHyprWorkspaceAnimationStyle = null;
        stagedHyprLayerAnimationStyle = null;
        stagedHyprFadeAnimationPreset = null;
        stagedHyprCustomAnimationSpeedsEnabled = null;
        stagedHyprWindowSpeed = null;
        stagedHyprWindowInSpeed = null;
        stagedHyprWindowOutSpeed = null;
        stagedHyprWorkspaceSpeed = null;
        stagedHyprLayerSpeed = null;
        stagedHyprFadeSpeed = null;
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
        stagedMusicVisualizerEnabled = null;
        stagedMusicVisualizerSource = null;
        stagedMusicVisualizerBars = null;
        stagedMusicVisualizerFramerate = null;
        stagedMusicVisualizerSensitivity = null;
        stagedMusicVisualizerAutosens = null;
        stagedMusicVisualizerLowerCutoff = null;
        stagedMusicVisualizerHigherCutoff = null;
        stagedMusicVisualizerSleepTimer = null;
        stagedMusicVisualizerReverse = null;
        stagedMusicVisualizerNoiseReduction = null;
        stagedMusicVisualizerStyle = null;
        stagedMusicVisualizerUseThemeColor = null;
        stagedMusicVisualizerCustomColor = null;
        stagedMusicVisualizerColorMode = null;
        stagedMusicVisualizerFadeDarkerTop = null;
        stagedMusicVisualizerFadeStrength = null;
        stagedMusicVisualizerLowColor = null;
        stagedMusicVisualizerMidColor = null;
        stagedMusicVisualizerHighColor = null;
        stagedMusicVisualizerLedSegments = null;
        stagedMusicVisualizerLedGap = null;
        stagedMusicVisualizerLedUnlitOpacity = null;
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
        const customSelected = shownTheme === "CustomTheme";
        const primaryHex = customSelected
            ? _settingsHexToHyprHex(shownCustomThemeBorder)
            : _qColorToHyprHex(selectedTheme.barBorderColor);
        const secondaryEnabled = customSelected
            ? shownCustomThemeBorder2 !== "transparent"
            : selectedTheme.barBorderColor2.a > 0.001;
        const secondaryHex = customSelected
            ? (secondaryEnabled ? _settingsHexToHyprHex(shownCustomThemeBorder2) : "")
            : (secondaryEnabled ? _qColorToHyprHex(selectedTheme.barBorderColor2) : "");
        const gradient = followsAppearance && shownBarBorderUseThemeColor && secondaryEnabled;
        return {
            useTheme: followsAppearance,
            primaryHex: shownBarBorderUseThemeColor
                ? primaryHex : _settingsHexToHyprHex(shownBarBorderCustomColor),
            secondaryHex: gradient ? secondaryHex : "",
            gradient: gradient,
            angle: customSelected ? shownCustomThemeBorderAngle : selectedTheme.barBorderGradientAngle,
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
            { key: "hyprWindowAnimationStyle", value: UserPrefs.hyprWindowAnimationStyle },
            { key: "hyprWorkspaceAnimationStyle", value: UserPrefs.hyprWorkspaceAnimationStyle },
            { key: "hyprLayerAnimationStyle", value: UserPrefs.hyprLayerAnimationStyle },
            { key: "hyprFadeAnimationPreset", value: UserPrefs.hyprFadeAnimationPreset },
            { key: "hyprCustomAnimationSpeedsEnabled", value: UserPrefs.hyprCustomAnimationSpeedsEnabled },
            { key: "hyprWindowSpeed", value: UserPrefs.hyprWindowSpeed },
            { key: "hyprWindowInSpeed", value: UserPrefs.hyprWindowInSpeed },
            { key: "hyprWindowOutSpeed", value: UserPrefs.hyprWindowOutSpeed },
            { key: "hyprWorkspaceSpeed", value: UserPrefs.hyprWorkspaceSpeed },
            { key: "hyprLayerSpeed", value: UserPrefs.hyprLayerSpeed },
            { key: "hyprFadeSpeed", value: UserPrefs.hyprFadeSpeed },
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
