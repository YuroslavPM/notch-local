import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let store: SettingsStore
    private var restoreAccessory = false

    init(store: SettingsStore) {
        self.store = store
    }

    func show() {
        restoreAccessory = NSApp.activationPolicy() == .accessory
        if restoreAccessory {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate()

        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView(store: store))
            let window = NSWindow(contentViewController: hosting)
            window.title = "NotchLocal Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.level = .floating
            self.window = window
        }
        guard let window else { return }
        window.center()
        if let visible = NSScreen.main?.visibleFrame {
            var frame = window.frame
            frame.origin.x = visible.midX - frame.width / 2
            frame.origin.y = visible.midY - frame.height / 2 - 40
            window.setFrame(frame, display: true)
        }
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        if restoreAccessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
