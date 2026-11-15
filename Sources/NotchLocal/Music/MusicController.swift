import AppKit
import Observation

@MainActor
@Observable
final class MusicController {
    private(set) var nowPlaying: NowPlaying?
    private(set) var artwork: NSImage?
    private(set) var permissionDenied = false
    private(set) var isScrubbing = false
    private(set) var scrubPosition: Double = 0
    var onNowPlayingChange: ((NowPlaying?) -> Void)?

    private let scripts = AppleScriptRunner()
    private let mediaRemote = MediaRemoteClient.make()
    private var pollTask: Task<Void, Never>?
    private var isExpanded = false
    private var lastArtworkKey: String?
    private var lastTrackKey: String?
    private var observers: [NSObjectProtocol] = []

    func start() {
        guard pollTask == nil else { return }
        subscribe()
        mediaRemote?.startStream { [weak self] info in
            Task { @MainActor in
                guard let self else { return }
                if let info {
                    await self.applyRemote(info, fetchArtwork: true)
                }
            }
        }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                await self.refresh()
                let interval: Duration = self.isExpanded ? .seconds(1) : .seconds(4)
                try? await Task.sleep(for: interval)
            }
        }
    }

    func shutdown() {
        pollTask?.cancel()
        pollTask = nil
        mediaRemote?.stopStream()
        unsubscribe()
    }

    func setActive(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
        if isExpanded {
            Task { await refresh() }
        }
    }

    func playPause() {
        Task { await sendControl(media: ["toggle-play-pause"], script: "playpause") }
    }

    func nextTrack() {
        Task { await sendControl(media: ["next-track"], script: "next track") }
    }

    func previousTrack() {
        Task { await sendControl(media: ["previous-track"], script: "previous track") }
    }

    func beginScrub(at seconds: TimeInterval) {
        isScrubbing = true
        scrubPosition = seconds
    }

    func updateScrub(_ seconds: TimeInterval) {
        scrubPosition = max(0, seconds)
    }

    func endScrub() {
        let seconds = scrubPosition
        isScrubbing = false
        seek(to: seconds)
    }

    func seek(to seconds: TimeInterval) {
        let clamped = max(0, seconds)
        if var playing = nowPlaying {
            playing.elapsedTime = clamped
            playing.capturedAt = Date()
            nowPlaying = playing
        }
        Task {
            await mediaRemote?.send(["seek", String(format: "%.3f", clamped)])
            if nowPlaying?.source.usesAppleScript == true {
                await seekWithAppleScript(clamped)
            }
            await refresh()
        }
    }

    func revealPlayer() {
        guard let source = nowPlaying?.source else { return }
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: source.bundleIdentifier)
        if let app = running.first {
            app.activate()
            return
        }
        guard source.usesAppleScript else { return }
        Task {
            _ = await scripts.run("tell application \"\(source.displayName)\" to activate")
        }
    }

    func refresh() async {
        if let remote = await mediaRemote?.getMetadata() {
            await applyRemote(remote, fetchArtwork: true)
            return
        }
        await refreshFromAppleScript()
    }

    private func applyRemote(_ info: MediaRemoteInfo, fetchArtwork: Bool) async {
        let bundle = info.parentBundleIdentifier ?? info.bundleIdentifier
        let source = MusicSource.named(bundleIdentifier: bundle)
        let playing = NowPlaying(
            source: source,
            title: info.title,
            artist: info.artist,
            isPlaying: info.isPlaying,
            artworkURL: nil,
            artworkData: info.artworkData,
            elapsedTime: info.elapsedTime,
            duration: info.duration,
            capturedAt: info.capturedAt
        )
        publish(playing)

        if let data = info.artworkData, let image = NSImage(data: data) {
            artwork = image
            lastArtworkKey = trackKey(playing)
            return
        }

        guard fetchArtwork else { return }
        let key = trackKey(playing)
        guard key != lastArtworkKey else { return }
        lastArtworkKey = key
        if let data = await mediaRemote?.getArtwork(), let image = NSImage(data: data) {
            artwork = image
        } else if source.usesAppleScript {
            await updateArtwork(for: playing)
        }
    }

    private func refreshFromAppleScript() async {
        let sources = runningScriptableSources()
        guard !sources.isEmpty else {
            publish(nil)
            return
        }

        var snapshots: [MusicSource: NowPlaying] = [:]
        for source in sources {
            if let playing = await read(from: source) {
                snapshots[source] = playing
            }
            if permissionDenied { return }
        }

        let chosen: NowPlaying?
        if let playing = snapshots[.spotify], playing.isPlaying {
            chosen = playing
        } else if let playing = snapshots[.appleMusic], playing.isPlaying {
            chosen = playing
        } else {
            chosen = snapshots[.spotify] ?? snapshots[.appleMusic]
        }

        guard let chosen else {
            publish(nil)
            return
        }

        publish(chosen)
        await updateArtwork(for: chosen)
    }

    private func publish(_ playing: NowPlaying?) {
        let key = playing.map(trackKey)
        let changed = key != lastTrackKey
        nowPlaying = playing
        if playing == nil {
            artwork = nil
            lastArtworkKey = nil
        }
        lastTrackKey = key
        if changed {
            onNowPlayingChange?(playing)
        }
    }

    private func trackKey(_ playing: NowPlaying) -> String {
        "\(playing.source.bundleIdentifier)|\(playing.title)|\(playing.artist)"
    }

    private func runningScriptableSources() -> [MusicSource] {
        let ids = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        var sources: [MusicSource] = []
        if ids.contains(MusicSource.spotify.bundleIdentifier) { sources.append(.spotify) }
        if ids.contains(MusicSource.appleMusic.bundleIdentifier) { sources.append(.appleMusic) }
        return sources
    }

    private func read(from source: MusicSource) async -> NowPlaying? {
        let outcome = await scripts.run(Self.readScript(for: source))
        if outcome.errorNumber == -1743 {
            permissionDenied = true
            return nil
        }
        guard let text = outcome.text else { return nil }
        return parse(text, source: source)
    }

    private func sendControl(media: [String], script: String) async {
        await mediaRemote?.send(media)
        if nowPlaying?.source.usesAppleScript == true || mediaRemote == nil {
            guard let source = nowPlaying?.source ?? runningScriptableSources().first, source.usesAppleScript else {
                await refresh()
                return
            }
            let outcome = await scripts.run("tell application \"\(source.displayName)\" to \(script)")
            if outcome.errorNumber == -1743 {
                permissionDenied = true
            }
        }
        await refresh()
    }

    private func seekWithAppleScript(_ seconds: TimeInterval) async {
        guard let source = nowPlaying?.source, source.usesAppleScript else { return }
        _ = await scripts.run("tell application \"\(source.displayName)\" to set player position to \(seconds)")
    }

    private func updateArtwork(for playing: NowPlaying) async {
        let key = trackKey(playing)
        if let url = playing.artworkURL {
            artwork = await downloadImage(from: url)
            lastArtworkKey = key
            return
        }

        guard playing.source == .appleMusic else { return }
        let outcome = await scripts.run(
            "tell application \"Music\" to get raw data of artwork 1 of current track"
        )
        if let data = outcome.data, let image = NSImage(data: data) {
            artwork = image
            lastArtworkKey = key
        }
    }

    private func downloadImage(from url: URL) async -> NSImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return NSImage(data: data)
        } catch {
            return nil
        }
    }

    private func parse(_ text: String, source: MusicSource) -> NowPlaying? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "stopped" { return nil }
        let parts = trimmed.components(separatedBy: "||")
        guard parts.count >= 3 else { return nil }
        let art = parts.count > 3 ? parts[3] : ""
        var elapsed = Double(parts.count > 4 ? parts[4] : "0") ?? 0
        var duration = Double(parts.count > 5 ? parts[5] : "0") ?? 0
        if source == .spotify, duration > 1000 {
            duration /= 1000
        }
        elapsed = max(0, elapsed)
        duration = max(0, duration)
        return NowPlaying(
            source: source,
            title: parts[1],
            artist: parts[2],
            isPlaying: parts[0] == "playing",
            artworkURL: URL(string: art),
            artworkData: nil,
            elapsedTime: elapsed,
            duration: duration,
            capturedAt: Date()
        )
    }

    private func subscribe() {
        let names = [
            Notification.Name("com.spotify.client.PlaybackStateChanged"),
            Notification.Name("com.apple.Music.playerInfo")
        ]
        for name in names {
            let token = DistributedNotificationCenter.default().addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    await self?.refresh()
                }
            }
            observers.append(token)
        }
    }

    private func unsubscribe() {
        for observer in observers {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        observers.removeAll()
    }

    private static func readScript(for source: MusicSource) -> String {
        switch source.bundleIdentifier {
        case MusicSource.spotify.bundleIdentifier:
            """
            tell application "Spotify"
              try
                set s to (player state as string)
                if s is "stopped" then return "stopped"
                set t to current track
                set art to ""
                try
                  set art to artwork url of t
                end try
                set pos to player position
                set dur to duration of t
                return s & "||" & (name of t) & "||" & (artist of t) & "||" & art & "||" & pos & "||" & dur
              on error
                return "stopped"
              end try
            end tell
            """
        default:
            """
            tell application "Music"
              try
                set s to (player state as string)
                if s is "stopped" then return "stopped"
                set t to current track
                set pos to player position
                set dur to duration of t
                return s & "||" & (name of t) & "||" & (artist of t) & "||" & "" & "||" & pos & "||" & dur
              on error
                return "stopped"
              end try
            end tell
            """
        }
    }
}
