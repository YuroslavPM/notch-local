import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NotchPanel?
    private var viewModel: NotchViewModel?
    private var mouseMonitor: MouseMonitor?
    private var musicController: MusicController?
    private var calendarController: CalendarController?
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if shouldYieldToExistingInstance() {
            NSApp.terminate(nil)
            return
        }

        let music = MusicController()
        musicController = music
        music.start()

        let calendar = CalendarController()
        calendarController = calendar
        calendar.start()

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

    func applicationWillTerminate(_ notification: Notification) {
        mouseMonitor?.stop()
        musicController?.shutdown()
        calendarController?.shutdown()
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
        panel?.close()
        panel = nil
    }

    func restart() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        config.arguments = ["--restarted"]
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            Task { @MainActor in
                NSApp.terminate(nil)
            }
        }
    }

    private func shouldYieldToExistingInstance() -> Bool {
        if CommandLine.arguments.contains("--restarted") {
            return false
        }
        let me = NSRunningApplication.current
        let others = NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.yuroslav.notchlocal")
            .filter { $0.processIdentifier != me.processIdentifier }
        return !others.isEmpty
    }

    private func layoutPanel() {
        guard let geometry = ScreenGeometry.current() else { return }
        let music = resolvedMusicController()
        let calendar = resolvedCalendarController()
        let viewModel = existingViewModel(updating: geometry)

        let hostingView = NSHostingView(
            rootView: NotchRootView(
                viewModel: viewModel,
                musicController: music,
                calendarController: calendar
            )
        )
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

        viewModel.onStateChange = { [weak panel, weak music, weak calendar] state in
            panel?.ignoresMouseEvents = (state == .collapsed)
            music?.setActive(state == .expanded)
            if state == .expanded {
                Task { await calendar?.requestAccessIfNeeded() }
            }
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

    private func resolvedMusicController() -> MusicController {
        if let musicController { return musicController }
        let music = MusicController()
        musicController = music
        music.start()
        return music
    }

    private func resolvedCalendarController() -> CalendarController {
        if let calendarController { return calendarController }
        let calendar = CalendarController()
        calendarController = calendar
        calendar.start()
        return calendar
    }
}
