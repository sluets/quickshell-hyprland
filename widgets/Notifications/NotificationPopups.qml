//=============================================================================
// FILE
//=============================================================================
//
// widgets/Notifications/NotificationPopups.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Renders services/Notifs.qml's tracked notifications as a stack of
// popup cards in the top-right corner, under the bar — the visible
// half of the shell's notification daemon. Cards show app icon/image, summary,
// body, and action buttons; they auto-expire on a timer (critical
// urgency never does), left-click dismisses one, middle-click
// dismisses ALL.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick
// QtQuick.Layouts
// Quickshell                            (PanelWindow, Quickshell.iconPath)
// Quickshell.Services.Notifications    (NotificationUrgency enum only —
//                                        the server lives in the service)
// core/Theme.qml, core/Settings.qml    (via `import qs.core`)
// services/Notifs.qml                  (via `import qs.services`)
//
//=============================================================================
// USED BY
//=============================================================================
//
// shell.qml (instantiated once — top-level window, not a bar module)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// The notification server still runs (it's in the service) but nothing
// renders — notifications arrive, get tracked, and sit invisible
// forever (nothing expires them without this widget's timers). If
// removing this on purpose, remove services/Notifs.qml from use too.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WINDOW PLACEMENT (2026-07-11 — now user-positionable): anchored to
// UserPrefs.notifCorner (default top-right, the original placement)
// with UserPrefs.notifOffsetX/Y added to the chosen corner's margins.
// Base margins clear the FLOATING bar on top corners (barHeight +
// barMargin + spacingMedium) and match the bar's inset elsewhere, so
// offsets of 0/0 reproduce the pre-pref placement pixel-for-pixel.
// The window is exactly the size of the visible card stack and
// invisible when there are no notifications, so there's nothing to
// click through the rest of the time (unlike the OSD, this window
// takes real input — cards are clickable — so no empty-Region mask
// here).
//
// BOTTOM-CORNER STACKING (v1 known limit): cards keep newest-FIRST
// order top-to-bottom regardless of corner, so in a bottom corner the
// newest card is the one FARTHEST from the corner. Conventional
// bottom-corner behavior (newest nearest the corner, pushing older
// cards up) would need the visible-cap + expiry logic to run against
// a reversed model — deliberately not done until someone actually
// lives in a bottom corner and cares.
//
// TIMEOUT POLICY:
//
//   sender expireTimeout  > 0   -> that many ms
//   sender expireTimeout == 0   -> never auto-expires (spec: "never")
//   sender expireTimeout  < 0   -> Settings.notifDefaultTimeout
//   urgency == Critical         -> never auto-expires, regardless
//
// Timer -> notif.expire(), click -> notif.dismiss(): the distinction
// matters — the sender is told WHY it closed (Expired vs Dismissed),
// and some apps behave differently (e.g. re-notify after expiry but
// not after dismissal).
//
// VISIBLE CAP: only the first Settings.notifMaxVisible cards render
// (delegate visible: index < cap; Column doesn't reserve space for
// invisible items). The rest stay tracked and slide in as older ones
// close — a notification storm can't fill the screen.
//
// ACTIONS: invoke() then dismiss, UNLESS the notification is marked
// resident (spec: resident notifications survive their actions —
// media players use this for prev/play/next buttons).
//
// KNOWN LIMITS (v1, deliberate): no history/notification center (see
// services/Notifs.qml for where that layer goes), no inline reply, no
// grouping by app, no DND toggle, doesn't show over fullscreen apps
// (default "top" layer — moving to the overlay layer would also cover
// fullscreen video with popups, which is usually NOT wanted).
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-11  (Fable 5) Corner + x/y offset placement from UserPrefs
//             (notifCorner/notifOffsetX/notifOffsetY — settings
//             window, Notifications page). Defaults reproduce the
//             old fixed top-right placement exactly. Bottom-corner
//             stacking order is a documented v1 known limit (see
//             DESIGN NOTES).
// 2026-07-10  (Fable 5) Cards use the shell-wide border tokens
//             (Theme.barBorderWidth/Color, incl. the Appearance
//             page's overrides); critical cards keep urgent-red at
//             >= 2px regardless of the token.
//
// 2026-07-09  (Fable 5) Notification prefs (settings window,
//             Notifications page): appName visibility (the
//             maintainer's comment-out of this block, adopted as
//             UserPrefs.notifShowAppName, default false — it shared
//             the summary's ROW and truncated long titles), icon
//             size, body max lines, and a card-local font scale
//             multiplying the existing size ratios. Bold artist
//             names inside bodies are the SENDER's markup (Tauon
//             sends <b>…</b>; StyledText renders it) — not ours to
//             configure.
// 2026-07-05  Icon Image now hides on Image.Error instead of just on an
//             empty `resolved` string — a failed icon-theme lookup
//             (iconPath() returning a URL that never actually loads)
//             was leaving a blank 48x48 square in the card. Doesn't
//             stop the underlying "could not load icon" warning itself
//             (logged inside iconPath(), before this file sees
//             anything) — that needs an icon theme installed.
// 2026-07-04  Created, with services/Notifs.qml. Written offline;
//             confirmed working live 2026-07-05 on the first run (see
//             the service's DESIGN NOTES on D-Bus name ownership for
//             why only one notification daemon can run at a time).
//
//=============================================================================

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.core
import qs.services

