// Music player settings. Phase 1 exposes the CAVA visualizer controls.
// Equalizer controls arrive after the EasyEffects backend is verified.
// GPT — 2026-07-25

import QtQuick
import QtQuick.Layouts
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page

    required property var settingsRoot

    spacing: Theme.spacingSmall

    // Keep the control cluster clear of long labels at the minimum
    // supported Settings window width. // GPT 2026-07-25
    readonly property int controlLabelWidth: Math.round(Theme.fontSize * 13.0)
    readonly property int controlValueWidth: Math.round(Theme.fontSize * 5.2)
    SettingsComponents.SettingsSectionHeader { title: "Visualizer" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall

        SettingsComponents.ToggleSettingRow {
            label: "Show visualizer"
            value: page.settingsRoot.shownMusicVisualizerEnabled
            staged: page.settingsRoot.stagedMusicVisualizerEnabled !== null
            onToggled: page.settingsRoot.stagedMusicVisualizerEnabled =
                !page.settingsRoot.shownMusicVisualizerEnabled
        }

        SettingsComponents.OptionPickerRow {
            label: "Audio source"
            description: "Choose MPD only or the complete PipeWire output."
            options: [
                { text: "MPD only", value: "mpd" },
                { text: "All system audio", value: "system" }
            ]
            shownValue: page.settingsRoot.shownMusicVisualizerSource
            staged: page.settingsRoot.stagedMusicVisualizerSource !== null
            onPicked: value => page.settingsRoot.stagedMusicVisualizerSource = value
        }
    }
    SettingsComponents.SettingsSectionHeader { title: "Appearance" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall

        SettingsComponents.OptionPickerRow {
            label: "Bar style"
            options: [
                { text: "Solid", value: "solid" },
                { text: "LED", value: "led" },
                { text: "Dots", value: "dots" }
            ]
            shownValue: page.settingsRoot.shownMusicVisualizerStyle
            staged: page.settingsRoot.stagedMusicVisualizerStyle !== null
            onPicked: value => page.settingsRoot.stagedMusicVisualizerStyle = value
        }

        SettingsComponents.OptionPickerRow {
            label: "Color treatment"
            options: [
                { text: "Solid", value: "solid" },
                { text: "Fade", value: "fade" },
                { text: "3-zone", value: "zones" }
            ]
            shownValue: page.settingsRoot.shownMusicVisualizerColorMode
            staged: page.settingsRoot.stagedMusicVisualizerColorMode !== null
            onPicked: value => page.settingsRoot.stagedMusicVisualizerColorMode = value
        }

        SettingsComponents.ToggleSettingRow {
            visible: page.settingsRoot.shownMusicVisualizerColorMode !== "zones"
            label: "Use theme accent"
            value: page.settingsRoot.shownMusicVisualizerUseThemeColor
            staged: page.settingsRoot.stagedMusicVisualizerUseThemeColor !== null
            onToggled: page.settingsRoot.stagedMusicVisualizerUseThemeColor =
                !page.settingsRoot.shownMusicVisualizerUseThemeColor
        }

        SettingsComponents.HexColorRow {
            visible: page.settingsRoot.shownMusicVisualizerColorMode !== "zones"
                && !page.settingsRoot.shownMusicVisualizerUseThemeColor
            colorPickerHost: page.settingsRoot
            label: "Visualizer color"
            shownValue: page.settingsRoot.shownMusicVisualizerCustomColor
            staged: page.settingsRoot.stagedMusicVisualizerCustomColor !== null
            onHexStaged: value => page.settingsRoot.stagedMusicVisualizerCustomColor = value
        }

        SettingsComponents.ToggleSettingRow {
            visible: page.settingsRoot.shownMusicVisualizerColorMode === "fade"
            label: "Darker toward top"
            value: page.settingsRoot.shownMusicVisualizerFadeDarkerTop
            staged: page.settingsRoot.stagedMusicVisualizerFadeDarkerTop !== null
            onToggled: page.settingsRoot.stagedMusicVisualizerFadeDarkerTop =
                !page.settingsRoot.shownMusicVisualizerFadeDarkerTop
        }

        SettingsComponents.StepperRow {
            visible: page.settingsRoot.shownMusicVisualizerColorMode === "fade"
            label: "Fade strength"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: page.settingsRoot.shownMusicVisualizerFadeStrength + "%"
            staged: page.settingsRoot.stagedMusicVisualizerFadeStrength !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerFadeStrength = Math.max(0, page.settingsRoot.shownMusicVisualizerFadeStrength - 5)
            onPlus: page.settingsRoot.stagedMusicVisualizerFadeStrength = Math.min(100, page.settingsRoot.shownMusicVisualizerFadeStrength + 5)
            onReset: page.settingsRoot.stagedMusicVisualizerFadeStrength = 45
        }

        SettingsComponents.HexColorRow {
            visible: page.settingsRoot.shownMusicVisualizerColorMode === "zones"
            colorPickerHost: page.settingsRoot
            label: "Low segments"
            shownValue: page.settingsRoot.shownMusicVisualizerLowColor
            staged: page.settingsRoot.stagedMusicVisualizerLowColor !== null
            onHexStaged: value => page.settingsRoot.stagedMusicVisualizerLowColor = value
        }

        SettingsComponents.HexColorRow {
            visible: page.settingsRoot.shownMusicVisualizerColorMode === "zones"
            colorPickerHost: page.settingsRoot
            label: "Middle segments"
            shownValue: page.settingsRoot.shownMusicVisualizerMidColor
            staged: page.settingsRoot.stagedMusicVisualizerMidColor !== null
            onHexStaged: value => page.settingsRoot.stagedMusicVisualizerMidColor = value
        }

        SettingsComponents.HexColorRow {
            visible: page.settingsRoot.shownMusicVisualizerColorMode === "zones"
            colorPickerHost: page.settingsRoot
            label: "High segments"
            shownValue: page.settingsRoot.shownMusicVisualizerHighColor
            staged: page.settingsRoot.stagedMusicVisualizerHighColor !== null
            onHexStaged: value => page.settingsRoot.stagedMusicVisualizerHighColor = value
        }

        Text {
            visible: page.settingsRoot.shownMusicVisualizerStyle !== "solid"
            text: page.settingsRoot.shownMusicVisualizerStyle === "dots" ? "Dot cells" : "LED cells"
            Layout.topMargin: Theme.spacingLarge
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
        }

        SettingsComponents.StepperRow {
            visible: page.settingsRoot.shownMusicVisualizerStyle !== "solid"
            label: "Segments"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: String(page.settingsRoot.shownMusicVisualizerLedSegments)
            staged: page.settingsRoot.stagedMusicVisualizerLedSegments !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerLedSegments = Math.max(8, page.settingsRoot.shownMusicVisualizerLedSegments - 2)
            onPlus: page.settingsRoot.stagedMusicVisualizerLedSegments = Math.min(40, page.settingsRoot.shownMusicVisualizerLedSegments + 2)
            onReset: page.settingsRoot.stagedMusicVisualizerLedSegments = 20
        }

        SettingsComponents.StepperRow {
            visible: page.settingsRoot.shownMusicVisualizerStyle !== "solid"
            label: "Cell gap"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: page.settingsRoot.shownMusicVisualizerLedGap + " px"
            staged: page.settingsRoot.stagedMusicVisualizerLedGap !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerLedGap = Math.max(0, page.settingsRoot.shownMusicVisualizerLedGap - 1)
            onPlus: page.settingsRoot.stagedMusicVisualizerLedGap = Math.min(6, page.settingsRoot.shownMusicVisualizerLedGap + 1)
            onReset: page.settingsRoot.stagedMusicVisualizerLedGap = 2
        }

        SettingsComponents.StepperRow {
            visible: page.settingsRoot.shownMusicVisualizerStyle !== "solid"
            label: "Unlit opacity"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: page.settingsRoot.shownMusicVisualizerLedUnlitOpacity + "%"
            staged: page.settingsRoot.stagedMusicVisualizerLedUnlitOpacity !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerLedUnlitOpacity = Math.max(0, page.settingsRoot.shownMusicVisualizerLedUnlitOpacity - 5)
            onPlus: page.settingsRoot.stagedMusicVisualizerLedUnlitOpacity = Math.min(50, page.settingsRoot.shownMusicVisualizerLedUnlitOpacity + 5)
            onReset: page.settingsRoot.stagedMusicVisualizerLedUnlitOpacity = 10
        }
    }
    SettingsComponents.SettingsSectionHeader { title: "Spectrum" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall

        SettingsComponents.StepperRow {
            label: "Bars"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: String(page.settingsRoot.shownMusicVisualizerBars)
            staged: page.settingsRoot.stagedMusicVisualizerBars !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerBars = Math.max(8, page.settingsRoot.shownMusicVisualizerBars - 8)
            onPlus: page.settingsRoot.stagedMusicVisualizerBars = Math.min(96, page.settingsRoot.shownMusicVisualizerBars + 8)
            onReset: page.settingsRoot.stagedMusicVisualizerBars = 32
        }

        SettingsComponents.StepperRow {
            label: "Frame rate"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: page.settingsRoot.shownMusicVisualizerFramerate + " FPS"
            staged: page.settingsRoot.stagedMusicVisualizerFramerate !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerFramerate = Math.max(15, page.settingsRoot.shownMusicVisualizerFramerate - 5)
            onPlus: page.settingsRoot.stagedMusicVisualizerFramerate = Math.min(144, page.settingsRoot.shownMusicVisualizerFramerate + 5)
            onReset: page.settingsRoot.stagedMusicVisualizerFramerate = 60
        }

        SettingsComponents.StepperRow {
            label: "Sensitivity"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: String(page.settingsRoot.shownMusicVisualizerSensitivity)
            staged: page.settingsRoot.stagedMusicVisualizerSensitivity !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerSensitivity = Math.max(10, page.settingsRoot.shownMusicVisualizerSensitivity - 5)
            onPlus: page.settingsRoot.stagedMusicVisualizerSensitivity = Math.min(300, page.settingsRoot.shownMusicVisualizerSensitivity + 5)
            onReset: page.settingsRoot.stagedMusicVisualizerSensitivity = 100
        }

        SettingsComponents.StepperRow {
            label: "Automatic sensitivity"
            labelColumnWidth: page.controlLabelWidth
            valueText: page.settingsRoot.shownMusicVisualizerAutosens === 0 ? "Off"
                : page.settingsRoot.shownMusicVisualizerAutosens === 1 ? "Normal" : "Aggressive"
            staged: page.settingsRoot.stagedMusicVisualizerAutosens !== null
            showReset: true
            valueColumnWidth: Math.round(Theme.fontSize * 6.2)
            onMinus: page.settingsRoot.stagedMusicVisualizerAutosens = Math.max(0, page.settingsRoot.shownMusicVisualizerAutosens - 1)
            onPlus: page.settingsRoot.stagedMusicVisualizerAutosens = Math.min(2, page.settingsRoot.shownMusicVisualizerAutosens + 1)
            onReset: page.settingsRoot.stagedMusicVisualizerAutosens = 1
        }

        SettingsComponents.StepperRow {
            label: "Smoothing"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: String(page.settingsRoot.shownMusicVisualizerNoiseReduction)
            staged: page.settingsRoot.stagedMusicVisualizerNoiseReduction !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerNoiseReduction = Math.max(0, page.settingsRoot.shownMusicVisualizerNoiseReduction - 5)
            onPlus: page.settingsRoot.stagedMusicVisualizerNoiseReduction = Math.min(100, page.settingsRoot.shownMusicVisualizerNoiseReduction + 5)
            onReset: page.settingsRoot.stagedMusicVisualizerNoiseReduction = 77
        }
    }
    SettingsComponents.SettingsSectionHeader { title: "Frequency range" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall

        SettingsComponents.StepperRow {
            label: "Low cutoff"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: page.settingsRoot.shownMusicVisualizerLowerCutoff + " Hz"
            staged: page.settingsRoot.stagedMusicVisualizerLowerCutoff !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerLowerCutoff = Math.max(20, page.settingsRoot.shownMusicVisualizerLowerCutoff - 10)
            onPlus: page.settingsRoot.stagedMusicVisualizerLowerCutoff = Math.min(1000, Math.min(page.settingsRoot.shownMusicVisualizerHigherCutoff - 100, page.settingsRoot.shownMusicVisualizerLowerCutoff + 10))
            onReset: page.settingsRoot.stagedMusicVisualizerLowerCutoff = 50
        }

        SettingsComponents.StepperRow {
            label: "High cutoff"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: page.settingsRoot.shownMusicVisualizerHigherCutoff + " Hz"
            staged: page.settingsRoot.stagedMusicVisualizerHigherCutoff !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerHigherCutoff = Math.max(page.settingsRoot.shownMusicVisualizerLowerCutoff + 100, page.settingsRoot.shownMusicVisualizerHigherCutoff - 500)
            onPlus: page.settingsRoot.stagedMusicVisualizerHigherCutoff = Math.min(22000, page.settingsRoot.shownMusicVisualizerHigherCutoff + 500)
            onReset: page.settingsRoot.stagedMusicVisualizerHigherCutoff = 10000
        }

        SettingsComponents.ToggleSettingRow {
            label: "Reverse frequency direction"
            value: page.settingsRoot.shownMusicVisualizerReverse
            staged: page.settingsRoot.stagedMusicVisualizerReverse !== null
            onToggled: page.settingsRoot.stagedMusicVisualizerReverse =
                !page.settingsRoot.shownMusicVisualizerReverse
        }
    }
    SettingsComponents.SettingsSectionHeader { title: "Process" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall

        SettingsComponents.StepperRow {
            label: "Silence sleep timer"
            labelColumnWidth: page.controlLabelWidth
            valueColumnWidth: page.controlValueWidth
            valueText: page.settingsRoot.shownMusicVisualizerSleepTimer === 0
                ? "Off" : page.settingsRoot.shownMusicVisualizerSleepTimer + " s"
            staged: page.settingsRoot.stagedMusicVisualizerSleepTimer !== null
            showReset: true
            onMinus: page.settingsRoot.stagedMusicVisualizerSleepTimer = Math.max(0, page.settingsRoot.shownMusicVisualizerSleepTimer - 5)
            onPlus: page.settingsRoot.stagedMusicVisualizerSleepTimer = Math.min(60, page.settingsRoot.shownMusicVisualizerSleepTimer + 5)
            onReset: page.settingsRoot.stagedMusicVisualizerSleepTimer = 0
        }

        Item { Layout.fillHeight: true }
    }
}
