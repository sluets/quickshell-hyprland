# services/

System integration files — things that talk to D-Bus, a daemon socket,
a CLI tool via `Process`, or web APIs, and expose clean QML
properties/signals from that data. Widgets read services; they don't
shell out themselves. See `docs/ARCHITECTURE.md` for the full
services-vs-widgets distinction and when NOT to build a service.

**Pattern note:** every file here is a `pragma Singleton` with
Quickshell's `Singleton` root type (BOTH — see
`docs/PROBLEMS_AND_FIXES.md` 2026-07-03), readable from anywhere via
`import qs.services` with no manual wiring. Singletons instantiate
lazily on first property access — a service that must be alive from
launch needs something to touch it early (see BluetoothAgent.qml's
DESIGN NOTES for how that's handled).

## What's here (as of 2026-07-09)

- **`Audio.qml`** — PipeWire default sink: volume, mute, sink
  list/switching. Read by `widgets/TopBar/Volume.qml` and the OSD.
  See its header for the PwObjectTracker binding gotcha.
- **`Network.qml`** — wifi status from `Quickshell.Networking`; scan
  list, connect, forget via `nmcli` (Quickshell's own scan-list API
  silently never populated — see the file header and
  PROBLEMS_AND_FIXES 2026-07-05). Read by `widgets/TopBar/Wifi.qml`.
- **`Notifs.qml`** — THE notification daemon. Owns the one
  NotificationServer and with it the `org.freedesktop.Notifications`
  D-Bus name (exactly one owner allowed system-wide — that's why this
  is a service even with a single consumer). Read by
  `widgets/Notifications/NotificationPopups.qml`.
- **`BluetoothAgent.qml`** — keeps a `bluetoothctl` process alive for
  the session purely to register a BlueZ pairing agent
  (NoInputNoOutput, "Just Works" pairing only). Without it, pairing
  from the Bluetooth popout silently fails.
- **`ConfigManager.qml`** — the snapshot/restore engine and Apply
  transaction (settings-manager plan). Original Backup, snapshots,
  restore, pruning, and `applyChanges` (auto snapshot → staged
  UserPrefs writes). Consumed by shell.qml's `config` IPC target and
  `widgets/Settings/SettingsWindow.qml`. User guide: docs/BACKUPS.md.
- **`Weather.qml`** — ZIP code → coordinates (zippopotam.us) → current
  temperature + condition category (Open-Meteo), refreshed on a timer.
  Read by `widgets/Desktop/DesktopClock.qml`. Does nothing until
  `Settings.weatherZipCode` is set.

## What deliberately does NOT exist here

- **`Hyprland.qml`** — unnecessary. Quickshell ships a first-party
  `Quickshell.Hyprland` module with a reactive singleton
  (`Hyprland.workspaces`, `Hyprland.focusedMonitor`, dispatch).
  `widgets/TopBar/Workspaces.qml` and `shell.qml` import it directly.
- **`Bluetooth.qml`** (a device-state wrapper) — unnecessary for the
  same reason: `Quickshell.Bluetooth` is first-party and
  `widgets/TopBar/Bluetooth.qml` reads it directly (the "don't wrap
  until shared" rule). BluetoothAgent above is different — it exists
  because agent *registration* is something no built-in module does.
- **`Battery.qml`** — desktop machine, no battery, no urgency. If ever
  needed: `/sys/class/power_supply/`.

The recurring lesson (caught twice, for Hyprland and Bluetooth): check
whether Quickshell already ships a built-in module BEFORE hand-rolling
a D-Bus/IPC integration. Only build a service here when the built-in
doesn't exist, derived state needs sharing across widgets, or the
integration owns a system-wide singleton resource (Notifs, the agent).
