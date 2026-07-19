// App launcher presentation host. Content is shared by attached and centered modes. // GPT Rev 41
import QtQuick
import Quickshell
import qs.core
import "../Common" as Common

Item {
    id: root

    required property ShellScreen modelData
    width: 1
    height: Theme.barHeight

    function isCentered(): bool {
        return UserPrefs.launcherPlacement === "centered";
    }

    function toggle(): void {
        if (isCentered()) {
            attachedPopout.open = false;
            centeredSurface.open = !centeredSurface.open;
        } else {
            centeredSurface.open = false;
            attachedPopout.open = !attachedPopout.open;
        }
    }

    function close(): void {
        attachedPopout.open = false;
        centeredSurface.open = false;
    }

    BarPopout {
        id: attachedPopout
        anchorItem: root
        alignment: "center"

        onOpenChanged: {
            if (open)
                Qt.callLater(function() { attachedContent.resetAndFocus(); });
        }

        LauncherContent {
            id: attachedContent
            onCloseRequested: attachedPopout.open = false
        }
    }

    Common.CenteredSurface {
        id: centeredSurface
        targetScreen: root.modelData
        offsetX: UserPrefs.launcherOffsetX
        offsetY: UserPrefs.launcherOffsetY

        onOpenChanged: {
            if (open)
                Qt.callLater(function() { centeredContent.resetAndFocus(); });
        }

        LauncherContent {
            id: centeredContent
            onCloseRequested: centeredSurface.open = false
        }
    }
}
