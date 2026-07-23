// Keeps both notification hosts alive and selects which one is exposed. // GPT
import QtQuick
import Quickshell
import qs.core
import "." as NotificationComponents

Scope {
    id: root
    property Item candidateAnchorItem: null

    NotificationComponents.DetachedNotificationSurface {
        presentationActive: UserPrefs.notifPresentation === "detached"
    }

    NotificationComponents.AttachedNotificationSurface {
        presentationActive: UserPrefs.notifPresentation === "bar"
        candidateAnchorItem: root.candidateAnchorItem
    }
}
