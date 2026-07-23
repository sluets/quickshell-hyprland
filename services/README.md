# services/

System-integration and shared-runtime singletons. These files talk to D-Bus, daemon sockets, CLI tools through reusable `Process` objects, or web APIs, then expose clean QML state and commands. Widgets consume services; widgets should not duplicate the same shell-outs or own shared state.

Every file here is a `pragma Singleton` using Quickshell's `Singleton` root and is imported with:

```qml
import qs.services
```

Singletons instantiate lazily. A service that must be alive from launch needs an early consumer or an explicit shell reference.

## Current services

- **`Audio.qml`** — PipeWire default sink, volume/mute, sink enumeration, and sink switching.
- **`BluetoothAgent.qml`** — keeps a `bluetoothctl` pairing agent registered and restarts it with bounded session behavior if needed.
- **`ClipboardHistory.qml`** — bounded `cliphist` history model, restore/delete/wipe actions, trimming, and sequential image-thumbnail decoding into `$XDG_RUNTIME_DIR`. The external `wl-clip-persist` and `wl-paste --watch cliphist store` processes are user-session dependencies and must be verified before debugging this service.
- **`ClockTools.qml`** — runtime state for timer, stopwatch, laps, interval alerts, alarm, sound choice, and notification dispatch. It updates a reactive `nowMs` property because `Date.now()` alone does not invalidate QML bindings.
- **`ConfigManager.qml`** — snapshots, restore, pruning, and Settings Apply transaction orchestration. See `docs/BACKUPS.md`.
- **`Network.qml`** — Wi-Fi status and operations using Quickshell networking state plus `nmcli` where needed.
- **`Notifs.qml`** — owns `org.freedesktop.Notifications` and the notification model. Only one notification daemon may own that name.
- **`Weather.qml`** — ZIP-code geocoding and Open-Meteo condition/temperature refresh for the desktop clock.

## Deliberately not wrapped

- Hyprland workspace/window state uses Quickshell's first-party `Quickshell.Hyprland` module directly.
- Bluetooth device state uses `Quickshell.Bluetooth` directly; only pairing-agent registration needs a custom service.
- Battery support is not currently required on the main desktop.

## Dependency-health gate

Before changing QML because an integration appears empty or broken, verify the external dependency first:

1. package installed;
2. process/service running;
3. command/socket reachable;
4. raw output contains expected data;
5. only then debug the service or widget.

The clipboard refresh incident is the model example: `cliphist list` was empty because the watcher processes had stopped, while the Quickshell list code was functioning.
