# FeatherLog

A free, open-source, **local-first** weight & BMI tracker for Android. No accounts, no ads, no trackers. Your data stays on your device and is yours to export anytime.

<!-- Badges: these light up once the repo + workflows + Codecov are set up -->
[![PR Validation](https://github.com/tifandrei42/FeatherLog/actions/workflows/pr-validation.yml/badge.svg)](https://github.com/tifandrei42/FeatherLog/actions/workflows/pr-validation.yml)
[![Release](https://github.com/tifandrei42/FeatherLog/actions/workflows/release.yml/badge.svg)](https://github.com/tifandrei42/FeatherLog/actions/workflows/release.yml)
[![codecov](https://codecov.io/gh/tifandrei42/FeatherLog/branch/main/graph/badge.svg)](https://codecov.io/gh/tifandrei42/FeatherLog)
[![License](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)

---

## Features

- Log weight; see BMI computed against WHO standards
- Interactive trend chart — tap any point for that day's details
- Time-range controls (1W / 1M / 3M / 1Y / All) and overlay toggles
- Statistics: total/period change, rate of change, 7-day moving average, projection to goal
- Goal setting with a goal line on the chart
- Units (kg/lb, cm/in) and light/dark themes
- Local export/import (JSON + CSV) — you own your data

## Install

FeatherLog is distributed as a signed APK on the [Releases page](https://github.com/tifandrei42/FeatherLog/releases).

1. Download the APK matching your device's architecture (`arm64-v8a` for most modern phones).
2. Enable installing from unknown sources for your browser/file manager when prompted.
3. Open the APK to install.

### Stay updated automatically (recommended)

Use **[Obtainium](https://github.com/ImranR98/Obtainium)** to track this repo's
releases and get update prompts like an app store — no Google account, no Play:

1. Install Obtainium.
2. **Add App** → paste `https://github.com/tifandrei42/FeatherLog`.
3. Obtainium notifies you on each new release; tap to update in place (your data
   is preserved, since every release is signed with the same key).

> Because the GitHub-release APK and any future Play Store build are signed
> differently, pick one channel and stick with it — switching requires a
> reinstall.

## Privacy

FeatherLog stores all data locally on your device. It has no backend, requests no network permissions, and contains no analytics or advertising SDKs. Backups happen via Android Auto Backup (to *your* Google account) and via manual export to a file you control. See the full [Privacy Policy](PRIVACY.md).

## Build from source

```bash
flutter pub get
flutter run            # debug build on a connected device/emulator
flutter build apk --release   # release build (requires signing setup)
```

Signing setup: copy `android/key.properties.example` to `android/key.properties` and point it at your keystore. The real `key.properties` and `*.jks` are gitignored — never commit them.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs welcome.

## License

[GPL-3.0](LICENSE) — copyleft: forks and derivatives must also stay free and open source. Chosen to keep FeatherLog (and anything built from it) free forever, and for smoother F-Droid inclusion.
