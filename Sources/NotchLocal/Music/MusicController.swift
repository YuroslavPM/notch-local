import AppKit
import Observation

@MainActor
@Observable
final class MusicController {
    private(set) var nowPlaying: NowPlaying?
    private(set) var artwork: NSImage?
    private(set) var permissionDenied = false

    private let scripts = AppleScriptRunner()
    private var pollTask: Task<Void, Never>?
    private var isExpanded = false
    private var lastArtworkKey: String?
    private var observers: [NSObjectProtocol] = []

    func start() {
        guard pollTask == nil else { return }
        subscribe()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { break }
                await self.refresh()
                let interval: Duration = self.isExpanded ? .seconds(1) : .seconds(5)
                try? await Task.sleep(for: interval)
            }
        }
    }

    func shutdown() {
        pollTask?.cancel()
        pollTask = nil
        unsubscribe()
    }

    func setActive(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
        if isExpanded {
            Task { await refresh() }
        }
    }

    func playPause() {
        Task { await send("playpause") }
    }

    func nextTrack() {
        Task { await send("next track") }
    }

    func previousTrack() {
        Task { await send("previous track") }
    }

    func refresh() async {
        let sources = runningSources()
        guard !sources.isEmpty else {
            clearNowPlaying()
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
            clearNowPlaying()
            return
        }

        nowPlaying = chosen
        await updateArtwork(for: chosen)
    }

    private func runningSources() -> [MusicSource] {
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

    private func send(_ command: String) async {
        guard let source = nowPlaying?.source ?? runningSources().first else { return }
        let outcome = await scripts.run("tell application \"\(source.rawValue)\" to \(command)")
        if outcome.errorNumber == -1743 {
            permissionDenied = true
            return
        }
        await refresh()
    }

    private func updateArtwork(for playing: NowPlaying) async {
        let key = "\(playing.source.rawValue)|\(playing.title)|\(playing.artist)"
        guard key != lastArtworkKey else { return }
        lastArtworkKey = key
        artwork = nil

        if let url = playing.artworkURL {
            artwork = await downloadImage(from: url)
            return
        }

        guard playing.source == .appleMusic else { return }
        let outcome = await scripts.run(
            "tell application \"Music\" to get raw data of artwork 1 of current track"
        )
        if let data = outcome.data, let image = NSImage(data: data) {
            artwork = image
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
        return NowPlaying(
            source: source,
            title: parts[1],
            artist: parts[2],
            isPlaying: parts[0] == "playing",
            artworkURL: URL(string: art),
            artworkData: nil
        )
    }

    private func clearNowPlaying() {
        nowPlaying = nil
        artwork = nil
        lastArtworkKey = nil
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
        switch source {
        case .spotify:
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
                return s & "||" & (name of t) & "||" & (artist of t) & "||" & art
              on error
                return "stopped"
              end try
            end tell
            """
        case .appleMusic:
            """
            tell application "Music"
              try
                set s to (player state as string)
                if s is "stopped" then return "stopped"
                set t to current track
                return s & "||" & (name of t) & "||" & (artist of t)
              on error
                return "stopped"
              end try
            end tell
            """
        }
    }
}
