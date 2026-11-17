import AppKit

struct MusicSource: Equatable, Hashable {
    let bundleIdentifier: String
    let displayName: String

    static let spotify = MusicSource(bundleIdentifier: "com.spotify.client", displayName: "Spotify")
    static let appleMusic = MusicSource(bundleIdentifier: "com.apple.Music", displayName: "Music")

    var usesAppleScript: Bool {
        self == .spotify || self == .appleMusic
    }

    static func launchable(child: String, parent: String?) -> String {
        let ordered = [parent, child].compactMap { id -> String? in
            guard let id else { return nil }
            let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        let preferred = ordered.filter { id in
            !id.contains("WebKit") && !id.contains("Helper") && !id.hasSuffix(".xpc")
        }
        for id in preferred + ordered {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil {
                return id
            }
        }
        return parent ?? child
    }

    static func named(bundleIdentifier: String) -> MusicSource {
        if bundleIdentifier == spotify.bundleIdentifier { return .spotify }
        if bundleIdentifier == appleMusic.bundleIdentifier { return .appleMusic }
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        let name = running.first?.localizedName
            ?? bundleIdentifier.split(separator: ".").last.map(String.init)
            ?? bundleIdentifier
        return MusicSource(bundleIdentifier: bundleIdentifier, displayName: name)
    }
}
