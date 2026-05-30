# Contributing to FeatherLog

Thanks for your interest! This project aims to be a clean, well-engineered example as much as a useful app, so contributions that keep the codebase tidy are especially welcome.

## Development setup

1. Install Flutter (stable channel) and Android Studio — run `flutter doctor` until clean.
2. `flutter pub get`
3. `flutter run` to launch on a device/emulator.

## Workflow

- `main` is protected. All changes land via pull request.
- Branch from `main` using a descriptive name: `feat/chart-overlays`, `fix/import-crash`.
- CI must pass (analyze, format, tests, security) before merge.

## Commit messages — Conventional Commits

This repo uses [Conventional Commits](https://www.conventionalcommits.org/) so the changelog and version bumps can be generated automatically. Format:

```
<type>(<optional scope>): <description>
```

Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`.

Examples:
- `feat(chart): add 7-day moving average overlay`
- `fix(import): reject malformed JSON without wiping data`
- `ci: cache gradle dependencies in release workflow`

A `feat` triggers a minor version bump; a `fix` a patch; a `!` or `BREAKING CHANGE:` footer a major bump.

## Code standards

- Run `dart format .` and `flutter analyze` before pushing — CI enforces both.
- Keep the **domain layer pure** (no Flutter/DB imports in BMI/stats/conversion code) and unit-test it.
- New computed logic (stats, conversions) requires unit tests.

## Reporting bugs / requesting features

Use the issue templates. Include device, Android version, and steps to reproduce for bugs.
