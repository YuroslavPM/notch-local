import Foundation

struct NowPlaying: Equatable {
    var source: MusicSource
    var title: String
    var artist: String
    var isPlaying: Bool
    var artworkURL: URL?
    var artworkData: Data?
    var elapsedTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var capturedAt: Date = Date()

    func displayedElapsed(at now: Date = Date()) -> TimeInterval {
        var elapsed = elapsedTime
        if isPlaying {
            elapsed += now.timeIntervalSince(capturedAt)
        }
        if duration > 0 {
            return min(duration, max(0, elapsed))
        }
        return max(0, elapsed)
    }
}
