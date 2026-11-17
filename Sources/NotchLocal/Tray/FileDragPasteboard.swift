import AppKit

enum FileDragPasteboard {
    static let filenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")

    static var isDraggingFiles: Bool {
        // The drag pasteboard often still holds the last Finder files after
        // mouse-up. Only treat it as an active drag while the button is down.
        guard NSEvent.pressedMouseButtons & (1 << 0) != 0 else { return false }
        return !fileURLs(from: NSPasteboard(name: .drag)).isEmpty
    }

    static func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        if let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] {
            let files = urls.filter(\.isFileURL)
            if !files.isEmpty { return unique(files) }
        }

        if let paths = pasteboard.propertyList(forType: filenamesType) as? [String] {
            let files = paths.map { URL(fileURLWithPath: $0) }
            if !files.isEmpty { return unique(files) }
        }

        if let string = pasteboard.string(forType: .fileURL),
           let url = URL(string: string),
           url.isFileURL {
            return [url]
        }

        return []
    }

    private static func unique(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.filter { url in
            let path = url.resolvingSymlinksInPath().standardizedFileURL.path
            return seen.insert(path).inserted
        }
    }
}
