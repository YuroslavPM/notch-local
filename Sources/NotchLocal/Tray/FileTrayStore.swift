import Foundation

struct FileTrayStore: Sendable {
    static let cap = 12

    private let fileURL: URL?

    init() {
        let fm = FileManager.default
        guard let root = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fileURL = nil
            return
        }
        let directory = root.appendingPathComponent("NotchLocal", isDirectory: true)
        fileURL = directory.appendingPathComponent("tray.json")
    }

    func load() -> [TrayItem] {
        guard let fileURL else { return [] }
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([TrayItem].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ items: [TrayItem]) {
        guard let fileURL else { return }
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
    }

    func makeItem(from url: URL) -> TrayItem? {
        let fileURL = url.resolvingSymlinksInPath().standardizedFileURL
        guard fileURL.isFileURL else { return nil }
        do {
            let bookmark = try fileURL.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return TrayItem(
                id: UUID(),
                bookmark: bookmark,
                name: fileURL.lastPathComponent,
                addedAt: Date()
            )
        } catch {
            return nil
        }
    }

    func resolve(_ item: TrayItem) -> ResolvedBookmark {
        var stale = false
        do {
            let url = try URL(
                resolvingBookmarkData: item.bookmark,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
            let standardized = url.resolvingSymlinksInPath().standardizedFileURL
            let exists = FileManager.default.fileExists(atPath: standardized.path)
            var bookmark = item.bookmark
            if exists, stale {
                bookmark = (try? standardized.bookmarkData(
                    options: .minimalBookmark,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )) ?? item.bookmark
            }
            return ResolvedBookmark(
                url: standardized,
                bookmark: bookmark,
                isMissing: !exists,
                name: exists ? standardized.lastPathComponent : item.name
            )
        } catch {
            return ResolvedBookmark(url: nil, bookmark: item.bookmark, isMissing: true, name: item.name)
        }
    }
}
