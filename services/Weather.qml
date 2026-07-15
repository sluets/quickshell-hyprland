//=============================================================================
// FILE
//=============================================================================
//
// services/Weather.qml
//
//=============================================================================
// PURPOSE
//=============================================================================
//
// Current temperature + a broad weather CATEGORY (clear/partly-cloudy/
// cloudy/fog/rain/snow/thunderstorm) for a configured US ZIP code, for
// widgets/Desktop/DesktopClock.qml. Two network calls, both plain HTTPS
// GET, both hit only when the refresh timer fires (not continuously):
//
// 1. ZIP -> lat/long, via zippopotam.us (free, no key, US postal codes)
// 2. lat/long -> current conditions, via Open-Meteo's forecast API
//    (free, no key, no signup — https://open-meteo.com)
//
//=============================================================================
// DEPENDENCIES
//=============================================================================
//
// QtQuick                 (Timer)
// Quickshell              (Singleton root type)
// core/Settings.qml       (singleton, via `import qs.core` —
//                          weatherZipCode/weatherUnits/
//                          weatherRefreshMinutes)
// No Quickshell.Io Process/curl — see DESIGN NOTES, "WHY XMLHttpRequest".
//
//=============================================================================
// USED BY
//=============================================================================
//
// widgets/Desktop/DesktopClock.qml
//
//=============================================================================
// IF REMOVED
//=============================================================================
//
// DesktopClock.qml fails to resolve `Weather`. Nothing else in the
// project references this file.
//
//=============================================================================
// DESIGN NOTES
//=============================================================================
//
// WHY XMLHttpRequest, NOT Process + curl:
//
// This project's OWN docs/PROBLEMS_AND_FIXES.md has two separate entries
// about building something from scratch that Quickshell/Qt already
// ships (a hand-rolled Hyprland IPC parser, a `Process`-driven clock) —
// same mistake pattern this file deliberately avoids. QML's JS engine
// has shipped a real, spec-based `XMLHttpRequest` for a long time
// (confirmed against Qt's own current docs, doc.qt.io/qt-6/
// qml-qtqml-xmlhttprequest.html — no import needed beyond the engine
// itself, it's a JS global). That means no external process, no
// dependency on `curl` being installed, and no shell-escaping to get
// wrong — genuinely the more "native" choice here, not just a
// stylistic one.
//
// WHY TWO SEPARATE FREE SERVICES INSTEAD OF ONE:
//
// Open-Meteo's forecast API is excellent (no key, no signup, generous
// use policy) but takes latitude/longitude, not a ZIP code — it isn't
// a geocoder. zippopotam.us is a small, purpose-built, equally
// keyless service that does exactly the ZIP -> lat/long step and
// nothing else. Chaining two single-purpose free APIs beats either
// (a) requiring the maintainer sign up for a paid/keyed weather API
// (OpenWeatherMap etc.) just to get an address-to-coordinates lookup,
// or (b) hand-rolling ZIP centroid data into this project.
//
// WMO WEATHER-CODE TABLE — SOURCE, NOT GUESSED:
//
// Open-Meteo returns a numeric `weather_code` (WMO 4677 table) with no
// text description of its own. The exact code->description mapping
// below is taken from the community reference table nearly every
// Open-Meteo integration cites (gist.github.com/stellasphere/
// 9490c195ed2b53c707087c8c2db4ec0c — 140+ stars, actively maintained,
// linked from Open-Meteo's own GitHub issue tracker), not reconstructed
// from memory. Collapsed to 7 broad categories on purpose — asking for
// a matching SVG per exact code (27 of them) would be an unreasonable
// ask; 7 is a small, sourceable set.
//
// CACHING / REFRESH: a single Timer re-fetches every
// Settings.weatherRefreshMinutes (default 30) — weather doesn't need
// anything faster, and both APIs' fair-use policies are built around
// infrequent polling, not a tight loop. The geocode step only re-runs
// if `Settings.weatherZipCode` actually changes (cached lat/long
// otherwise) — no reason to re-resolve the same ZIP every refresh.
//
// FAILURE MODE: `available` goes false on any network error, missing
// ZIP, or malformed response — DesktopClock.qml is expected to hide
// the weather line entirely rather than show stale or garbage data.
// This mirrors the wallpaper picker's `daemonOk` pattern: fail
// visibly-by-omission, never silently wrong.
//
//=============================================================================
// REVISION HISTORY
//=============================================================================
//
// 2026-07-09  (Fable 5) Root type Item -> Quickshell's Singleton (+
//             `import Quickshell`), matching every other pragma
//             Singleton in this project (Audio, Network, Notifs,
//             BluetoothAgent, UserPrefs, Theme, Settings, Globals,
//             Signals). The Item root appeared to work but was the lone
//             deviation from the established pattern, and this service
//             renders nothing — there was no reason for a visual root.
// 2026-07-05  Created for the new desktop clock widget.
//
//=============================================================================

