import Foundation

struct TrayItem: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var bookmark: Data
    var name: String
    var addedAt: Date
}
