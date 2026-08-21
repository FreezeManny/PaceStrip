# PaceStrip

A live cycling stats overlay, built with Flutter and designed for **split-screen use**.

PaceStrip shows your heart rate and cadence at a glance while you ride — large,
colour-coded numbers and rolling sparkline graphs that stay readable even when
the app is squeezed into a thin strip alongside a map, video, or training app.

## Features

- **Heart rate & cadence** displayed as big, high-contrast metric cards.
- **Training zones** with colour coding:
  - 5 heart-rate zones (Z1–Z5), configurable either as a **% of max HR** or as **manual bpm boundaries**.
  - 3 cadence zones (low / target / high), with configurable rpm boundaries.
- **Rolling sparkline graphs** showing the last 60 seconds of heart rate and cadence.
- **Colorful graphs** (optional, in Settings) — each bar is drawn in the color of
  the zone that reading was in, so a graph shows every zone you rode through
  instead of only the current one.
- **Split-screen aware layout** — the dashboard adapts to short panes, hiding
  chrome (like the settings button) when running in a split-screen strip so the
  numbers get all the space.
- **Light & dark themes** (dark by default, tuned for low-glare on-the-bike viewing).
- **Persistent settings** — your zone configuration, theme and graph style are
  saved locally via `shared_preferences`.

## Bluetooth sensors

PaceStrip connects to real fitness sensors over **Bluetooth Low Energy (BLE)**
using standard GATT profiles, so most off-the-shelf devices (Coospo, Garmin,
Polar, Wahoo, …) work out of the box:

- **Heart Rate Monitors** — Heart Rate Service (`0x180D`), e.g. chest straps and
  optical HR armbands.
- **Cadence sensors** — Cycling Speed and Cadence Service (`0x1816`), plus
  cadence from crank-equipped power meters via Cycling Power Service (`0x1818`).
  Speed-only sensors are ignored.

How it works:

- Open **Settings → SENSORS** and connect a sensor for each role. The scan is
  filtered by service type, so each role only lists matching devices — you just
  pick yours once. BLE sensors are connected directly by the app (they are *not*
  paired in Android's Bluetooth settings).
- Chosen sensors are remembered and **auto-reconnect** on launch / when they
  come back in range.
- Each metric **falls back to a built-in simulator** when its sensor is not
  connected, so the UI always shows data for development and demos. Cadence
  decays to 0 when you stop pedalling.

Data acquisition is isolated behind `SensorHub`
(`lib/services/sensor_service.dart`), which merges the live BLE streams
(`lib/services/ble/`) and the simulator into the single `CyclingStats` stream
the UI consumes.

## Roadmap

- Session recording / export.

> ℹ️ BLE requires a physical Android device — sensors do not work on emulators.

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.5.4`) or use the `Devcontainer`
- An Android device or emulator (Android is the currently configured platform).

### Run

```bash
flutter pub get
flutter run
```

### Test

```bash
flutter test
```

## Project structure

```
lib/
├── main.dart                  # App entry point, theming, providers
├── models/
│   ├── cycling_stats.dart     # Single HR/cadence reading + zones
│   ├── ring_buffer.dart       # Fixed-size history buffer for graphs
│   └── zone_config.dart       # Zone definitions, boundaries, colours
├── providers/
│   ├── settings_provider.dart # Zone config + theme state
│   └── stats_provider.dart    # Live stats stream + rolling history
├── services/
│   ├── sensor_service.dart    # Data source (simulated; BLE planned)
│   └── settings_service.dart  # Persistence via shared_preferences
└── widgets/                   # Dashboard, metric cards, graphs, settings UI
```

State is managed with [`provider`](https://pub.dev/packages/provider):
`SettingsProvider` holds the user's zone configuration and theme, and
`StatsProvider` subscribes to the sensor stream and maintains the rolling
history that feeds the graphs.

## Contributing

Every PR is **squash-merged**, and the squash commit message is the **PR title**. That single
title is therefore the only string release-please ever reads, and the only one that has to be
a [Conventional Commit](https://www.conventionalcommits.org/) — the **pr-title** check enforces
it. Commits *inside* your branch are yours: `wip`, `fixup`, `asdf`, whatever helps you save
work. None of them reach `main` or the changelog.

Title format:

```
<type>(<optional scope>): <description>
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`,
`chore`, `revert`. Append `!` for a breaking change (e.g. `feat!:`). Because the squash body is
the **PR description**, that is also where a `BREAKING CHANGE:` footer goes. Examples:

```
feat: add heart-rate zone alerts
fix(ble): reconnect after the sensor sleeps
chore(deps): bump flutter_lints
```

> Only `feat`, `fix`, and breaking changes bump a version; the rest don't trigger a release.
> Merging the release PR bumps `pubspec.yaml`, tags `vX.Y.Z`, and builds the release APK as a
> GitHub release asset — which is what Obtainium picks up.
>
> A PR that does two unrelated things collapses into one changelog entry under one type. The fix
> is to split the PR.

The **test** check runs `flutter analyze`, `flutter test` and a full `flutter build apk
--release` on every PR: analyze and test never touch the Android toolchain, so building the APK
is what catches a bad Gradle or AGP bump before release time.
