import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NotchPanel?
    private var viewModel: NotchViewModel?
    private var mouseMonitor: MouseMonitor?
    private var musicController: MusicController?
    private var calendarController: CalendarController?
    private var trayController: FileTrayController?
    private var liveActivities: LiveActivityController?
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

        let tray = FileTrayController()
        trayController = tray
        tray.start()

        liveActivities = LiveActivityController()
        music.onNowPlayingChange = { [weak self] playing in
            self?.liveActivities?.handleMusicChange(playing)
        }

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
        trayController?.shutdown()
        liveActivities?.shutdown()
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
        let tray = resolvedTrayController()
        let viewModel = existingViewModel(updating: geometry)
        let content = makeContentView(
            geometry: geometry,
            viewModel: viewModel,
            music: music,
            calendar: calendar,
            tray: tray
        )

        if let panel {
            panel.setFrame(geometry.expandedRect, display: true)
            panel.contentView = content
            tray.airDrop.sourceWindow = panel
            return
        }

        let panel = NotchPanel(contentRect: geometry.expandedRect)
        panel.contentView = content
        panel.ignoresMouseEvents = true
        self.panel = panel
        tray.airDrop.sourceWindow = panel

        liveActivities?.attach(viewModel: viewModel, calendar: calendar)
        liveActivities?.start()

        viewModel.onStateChange = { [weak panel, weak music, weak calendar] state in
            panel?.ignoresMouseEvents = (state != .expanded)
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

    private func resolvedTrayController() -> FileTrayController {
        if let trayController { return trayController }
        let tray = FileTrayController()
        trayController = tray
        tray.start()
        return tray
    }

    private func makeContentView(
        geometry: NotchGeometry,
        viewModel: NotchViewModel,
        music: MusicController,
        calendar: CalendarController,
        tray: FileTrayController
    ) -> NSView {
        let hostingView = NSHostingView(
            rootView: NotchRootView(
                viewModel: viewModel,
                musicController: music,
                calendarController: calendar,
                trayController: tray
            )
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let bounds = NSRect(origin: .zero, size: NotchGeometry.expandedSize)
        hostingView.frame = bounds

        let dropView = FileDropView(frame: bounds)
        dropView.controller = tray

        let container = NSView(frame: bounds)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.autoresizingMask = [.width, .height]
        dropView.autoresizingMask = [.width, .height]
        container.addSubview(hostingView)
        container.addSubview(dropView)
        return container
    }
}
