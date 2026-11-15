# 11 - Generic Now Playing

## Goal

The expanded panel shows whatever macOS reports as Now Playing: Spotify, Apple Music, Safari/Chrome YouTube, Podcasts, and other players. AppleScript remains the fallback when `media-control` is missing.

## Files created / changed

- `Sources/NotchLocal/Music/MediaRemoteClient.swift`
- `Sources/NotchLocal/Music/MusicSource.swift`
- `Sources/NotchLocal/Music/NowPlaying.swift`
- `Sources/NotchLocal/Music/MusicController.swift`
- `Sources/NotchLocal/Music/MusicView.swift`

## Steps

1. Install [media-control](https://github.com/ungive/media-control) (BSD-3-Clause, wraps mediaremote-adapter):
   ```bash
   brew install media-control
   ```
   The app looks for `/opt/homebrew/bin/media-control` then `/usr/local/bin/media-control`. It does not launch closed players.

2. **MediaRemoteClient.** Run `media-control get --no-artwork --now --allow-missing-title` and `stream --no-diff --no-artwork --allow-missing-title` off the main thread. Read the process pipe **before** `waitUntilExit` so large `artworkData` cannot deadlock. Parse JSON (`bundleIdentifier`, `parentApplicationBundleIdentifier`, `playing`, `title`, `artist`, `elapsedTime` / `elapsedTimeNow`, `duration`, `artworkData`). Send `toggle-play-pause`, `next-track`, `previous-track`, and `seek`. Fetch artwork with a separate `get` when the track changes.

3. Prefer MediaRemote when it reports a title. If `get` returns `null` or fails, fall back to Spotify / Music AppleScript so those players keep working.

4. Show a live progress bar and let the user drag to seek (`media-control seek` plus AppleScript `player position` for Spotify / Music).

4. Activate the reporting app by bundle identifier when the user clicks artwork or title.

## Done when

- YouTube in Safari or Chrome shows title (and artwork when the system provides it) and the three buttons work.
- Spotify and Apple Music still work if `media-control` is missing or stalls.
- The progress bar moves while playing; dragging it seeks.
- Closed players are not launched.

## Pitfalls

- `media-control` is a Perl wrapper plus `MediaRemoteAdapter.framework`. Do not copy only the script into the `.app`.
- `artworkData` is large base64 and often arrives a moment after title/artist. Stream without artwork, then `get` once per track.
- Finder-launched apps do not inherit Homebrew `PATH`. Use absolute binary paths.
