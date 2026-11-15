import Foundation

struct NowPlaying: Equatable {
    var source: MusicSource
    var title: String
    var artist: String
    var isPlaying: Bool
    var artworkURL: URL?
    var artworkData: Data?
}
