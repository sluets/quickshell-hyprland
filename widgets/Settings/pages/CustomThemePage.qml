import QtQuick
import QtQuick.Layouts
import qs.core
import "../components" as SettingsComponents

ColumnLayout {
    id: page
    required property var settingsRoot
    spacing: Theme.spacingMedium
    property string selectedKey: "background"
    readonly property var rows: [
        { key:"background", label:"Background", value:settingsRoot.shownCustomThemeBackground },
        { key:"surface", label:"Surface", value:settingsRoot.shownCustomThemeSurface },
        { key:"hover", label:"Hover", value:settingsRoot.shownCustomThemeHover },
        { key:"foreground", label:"Foreground", value:settingsRoot.shownCustomThemeForeground },
        { key:"muted", label:"Muted", value:settingsRoot.shownCustomThemeMuted },
        { key:"accent", label:"Accent", value:settingsRoot.shownCustomThemeAccent },
        { key:"urgent", label:"Urgent", value:settingsRoot.shownCustomThemeUrgent },
        { key:"border", label:"Border primary", value:settingsRoot.shownCustomThemeBorder },
        { key:"border2", label:"Border secondary", value:settingsRoot.shownCustomThemeBorder2 === "transparent" ? "#000000" : settingsRoot.shownCustomThemeBorder2 }
    ]
    function currentValue() { for (let r of rows) if (r.key===selectedKey) return r.value; return "#ffffff"; }
    function stage(key, value) {
        if (key==="background") settingsRoot.stagedCustomThemeBackground=value;
        else if (key==="surface") settingsRoot.stagedCustomThemeSurface=value;
        else if (key==="hover") settingsRoot.stagedCustomThemeHover=value;
        else if (key==="foreground") settingsRoot.stagedCustomThemeForeground=value;
        else if (key==="muted") settingsRoot.stagedCustomThemeMuted=value;
        else if (key==="accent") settingsRoot.stagedCustomThemeAccent=value;
        else if (key==="urgent") settingsRoot.stagedCustomThemeUrgent=value;
        else if (key==="border") settingsRoot.stagedCustomThemeBorder=value;
        else if (key==="border2") settingsRoot.stagedCustomThemeBorder2=value;
    }
    function copyCurrentTheme() {
        const sourceName = settingsRoot.shownTheme === "CustomTheme" ? settingsRoot.shownCustomThemeBaseName : settingsRoot.shownTheme;
        const t = Theme.themesWithoutCustom[sourceName] || Theme.themesWithoutCustom[Theme.fallbackThemeName];
        settingsRoot.stagedCustomThemeBaseName=sourceName;
        settingsRoot.stagedCustomThemeBackground=t.colorBackground.toString(); settingsRoot.stagedCustomThemeForeground=t.colorForeground.toString();
        settingsRoot.stagedCustomThemeAccent=t.colorAccent.toString(); settingsRoot.stagedCustomThemeUrgent=t.colorUrgent.toString();
        settingsRoot.stagedCustomThemeMuted=t.colorMuted.toString(); settingsRoot.stagedCustomThemeSurface=t.colorSurface.toString();
        settingsRoot.stagedCustomThemeHover=t.colorHover.toString(); settingsRoot.stagedCustomThemeBorder=t.barBorderColor.toString();
        settingsRoot.stagedCustomThemeBorder2=t.barBorderColor2.a < 0.001 ? "transparent" : t.barBorderColor2.toString();
        settingsRoot.stagedCustomThemeBorderAngle=t.barBorderGradientAngle;
        settingsRoot.stagedTheme="CustomTheme";
    }
    SettingsComponents.SettingsSectionHeader { title: "Palette" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall

        Rectangle {
            Layout.fillWidth:true; implicitHeight: startText.implicitHeight + Theme.spacingMedium*2; radius:Theme.radiusMedium; color:startMouse.containsMouse?Theme.colorHover:Theme.colorSurface
        Text { id:startText; anchors.centerIn:parent; text:"Start from current theme"; color:Theme.colorForeground; font.family:Theme.fontFamily; font.pixelSize:Theme.fontSize }
        MouseArea { id:startMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:page.copyCurrentTheme() }
    }
    GridLayout {
        Layout.fillWidth:true; columns:3; rowSpacing:Theme.spacingSmall; columnSpacing:Theme.spacingSmall
        Repeater { model:page.rows
            Rectangle { required property var modelData; Layout.fillWidth:true; implicitHeight:42; radius:Theme.radiusMedium; color:page.selectedKey===modelData.key?Theme.colorHover:Theme.colorSurface; border.width:page.selectedKey===modelData.key?1:0; border.color:Theme.colorAccent
                RowLayout { anchors.fill:parent; anchors.margins:Theme.spacingSmall
                    Rectangle { width:24;height:24;radius:4;color:modelData.value;border.width:1;border.color:Theme.colorMuted }
                    Text { text:modelData.label; color:Theme.colorForeground; font.family:Theme.fontFamily; font.pixelSize:Math.round(Theme.fontSize*.85); Layout.fillWidth:true; elide:Text.ElideRight }
                }
                MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:page.selectedKey=modelData.key }
            }
        }
    }
    SettingsComponents.ColorGradientPicker { id:picker; Layout.fillWidth:true; value:page.currentValue(); onColorEdited: value => page.stage(page.selectedKey,value) }
    RowLayout { Layout.fillWidth:true
        Text { text:"Selected: "+page.selectedKey; color:Theme.colorMuted; font.family:Theme.fontFamily; font.pixelSize:Theme.fontSize }
        Item { Layout.fillWidth:true }
        TextInput { text:page.currentValue(); color:Theme.colorForeground; font.family:Theme.fontFamily; font.pixelSize:Theme.fontSize; selectByMouse:true; onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) page.stage(page.selectedKey,text) }
    }
    RowLayout { Layout.fillWidth:true; visible:page.selectedKey==="border2"
        Text { text:"Secondary border can be disabled for a solid border."; color:Theme.colorMuted; font.family:Theme.fontFamily; font.pixelSize:Math.round(Theme.fontSize*.85); Layout.fillWidth:true; wrapMode:Text.WordWrap }
        Rectangle { implicitWidth:90; implicitHeight:34; radius:Theme.radiusMedium; color:Theme.colorSurface
            Text { anchors.centerIn:parent; text:"Transparent"; color:Theme.colorForeground; font.family:Theme.fontFamily; font.pixelSize:Math.round(Theme.fontSize*.8) }
            MouseArea { anchors.fill:parent; onClicked:settingsRoot.stagedCustomThemeBorder2="transparent" }
        }
    }
    }

    SettingsComponents.SettingsSectionHeader { title: "Border" }
    SettingsComponents.SettingsCard {
        contentSpacing: Theme.spacingSmall
    SettingsComponents.StepperRow { label:"Gradient angle"; labelColumnWidth:190; valueColumnWidth:72; valueText:Math.round(settingsRoot.shownCustomThemeBorderAngle)+"°"; staged:settingsRoot.stagedCustomThemeBorderAngle !== null; onMinus: settingsRoot.stagedCustomThemeBorderAngle = (settingsRoot.shownCustomThemeBorderAngle + 345) % 360; onPlus: settingsRoot.stagedCustomThemeBorderAngle = (settingsRoot.shownCustomThemeBorderAngle + 15) % 360 }
    }
}
