//=============================================================================
// FILE
//=============================================================================
//
// widgets/TopBar/BarPopout.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The reusable "scroll down out of the bar" popup that every bar dropdown
// uses — extracted from SystemMenu.qml, which was the reference
// implementation of this pattern (see docs/ARCHITECTURE.md, "Dropdown
// menu pattern"). SystemMenu, Volume, Wifi, Bluetooth, and Clock all now
// declare one of these instead of each re-implementing the
// PopupWindow + reveal-clip + visible-sync dance.
//
// Usage, from a bar widget:
//
//     BarPopout {
//         id: popout
//         anchorItem: someItemInTheBar   // what it hangs below
//         alignment: "right"             // "left" (default) or "right"
//
//         // children go inside the themed panel automatically:
//         MenuButton { ... }
//         MenuDivider { ... }
//     }
//
//     // toggle it from a MouseArea:
//     onClicked: popout.open = !popout.open
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// QtQuick.Layouts   (children land in a ColumnLayout)
// Quickshell        (PopupWindow, Edges)
// core/Theme.qml    (singleton, via `import qs.core`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/TopBar/SystemMenu.qml, Volume.qml, Wifi.qml, Bluetooth.qml,
// Clock.qml — every dropdown in the bar.
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// Every dropdown in the bar fails to load. This is now the single point
// of truth for the popup pattern.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY `open` EXISTS INSTEAD OF BINDING `visible` DIRECTLY:
//
// Originally this was because PopupWindow's own `grabFocus` made
// Quickshell itself assign `visible = false` on an outside click,
// which SILENTLY DESTROYS a declarative binding on `visible` — after
// the first outside-click dismiss the binding was gone and the popup
// never opened again (full story in docs/PROBLEMS_AND_FIXES.md). As of
// 2026-07-05 dismissal goes through HyprlandFocusGrab's `onCleared`
// instead, which sets `open`, not `visible`, directly. The SAME class
// of bug bit `HyprlandFocusGrab.active` on the same day, the first time
// around (see its own comment below) — worth remembering as a general
// rule for this whole file: never declaratively bind a property that
// Quickshell/Hyprland's own C++ side writes to internally. Push it
// imperatively from a signal handler instead.
//
// WHY CLOSING NOW ANIMATES:
//
// The old implementation assigned `visible = open`, so closing destroyed
// the popup surface immediately and left nothing to animate. The surface now
// remains visible while revealProgress runs 1 -> 0, then hides itself. This
// is a lifecycle choice, not a QML limitation.
//
// ALIGNMENT:
//
// Left-side bar widgets want the panel's left edge under the anchor
// ("left", the default). Right-side widgets (volume/wifi/bt/clock) want
// the panel's RIGHT edge under the anchor so the panel grows leftward
// into the screen instead of running off the right edge ("right").
// "center" centers the panel horizontally under the anchor — a lone
// Edges.Bottom for both `edges` and `gravity` means "attach at the
// bottom-CENTER of the anchor rect, grow straight down, centered"
// (same semantics as an xdg-popup positioner, which is what this maps
// to under Wayland). Used by the launcher, which hangs from the middle
// of the bar. `flushToBarEdge` is meaningless for "center" and is
// simply ignored there (the ternaries below only apply it for
// left/right).
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  (Fable 5) xOffset property — signed horizontal shift of
//             the whole popout, applied in BOTH the anchor rect and
//             _updateGap per their change-together rule. First user:
//             SettingsMenu, whose right fillet landed ~2 px PAST the
//             bar's right edge (gear sits spacingMedium from the
//             bar's end; fillet + barRadius > that margin, so the
//             arc had no straight bottom border to curve into and
//             collided with the bar's corner arc — found live).
// 2026-07-10  (Fable 5) Bar border project: on open, the popout
//             registers its x-range with the bar (parent-walk from
//             anchorItem to TopBar's `isBarBorderHost` marker) so the
//             bar's new border leaves a gap where the panel hangs,
//             and a Canvas inside the panel draws the panel's own
//             left/bottom/right border — bar + open menu read as one
//             outlined shape, and the border grows with the reveal
//             clip. Gap math mirrors the anchor-rect math; the two
//             must change together. Zero-width border (theme token)
//             disables all of it. Same-day extension: FILLET flanks
//             (window widened by Theme.barBorderFillet per side,
//             panel recentered via anchor-rect compensation, quarter
//             arcs curve the bar's bottom border into the panel's
//             sides — flush sides statically skip theirs) and
//             GRADIENT borders (bar's gradient line translated into
//             this window's coords so color flows through the seam).
// 2026-07-05  (same day, follow-up — found live) HyprlandFocusGrab's
//             `active` was originally `active: root.visible` — a
//             declarative binding. Quickshell itself writes
//             `active = false` when the compositor clears the grab,
//             which silently destroys that binding the same way
//             `visible` used to break under grabFocus (see the note
//             above). Result: the FIRST outside-click dismiss worked,
//             then the grab never reactivated on later opens, so
//             nothing dismissed the popout — it "just stayed there."
//             Fixed: `active` is now pushed imperatively from
//             onOpenChanged instead of bound.
// 2026-07-05  Swapped PopupWindow's native `grabFocus` (xdg_popup grab)
//             for HyprlandFocusGrab. grabFocus requires the bar's
//             surface to have already received an input event before
//             the grab can attach — cold (e.g. right after reload,
//             before the mouse ever crossed the bar), it can't, and Qt
//             logs "Cannot attach popup ... not an xdg_popup" /
//             "Failed to create grabbing popup ... has received input"
//             and the popup silently fails to open (fixed itself after
//             one mouse-over — that's what was "warming up" it). Known
//             Qt Wayland regression (6.9.1+), not shell-specific.
//             HyprlandFocusGrab doesn't use xdg_popup at all, so it
//             isn't affected — same fix Quickshell's own docs recommend
//             under Hyprland. Affects every dropdown in
//             the bar at once, since they all go through this file.
//             VERIFY LIVE: keyboard input (Wifi's password field,
//             Launcher's search field) should still reach the popout
//             under the new grab — HyprlandFocusGrab is documented as
//             an "input grab" (keyboard + pointer), but if typing stops
//             working, the known fix for this
//             scenario is an explicit `WlrLayershell.keyboardFocus:
//             WlrKeyboardFocus.OnDemand` binding while the grab is
//             active — not added here yet since it may not be needed.
// 2026-07-04  Renamed flushToScreenEdge -> flushToBarEdge (no behavior
//             change — the math was always relative to the bar, and
//             with the bar now inset from the screen, "bar edge" is
//             the honest name). Callers updated: SystemMenu, Clock.
// 2026-07-04  Added "center" alignment (edges/gravity: plain
//             Edges.Bottom) for the new launcher. Existing left/right
//             behavior untouched.
// 2026-07-03  Created — pattern extracted verbatim from SystemMenu.qml,
//             plus the new `alignment` property. See
//             docs/REVISION_HISTORY.md.
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.core

