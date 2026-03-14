# Windows Updater

This project now includes an in-app Windows updater built on top of the
`desktop_updater` package.

## What the app expects

The game reads updater settings from:

`assets/config/update_config.json`

Current shape:

```json
{
  "windowsArchiveUrl": "https://downloads.example.com/room-zero/app-archive.json",
  "autoCheckOnLaunch": true,
  "showPromptWhenAvailable": true
}
```

Only `windowsArchiveUrl` is required for update checks.

## How updates work

1. Bump the version in `pubspec.yaml`.
2. Build the release.
3. Generate the updater archive for Windows.
4. Publish both:
   - `app-archive.json`
   - the generated version folder
5. Keep `windowsArchiveUrl` pointed at the stable `app-archive.json` URL.

The app compares the local build number with `shortVersion` from the feed and,
if newer files exist, downloads only changed files before asking the player to
restart.

## Release flow

Run these commands from the repo root:

```powershell
& 'C:\Users\Senva\source\flutter\bin\flutter.bat' build windows --release
& 'C:\Users\Senva\source\flutter\bin\cache\dart-sdk\bin\dart.exe' run desktop_updater:release windows
& 'C:\Users\Senva\source\flutter\bin\cache\dart-sdk\bin\dart.exe' run desktop_updater:archive windows
```

After that, the package will create a `dist/` directory with the Windows update
payload folder named like:

`1.0.0+1-windows`

Publish that folder as-is on HTTPS.

## Feed format

Use `distribution/windows/app-archive.example.json` as the starting point.

Important fields:

- `version`: semantic version shown to users
- `shortVersion`: build number used for comparison
- `changes`: release notes shown inside the game
- `mandatory`: when `true`, the player cannot dismiss the update prompt
- `url`: direct URL to the published archive folder
- `platform`: must be `windows`

Example:

```json
{
  "appName": "Room Zero",
  "description": "Room Zero Windows update feed",
  "items": [
    {
      "version": "1.0.1",
      "shortVersion": 2,
      "changes": [
        { "type": "feat", "message": "Added the in-game Windows updater." },
        { "type": "fix", "message": "Improved room backdrop rendering." }
      ],
      "date": "2026-03-14",
      "mandatory": false,
      "url": "https://downloads.example.com/room-zero/1.0.1+2-windows",
      "platform": "windows"
    }
  ]
}
```

## Hosting requirements

- Use HTTPS.
- The app must be able to fetch `app-archive.json`.
- The `url` field for each item must point to the archive folder itself.
- Do not require auth for updater files unless you also modify the client for
  authenticated fetches.

## UI behavior

The Windows build now exposes:

- automatic update checks on launch
- a settings toggle for automatic checks
- a manual `Check for updates` action
- in-game update prompt with release notes
- download progress
- restart prompt when the update is ready

## Recommended operational rules

- Never reuse a version/build number.
- Keep at least one previous archive available while rolling out a new feed.
- Put real player-facing notes into `changes`; they are shown inside the game.
- Test the full flow with a staging feed before changing the production URL.
