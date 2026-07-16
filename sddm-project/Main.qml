//=============================================================================
// FILE
//=============================================================================
//
// sddm-project/Main.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Phase 1 static SDDM greeter. This is a standalone QtQuick application run by
// SDDM before the desktop session starts. It intentionally imports no
// Quickshell modules and reads only values exposed by SDDM plus theme.conf.
//
// The structure is already prepared for Phase 2: the layout remains here while
// colors, font choices, clock formats, and background filename live in
// theme.conf. Later, Quickshell can generate a replacement config and wallpaper
// snapshot without editing this file.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-16  Rev 1. Replaced the Phase 0 test rectangle with the first full
//             Honeycomb-derived greeter: background, clock/date, login card,
//             user/session selectors, failure feedback, and power controls.
// 2026-07-16  Rev 4. Moved the clock to the top-left and centered the login
//             card. Added config-backed X/Y offsets for future Settings UI.
// 2026-07-16  Rev 5. Removed the decorative clock accent bar and strengthened
//             the clock shadow for readability over bright wallpapers.
//
//=============================================================================

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    // ---- Config-backed visual values ---------------------------------------
    // Keep every replaceable theme value here instead of scattering literal
    // colors through the component tree. `config` is supplied by SDDM.
    readonly property color colorBackground: config.stringValue("ColorBackground")
    readonly property color colorForeground: config.stringValue("ColorForeground")
    readonly property color colorAccent: config.stringValue("ColorAccent")
    readonly property color colorMuted: config.stringValue("ColorMuted")
    readonly property color colorSurface: config.stringValue("ColorSurface")
    readonly property color colorHover: config.stringValue("ColorHover")
    readonly property color colorBorder: config.stringValue("ColorBorder")
    readonly property color colorUrgent: config.stringValue("ColorUrgent")
    readonly property string fontFamily: config.stringValue("FontFamily")
    readonly property int radius: config.intValue("Radius")

    // Position values are config-backed now so the future Settings page can
    // expose X/Y controls without changing the layout code.
    readonly property int clockXOffset: config.intValue("ClockXOffset")
    readonly property int clockYOffset: config.intValue("ClockYOffset")
    readonly property int loginXOffset: config.intValue("LoginXOffset")
    readonly property int loginYOffset: config.intValue("LoginYOffset")

    color: colorBackground

    property bool loginBusy: false
    property string statusText: ""
    property bool statusIsError: false

    function performLogin() {
        if (loginBusy || passwordField.text.length === 0)
            return

        loginBusy = true
        statusIsError = false
        statusText = "Signing in…"

        const username = userBox.editText.length > 0
                       ? userBox.editText
                       : userBox.currentText
        sddm.login(username, passwordField.text, sessionBox.currentIndex)
    }

    function clearFailure() {
        if (statusIsError) {
            statusText = ""
            statusIsError = false
        }
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.loginBusy = false
            root.statusIsError = true
            root.statusText = "That password did not work."
            passwordField.selectAll()
            passwordField.forceActiveFocus()
        }

        function onLoginSucceeded() {
            root.loginBusy = true
            root.statusIsError = false
            root.statusText = "Starting session…"
        }
    }

    // ---- Bundled background -------------------------------------------------
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.stringValue("Background")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    // A restrained dark veil keeps the login surface readable on the bundled
    // light wallpaper and remains useful when Phase 2 swaps in arbitrary images.
    Rectangle {
        anchors.fill: parent
        color: "#18000000"
    }

    // Slight left-to-right emphasis behind the clock without relying on a
    // blur shader, which keeps the theme predictable in SDDM test mode.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#50000000" }
            GradientStop { position: 0.52; color: "#08000000" }
            GradientStop { position: 1.0; color: "#28000000" }
        }
    }

    // ---- Clock --------------------------------------------------------------
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: clockText.now = new Date()
    }

    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Math.max(32, Math.round(parent.width * 0.035)) + root.clockXOffset
        anchors.topMargin: Math.max(28, Math.round(parent.height * 0.045)) + root.clockYOffset
        spacing: 8

        Text {
            id: clockText
            property date now: new Date()

            text: Qt.formatTime(now, config.stringValue("ClockFormat"))
            color: root.colorForeground
            font.family: root.fontFamily
            font.pixelSize: Math.max(62, Math.min(116, Math.round(root.width * 0.074)))
            font.bold: true
            style: Text.Raised
            styleColor: "#90000000"
        }

        Text {
            text: Qt.formatDate(clockText.now, config.stringValue("DateFormat"))
            color: root.colorForeground
            opacity: 0.92
            font.family: root.fontFamily
            font.pixelSize: Math.max(18, Math.min(28, Math.round(root.width * 0.017)))
            font.weight: Font.Medium
        }
    }

    // ---- Login panel --------------------------------------------------------
    Rectangle {
        id: loginCard

        width: Math.min(430, Math.max(360, root.width * 0.29))
        implicitHeight: loginColumn.implicitHeight + 58
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.loginXOffset
        anchors.verticalCenterOffset: root.loginYOffset
        radius: root.radius + 6
        color: Qt.rgba(root.colorSurface.r, root.colorSurface.g,
                       root.colorSurface.b, 0.94)
        border.width: 1
        border.color: root.colorBorder

        ColumnLayout {
            id: loginColumn
            anchors.fill: parent
            anchors.margins: 29
            spacing: 14

            Text {
                Layout.fillWidth: true
                text: config.stringValue("Greeting")
                color: root.colorForeground
                font.family: root.fontFamily
                font.pixelSize: 24
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: "Choose a user and enter the password."
                color: root.colorMuted
                font.family: root.fontFamily
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Item { Layout.preferredHeight: 2 }

            Text {
                text: "USER"
                color: root.colorMuted
                font.family: root.fontFamily
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.2
            }

            ComboBox {
                id: userBox
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                model: userModel
                textRole: "name"
                editable: true
                currentIndex: userModel.lastIndex
                font.family: root.fontFamily
                font.pixelSize: 14

                background: Rectangle {
                    radius: root.radius
                    color: userBox.hovered ? root.colorHover : root.colorBackground
                    border.width: userBox.activeFocus ? 2 : 1
                    border.color: userBox.activeFocus ? root.colorBorder : root.colorHover
                }

                contentItem: TextInput {
                    leftPadding: 13
                    rightPadding: 34
                    text: userBox.editText
                    color: root.colorForeground
                    selectionColor: root.colorAccent
                    selectedTextColor: root.colorBackground
                    font: userBox.font
                    verticalAlignment: TextInput.AlignVCenter
                    readOnly: !userBox.editable
                    selectByMouse: true
                }

                indicator: Text {
                    x: userBox.width - width - 13
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⌄"
                    color: root.colorMuted
                    font.family: root.fontFamily
                    font.pixelSize: 19
                }

                popup: Popup {
                    y: userBox.height + 4
                    width: userBox.width
                    implicitHeight: Math.min(contentItem.implicitHeight + 8, 230)
                    padding: 4

                    background: Rectangle {
                        color: root.colorSurface
                        radius: root.radius
                        border.width: 1
                        border.color: root.colorBorder
                    }

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: userBox.popup.visible ? userBox.delegateModel : null
                        currentIndex: userBox.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator {}
                    }
                }

                delegate: ItemDelegate {
                    width: userBox.width - 8
                    height: 40
                    highlighted: userBox.highlightedIndex === index

                    background: Rectangle {
                        color: parent.highlighted ? root.colorHover : "transparent"
                        radius: Math.max(2, root.radius - 2)
                    }

                    contentItem: Text {
                        text: model.name
                        color: root.colorForeground
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                text: "PASSWORD"
                color: root.colorMuted
                font.family: root.fontFamily
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.2
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                placeholderText: "Password"
                echoMode: TextInput.Password
                passwordCharacter: "●"
                enabled: !root.loginBusy
                font.family: root.fontFamily
                font.pixelSize: 14
                color: root.colorForeground
                placeholderTextColor: root.colorMuted
                selectionColor: root.colorAccent
                selectedTextColor: root.colorBackground
                leftPadding: 13
                rightPadding: 13
                selectByMouse: true

                background: Rectangle {
                    radius: root.radius
                    color: passwordField.hovered ? root.colorHover : root.colorBackground
                    border.width: passwordField.activeFocus ? 2 : 1
                    border.color: root.statusIsError
                                  ? root.colorUrgent
                                  : (passwordField.activeFocus
                                     ? root.colorBorder : root.colorHover)
                }

                onTextChanged: root.clearFailure()
                onAccepted: root.performLogin()
                Component.onCompleted: forceActiveFocus()
            }

            ComboBox {
                id: sessionBox
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                font.family: root.fontFamily
                font.pixelSize: 13

                background: Rectangle {
                    radius: root.radius
                    color: sessionBox.hovered ? root.colorHover : root.colorBackground
                    border.width: sessionBox.activeFocus ? 2 : 1
                    border.color: sessionBox.activeFocus ? root.colorBorder : root.colorHover
                }

                contentItem: Text {
                    leftPadding: 13
                    rightPadding: 34
                    text: sessionBox.displayText
                    color: root.colorForeground
                    font: sessionBox.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: Text {
                    x: sessionBox.width - width - 13
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⌄"
                    color: root.colorMuted
                    font.family: root.fontFamily
                    font.pixelSize: 19
                }

                popup: Popup {
                    y: sessionBox.height + 4
                    width: sessionBox.width
                    implicitHeight: Math.min(contentItem.implicitHeight + 8, 230)
                    padding: 4

                    background: Rectangle {
                        color: root.colorSurface
                        radius: root.radius
                        border.width: 1
                        border.color: root.colorBorder
                    }

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                        currentIndex: sessionBox.highlightedIndex
                        ScrollIndicator.vertical: ScrollIndicator {}
                    }
                }

                delegate: ItemDelegate {
                    width: sessionBox.width - 8
                    height: 40
                    highlighted: sessionBox.highlightedIndex === index

                    background: Rectangle {
                        color: parent.highlighted ? root.colorHover : "transparent"
                        radius: Math.max(2, root.radius - 2)
                    }

                    contentItem: Text {
                        text: model.name
                        color: root.colorForeground
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumHeight: 18
                text: root.statusText
                color: root.statusIsError ? root.colorUrgent : root.colorMuted
                font.family: root.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                enabled: !root.loginBusy && passwordField.text.length > 0
                text: root.loginBusy ? "PLEASE WAIT" : "SIGN IN"
                font.family: root.fontFamily
                font.pixelSize: 13
                font.bold: true

                background: Rectangle {
                    radius: root.radius
                    color: !loginButton.enabled
                           ? root.colorMuted
                           : (loginButton.down ? root.colorForeground
                                              : (loginButton.hovered
                                                 ? root.colorForeground
                                                 : root.colorAccent))
                    opacity: loginButton.enabled ? 1.0 : 0.46
                    border.width: 1
                    border.color: root.colorForeground
                }

                contentItem: Text {
                    text: loginButton.text
                    color: root.colorBackground
                    font: loginButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: root.performLogin()
            }
        }
    }

    // ---- Power controls -----------------------------------------------------
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Math.max(46, Math.round(parent.width * 0.065))
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 34
        spacing: 8

        PowerButton {
            text: "SUSPEND"
            visible: sddm.canSuspend
            onClicked: sddm.suspend()
        }

        PowerButton {
            text: "REBOOT"
            visible: sddm.canReboot
            onClicked: sddm.reboot()
        }

        PowerButton {
            text: "SHUT DOWN"
            visible: sddm.canPowerOff
            urgent: true
            onClicked: sddm.powerOff()
        }
    }

    component PowerButton: Button {
        id: control
        property bool urgent: false

        height: 36
        padding: 12
        font.family: root.fontFamily
        font.pixelSize: 11
        font.bold: true

        background: Rectangle {
            radius: root.radius
            color: control.down
                   ? root.colorForeground
                   : (control.hovered ? root.colorHover : root.colorSurface)
            border.width: 1
            border.color: control.urgent ? root.colorUrgent : root.colorBorder
        }

        contentItem: Text {
            text: control.text
            color: control.down
                   ? root.colorBackground
                   : (control.urgent ? root.colorUrgent : root.colorForeground)
            font: control.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
