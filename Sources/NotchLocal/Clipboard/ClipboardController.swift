import AppKit
import Observation

@MainActor
@Observable
final class ClipboardController {
    private(set) var items: [ClipboardItem] = []

    private var pollTask: Task<Void, Never>?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var ignoringChangeCount: Int?

    func start() {
        guard pollTask == nil else { return }
        lastChangeCount = NSPasteboard.general.changeCount
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.poll()
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }

    func shutdown() {
        pollTask?.cancel()
        pollTask = nil
    }

    func restore(_ item: ClipboardItem) {
        let board = NSPasteboard.general
        board.clearContents()
        switch item.kind {
        case .text(let text):
            board.setString(text, forType: .string)
        case .files(let urls):
            board.writeObjects(urls as [NSURL])
        case .image(let data):
            if let image = NSImage(data: data) {
                board.writeObjects([image])
            }
        }
        ignoringChangeCount = board.changeCount
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
    }

    private func poll() {
        let board = NSPasteboard.general
        let count = board.changeCount
        guard count != lastChangeCount else { return }
        lastChangeCount = count
        if count == ignoringChangeCount {
            ignoringChangeCount = nil
            return
        }
        guard let item = Self.read(from: board) else { return }
        items.removeAll { $0.kind == item.kind && $0.preview == item.preview }
        items.insert(item, at: 0)
        if items.count > 8 {
            items = Array(items.prefix(8))
        }
    }

    private static func read(from board: NSPasteboard) -> ClipboardItem? {
        if let urls = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           !urls.isEmpty {
            let files = urls.filter(\.isFileURL)
            if !files.isEmpty {
                let names = files.map(\.lastPathComponent).joined(separator: ", ")
                return ClipboardItem(id: UUID(), kind: .files(files), preview: names)
            }
        }
        if let text = board.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            let preview = text.replacingOccurrences(of: "\n", with: " ")
            return ClipboardItem(id: UUID(), kind: .text(text), preview: preview)
        }
        if let image = board.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
           let data = image.tiffRepresentation {
            return ClipboardItem(id: UUID(), kind: .image(data), preview: "Image")
        }
        return nil
    }
}
