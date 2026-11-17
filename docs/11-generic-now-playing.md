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

2. **MediaRemoteClient.** Run `media-control get --no-artwork --now --micros --allow-missing-title` and `stream --no-diff --no-artwork --micros --allow-missing-title` off the main thread. Read the process pipe **before** `waitUntilExit` so large `artworkData` cannot deadlock. Parse JSON (`bundleIdentifier`, `parentApplicationBundleIdentifier`, `playing`, `title`, `artist`, `elapsedTimeMicros` / `timestampEpochMicros` / `durationMicros`, `artworkData`). Use `elapsedTime` at `timestamp` and interpolate in the UI. Prefer `--micros`: the ISO `timestamp` is truncated to whole seconds and leaves the bar ~1 s off. Do **not** combine `elapsedTimeNow` with `timestamp` — that value is already live and would run the bar at ~2× until it pins at duration. Fall back to `elapsedTimeNow` only when `elapsedTime` is missing, and treat it as captured at `Date()`. Send `play` / `pause` (not toggle), `next-track`, `previous-track`, and `seek` in seconds. Fetch artwork with a separate `get` when the track changes. Spotify and Music use AppleScript **instead of** MediaRemote for commands — sending both toggles twice and leaves playback paused.

3. Prefer MediaRemote when it reports a title. If `get` returns `null` or fails, fall back to Spotify / Music AppleScript so those players keep working.

4. Show a live progress bar and let the user drag to seek (`media-control seek` plus AppleScript `player position` for Spotify / Music).

4. Clicking the artwork, the title, or a music peek calls `revealPlayer()`. Collapse the notch, then open that app with `NSWorkspace.openApplication` (`activates = true`). An accessory panel’s `activate()` is ignored, so briefly switch to `.regular` for the handoff. Prefer the parent app bundle over a WebKit or Helper id. Spotify and Music also get AppleScript `activate`.

## Done when

- YouTube in Safari or Chrome shows title (and artwork when the system provides it) and the three buttons work.
- Spotify and Apple Music still work if `media-control` is missing or stalls.
- The progress bar moves in sync with the track; it does not race ahead and stick at the end. Dragging it seeks.
- Closed players are not launched.

## Pitfalls

- `media-control` is a Perl wrapper plus `MediaRemoteAdapter.framework`. Do not copy only the script into the `.app`.
- `artworkData` is large base64 and often arrives a moment after title/artist. Stream without artwork, then `get` once per track.
- Finder-launched apps do not inherit Homebrew `PATH`. Use absolute binary paths.
- Play/pause must be a single `play` or `pause`, not MediaRemote **and** AppleScript `playpause`. The second toggle cancels the first, so after a few clicks the track stays paused. Hold the local playing flag until Now Playing agrees, or a stale stream event will flip the button back.
