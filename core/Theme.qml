//=============================================================================
// FILE
//=============================================================================
//
// core/Theme.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// This is THE thing every widget should reference for colors, fonts, and
// sizes. No widget should ever hardcode a hex color, a font name, or a
// pixel size directly — it should ask this file for it instead.
//
// This file does not contain the actual color/font/size VALUES. Those live
// in themes/DefaultTheme.qml (and, later, any other theme file you build).
// This file just exposes a stable set of property names that widgets can
// depend on, and points them at whichever theme file is currently active.
//
// Why split it this way instead of putting colors directly in this file:
// so that building a new theme later means writing ONE new file in themes/
// and changing ONE line here — not hunting through every widget.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell               (for the Singleton type)
// QtQuick
// themes/DefaultTheme.qml  (imported as qs.themes — the currently active
//                           theme's actual values)
// core/Settings.qml        (neighboring file in this same folder, no
//                           import needed — reads `Settings.fontScale`
//                           to compute `fontSize`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// Any file that does `import qs.core` and references `Theme.something`.
// Currently: widgets/TopBar/TopBar.qml, widgets/TopBar/Clock.qml,
// widgets/TopBar/Workspaces.qml, widgets/TopBar/SystemMenu.qml,
// widgets/TopBar/MenuButton.qml, widgets/TopBar/MenuDivider.qml.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Every widget referencing `Theme.something` will fail to resolve that
// name and QML will throw a reference error at load time. This file is a
// hard dependency for the whole visual layer.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// THIS IS NOW A SINGLETON — read this if you're used to the old pattern:
//
// This file used to be a plain QtObject that core/ShellRoot.qml
// instantiated once and passed down to every widget as a `theme:`
// property. It's now `pragma Singleton`, which means:
//
//   - There is still only ONE instance, same as before.
//   - Nothing creates it explicitly anymore — Quickshell instantiates it
//     lazily the first time something reads a property from it.
//   - Any file reaches it with `import qs.core` and then just uses
//     `Theme.colorBackground` etc. directly — no `property var theme`
//     declaration, no passing it in when a widget is instantiated.
//
// This was a deliberate change from the original design, which avoided
// `pragma Singleton` due to a since-corrected misunderstanding about it
// requiring extra qmldir setup. See docs/PROBLEMS_AND_FIXES.md for the
// full story if you're wondering why this looks different from an older
// version of this file.
//
// HOW TO BUILD A NEW THEME LATER:
//
// 1. Copy themes/DefaultTheme.qml to themes/YourThemeName.qml
// 2. Change the values inside it
// 3. Change the import alias below from DefaultTheme to YourThemeName
//    (or, once core/Settings.qml grows out further, make this switchable
//    at runtime instead of requiring an edit here — planned, not done)
//
// PROPERTY NAMING CONVENTION (keep this consistent as we add more):
//
//   colorBackground     - main panel/bar background
//   colorForeground     - main text color
//   colorAccent         - hover/selected/active highlight color
//   colorUrgent         - critical/urgent state color (#f53c3c in the
//                         default theme)
//   colorMuted          - de-emphasized state (e.g. an empty workspace
//                         indicator) — present but not active/important
//   colorSurface        - background for elevated UI like dropdown
//                         menus — a shade off colorBackground so popups
//                         read as sitting above the bar, not blended in
//   colorHover          - hover/highlight background for clickable rows
//                         inside a menu (e.g. widgets/TopBar/MenuButton.qml)
//   fontFamily          - default font for all widgets
//   fontSize            - default font size, in pixels. This is the
//                         active theme's base size (`active.fontSize`)
//                         multiplied by `Settings.fontScale` — widgets
//                         should ALWAYS read `Theme.fontSize`, never
//                         `active.fontSize` directly, or they'll ignore
//                         the user's text-scale preference.
//   barHeight           - height of the top bar, in pixels
//   radiusMedium        - corner radius for popups/menu buttons
//   spacingSmall/Medium/Large - standard gaps, so widgets don't each
//                         invent their own padding values
//   animationDuration   - shared duration (ms) for popup-menu open
//                         animations, so every dropdown opens at the
//                         same speed without each widget picking its own
//   animationEasing     - shared easing curve (an Easing.* enum value)
//                         for the same animations
//
// WHY fontSize IS COMPUTED, NOT A DIRECT FORWARD:
//
// Every other property here is a straight passthrough to `active.x`.
// `fontSize` is the one exception — it's `active.fontSize *
// Settings.fontScale`, rounded to a whole pixel. See core/Settings.qml's
// DESIGN NOTES for why the scale factor itself lives in Settings rather
// than in the theme: short version, "bigger text" is a behavior
// preference that should survive switching themes, not a per-theme
// value.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-12  (Sonnet 5) Forwarded `barPaddingTop`/`barPaddingSide`/
//             `barPaddingBottom` (per-edge overrides of barMargin,
//             settings window Appearance page) and made `fontFamily`
//             consult UserPrefs.fontFamilyOverride first. Same
//             -1/"" = follow-theme convention as the existing
//             barBorderWidth override; fresh installs unaffected.
// 2026-07-10  (Fable 5) Forwarded new `barBorderColor` and computed
//             `barBorderWidth` (theme value -1 = follow
//             UserPrefs.hyprBorderSize live — the bar/popout border
//             project; see TopBar.qml + BarPopout.qml). Same-day:
//             `barBorderColor2`, `barBorderGradientAngle`, and
//             computed `barBorderFillet` (-1 = follow barRadius).
//             Later same day: barBorderWidth/Color now consult the
//             UserPrefs overrides FIRST (Appearance page's Bar Border
//             section) — full precedence chain at the definitions.
// 2026-07-04  Forwarded new `barMargin` and `barRadius` (bar framing —
//             see themes/DefaultTheme.qml).
// 2026-07-01  Removed `tooltipDelay` forward — the tooltip was removed
//             same day.
// 2026-07-01  Forwarded new `tooltipDelay`. (Removed — see entry above.)
// 2026-07-01  Forwarded new `animationDuration` and `animationEasing` —
//             shared timing for the dropdown-menu open animation (see
//             widgets/TopBar/SystemMenu.qml).
// 2026-07-01  Forwarded new `colorSurface`, `colorHover`, and
//             `radiusMedium` — used by the new dropdown-menu pattern
//             (widgets/TopBar/SystemMenu.qml, MenuButton.qml).
// 2026-07-11  (Sonnet 5) FIX: 18 theme files (AyuDark through
//             TokyoNight) existed on disk but were never instantiated
//             here — `themes` only had DefaultTheme/HoneycombTheme,
//             so the settings window's picker could never actually
//             select them (they were entirely invisible, not broken).
//             Added a child instance + map entry for each; no other
//             property changed. See PROBLEMS_AND_FIXES.md.
// 2026-07-09  (Fable 5) RUNTIME THEME SWITCHING — the retry of the
//             2026-07-05 attempt that broke the bar, this time with a
//             ConfigManager snapshot taken first and a deliberately
//             different pattern: theme instances as named children
//             (never inline in an object literal), a parenthesized
//             `themes` map, `themeNames` for the picker, and `active`
//             bound to UserPrefs.themeName with a fallback for
//             unknown names. Also `fontSize` now multiplies by
//             UserPrefs.fontScale (moved from Settings this session —
//             see both files' revision notes). Widgets untouched:
//             the forwarding layer did its job.
// 2026-07-01  Forwarded new `colorMuted` from the active theme.
// 2026-07-01  `fontSize` is now `active.fontSize * Settings.fontScale`
//             (rounded), instead of a direct forward of
//             `active.fontSize`. No import needed for Settings — it's a
//             neighboring file in core/. Every other property unchanged.
// 2026-07-01  Converted to `pragma Singleton`. Removed the old
//             "core/ShellRoot.qml creates one instance, passes it down"
//             wiring entirely. Import switched from relative
//             (`import "../themes"`) to module-style (`import qs.themes`).
//             Values unchanged (still forwards themes/DefaultTheme.qml).
//
//=============================================================================

