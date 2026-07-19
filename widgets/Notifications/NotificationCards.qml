// Shared notification-card stack for detached and bar-attached hosts. // GPT Rev 52
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.core
import qs.services

Column {
    id: root

    property bool attached: false

    // Publish the stack width before the first Repeater delegate exists.
    // BarPopout uses its content width to carve the matching gap in the bar
    // border. Without this explicit width, the popup initially opens at its
    // padding-only width and corrects only after the first card finishes
    // creation/layout, briefly exposing the bar's bottom border through the
    // notification seam. The card width is already fixed to notifWidth, so
    // publishing it here removes that first-frame geometry race. // GPT Rev 61
    width: Settings.notifWidth

    spacing: Theme.spacingSmall

    // Middle-click dismissal asks every visible delegate to run its own exit
    // animation before the notification service removes it. // GPT Rev 57
    signal closeAllRequested()

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

            readonly property real naturalHeight:
                cardContent.implicitHeight + Theme.spacingMedium * 2
            property real revealProgress: 0
            property bool closing: false
            property string closeMode: "dismiss"

            width: Settings.notifWidth
            height: root.attached
                ? naturalHeight * revealProgress
                : naturalHeight
            implicitHeight: height
            clip: true
            radius: Theme.radiusMedium
            color: root.attached ? Theme.colorSurface : Theme.colorBackground
            // The shell-wide border tokens (2026-07-10, same
            // width/color chain as the bar — see core/Theme.qml).
            // CRITICAL cards keep their urgent-red border and
            // never render thinner than the original 2px
            // emphasis, whatever the token says — the highlight
            // is semantic, not cosmetic.
            // The attached BarPopout owns the continuous outer border. A
            // second normal card border starts at the bar seam while the card
            // grows from zero height, which briefly redraws the horizontal line
            // we intentionally removed from the bar. Keep only the semantic
            // urgent border for critical notifications in attached mode. // GPT Rev 59
            border.width: card.critical
                ? Math.max(2, Theme.barBorderWidth)
                : (root.attached ? 0 : Theme.barBorderWidth)
            border.color: card.critical
                ? Theme.colorUrgent : Theme.barBorderColor

            // Attached cards grow out of the bar on arrival and collapse back
            // into it before removal. Detached cards keep their full height but
            // share the same fade lifecycle. // GPT Rev 57
            opacity: revealProgress

            Behavior on revealProgress {
                NumberAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.animationEasing
                }
            }

            Component.onCompleted: Qt.callLater(() => revealProgress = 1)

            function requestClose(mode): void {
                if (closing)
                    return;

                closing = true;
                closeMode = mode || "dismiss";
                revealProgress = 0;
                removalTimer.restart();
            }

            Timer {
                id: removalTimer
                interval: Theme.animationDuration + 40
                repeat: false
                onTriggered: {
                    if (card.closeMode === "expire")
                        card.modelData.expire();
                    else
                        card.modelData.dismiss();
                }
            }

            Connections {
                target: root
                function onCloseAllRequested(): void {
                    card.requestClose("dismiss");
                }
            }

            // Auto-expiry — full policy table in DESIGN NOTES.
            Timer {
                running: !card.closing
                    && !card.critical
                    && card.modelData.expireTimeout !== 0
                interval: card.modelData.expireTimeout > 0
                    ? card.modelData.expireTimeout
                    : Settings.notifDefaultTimeout
                onTriggered: card.requestClose("expire")
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton)
                        root.closeAllRequested();
                    else
                        card.requestClose("dismiss");
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
                                        card.requestClose("dismiss");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
