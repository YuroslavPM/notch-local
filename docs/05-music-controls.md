# 05 - Music controls

## Goal

The expanded panel shows the current Spotify or Apple Music track (artwork, title, artist) with previous / play-pause / next buttons that control playback.

## Files created / changed

- `Sources/NotchLocal/Music/MusicSource.swift`
- `Sources/NotchLocal/Music/NowPlaying.swift`
- `Sources/NotchLocal/Music/AppleScriptRunner.swift`
- `Sources/NotchLocal/Music/MusicController.swift`
- `Sources/NotchLocal/Music/MusicView.swift`
- `Sources/NotchLocal/Notch/NotchRootView.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`

## Steps

1. **Model.**
   ```swift
   enum MusicSource: String { case spotify = "Spotify", appleMusic = "Music" }

   struct NowPlaying: Equatable {
       var source: MusicSource
       var title: String
       var artist: String
       var isPlaying: Bool
       var artworkURL: URL?      // Spotify
       var artworkData: Data?    // Apple Music
   }
   ```

2. **Detect the player without launching it.** A `tell application` block launches the app if it is closed, so always check first:
   ```swift
   func runningSource() -> MusicSource? {
       let ids = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
       if ids.contains("com.spotify.client") { return .spotify }
       if ids.contains("com.apple.Music") { return .appleMusic }
       return nil
   }
   ```
   If both are running, prefer the one whose player state is `playing`.

3. **AppleScript runner.** `NSAppleScript` is not thread-safe. Run every script on one serial queue and return results to the main actor:
   ```swift
   final class AppleScriptRunner: @unchecked Sendable {
       private let queue = DispatchQueue(label: "notchlocal.applescript")

       func run(_ source: String) async -> NSAppleEventDescriptor? {
           await withCheckedContinuation { cont in
               queue.async {
                   var error: NSDictionary?
                   let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
                   cont.resume(returning: error == nil ? result : nil)
               }
           }
       }
   }
   ```

4. **Read scripts.** Return one string separated by `||`:
   - Spotify:
     ```applescript
     tell application "Spotify"
       set s to (player state as string)
       set t to current track
       return s & "||" & (name of t) & "||" & (artist of t) & "||" & (artwork url of t)
     end tell
     ```
   - Music:
     ```applescript
     tell application "Music"
       set s to (player state as string)
       set t to current track
       return s & "||" & (name of t) & "||" & (artist of t)
     end tell
     ```
   - Music artwork (separate call, only when the track changes): `tell application "Music" to get raw data of artwork 1 of current track`. Read `descriptor.data` into `NSImage(data:)`.
   - Wrap reads in `try ... on error return "stopped"` so a stopped player does not error.

5. **Commands.** `tell application "<Spotify|Music>" to playpause`, `next track`, `previous track`. After a command, refresh immediately.

6. **MusicController** (`@MainActor @Observable`):
   - `nowPlaying: NowPlaying?`, `artwork: NSImage?`, `permissionDenied: Bool`.
   - `refresh()` reads state. It only re-fetches artwork when title or artist changes. Spotify artwork comes from `URLSession` on `artworkURL`.
   - Polling: a `Task` loop with 1 s interval while expanded and 5 s while collapsed. Expose `setActive(_ isExpanded: Bool)` and call it from `onStateChange`.
   - Instant updates: subscribe to `DistributedNotificationCenter` names `com.spotify.client.PlaybackStateChanged` and `com.apple.Music.playerInfo` and call `refresh()`.
   - If an error dictionary has `NSAppleScriptErrorNumber == -1743`, set `permissionDenied = true` (user denied Automation).

7. **MusicView.**
   - `HStack`: artwork 56 x 56 with corner radius 10 (gray placeholder with `music.note` symbol), then `VStack` with title (`.headline`, 1 line) and artist (`.subheadline`, secondary, 1 line).
   - Buttons: `backward.fill`, `play.fill` / `pause.fill`, `forward.fill` with `.buttonStyle(.plain)` and white foreground.
   - Empty state: "Nothing playing" when `nowPlaying == nil`.
   - Permission hint: "Allow NotchLocal in System Settings > Privacy & Security > Automation" when `permissionDenied`.

8. Put `MusicView` at the top of the expanded content in `NotchRootView`. Create `MusicController` in `AppDelegate` and inject it.

9. Run `make run`, verify, commit: `step 05: Spotify and Apple Music controls`.

## Key code notes

- The first script call against each player triggers a macOS "NotchLocal wants to control Spotify" prompt. This only works from the signed `.app`.
- Keep script parsing defensive. Titles can contain unusual characters, but `||` is very unlikely in a title.

## Done when

- Spotify playing: title, artist and artwork appear and all three buttons work.
- Apple Music playing: same.
- Neither app running: "Nothing playing", and neither app gets launched.
- Changing track in the player updates the panel within about 1 s.
- Denying Automation shows the hint instead of crashing.

## Pitfalls

- Never send a `tell application` script to a player that is not running.
- Do not run `NSAppleScript` concurrently from multiple threads.
- Spotify podcasts / ads may return empty artist or artwork URL. Handle empty strings.
