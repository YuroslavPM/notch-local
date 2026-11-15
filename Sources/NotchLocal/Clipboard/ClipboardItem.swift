import Foundation

struct ClipboardItem: Identifiable, Equatable {
    enum Kind: Equatable {
        case text(String)
        case files([URL])
        case image(Data)
    }

    var id: UUID
    var kind: Kind
    var preview: String
}
