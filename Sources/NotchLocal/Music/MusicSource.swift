enum MusicSource: String, Equatable, Hashable {
    case spotify = "Spotify"
    case appleMusic = "Music"

    var bundleIdentifier: String {
        switch self {
        case .spotify: "com.spotify.client"
        case .appleMusic: "com.apple.Music"
        }
    }
}
