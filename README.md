# Room Zero — AI Evolution

Room Zero is a sci-fi incremental game built with Flutter. Build up an AI through a technology tree, automate production, discover room events and secrets, unlock transformations, and progress through 20 themed rooms. Progress is saved locally and the game supports offline progression.

## Requirements

- Flutter 3.29 or newer (Dart 3.7 or newer)
- A supported Flutter target: Chrome/Web, Windows, Android, or Linux

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

For desktop development, choose the corresponding device (for example, `flutter run -d windows`). The first launch loads configuration from `assets/config/` and room definitions from `assets/config/rooms/`.

## Build

```bash
# Web build
flutter build web --release

# GitHub Pages build for the repository's /Game/ path
flutter build web --release --base-href /Game/

# Windows desktop build
flutter build windows --release

# Android release APK
flutter build apk --release
```

The GitHub Actions workflows run analysis and tests, build the web version, and publish the `/Game/` web build to GitHub Pages when changes are pushed to `main`.

## Validate changes

```bash
dart analyze lib
flutter test
flutter build web --release
```

A web build uses browser-safe audio feedback and disables the Windows desktop updater. Native IO, FFI audio, and desktop updater implementations are selected only on IO-capable platforms; platform-specific code is separated with conditional exports.

## Configuration and saves

- `assets/config/game_config.json` controls save intervals, tick rate, and offline progression limits.
- `assets/config/economy_config.json` defines the economy, generators, upgrades, eras, achievements, and endings.
- `assets/config/progression_config.json` and `assets/config/rooms/` define progression and room content.
- Player settings and save data use `shared_preferences` on the target platform.
- Supabase leaderboard configuration and safe submission guidance are documented in [SUPABASE_SETUP.md](SUPABASE_SETUP.md).
- Windows auto-updater setup is documented in [docs/WINDOWS_UPDATER.md](docs/WINDOWS_UPDATER.md).

## Platform notes

The Windows build can use the native WAV playback and updater integrations. Browser builds do not attempt to load Windows DLLs or use desktop updater APIs, and remain playable when online leaderboard requests fail.
