//=============================================================================
// widgets/TopBar/ClockSectionCard.qml
//
// The Clock popout's section card — same rounded Theme.colorCard container
// the Audio and Connectivity popouts use (AudioSectionCard /
// ConnectivitySectionCard), so all three redesigned dropdowns share one
// visual language. Kept as a per-popout file to match the existing
// precedent rather than inventing a shared generic card mid-redesign.
//
// ⚠ written offline — NOT yet run live. Test: open the clock popout,
// confirm every section renders as a rounded card with the theme's
// card border when the theme defines one.
//
// 2026-07-29  (Claude Fable 5) Created for the Clock Tools redesign.
//=============================================================================

import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    default property alias content: contentColumn.data
    property int contentSpacing: Theme.spacingSmall

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + Theme.spacingLarge * 2
    radius: Theme.radiusMedium
    color: Theme.colorCard
    border.width: Theme.colorCardBorder.a > 0 ? 1 : 0
    border.color: Theme.colorCardBorder

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: root.contentSpacing
    }
}
