import AppKit
import Observation

@MainActor
@Observable
final class FileTrayController {
    private(set) var items: [TrayItem] = []
    private(set) var isTargeted = false
    private(set) var hoveredID: UUID?

    let airDrop = AirDropService()

    private let store = FileTrayStore()
    private var urls: [UUID: URL] = [:]
    private var missing: Set<UUID> = []
    private var icons: [UUID: NSImage] = [:]
    private var saveTask: Task<Void, Never>?

    func start() {
        let store = store
        Task { [weak self] in
            let loaded = await Task.detached {
                store.load().map { item in
                    (item, store.resolve(item))
                }
            }.value
            self?.apply(loaded)
        }
    }

    func shutdown() {
        saveTask?.cancel()
        saveTask = nil
    }

    func setTargeted(_ targeted: Bool) {
        isTargeted = targeted
    }

    func setHovered(_ id: UUID?) {
        hoveredID = id
    }

    func add(urls incoming: [URL]) {
        guard !incoming.isEmpty else { return }
        let store = store
        Task { [weak self] in
            let prepared = await Task.detached {
                incoming.compactMap { url -> (TrayItem, ResolvedBookmark)? in
                    guard let item = store.makeItem(from: url) else { return nil }
                    return (item, store.resolve(item))
                }
            }.value
            self?.merge(prepared)
        }
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        urls[id] = nil
        missing.remove(id)
        icons[id] = nil
        if hoveredID == id { hoveredID = nil }
        persist()
    }

    func resolvedURL(for item: TrayItem) -> URL? {
        urls[item.id]
    }

    func isMissing(_ item: TrayItem) -> Bool {
        missing.contains(item.id)
    }

    func icon(for item: TrayItem) -> NSImage {
        if let cached = icons[item.id] { return cached }
        let image: NSImage
        if let url = urls[item.id], !missing.contains(item.id) {
            image = NSWorkspace.shared.icon(forFile: url.path)
        } else {
            image = NSImage(systemSymbolName: "questionmark.square", accessibilityDescription: item.name)
                ?? NSImage(size: NSSize(width: 36, height: 36))
        }
        image.size = NSSize(width: 36, height: 36)
        icons[item.id] = image
        return image
    }

    func open(_ item: TrayItem) {
        guard let url = urls[item.id], !missing.contains(item.id) else { return }
        NSWorkspace.shared.open(url)
    }

    func reveal(_ item: TrayItem) {
        guard let url = urls[item.id], !missing.contains(item.id) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func canAirDrop(_ item: TrayItem) -> Bool {
        guard let url = urls[item.id], !missing.contains(item.id) else { return false }
        return airDrop.canShare(url)
    }

    func airDrop(_ item: TrayItem) {
        guard let url = urls[item.id] else { return }
        airDrop.share(url)
    }

    func dragProvider(for item: TrayItem) -> NSItemProvider {
        guard let url = urls[item.id], !missing.contains(item.id) else {
            return NSItemProvider()
        }
        return NSItemProvider(contentsOf: url) ?? NSItemProvider()
    }

    private func merge(_ incoming: [(TrayItem, ResolvedBookmark)]) {
        var existingPaths = Set(items.compactMap { urls[$0.id]?.path })
        var additions: [TrayItem] = []
        for (item, resolved) in incoming {
            if let path = resolved.url?.path, existingPaths.contains(path) {
                continue
            }
            var stored = item
            stored.bookmark = resolved.bookmark
            stored.name = resolved.name
            additions.append(stored)
            urls[stored.id] = resolved.url
            icons[stored.id] = nil
            if resolved.isMissing {
                missing.insert(stored.id)
            } else {
                missing.remove(stored.id)
            }
            if let path = resolved.url?.path {
                existingPaths.insert(path)
            }
        }
        guard !additions.isEmpty else { return }
        let combined = additions + items
        if combined.count > FileTrayStore.cap {
            for item in combined.suffix(from: FileTrayStore.cap) {
                urls[item.id] = nil
                missing.remove(item.id)
                icons[item.id] = nil
            }
        }
        items = Array(combined.prefix(FileTrayStore.cap))
        persist()
    }

    private func apply(_ loaded: [(TrayItem, ResolvedBookmark)]) {
        var next: [TrayItem] = []
        var refreshed = false
        urls = [:]
        missing = []
        icons = [:]
        for (item, resolved) in loaded.prefix(FileTrayStore.cap) {
            var stored = item
            if stored.bookmark != resolved.bookmark {
                stored.bookmark = resolved.bookmark
                refreshed = true
            }
            stored.name = resolved.name
            next.append(stored)
            urls[stored.id] = resolved.url
            if resolved.isMissing {
                missing.insert(stored.id)
            }
        }
        items = next
        if refreshed {
            persist()
        }
    }

    private func persist() {
        let snapshot = items
        let store = store
        saveTask?.cancel()
        saveTask = Task.detached {
            store.save(snapshot)
        }
    }
}