pragma Singleton

import QtQuick
import Quickshell
import qs.core

Singleton {
    id: root

    readonly property bool available: _hasWeather
    readonly property real temperature: _temperature
    // One of: "clear", "partly-cloudy", "cloudy", "fog", "rain",
    // "snow", "thunderstorm" — see DESIGN NOTES for the source table.
    readonly property string condition: _condition

    property bool _hasWeather: false
    property real _temperature: 0
    property string _condition: ""
    property real _lat: NaN
    property real _lon: NaN
    property string _geocodedZip: ""

    function _categoryForCode(code: int): string {
        if (code === 0 || code === 1) return "clear";
        if (code === 2) return "partly-cloudy";
        if (code === 3) return "cloudy";
        if (code === 45 || code === 48) return "fog";
        if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].includes(code))
            return "rain";
        if ([71, 73, 75, 77, 85, 86].includes(code)) return "snow";
        if (code === 95 || code === 96 || code === 99) return "thunderstorm";
        return ""; // unrecognized code — DesktopClock hides the icon
    }

    function refresh(): void {
        const zip = Settings.weatherZipCode;
        if (!zip) {
            root._hasWeather = false;
            return;
        }
        if (zip === root._geocodedZip && !isNaN(root._lat)) {
            _fetchWeather(); // coordinates already known, skip geocoding
            return;
        }
        _geocodeZip(zip);
    }

    function _geocodeZip(zip: string): void {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.warn("Weather: ZIP geocode failed for", zip,
                             "status", xhr.status);
                root._hasWeather = false;
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                const place = data.places?.[0];
                if (!place) throw new Error("no places[] in response");
                root._lat = parseFloat(place.latitude);
                root._lon = parseFloat(place.longitude);
                root._geocodedZip = zip;
                _fetchWeather();
            } catch (e) {
                console.warn("Weather: couldn't parse geocode response:", e);
                root._hasWeather = false;
            }
        };
        // zippopotam.us: no key, "us" country code, plain GET. Response
        // field names verified against the service's real documented
        // output ("latitude"/"longitude" as strings inside places[0]) —
        // NOT reconstructed from memory. One unverified detail: public
        // examples for this API consistently show http://, not https://;
        // https SHOULD work (TLS is near-universal for public APIs in
        // 2026) but wasn't independently confirmed. If this request
        // fails outright on first live test, dropping to http:// is the
        // first thing to try.
        xhr.open("GET", "https://api.zippopotam.us/us/" + encodeURIComponent(zip));
        xhr.send();
    }

    function _fetchWeather(): void {
        const unit = Settings.weatherUnits === "celsius" ? "celsius" : "fahrenheit";
        const url = "https://api.open-meteo.com/v1/forecast" +
            "?latitude=" + root._lat +
            "&longitude=" + root._lon +
            "&current=temperature_2m,weather_code" +
            "&temperature_unit=" + unit;

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.warn("Weather: forecast fetch failed, status", xhr.status);
                root._hasWeather = false;
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                const current = data.current;
                if (!current || typeof current.temperature_2m !== "number")
                    throw new Error("missing current.temperature_2m");
                root._temperature = current.temperature_2m;
                root._condition = root._categoryForCode(current.weather_code);
                root._hasWeather = true;
            } catch (e) {
                console.warn("Weather: couldn't parse forecast response:", e);
                root._hasWeather = false;
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    Timer {
        interval: Math.max(1, Settings.weatherRefreshMinutes) * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
