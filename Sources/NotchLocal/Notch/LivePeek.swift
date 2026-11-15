import Foundation

enum LivePeek: Equatable {
    case music(title: String, artist: String)
    case meeting(title: String, startsAt: Date)
    case battery(percent: Int, charging: Bool)
}
