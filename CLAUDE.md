# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Stack

Flutter/Dart app (`yastik_alti`), SDK `^3.10.1`. Local-first: sqflite is the primary data store; the backend API is used only to refresh market prices.

## Commands

- Install deps: `flutter pub get`
- Run codegen (required after editing `.env` — see Gotchas): `dart run build_runner build --delete-conflicting-outputs`
- Run (dev): `flutter run`
- Analyze: `flutter analyze`
- Format: `dart format .`
- Test: `flutter test`

`test/` has unit tests (`AppFormatter`, `PortfolioValuator`) and widget tests (`AppSafeText`, `AppOutlinedCard`). `flutter test` also runs in CI on every push/PR to `main` (`.github/workflows/flutter-test.yml`). Write tests for new logic going forward.

## State management: Riverpod

The app uses Riverpod exclusively — the legacy `provider` package was removed (nothing in `lib/` ever imported it; the migration was already complete in code, `provider` was just a stale `pubspec.yaml` entry). Files named `*_provider.dart` under `lib/ui/states/` are Riverpod providers, unrelated to the old package.

## Architecture

Layered: `domain` (models/entities/value objects, repository interfaces) → `data` (`local/` sqflite store, `remote/` API client, `repositories/` implementing the domain interfaces) → `di` (Riverpod provider wiring in `providers.dart`) → `ui` (screens/widgets/state).

`lib/data/remote/remote_market_data.dart` is the only HTTP client — it calls `GET {BASE_URL}/api/prices/market` with an `X-Mobile-Client-Key` header, and defensively discards individual assets that fail to parse rather than failing the whole batch.

## Env vars and the `envied` gotcha

`.env` defines `YASTIK6_API_KEY`, `BASE_URL`, `GOOGLE_DRIVE_CLIENT_ID`. These are embedded at compile time via `envied` into `lib/core/env.g.dart` (obfuscated, generated, gitignored).

- **After editing `.env`, you must rerun `dart run build_runner build --delete-conflicting-outputs`** — otherwise the app keeps using the stale previously-generated values.
- Both `.env` and `lib/core/env.g.dart` are gitignored. On a fresh clone, neither exists — you must recreate `.env` (there's no `.env.example` here to copy from; check the backend's for the matching key format) and run the codegen before the app will build.

## Local backend for full-stack dev

`BASE_URL` defaults to production (`https://yastik6.net`) — running the app as-is does not hit a local backend. To point it at a locally running backend (`dotnet run` in `backend/`, listening on `http://0.0.0.0:5179`), set `BASE_URL=http://localhost:5179` in `.env` and rerun the `build_runner` codegen above. The `/use-local-backend` skill automates this.
