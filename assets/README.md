# assets/

Static runtime assets loaded directly by the shell. Generated caches do not belong here.

## Current contents

- `icons/calculator.svg` — launcher icon for the Quickshell-native calculator.
- `icons/power/` — power-menu action icons and source notes.
- `icons/weather/` — normalized weather-condition icons used by the desktop clock.
- `sounds/clock-soft.wav` — single soft timer/alarm alert.
- `sounds/clock-double.wav` — double alert.
- `sounds/clock-urgent.wav` — urgent repeated alert.

## Rules

- Keep stable, source-controlled assets under this directory.
- Use relative `Qt.resolvedUrl(...)` paths from QML.
- Do not store generated wallpaper thumbnails here; they live in the wallpaper library's `.thumbs/` directory.
- Do not store clipboard thumbnails here; `ClipboardHistory.qml` uses `$XDG_RUNTIME_DIR/qs-clipboard-thumbs/`.
- Cap QML `Image.sourceSize` when loading thumbnails or other potentially large images.
- Do not add font files to the repository unless licensing and redistribution are explicitly resolved.
