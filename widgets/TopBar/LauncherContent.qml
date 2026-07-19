// Launcher content shared by attached and centered presentation shells. // GPT Rev 46
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

ColumnLayout {
    id: root

    signal closeRequested()

    property int selectedIndex: 0
    property var results: []
    property alias searchField: searchField

    // DesktopEntries is populated asynchronously during shell startup.
    // Keeping a reactive count here makes the initial empty-query list
    // rebuild as soon as Quickshell finishes loading applications.
    readonly property int desktopEntryCount: DesktopEntries.applications.values.length

    onDesktopEntryCountChanged: {
        if (searchField.text.length === 0)
            refreshResults();
    }

    function isOneTypo(a: string, b: string): bool {
        const diffs = [];
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i]) diffs.push(i);
        }
        if (diffs.length === 1) return true;
        return diffs.length === 2
            && diffs[1] === diffs[0] + 1
            && a[diffs[0]] === b[diffs[1]]
            && a[diffs[1]] === b[diffs[0]];
    }

    function scoreEntry(q: string, name: string): int {
        const n = name.toLowerCase();
        if (n.startsWith(q)) return 100;
        const words = n.split(/[\s\-_./()]+/);
        for (const w of words) if (w.startsWith(q)) return 90;
        if (n.includes(q)) return 80;
        let qi = 0;
        for (let i = 0; i < n.length && qi < q.length; i++) {
            if (n[i] === q[qi]) qi++;
        }
        if (qi === q.length) return 50;
        if (q.length >= 3 && q.length <= n.length
                && isOneTypo(q, n.slice(0, q.length))) return 40;
        return 0;
    }

    function usageCount(id: string): int {
        return UserPrefs.launcherUsage[id] || 0;
    }

    function compareRanked(a: var, b: var, searching: bool): int {
        if (searching && a.score !== b.score) return b.score - a.score;

        const aFavorite = UserPrefs.launcherIsFavorite(a.entry.id) ? 1 : 0;
        const bFavorite = UserPrefs.launcherIsFavorite(b.entry.id) ? 1 : 0;
        if (aFavorite !== bFavorite) return bFavorite - aFavorite;

        const usageDifference = usageCount(b.entry.id) - usageCount(a.entry.id);
        if (usageDifference !== 0) return usageDifference;

        if (!searching && a.score !== b.score) return b.score - a.score;
        return a.entry.name.localeCompare(b.entry.name);
    }

    function computeResults(rawQuery: string): var {
        const q = rawQuery.trim().toLowerCase();
        const scored = [];

        for (const entry of DesktopEntries.applications.values) {
            if (entry.noDisplay || UserPrefs.launcherIsHidden(entry.id)) continue;

            if (q.length === 0) {
                const favorite = UserPrefs.launcherIsFavorite(entry.id);
                const used = usageCount(entry.id) > 0;
                if (UserPrefs.launcherShowAppsOnOpen || favorite || used)
                    scored.push({ entry: entry, score: 0 });
                continue;
            }

            const s = root.scoreEntry(q, entry.name);
            if (s > 0) scored.push({ entry: entry, score: s });
        }

        scored.sort((a, b) => root.compareRanked(a, b, q.length > 0));
        return scored.slice(0, Settings.launcherMaxResults).map(x => x.entry);
    }

    function refreshResults(): void {
        results = computeResults(searchField.text);
        selectedIndex = Math.max(0, Math.min(selectedIndex, results.length - 1));
    }

    function resetAndFocus(): void {
        searchField.text = "";
        refreshResults();
        selectedIndex = 0;
        searchField.forceActiveFocus();
    }

    function launch(entry: var): void {
        UserPrefs.recordLauncherUse(entry.id);
        closeRequested();
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: [...Settings.launcherTerminalCommand, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            entry.execute();
    }

    function launchSelected(): void {
        if (results.length > 0)
            launch(results[Math.min(selectedIndex, results.length - 1)]);
    }

    function moveSelection(delta: int): void {
        if (results.length === 0) return;
        selectedIndex = (selectedIndex + delta + results.length) % results.length;
    }

    spacing: Theme.spacingSmall

    Rectangle {
        implicitWidth: Settings.launcherWidth
        Layout.fillWidth: true
        implicitHeight: searchField.implicitHeight + Theme.spacingSmall * 2
        radius: Theme.radiusMedium
        color: Theme.colorSurface

        TextInput {
            id: searchField
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingMedium
            anchors.rightMargin: Theme.spacingMedium
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.colorForeground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            clip: true
            focus: true

            onTextChanged: {
                root.results = root.computeResults(text);
                root.selectedIndex = 0;
            }

            Keys.onDownPressed: root.moveSelection(1)
            Keys.onUpPressed: root.moveSelection(-1)
            Keys.onTabPressed: root.moveSelection(1)
            Keys.onBacktabPressed: root.moveSelection(-1)
            Keys.onReturnPressed: root.launchSelected()
            Keys.onEnterPressed: root.launchSelected()
            Keys.onEscapePressed: root.closeRequested()

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: searchField.text.length === 0
                text: "Search apps…"
                color: Theme.colorMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
            }
        }
    }

    Repeater {
        model: root.results

        Rectangle {
            id: row
            required property var modelData
            required property int index
            Layout.fillWidth: true
            implicitHeight: rowContent.implicitHeight + Theme.spacingSmall * 2
            radius: Theme.radiusMedium
            color: index === root.selectedIndex ? Theme.colorHover : "transparent"

            RowLayout {
                id: rowContent
                z: 1
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.spacingSmall
                anchors.rightMargin: Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingMedium

                Image {
                    Layout.preferredWidth: Theme.fontSize * 2
                    Layout.preferredHeight: Theme.fontSize * 2
                    sourceSize.width: Theme.fontSize * 2
                    sourceSize.height: Theme.fontSize * 2
                    source: Quickshell.iconPath(row.modelData.icon, "image-missing")
                    asynchronous: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        elide: Text.ElideRight
                        color: Theme.colorForeground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: row.modelData.comment ?? ""
                        elide: Text.ElideRight
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Theme.fontSize * 0.8)
                    }
                }

                Rectangle {
                    id: favoriteButton
                    Layout.preferredWidth: Theme.fontSize * 1.8
                    Layout.preferredHeight: Theme.fontSize * 1.8
                    radius: Theme.radiusMedium
                    color: favoriteMouse.containsMouse ? Theme.colorHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: UserPrefs.launcherIsFavorite(row.modelData.id) ? "★" : "☆"
                        color: UserPrefs.launcherIsFavorite(row.modelData.id) ? Theme.colorAccent : Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        id: favoriteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            UserPrefs.toggleLauncherFavorite(row.modelData.id);
                            root.refreshResults();
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: Theme.fontSize * 1.8
                    Layout.preferredHeight: Theme.fontSize * 1.8
                    radius: Theme.radiusMedium
                    color: hideMouse.containsMouse ? Theme.colorHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.colorMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                    }

                    MouseArea {
                        id: hideMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            UserPrefs.hideLauncherApp(row.modelData.id);
                            root.refreshResults();
                        }
                    }
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.rightMargin: Theme.fontSize * 4 + Theme.spacingMedium * 2
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedIndex = row.index
                onClicked: root.launch(row.modelData)
            }
        }
    }
}