PanelWindow {
    id: root

    // ---- Corner + offsets (2026-07-11, settings window) ----
    // Same two-anchor corner pattern as DesktopClock.qml. The base
    // margins keep their old jobs (clear the floating bar on top,
    // match the bar's inset on the sides); the offsets ADD to the
    // chosen corner's margins, so positive always moves the stack
    // INWARD from its corner and 0/0 reproduces the old placement
    // exactly. Negative is allowed (clamped in UserPrefs) to tuck
    // closer to an edge than the base inset — e.g. offsetY < 0 on a
    // top corner slides up toward/under the bar.
    readonly property string _corner: UserPrefs.notifCorner
    readonly property bool _top: _corner === "top-left" || _corner === "top-right"
    readonly property bool _left: _corner === "top-left" || _corner === "bottom-left"

    anchors {
        top: root._top
        bottom: !root._top
        left: root._left
        right: !root._left
    }

    // Top corners clear the floating bar: its bottom edge sits at
    // barMargin + barHeight from the screen top, plus a normal gap.
    // Bottom corners just match the bar's screen inset.
    margins {
        top: (Theme.barHeight + Theme.barMargin + Theme.spacingMedium)
             + UserPrefs.notifOffsetY
        bottom: Theme.barMargin + UserPrefs.notifOffsetY
        left: Theme.barMargin + UserPrefs.notifOffsetX
        right: Theme.barMargin + UserPrefs.notifOffsetX
    }

    exclusiveZone: 0
    color: "transparent"
    visible: Notifs.count > 0

    implicitWidth: stack.implicitWidth
    implicitHeight: stack.implicitHeight

    Column {
        id: stack
        spacing: Theme.spacingSmall

        Repeater {
            model: Notifs.all

            delegate: Rectangle {
                id: card

                required property var modelData
                required property int index

                readonly property bool critical:
                    modelData.urgency === NotificationUrgency.Critical

                // Cap how many render at once — see DESIGN NOTES.
                visible: index < Settings.notifMaxVisible

                width: Settings.notifWidth
                implicitHeight: cardContent.implicitHeight + Theme.spacingMedium * 2
                radius: Theme.radiusMedium
                color: Theme.colorBackground
                // The shell-wide border tokens (2026-07-10, same
                // width/color chain as the bar — see core/Theme.qml).
                // CRITICAL cards keep their urgent-red border and
                // never render thinner than the original 2px
                // emphasis, whatever the token says — the highlight
                // is semantic, not cosmetic.
                border.width: card.critical
                    ? Math.max(2, Theme.barBorderWidth)
                    : Theme.barBorderWidth
                border.color: card.critical
                    ? Theme.colorUrgent : Theme.barBorderColor

                // Gentle fade-in on arrival.
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animationDuration
                        easing.type: Theme.animationEasing
                    }
                }

                // Auto-expiry — full policy table in DESIGN NOTES.
                Timer {
                    running: !card.critical && card.modelData.expireTimeout !== 0
                    interval: card.modelData.expireTimeout > 0
                        ? card.modelData.expireTimeout
                        : Settings.notifDefaultTimeout
                    onTriggered: card.modelData.expire()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton)
                            Notifs.dismissAll();
                        else
                            card.modelData.dismiss();
                    }
                }

                ColumnLayout {
                    id: cardContent
                    anchors.fill: parent
                    anchors.margins: Theme.spacingMedium
                    spacing: Theme.spacingSmall

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.spacingMedium

                        // Rich image if the notification carries one,
                        // else the app's icon, else nothing (the row
                        // just closes up). notification.image is
                        // already a loadable url from Quickshell;
                        // appIcon can be an icon NAME or a path —
                        // Quickshell.iconPath resolves both, same call
                        // the launcher makes for .desktop icons.
                        Image {
                            id: iconImage
                            readonly property string resolved:
                                card.modelData.image !== ""
                                    ? card.modelData.image
                                    : (card.modelData.appIcon !== ""
                                        ? Quickshell.iconPath(card.modelData.appIcon)
                                        : "")
                            // NOTE: iconPath() always returns SOME string
                            // even when nothing in the icon theme actually
                            // matches (including its own internal
                            // "image-missing" fallback) — so `resolved`
                            // alone can't tell a real icon from a failed
                            // lookup. status can: Error means neither the
                            // real icon nor the fallback ever loaded, so
                            // collapse the row instead of holding open a
                            // blank 48x48 square. This doesn't stop Qt's
                            // "could not load icon" warning (that's logged
                            // from inside iconPath() before this Image
                            // ever sees a source) — only a real icon theme
                            // installed on the system fixes those.
                            visible: resolved !== "" && status !== Image.Error
                            source: resolved
                            sourceSize.width: UserPrefs.notifIconSize
                            sourceSize.height: UserPrefs.notifIconSize
                            Layout.preferredWidth: UserPrefs.notifIconSize
                            Layout.preferredHeight: UserPrefs.notifIconSize
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingSmall

                                Text {
                                    text: card.modelData.summary
                                    color: Theme.colorForeground
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Math.round(Theme.fontSize * UserPrefs.notifFontScale)
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Off by default: this shared the
                                // summary's row and truncated long
                                // song titles (maintainer hand-
                                // disabled it 2026-07-09; now a pref).
                                Text {
                                    visible: UserPrefs.notifShowAppName
                                    text: card.modelData.appName
                                    color: Theme.colorMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Math.round(Theme.fontSize * 0.85 * UserPrefs.notifFontScale)
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: Settings.notifWidth / 3
                                }
                            }

                            Text {
                                visible: card.modelData.body !== ""
                                text: card.modelData.body
                                color: Theme.colorForeground
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.round(Theme.fontSize * 0.9 * UserPrefs.notifFontScale)
                                // Notifications legally contain basic
                                // markup (<b>, <i>, <a>) — we declared
                                // bodyMarkupSupported in the service.
                                // StyledText renders that subset and
                                // ignores what it can't, without the
                                // full (heavier, scriptable) RichText
                                // engine.
                                textFormat: Text.StyledText
                                wrapMode: Text.Wrap
                                maximumLineCount: UserPrefs.notifBodyLines
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // ---- Action buttons ----
                    RowLayout {
                        visible: card.modelData.actions.length > 0
                        Layout.fillWidth: true
                        spacing: Theme.spacingSmall

                        Repeater {
                            model: card.modelData.actions

                            delegate: Rectangle {
                                id: actionButton
                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: actionLabel.implicitHeight + Theme.spacingSmall * 2
                                radius: Theme.radiusMedium
                                color: actionMouse.containsMouse
                                    ? Theme.colorHover : Theme.colorSurface

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionButton.modelData.text
                                    color: Theme.colorForeground
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Math.round(Theme.fontSize * 0.9)
                                    elide: Text.ElideRight
                                    width: Math.min(implicitWidth,
                                                    actionButton.width - Theme.spacingMedium)
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        actionButton.modelData.invoke();
                                        // resident notifications keep
                                        // living through their actions
                                        // (media controls) — see
                                        // DESIGN NOTES.
                                        if (!card.modelData.resident)
                                            card.modelData.dismiss();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
