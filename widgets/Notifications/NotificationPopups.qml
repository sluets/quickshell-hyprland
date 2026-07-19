// Selects the historical detached host or the new bar-attached host. // GPT Rev 52
import QtQuick
import Quickshell
import qs.core
import "." as NotificationComponents

Scope {
    id: root
    property Item anchorItem: null

    Loader {
        active: UserPrefs.notifPresentation === "detached"
        sourceComponent: Component {
            NotificationComponents.DetachedNotificationSurface {}
        }
    }

    Loader {
        active: UserPrefs.notifPresentation === "bar" && root.anchorItem !== null
        sourceComponent: Component {
            NotificationComponents.AttachedNotificationSurface {
                anchorItem: root.anchorItem
            }
        }
    }
}
