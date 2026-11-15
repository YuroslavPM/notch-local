import AppKit

@MainActor
final class AirDropService: NSObject, NSSharingServiceDelegate {
    weak var sourceWindow: NSWindow?

    func canShare(_ url: URL) -> Bool {
        guard url.isFileURL, FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        return NSSharingService(named: .sendViaAirDrop)?.canPerform(withItems: [url]) ?? false
    }

    func share(_ url: URL) {
        share(urls: [url])
    }

    func share(urls: [URL]) {
        let items = urls.filter(canShare)
        guard !items.isEmpty,
              let service = NSSharingService(named: .sendViaAirDrop),
              service.canPerform(withItems: items) else {
            return
        }
        NSApp.activate()
        sourceWindow?.makeKeyAndOrderFront(nil)
        service.delegate = self
        service.perform(withItems: items)
    }

    func sharingService(
        _ sharingService: NSSharingService,
        sourceWindowForShareItems items: [Any],
        sharingContentScope: UnsafeMutablePointer<NSSharingService.SharingContentScope>
    ) -> NSWindow? {
        sourceWindow
    }
}
