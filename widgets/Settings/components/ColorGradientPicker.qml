import QtQuick
import QtQuick.Layouts
import qs.core

ColumnLayout {
    id: root
    property string value: "#ffffff"
    property real hue: 0
    property real saturation: 0
    property real brightness: 1
    property bool syncing: false
    signal colorEdited(string value)

    function clamp(v) { return Math.max(0, Math.min(1, v)); }
    function hex2(n) { const h = Math.round(clamp(n) * 255).toString(16); return h.length < 2 ? "0" + h : h; }
    function emitColor() {
        if (syncing) return;
        const c = Qt.hsva(hue, saturation, brightness, 1);
        const hex = "#" + hex2(c.r) + hex2(c.g) + hex2(c.b);
        value = hex;
        colorEdited(hex);
    }
    function syncHex(hex) {
        if (!/^#[0-9a-fA-F]{6}$/.test(hex)) return;
        syncing = true;
        const r=parseInt(hex.slice(1,3),16)/255, g=parseInt(hex.slice(3,5),16)/255, b=parseInt(hex.slice(5,7),16)/255;
        const max=Math.max(r,g,b), min=Math.min(r,g,b), d=max-min;
        brightness=max; saturation=max === 0 ? 0 : d/max;
        if (d === 0) hue=0;
        else if (max===r) hue=((g-b)/d + (g<b?6:0))/6;
        else if (max===g) hue=((b-r)/d+2)/6;
        else hue=((r-g)/d+4)/6;
        syncing = false;
    }
    onValueChanged: syncHex(value)
    Component.onCompleted: syncHex(value)

    spacing: Theme.spacingMedium
    Rectangle {
        id: square
        Layout.fillWidth: true
        Layout.preferredHeight: 190
        radius: Theme.radiusMedium
        clip: true
        color: Qt.hsva(root.hue, 1, 1, 1)
        Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "white" } GradientStop { position: 1; color: "transparent" } } }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "black" } } }
        Rectangle { x: root.saturation * parent.width - width/2; y: (1-root.brightness)*parent.height-height/2; width: 14; height: 14; radius: 7; color: "transparent"; border.width: 2; border.color: "white" }
        MouseArea { anchors.fill: parent; onPressed: m => update(m); onPositionChanged: m => { if (pressed) update(m); } function update(m) { root.saturation=root.clamp(m.x/width); root.brightness=1-root.clamp(m.y/height); root.emitColor(); } }
    }
    Rectangle {
        id: hueBar
        Layout.fillWidth: true
        Layout.preferredHeight: 24
        radius: Theme.radiusMedium
        gradient: Gradient { orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: "#ff0000" } GradientStop { position: 0.17; color: "#ffff00" }
            GradientStop { position: 0.33; color: "#00ff00" } GradientStop { position: 0.50; color: "#00ffff" }
            GradientStop { position: 0.67; color: "#0000ff" } GradientStop { position: 0.83; color: "#ff00ff" }
            GradientStop { position: 1.00; color: "#ff0000" }
        }
        Rectangle { x: root.hue * parent.width - width/2; anchors.verticalCenter: parent.verticalCenter; width: 8; height: parent.height+6; radius: 4; color: "transparent"; border.width: 2; border.color: Theme.colorForeground }
        MouseArea { anchors.fill: parent; onPressed: m => update(m); onPositionChanged: m => { if (pressed) update(m); } function update(m) { root.hue=root.clamp(m.x/width); root.emitColor(); } }
    }
}
