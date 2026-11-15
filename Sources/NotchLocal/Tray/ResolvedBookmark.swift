import Foundation

struct ResolvedBookmark: Sendable {
    var url: URL?
    var bookmark: Data
    var isMissing: Bool
    var name: String
}
