import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NotchPanel?
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        layoutPanel()

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.layoutPanel()
            }
        }
    }

    private func layoutPanel() {
        guard let geometry = ScreenGeometry.current() else { return }

        let hostingView = NSHostingView(rootView: NotchRootView(geometry: geometry))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        if let panel {
            panel.setFrame(geometry.expandedRect, display: true)
            panel.contentView = hostingView
            return
        }

        let panel = NotchPanel(contentRect: geometry.expandedRect)
        panel.contentView = hostingView
        panel.ignoresMouseEvents = true
        panel.orderFrontRegardless()
        self.panel = panel
    }
}