PopupWindow {
    id: root

    // ---- Public interface ----
    // The bar item this popup hangs below.
    required property Item anchorItem
    // "left", "right", or "center" — which edge of anchorItem the panel
    // aligns to ("center" = centered under it; see DESIGN NOTES).
    property string alignment: "left"
    // For widgets at the far ends of the bar: extends the anchor
    // rect through the bar's inner content margin (spacingMedium) so
    // the popout ends flush with the END OF THE BAR instead of
    // stopping at the widget's edge. Everything here is positioned
    // relative to the anchor item, so this tracks the bar wherever it
    // sits — when the bar was full-width this meant the screen edge;
    // now that the bar floats inset (Theme.barMargin), it means the
    // bar's rounded end. Same property, same math, renamed 2026-07-04
    // from flushToScreenEdge to match what it actually guarantees.
    property bool flushToBarEdge: false
    // Signed horizontal shift of the WHOLE popout — window, panel,
    // fillet flanks, and the gap the bar leaves in its border — in
    // px; negative moves left. For popouts whose fillet would
    // otherwise land on (or past) the bar's rounded corner: a fillet
    // arc needs STRAIGHT bar-bottom border to curve into, and a
    // widget sitting spacingMedium from the bar's end doesn't leave
    // any when fillet + barRadius > that margin (SettingsMenu, the
    // first user). Applied identically in the anchor rect and in
    // _updateGap — those two mirror each other and must change
    // together (their standing rule; this property obeys it).
    property int xOffset: 0
    // The logical open/closed state. Callers toggle THIS, never
    // `visible` — see DESIGN NOTES.
    property bool open: false
    // Notifications open unsolicited and should not disappear on an unrelated click. // GPT Rev 52
    property bool dismissOnOutsideClick: true
    // Children declared inside a BarPopout land in the inner column.
    default property alias content: contentColumn.data

    // ---- Open/close lifecycle ----
    // Keep the popup surface alive while revealProgress animates back to
    // zero. Hiding `visible` immediately would destroy the surface before a
    // closing animation could be shown — that was the old limitation, not a
    // QML limitation. Reopening mid-close simply reverses the same animation.
    onOpenChanged: {
        if (open) {
            visible = true;
            focusGrab.active = root.dismissOnOutsideClick;
            _updateGap();
            revealProgress = 1;
        } else {
            // Release the outside-click grab immediately, but leave the
            // surface and bar-border gap present until the panel has fully
            // scrolled back into the bar.
            focusGrab.active = false;
            revealProgress = 0;
        }
    }
    onVisibleChanged: {
        // Quickshell/compositor-side dismissal must still update our logical
        // state. Our own delayed visible=false happens after open is already
        // false, so it does not recurse.
        if (!visible && open)
            open = false;
    }
    // Popup width can settle after open (it's the content column's
    // size, computed once mapped) — keep the gap in sync.
    onWidthChanged: if (open) _updateGap()

    // ---- Bar-border gap registration (2026-07-10) ----
    // The bar strokes a border around itself (TopBar.qml's Canvas)
    // and leaves its bottom edge OPEN exactly where this popout hangs,
    // while the Canvas below draws this panel's left/bottom/right
    // sides — so bar + open menu read as ONE outlined shape, and the
    // border grows with the reveal because the panel's Canvas lives
    // inside the reveal clip. The bar is found by walking anchorItem's
    // parents to the `isBarBorderHost` marker (per-instance, so each
    // monitor's popouts talk to their own bar). The gap x mirrors the
    // anchor-rect math above — if that changes, change this with it.
    readonly property string _gapKey:
        "popout_" + Math.random().toString(36).slice(2)

    function _findBarHost(): var {
        let it = anchorItem;
        while (it) {
            if (it.isBarBorderHost === true)
                return it;
            it = it.parent;
        }
        return null;
    }

    // ---- Fillet flanks (2026-07-10, same-day extension) ----
    // The window is WIDENED by the fillet radius on each side that
    // gets one; the panel stays where it always was (anchor rect
    // compensates below) and the flanks are transparent margin the
    // border Canvas draws the fillet arcs into — the bar itself can't
    // draw them (they live below its window's bottom edge). Flush
    // popouts statically skip the fillet on their flush side: there's
    // no bar-bottom-border beyond the bar's rounded end to curve into,
    // and skipping it keeps the panel genuinely flush. Known cost of
    // the flanks: two f-wide strips beside an open menu that receive
    // clicks and do nothing (input-mask polish item if it annoys).
    readonly property int _fL:
        (flushToBarEdge && alignment === "left") ? 0 : Theme.barBorderFillet
    readonly property int _fR:
        (flushToBarEdge && alignment === "right") ? 0 : Theme.barBorderFillet

    // Bar geometry captured at open, for the gradient's coordinate
    // shift (the popout's gradient CONTINUES the bar's — same line,
    // translated into this window's coords) and set by _updateGap.
    property real _barX: 0
    property real _barW: 0
    property real _barH: 0

    // PopupWindow geometry is ultimately placed on whole physical pixels by
    // Wayland/Qt. RowLayout and text implicit widths can still produce
    // fractional QML coordinates, though. Keep every value shared by the
    // popup anchor and the bar-border gap on the same pixel grid; otherwise
    // the bar can stop its stroke at (for example) x=367.4 while the popup
    // surface is actually placed at x=368, leaving the 1–3 px seam seen on
    // icon/text-anchored menus. Centered launcher/wallpaper popouts happened
    // to avoid it because their fixed geometry lands on integral pixels.
    function _pixel(v: real): int {
        return Math.round(v);
    }

    function _updateGap(): void {
        const bar = _findBarHost();
        if (!bar)
            return;
        // Keep the gap open during the closing animation. It is cleared only
        // when the popup surface is finally hidden at revealProgress == 0.
        if (!visible) {
            bar.clearPopoutGap(_gapKey);
            return;
        }
        const p = anchorItem.mapToItem(bar, 0, 0);
        const pw = _pixel(width > 0 ? width : implicitWidth);
        let gx;
        if (alignment === "right")
            gx = p.x + anchorItem.width
                 + (flushToBarEdge ? Theme.spacingMedium : 0) + _fR - pw;
        else if (alignment === "center")
            gx = p.x + anchorItem.width / 2 - pw / 2;
        else
            gx = p.x + (flushToBarEdge ? -Theme.spacingMedium : 0) - _fL;
        // xOffset shifts the whole popout (mirrors the same term in
        // the anchor rect's x — change together).
        gx = _pixel(gx + xOffset);
        // The gap spans between the fillet arcs' top tangent points
        // (window-local x = inset .. width - inset), so the bar's
        // border ink meets the arcs exactly.
        const inset = Theme.barBorderWidth / 2;
        bar.setPopoutGap(_gapKey, gx + inset, pw - Theme.barBorderWidth);
        _barX = gx;
        _barW = bar.width;
        _barH = bar.height;
        popBorderCanvas.requestPaint();
    }

    anchor {
        item: root.anchorItem
        // Anchor rect extended so its bottom sits at the BAR's bottom
        // edge MINUS one border width — the popup deliberately
        // OVERLAPS the bar's bottom bw pixels. Found live 2026-07-10:
        // without the overlap, the fillet arc's top tangent point sits
        // half a border width ABOVE the window's top edge (it meets
        // the bar's border centerline, which is inside the bar), and a
        // window can't draw above its own top — the first ~sqrt(2·f·
        // bw/2) px of each fillet were clipped to nothing ("a couple
        // pixels missing right before the fillet starts"). The overlap
        // region is transparent (panel starts at y = bw), so the bar
        // shows through it untouched. bw = 0 degenerates to the old
        // geometry exactly. The fillet terms shift/extend the rect so
        // the wider window lands with its PANEL exactly where the old
        // window did ("center" needs nothing — symmetric widening
        // stays centered). Mirrored in _updateGap — change together.
        // xOffset translates the whole rect, which moves the anchor
        // POINT by the same amount whichever edge is in use — so one
        // term here (+ its mirror in _updateGap) shifts any alignment.
        rect: Qt.rect(
            root._pixel(
                root.xOffset
                + ((root.flushToBarEdge && root.alignment === "left") ? -Theme.spacingMedium : 0)
                - (root.alignment === "left" ? root._fL : 0)),
            root._pixel((Theme.barHeight - root.anchorItem.height) / 2),
            Math.max(1, root._pixel(
                root.anchorItem.width
                + (root.flushToBarEdge ? Theme.spacingMedium : 0)
                + (root.alignment === "right" ? root._fR : 0))),
            Math.max(1, root._pixel(
                root.anchorItem.height - Theme.barBorderWidth)))
        edges: root.alignment === "right" ? (Edges.Bottom | Edges.Right)
        : root.alignment === "center" ? Edges.Bottom
        : (Edges.Bottom | Edges.Left)
        gravity: root.alignment === "right" ? (Edges.Bottom | Edges.Left)
        : root.alignment === "center" ? Edges.Bottom
        : (Edges.Bottom | Edges.Right)
    }

    implicitWidth: Math.ceil(contentColumn.implicitWidth
                             + Theme.spacingMedium * 2 + _fL + _fR)
    // + one border width for the overlap strip at the top (see the
    // anchor comment) — the panel itself is unchanged in size.
    implicitHeight: Math.ceil(contentColumn.implicitHeight
                              + Theme.spacingMedium * 2
                              + Theme.barBorderWidth)
    color: "transparent"

    // ---- Dismiss-on-outside-click (see 2026-07-05 REVISION HISTORY) ----
    // NOT PopupWindow's own `grabFocus` — that uses Wayland's native
    // xdg_popup grab, which requires the PARENT surface (the bar) to
    // have already received at least one real input event before the
    // grab can attach. Cold — e.g. right after a reload, before the
    // mouse has ever crossed the bar — that requirement isn't met, and
    // Qt logs "Cannot attach popup ... as the popup is not an
    // xdg_popup" / "Failed to create grabbing popup ... parent window
    // has received input" and the popup just doesn't open. Moving the
    // mouse over the bar once "warms up" that serial and grabFocus
    // starts working — exactly the symptom reported live. This is a
    // known Qt Wayland regression (6.9.1+), not something specific to
    // this shell. HyprlandFocusGrab sidesteps it entirely: it's a
    // Hyprland compositor extension, not the xdg_popup protocol, so it
    // has no such prior-input requirement. Quickshell's own PopupWindow
    // docs recommend exactly this swap under Hyprland.
    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        onCleared: if (root.dismissOnOutsideClick) root.open = false
    }

    // ---- Scroll down / scroll back up reveal ----
    // 180 ms was a little abrupt. 1.4x keeps the theme token as the source of
    // truth while giving these larger menus a calmer ~250 ms travel time.
    readonly property int revealDuration:
        Math.round(Theme.animationDuration * 1.4)
    property real revealProgress: 0

    onRevealProgressChanged: {
        if (!open && revealProgress <= 0.0001 && visible) {
            visible = false;
            _updateGap();
        }
    }

    Behavior on revealProgress {
        NumberAnimation {
            duration: root.revealDuration
            easing.type: Theme.animationEasing
        }
    }

    Item {
        id: revealClip
        width: parent.width
        height: parent.height * root.revealProgress
        anchors.top: parent.top
        clip: true

        Rectangle {
            id: panel
            x: root._fL
            // Starts below the bw-tall overlap strip (transparent —
            // the bar's own bottom edge shows through it), i.e. at the
            // bar's true bottom edge, exactly where it always was.
            y: Theme.barBorderWidth
            width: parent.width - root._fL - root._fR
            height: root.implicitHeight - Theme.barBorderWidth
            // Same color as the bar and rounded on the BOTTOM corners
            // only — the panel reads as a piece of the bar sliding out,
            // not a separate floating window. Its border (when the
            // theme enables one) is the Canvas below, drawn to
            // CONTINUE the bar's border rather than outline this panel
            // separately — same "one shape" principle. The window is
            // wider than the panel by the fillet flanks (root._fL/_fR
            // — see up top); the flanks are transparent, holding only
            // the border Canvas's fillet arcs.
            color: Theme.colorBackground
            radius: Theme.radiusMedium

            // Squares off the top two corners (radius applies to all
            // four, so this covers the top ones with the same color).
            Rectangle {
                width: parent.width
                height: parent.radius
                color: parent.color
            }

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingSmall
            }
        }

        // The popout's share of the continuous bar border: fillet arc
        // (where the bar's bottom border curves down into this panel),
        // left side, bottom with rounded corners, right side, fillet
        // arc — top open, meeting the gap the bar leaves in its own
        // bottom border (see _updateGap). A SIBLING of the panel, not
        // a child, because the fillet arcs live in the flanks OUTSIDE
        // the panel; sized to the full window and declared last so it
        // paints above panel + content. Inside the reveal clip, so the
        // whole outline grows with the scroll-out. Gradient (when the
        // theme sets barBorderColor2) is the BAR's gradient line
        // translated into this window's coordinates — colors flow
        // through the seam as if bar and panel were one surface.
        // Property change handlers force the repaints Canvas won't do
        // on its own; _updateGap requestPaint()s when geometry lands.
        Canvas {
            id: popBorderCanvas
            width: parent.width
            height: root.implicitHeight
            anchors.top: parent.top

            property int bwT: Theme.barBorderWidth
            property color bc: Theme.barBorderColor
            property color bc2: Theme.barBorderColor2
            property real bgAng: Theme.barBorderGradientAngle
            property color pbg: Theme.colorBackground
            onBwTChanged: requestPaint()
            onBcChanged: requestPaint()
            onBc2Changed: requestPaint()
            onBgAngChanged: requestPaint()
            onPbgChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const bwv = bwT;
                if (bwv <= 0)
                    return;
                const w = width, h = height;
                const inset = bwv / 2;
                const cr = Math.max(panel.radius, inset);
                const ar = Math.max(0, cr - inset);
                const fL = root._fL, fR = root._fR;

                // Solid, or the bar's gradient shifted into our coords
                // (our origin sits at bar coords (_barX, _barH - bwv)
                // — the window overlaps the bar's bottom bwv pixels).
                if (bc2.a <= 0.001) {
                    ctx.strokeStyle = bc;
                } else {
                    const ang = bgAng * Math.PI / 180;
                    const dx = Math.cos(ang), dy = Math.sin(ang);
                    const L = (Math.abs(root._barW * dx)
                             + Math.abs(root._barH * dy)) / 2;
                    const cx = root._barW / 2 - root._barX;
                    const cy = root._barH / 2 - (root._barH - bwv);
                    const g = ctx.createLinearGradient(
                        cx - dx * L, cy - dy * L, cx + dx * L, cy + dy * L);
                    g.addColorStop(0, "rgba(" + Math.round(bc.r * 255) + ","
                        + Math.round(bc.g * 255) + "," + Math.round(bc.b * 255)
                        + "," + bc.a + ")");
                    g.addColorStop(1, "rgba(" + Math.round(bc2.r * 255) + ","
                        + Math.round(bc2.g * 255) + "," + Math.round(bc2.b * 255)
                        + "," + bc2.a + ")");
                    ctx.strokeStyle = g;
                }
                ctx.lineWidth = bwv;

                // Fillet tangent geometry: the arcs meet the bar's
                // border CENTERLINE, which — thanks to the bw overlap
                // (see the anchor comment) — sits at window y = inset,
                // fully inside this window. Left arc center
                // (inset, fL + inset); right arc center
                // (w - inset, fR + inset).

                // The webs first: the concave area between each arc,
                // the bar's bottom edge, and the panel's side is
                // FILLED with the background color so bar + panel +
                // fillet read as one solid silhouette (the maintainer's
                // mockup), not a curve floating over wallpaper.
                ctx.fillStyle = Theme.colorBackground;
                if (fL > 0) {
                    ctx.beginPath();
                    ctx.moveTo(inset, inset);
                    ctx.arc(inset, fL + inset, fL, 1.5 * Math.PI, 2 * Math.PI, false);
                    ctx.lineTo(fL + inset, inset);
                    ctx.closePath();
                    ctx.fill();
                }
                if (fR > 0) {
                    ctx.beginPath();
                    ctx.moveTo(w - fR - inset, fR + inset);
                    ctx.arc(w - inset, fR + inset, fR, Math.PI, 1.5 * Math.PI, false);
                    ctx.lineTo(w - fR - inset, inset);
                    ctx.closePath();
                    ctx.fill();
                }

                // The border stroke: left fillet -> left side ->
                // rounded bottom -> right side -> right fillet.
                ctx.beginPath();
                if (fL > 0) {
                    ctx.moveTo(inset, inset);
                    ctx.arc(inset, fL + inset, fL, 1.5 * Math.PI, 2 * Math.PI, false);
                } else {
                    // Flush side, no fillet: start at the bar's bottom
                    // edge (window y = bwv), the pre-overlap visual.
                    ctx.moveTo(inset, bwv);
                }
                ctx.lineTo(fL + inset, h - cr);
                ctx.arc(fL + cr, h - cr, ar, Math.PI, Math.PI / 2, true);
                ctx.lineTo(w - fR - cr, h - inset);
                ctx.arc(w - fR - cr, h - cr, ar, Math.PI / 2, 0, true);
                ctx.lineTo(w - fR - inset, fR > 0 ? fR + inset : bwv);
                if (fR > 0)
                    ctx.arc(w - inset, fR + inset, fR, Math.PI, 1.5 * Math.PI, false);
                ctx.stroke();
            }
        }
        }
    }

