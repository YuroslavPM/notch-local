import AppKit

enum FileDragPasteboard {
    static var isDraggingFiles: Bool {
        NSPasteboard(name: .drag).canReadObject(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        )
    }

    static func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        return urls.filter(\.isFileURL)
    }
}