pragma Singleton

import Quickshell
import QtQuick
import qs.themes

Singleton {
    id: root

    // Every theme instantiated ONCE, as named children of the
    // singleton. NOT instantiated inline inside the `themes` object
    // literal below — QML cannot create objects inside a `{...}` JS
    // expression, and that pattern is the prime suspect for what
    // killed the 2026-07-05 theme-switching attempt (root cause was
    // never confirmed; this rebuild avoids every candidate).
    DefaultTheme { id: defaultThemeInst }
    HoneycombTheme { id: honeycombThemeInst }
    AyuDarkTheme { id: ayuDarkThemeInst }
    AyuMirageTheme { id: ayuMirageThemeInst }
    CatppuccinMochaTheme { id: catppuccinMochaThemeInst }
    DraculaTheme { id: draculaThemeInst }
    EverforestTheme { id: everforestThemeInst }
    GruvboxTheme { id: gruvboxThemeInst }
    HorizonTheme { id: horizonThemeInst }
    KanagawaTheme { id: kanagawaThemeInst }
    MaterialOceanTheme { id: materialOceanThemeInst }
    MonokaiTheme { id: monokaiThemeInst }
    NightfoxTheme { id: nightfoxThemeInst }
    NordTheme { id: nordThemeInst }
    OceanicNextTheme { id: oceanicNextThemeInst }
    OneDarkTheme { id: oneDarkThemeInst }
    PalenightTheme { id: palenightThemeInst }
    RosePineTheme { id: rosePineThemeInst }
    SolarizedTheme { id: solarizedThemeInst }
    Synthwave84Theme { id: synthwave84ThemeInst }
    TokyoNightTheme { id: tokyoNightThemeInst }

    // Type-name -> instance. Parenthesized so the QML parser reads an
    // object literal, not a code block. ADDING A THEME = one child
    // instance above + one line here; nothing else changes.
    //
    // 2026-07-11 (Sonnet 5): FOUND + FIXED — 18 theme files existed on
    // disk (AyuDark through TokyoNight) but were never instantiated
    // here, so they were completely invisible to the picker (the
    // AI-MAINTENANCE-GUIDE's documented "a file nothing instantiates
    // is invisible" failure mode, verbatim). This is why the settings
    // window "didn't update themes" — selecting one of those names was
    // never actually possible; `themeNames` only ever had two entries.
    readonly property var themes: ({
        "DefaultTheme": defaultThemeInst,
        "HoneycombTheme": honeycombThemeInst,
        "AyuDarkTheme": ayuDarkThemeInst,
        "AyuMirageTheme": ayuMirageThemeInst,
        "CatppuccinMochaTheme": catppuccinMochaThemeInst,
        "DraculaTheme": draculaThemeInst,
        "EverforestTheme": everforestThemeInst,
        "GruvboxTheme": gruvboxThemeInst,
        "HorizonTheme": horizonThemeInst,
        "KanagawaTheme": kanagawaThemeInst,
        "MaterialOceanTheme": materialOceanThemeInst,
        "MonokaiTheme": monokaiThemeInst,
        "NightfoxTheme": nightfoxThemeInst,
        "NordTheme": nordThemeInst,
        "OceanicNextTheme": oceanicNextThemeInst,
        "OneDarkTheme": oneDarkThemeInst,
        "PalenightTheme": palenightThemeInst,
        "RosePineTheme": rosePineThemeInst,
        "SolarizedTheme": solarizedThemeInst,
        "Synthwave84Theme": synthwave84ThemeInst,
        "TokyoNightTheme": tokyoNightThemeInst
    })

    // What the settings window's theme picker lists.
    readonly property var themeNames: Object.keys(themes)

    readonly property string fallbackThemeName: "HoneycombTheme"

    // Runtime theme switching, live: UserPrefs (neighboring core
    // singleton, no import needed) persists the name; unknown/legacy
    // names (e.g. the pre-Phase-2 stored "Honeycomb") fall back
    // gracefully and self-correct on the next Apply.
    property var active: themes[UserPrefs.themeName] ?? themes[fallbackThemeName]

    // ---- Forwarded properties — widgets bind to THESE, never to `active` directly ----
    // This extra layer of indirection means if we ever change how themes
    // are loaded (e.g. runtime switching), widget code doesn't change at all.
    readonly property color colorBackground: active.colorBackground
    readonly property color colorForeground: active.colorForeground
    readonly property color colorAccent: active.colorAccent
    readonly property color colorUrgent: active.colorUrgent
    readonly property color colorMuted: active.colorMuted
    readonly property color colorSurface: active.colorSurface
    readonly property color colorHover: active.colorHover

    // NOT a direct forward (third exception, after fontSize and
    // barBorderWidth): "" from UserPrefs means "follow the theme",
    // same convention as everywhere else an override lives.
    readonly property string fontFamily:
        UserPrefs.fontFamilyOverride !== ""
            ? UserPrefs.fontFamilyOverride : active.fontFamily

    // NOT a direct forward — see DESIGN NOTES above. `Settings` is a
    // neighboring singleton in this same folder, reachable with no
    // import statement.
    readonly property int fontSize: Math.round(active.fontSize * UserPrefs.fontScale)

    readonly property int barHeight: active.barHeight
    readonly property int radiusMedium: active.radiusMedium
    readonly property int barMargin: active.barMargin
    readonly property int barRadius: active.barRadius

    // Per-edge bar padding (settings window, Appearance page,
    // 2026-07-12). Same precedence rule as barBorderWidth: a user
    // override (>=0) wins, otherwise fall through to the theme's
    // single barMargin token — so every existing theme keeps working
    // unmodified (they only define barMargin, never the per-edge
    // ones) and the default on a fresh install is identical on all
    // three edges, exactly like before this feature existed.
    readonly property int barPaddingTop:
        UserPrefs.barPaddingTopOverride >= 0
            ? UserPrefs.barPaddingTopOverride : active.barMargin
    readonly property int barPaddingSide:
        UserPrefs.barPaddingSideOverride >= 0
            ? UserPrefs.barPaddingSideOverride : active.barMargin
    // NOT a ">= 0" check like top/side — bottom can legitimately be
    // negative (canceling out Hyprland's own gaps_out under the bar;
    // see UserPrefs.barPaddingBottomOffSentinel for why -1 couldn't
    // keep double-duty as the sentinel here).
    readonly property int barPaddingBottom:
        UserPrefs.barPaddingBottomOverride > UserPrefs.barPaddingBottomOffSentinel
            ? UserPrefs.barPaddingBottomOverride : active.barMargin

    // NOT a direct forward (second exception after fontSize): a theme
    // value of -1 means "follow the Hyprland border size the settings
    // window manages" — UserPrefs.hyprBorderSize, live, so moving
    // Border Size on the Hyprland page moves the bar's border with it.
    // 0 disables the border; >0 is a fixed per-theme width.
    // Precedence: user override (settings window, Appearance page)
    // beats the theme token; the theme's -1 beats nothing and falls
    // through to the Hyprland border size. So:
    //   width: UserPrefs.barBorderWidthOverride (>=0)
    //          -> theme barBorderWidth (>=0)
    //          -> UserPrefs.hyprBorderSize
    //   color: theme's, unless the user turned "use theme color" off,
    //          then their validated hex from user-prefs.json.
    readonly property int barBorderWidth:
        UserPrefs.barBorderWidthOverride >= 0
            ? UserPrefs.barBorderWidthOverride
            : (active.barBorderWidth >= 0
                ? active.barBorderWidth : UserPrefs.hyprBorderSize)
    readonly property color barBorderColor:
        UserPrefs.barBorderUseThemeColor
            ? active.barBorderColor : UserPrefs.barBorderCustomColor

    // Gradient second stop (transparent = solid) and angle — see
    // themes/DefaultTheme.qml for the convention.
    // A manually selected bar-border color is intentionally solid. The
    // theme's second gradient stop only participates while "Use theme color"
    // is enabled; otherwise it would keep bleeding the theme color into the
    // user's custom primary color and make the override look ineffective.
    readonly property color barBorderColor2:
        UserPrefs.barBorderUseThemeColor ? active.barBorderColor2 : "transparent"
    readonly property real barBorderGradientAngle: active.barBorderGradientAngle

    // Fillet radius where popouts meet the bar. Theme value -1 =
    // follow barRadius so the joint matches the bar's own corners.
    readonly property int barBorderFillet: active.barBorderFilletRadius >= 0
        ? active.barBorderFilletRadius : active.barRadius

    readonly property int spacingSmall: active.spacingSmall
    readonly property int spacingMedium: active.spacingMedium
    readonly property int spacingLarge: active.spacingLarge

    readonly property int animationDuration: active.animationDuration
    readonly property int animationEasing: active.animationEasing
}
