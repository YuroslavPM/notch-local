import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NotchPanel?
    private var viewModel: NotchViewModel?
    private var mouseMonitor: MouseMonitor?
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

        let viewModel = existingViewModel(updating: geometry)
        let hostingView = NSHostingView(rootView: NotchRootView(viewModel: viewModel))
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
        self.panel = panel

        viewModel.onStateChange = { [weak panel] state in
            panel?.ignoresMouseEvents = (state == .collapsed)
        }

        let monitor = MouseMonitor(viewModel: viewModel)
        mouseMonitor = monitor
        panel.orderFrontRegardless()
        monitor.start()
    }

    private func existingViewModel(updating geometry: NotchGeometry) -> NotchViewModel {
        if let viewModel {
            viewModel.geometry = geometry
            return viewModel
        }
        let viewModel = NotchViewModel(geometry: geometry)
        self.viewModel = viewModel
        return viewModel
    }
}
