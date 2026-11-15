import Foundation

struct MediaRemoteInfo: Sendable, Equatable {
    var bundleIdentifier: String
    var parentBundleIdentifier: String?
    var title: String
    var artist: String
    var isPlaying: Bool
    var elapsedTime: TimeInterval
    var duration: TimeInterval
    var capturedAt: Date
    var artworkData: Data?
}
