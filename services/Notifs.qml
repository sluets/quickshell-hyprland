//=============================================================================
// FILE
//=============================================================================
//
// services/Notifs.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// The shell's freedesktop notification daemon. Owns the one-and-only
// NotificationServer
// (the org.freedesktop.Notifications D-Bus name can have exactly one
// owner, so the server MUST live in a singleton service, never inside
// a widget — see DESIGN NOTES) and exposes the tracked-notification
// list plus dismiss/expire helpers. Widgets render this; they never
// instantiate their own server.
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// Quickshell                              (Singleton)
// Quickshell.Services.Notifications      (NotificationServer,
//                                          Notification,
//                                          NotificationUrgency)
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/Notifications/NotificationPopups.qml (renders `all`)
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// No notification daemon on the system at all — apps' notify calls go
// nowhere (this shell IS the daemon; there is no other one installed).
// NotificationPopups.qml fails to resolve `Notifs`.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY THIS IS A SERVICE (vs. the "wrap only when shared" rule):
//
// docs/REVISION_HISTORY.md (2026-07-02) set the rule: don't wrap a
// Quickshell.* module in a services/ file until more than one widget
// needs it — Bluetooth.qml reads Quickshell.Bluetooth directly for
// exactly that reason. Notifications are the case the rule's
// exception exists for: the D-Bus name is a singleton resource. The
// moment a second consumer exists (the planned notification
// center/history), it CANNOT create a second NotificationServer —
// two would fight over name ownership. So the server goes in a
// singleton on day one, and popups/history/whatever all read the
// same instance.
//
// TRACKED == VISIBLE (v1 model):
//
// `notif.tracked = true` in onNotification is what keeps a
// notification alive in `server.trackedNotifications`; without it the
// object is dropped at the end of the signal handler. In v1 there is
// no history UI, so tracked-but-hidden would be invisible state — the
// contract instead is: the tracked list IS the popup list. Timeouts
// call expire(), clicks call dismiss(), both of which close the
// notification and remove it from the list. When a history/center
// gets built, THAT's when this service grows a "popup done, keep in
// history" state layer (per-notification QtObject copies with a
// `popup` flag — deliberately not built until something displays
// history).
//
// D-BUS NAME OWNERSHIP — WHY A SECOND DAEMON BREAKS THIS SILENTLY:
//
// Only one process can own org.freedesktop.Notifications. If any other
// notification daemon is running (or is D-Bus-ACTIVATABLE — some
// daemons ship a .service file that lets the next notify-send summon
// them back even after being killed), this server fails to register
// and the shell shows nothing — no error surfaces in the UI,
// Quickshell just logs it. This shell has been the machine's only
// daemon since 2026-07-05; if popups ever silently stop, "something
// else grabbed the name first" is the first thing to check
// (`qs log`, or ask D-Bus who owns the name).
//
// CAPABILITY FLAGS: actions/body/markup/image are declared supported
// because the popup widget renders all of them. persistence is NOT
// (no history in v1 — declaring it would tell apps their transient
// notifications get stored, which would be a lie). keepOnReload false:
// a config reload drops pending popups, which beats stale
// Notification objects surviving into a freshly-loaded widget tree.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-22  (GPT) Memory stabilization Phase 2: hard-capped the
//             tracked collection at 8. Overflow dismisses the oldest
//             notification even when it is critical or timeout-zero.
//             dismissAll() now returns the number removed for IPC test
//             reporting; its cleanup behavior is unchanged.
// 2026-07-09  (Fable 5) Header cleanup: migration-era notes about the
//             previous daemon rewritten as a general D-Bus
//             name-ownership note — the handoff finished 07-05 and
//             this shell is the machine's only daemon now.
// 2026-07-04  Created — first D-Bus-facing service, the shell's own
//             notification daemon. ⚠ Written offline against the
//             Quickshell.Services.Notifications API (server flags,
//             tracked=true pattern, action invoke()) — not yet run.
//             Confirmed live 2026-07-05 on the first run.
//
//=============================================================================

pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // This bounds the Notification objects themselves, not merely the number
    // of visible delegates. Critical and timeout-zero notifications remain
    // persistent, but they cannot grow this collection without limit. // GPT
    readonly property int maxTracked: 8

    // Critical is a visual urgency level, not permission to retain a second
    // unbounded queue. Two persistent critical alerts are enough to get the
    // user's attention; newer critical alerts displace the oldest one. // GPT
    readonly property int maxCriticalTracked: 2

    // The live list widgets render — an ObjectModel of Notification;
    // use `.values` for a plain JS array (same as Pipewire.nodes).
    readonly property var all: server.trackedNotifications

    // Convenience for "is there anything to show" bindings.
    readonly property int count: server.trackedNotifications.values.length

    function dismissAll(): int {
        // Iterate a COPY — dismiss() mutates the list underneath.
        const tracked = [...server.trackedNotifications.values];
        for (const n of tracked)
            n.dismiss();
        return tracked.length;
    }

    function enforceTrackedLimit(): void {
        // Tracking updates the ObjectModel from inside onNotification. Defer
        // enforcement until that delivery has completed, then snapshot once
        // so dismiss()-driven model mutation cannot disturb iteration. Apply
        // the critical sub-cap first, then the total cap to the survivors.
        // Bursts may queue several checks; only calls with overflow do work.
        const tracked = [...server.trackedNotifications.values];
        const displaced = new Set();
        const critical = tracked.filter(n =>
            n.urgency === NotificationUrgency.Critical);
        const criticalOverflow = critical.length - maxCriticalTracked;

        for (let i = 0; i < criticalOverflow; ++i)
            displaced.add(critical[i]);

        const survivors = tracked.filter(n => !displaced.has(n));
        const totalOverflow = survivors.length - maxTracked;
        for (let i = 0; i < totalOverflow; ++i)
            displaced.add(survivors[i]);

        for (const n of displaced)
            n.dismiss();
    }

    NotificationServer {
        id: server

        keepOnReload: false

        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: false

        onNotification: notif => {
            // Without this the notification is dropped as soon as this
            // handler returns — see DESIGN NOTES ("TRACKED == VISIBLE").
            notif.tracked = true;
            Qt.callLater(root.enforceTrackedLimit);
        }
    }
}
