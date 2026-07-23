// Quickshell-native basic calculator. Session history only; no settings. // GPT
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

FloatingWindow {
    id: root

    title: "Quickshell Calculator"
    color: Theme.colorBackground
    implicitWidth: Math.round(Theme.fontSize * 52)
    implicitHeight: Math.round(Theme.fontSize * 36)
    minimumSize: Qt.size(Math.round(Theme.fontSize * 42), Math.round(Theme.fontSize * 30))
    maximumSize: Qt.size(1200, 900)

    property bool shown: false
    property string displayText: "0"
    property string expressionText: ""
    property real accumulator: 0
    property string pendingOperator: ""
    property bool replaceEntry: true
    property bool errorState: false
    property real lastOperand: 0
    property string lastOperator: ""

    visible: shown

    function open(): void {
        shown = true;
        Qt.callLater(function() { keyCatcher.forceActiveFocus(); });
    }

    function close(): void {
        shown = false;
    }

    function toggle(): void {
        if (shown) close(); else open();
    }

    function normalizedNumber(value: real): string {
        if (!isFinite(value))
            return "Error";
        if (Math.abs(value) < 1e-14)
            value = 0;
        const rounded = Number(value.toPrecision(12));
        return String(rounded);
    }

    function currentValue(): real {
        const parsed = Number(displayText);
        return isFinite(parsed) ? parsed : 0;
    }

    function setValue(value: real): bool {
        const formatted = normalizedNumber(value);
        if (formatted === "Error") {
            displayText = "Error";
            expressionText = "";
            errorState = true;
            replaceEntry = true;
            pendingOperator = "";
            return false;
        }
        displayText = formatted;
        errorState = false;
        return true;
    }

    function clearAll(): void {
        displayText = "0";
        expressionText = "";
        accumulator = 0;
        pendingOperator = "";
        replaceEntry = true;
        errorState = false;
        lastOperand = 0;
        lastOperator = "";
    }

    function clearEntry(): void {
        displayText = "0";
        errorState = false;
        replaceEntry = true;
    }

    function inputDigit(digit: string): void {
        if (errorState)
            clearAll();
        if (replaceEntry || displayText === "0") {
            displayText = digit;
            replaceEntry = false;
        } else if (displayText.length < 18) {
            displayText += digit;
        }
    }

    function inputDecimal(): void {
        if (errorState)
            clearAll();
        if (replaceEntry) {
            displayText = "0.";
            replaceEntry = false;
        } else if (displayText.indexOf(".") < 0) {
            displayText += ".";
        }
    }

    function backspace(): void {
        if (errorState) {
            clearAll();
            return;
        }
        if (replaceEntry)
            return;
        if (displayText.length <= 1 || (displayText.length === 2 && displayText[0] === "-")) {
            displayText = "0";
            replaceEntry = true;
        } else {
            displayText = displayText.slice(0, -1);
        }
    }

    function symbolFor(op: string): string {
        switch (op) {
        case "/": return "÷";
        case "*": return "×";
        case "-": return "−";
        default: return op;
        }
    }

    function calculate(left: real, op: string, right: real): real {
        switch (op) {
        case "+": return left + right;
        case "-": return left - right;
        case "*": return left * right;
        case "/": return right === 0 ? NaN : left / right;
        default: return right;
        }
    }

    function chooseOperator(op: string): void {
        if (errorState)
            return;

        const value = currentValue();
        if (pendingOperator !== "" && !replaceEntry) {
            const result = calculate(accumulator, pendingOperator, value);
            if (!setValue(result))
                return;
            accumulator = result;
        } else if (pendingOperator === "") {
            accumulator = value;
        }

        pendingOperator = op;
        expressionText = normalizedNumber(accumulator) + " " + symbolFor(op);
        replaceEntry = true;
        lastOperator = "";
    }

    function equals(): void {
        if (errorState)
            return;

        let op = pendingOperator;
        let right = currentValue();
        let left = accumulator;

        if (op === "") {
            if (lastOperator === "")
                return;
            op = lastOperator;
            right = lastOperand;
            left = currentValue();
        }

        const result = calculate(left, op, right);
        const expression = normalizedNumber(left) + " " + symbolFor(op) + " " + normalizedNumber(right) + " =";
        if (!setValue(result))
            return;

        historyModel.insert(0, {
            expression: expression,
            result: displayText
        });
        expressionText = expression;
        accumulator = result;
        lastOperator = op;
        lastOperand = right;
        pendingOperator = "";
        replaceEntry = true;
    }

    function unary(kind: string): void {
        if (errorState)
            return;
        const value = currentValue();
        let result = value;
        let label = "";
        switch (kind) {
        case "sign":
            result = -value;
            label = "negate(" + normalizedNumber(value) + ")";
            break;
        case "percent":
            result = value / 100;
            label = normalizedNumber(value) + "%";
            break;
        case "reciprocal":
            result = value === 0 ? NaN : 1 / value;
            label = "1/" + normalizedNumber(value);
            break;
        case "square":
            result = value * value;
            label = "sqr(" + normalizedNumber(value) + ")";
            break;
        case "sqrt":
            result = value < 0 ? NaN : Math.sqrt(value);
            label = "√(" + normalizedNumber(value) + ")";
            break;
        }
        if (setValue(result)) {
            expressionText = label;
            replaceEntry = true;
        }
    }

    function useHistoryResult(value: string): void {
        displayText = value;
        expressionText = "";
        accumulator = Number(value);
        pendingOperator = "";
        replaceEntry = true;
        errorState = false;
        lastOperator = "";
        open();
    }

    onClosed: shown = false

    ListModel { id: historyModel }

    Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            const text = event.text;
            if (text >= "0" && text <= "9") {
                root.inputDigit(text);
                event.accepted = true;
            } else if (text === "." || text === ",") {
                root.inputDecimal();
                event.accepted = true;
            } else if (text === "+" || text === "-" || text === "*" || text === "/") {
                root.chooseOperator(text);
                event.accepted = true;
            } else if (text === "%") {
                root.unary("percent");
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || text === "=") {
                root.equals();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace) {
                root.backspace();
                event.accepted = true;
            } else if (event.key === Qt.Key_Delete) {
                root.clearEntry();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingLarge
        spacing: Theme.spacingLarge

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 3
            spacing: Theme.spacingMedium

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Calculator"
                    color: Theme.colorForeground
                    font.family: Theme.fontFamily
                    font.pixelSize: Math.round(Theme.fontSize * 1.15)
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Standard"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(Theme.fontSize * 6)

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: Theme.spacingSmall

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                        text: root.expressionText
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 0.85)
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                        text: root.displayText
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 2.5)
                        font.bold: true
                    }
                }
            }

            GridLayout {
                id: keypad
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 4
                rowSpacing: Theme.spacingSmall
                columnSpacing: Theme.spacingSmall

                Repeater {
                    model: [
                        { t: "%", a: "percent" }, { t: "CE", a: "clearEntry" }, { t: "C", a: "clearAll" }, { t: "⌫", a: "backspace" },
                        { t: "1/x", a: "reciprocal" }, { t: "x²", a: "square" }, { t: "√x", a: "sqrt" }, { t: "÷", a: "/", op: true },
                        { t: "7", a: "7" }, { t: "8", a: "8" }, { t: "9", a: "9" }, { t: "×", a: "*", op: true },
                        { t: "4", a: "4" }, { t: "5", a: "5" }, { t: "6", a: "6" }, { t: "−", a: "-", op: true },
                        { t: "1", a: "1" }, { t: "2", a: "2" }, { t: "3", a: "3" }, { t: "+", a: "+", op: true },
                        { t: "+/−", a: "sign" }, { t: "0", a: "0" }, { t: ".", a: "decimal" }, { t: "=", a: "equals", equal: true }
                    ]

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: Math.round(Theme.fontSize * 4)
                        Layout.minimumHeight: Math.round(Theme.fontSize * 2.4)
                        radius: Theme.radiusMedium
                        color: modelData.equal === true ? Theme.colorAccent
                            : buttonMouse.containsMouse ? Theme.colorHover
                            : Theme.colorSurface

                        Text {
                            anchors.centerIn: parent
                            text: parent.modelData.t
                            color: parent.modelData.equal === true ? Theme.colorBackground : Theme.colorForeground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.bold: parent.modelData.equal === true
                        }

                        MouseArea {
                            id: buttonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const action = parent.modelData.a;
                                if (action >= "0" && action <= "9") root.inputDigit(action);
                                else if (action === "decimal") root.inputDecimal();
                                else if (action === "clearEntry") root.clearEntry();
                                else if (action === "clearAll") root.clearAll();
                                else if (action === "backspace") root.backspace();
                                else if (action === "equals") root.equals();
                                else if (parent.modelData.op) root.chooseOperator(action);
                                else root.unary(action);
                                keyCatcher.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: Math.round(Theme.fontSize * 18)
            Layout.fillHeight: true
            radius: Theme.radiusMedium
            color: Theme.colorSurface

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingMedium
                spacing: Theme.spacingMedium

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "History"
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        visible: historyModel.count > 0
                        implicitWidth: clearHistoryText.implicitWidth + Theme.spacingMedium * 2
                        implicitHeight: clearHistoryText.implicitHeight + Theme.spacingSmall * 2
                        radius: Theme.radiusMedium
                        color: clearHistoryMouse.containsMouse ? Theme.colorHover : "transparent"

                        Text {
                            id: clearHistoryText
                            anchors.centerIn: parent
                            text: "Clear"
                            color: Theme.colorMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Theme.fontSize * 0.8)
                        }

                        MouseArea {
                            id: clearHistoryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: historyModel.clear()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: historyModel.count === 0
                    text: "There’s no history yet"
                    color: Theme.colorMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                }

                ListView {
                    id: historyList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: historyModel.count > 0
                    model: historyModel
                    clip: true
                    spacing: Theme.spacingSmall
                    reuseItems: true

                    delegate: Rectangle {
                        required property string expression
                        required property string result
                        width: historyList.width
                        implicitHeight: historyColumn.implicitHeight + Theme.spacingMedium * 2
                        radius: Theme.radiusMedium
                        color: historyMouse.containsMouse ? Theme.colorHover : "transparent"

                        Column {
                            id: historyColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: Theme.spacingMedium
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingSmall

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                                text: expression
                                color: Theme.colorMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.round(Theme.fontSize * 0.8)
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                                text: result
                                color: Theme.colorForeground
                                font.family: Theme.fontFamily
                                font.pixelSize: Math.round(Theme.fontSize * 1.05)
                                font.bold: true
                            }
                        }

                        MouseArea {
                            id: historyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.useHistoryResult(result)
                        }
                    }
                }
            }
        }
    }
}
