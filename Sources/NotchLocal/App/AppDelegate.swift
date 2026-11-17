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
    private var clipboardController: ClipboardController?
    private var batteryMonitor: BatteryMonitor?
    private var focusMonitor: FocusMonitor?
    private var liveActivities: LiveActivityController?
    private var mediaKeyMonitor: MediaKeyMonitor?
    private var settingsWindow: SettingsWindowController?
    private var screenObserver: NSObjectProtocol?
    private let settings = SettingsStore.shared

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

        let clipboard = ClipboardController()
        clipboardController = clipboard
        clipboard.start()

        let battery = BatteryMonitor()
        batteryMonitor = battery
        battery.start()

        let focus = FocusMonitor()
        focusMonitor = focus
        focus.start()

        liveActivities = LiveActivityController()
        music.onNowPlayingChange = { [weak self] playing in
            self?.liveActivities?.handleMusicChange(playing)
        }

        settingsWindow = SettingsWindowController(store: settings)
        layoutPanel()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseMonitor?.stop()
        mediaKeyMonitor?.stop()
        musicController?.shutdown()
        calendarController?.shutdown()
        trayController?.shutdown()
        clipboardController?.shutdown()
        batteryMonitor?.shutdown()
        focusMonitor?.shutdown()
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

    func openSettings() {
        settingsWindow?.show()
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
        let clipboard = resolvedClipboardController()
        let battery = resolvedBatteryMonitor()
        let focus = resolvedFocusMonitor()
        let viewModel = existingViewModel(updating: geometry)
        music.onRevealPlayer = { [weak viewModel] in
            viewModel?.collapseNow()
        }
        let content = makeContentView(
            geometry: geometry,
            viewModel: viewModel,
            music: music,
            calendar: calendar,
            tray: tray,
            clipboard: clipboard,
            battery: battery,
            focus: focus
        )

        if let panel {
            panel.setFrame(geometry.expandedRect, display: true)
            panel.contentView = content
            tray.airDrop.sourceWindow = panel
            bindFilePicker(tray: tray, panel: panel, viewModel: viewModel)
            return
        }

        let panel = NotchPanel(contentRect: geometry.expandedRect)
        panel.contentView = content
        panel.ignoresMouseEvents = true
        self.panel = panel
        tray.airDrop.sourceWindow = panel

        bindFilePicker(tray: tray, panel: panel, viewModel: viewModel)

        liveActivities?.attach(viewModel: viewModel, calendar: calendar, battery: battery)
        liveActivities?.start()

        viewModel.onStateChange = { [weak panel, weak music, weak calendar] state in
            panel?.ignoresMouseEvents = (state != .expanded)
            music?.setActive(state == .expanded)
            if state == .expanded {
                Task { await calendar?.requestAccessIfNeeded() }
            }
        }

        let monitor = MouseMonitor(viewModel: viewModel, tray: tray, settings: settings)
        monitor.onRevealPlayer = { [weak music] in
            music?.revealPlayer()
        }
        mouseMonitor = monitor
        let keys = MediaKeyMonitor(settings: settings, viewModel: viewModel)
        mediaKeyMonitor = keys
        keys.start()
        panel.orderFrontRegardless()
        monitor.start()

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

    private func resolvedClipboardController() -> ClipboardController {
        if let clipboardController { return clipboardController }
        let clipboard = ClipboardController()
        clipboardController = clipboard
        clipboard.start()
        return clipboard
    }

    private func resolvedBatteryMonitor() -> BatteryMonitor {
        if let batteryMonitor { return batteryMonitor }
        let battery = BatteryMonitor()
        batteryMonitor = battery
        battery.start()
        return battery
    }

    private func resolvedFocusMonitor() -> FocusMonitor {
        if let focusMonitor { return focusMonitor }
        let focus = FocusMonitor()
        focusMonitor = focus
        focus.start()
        return focus
    }

    private func bindFilePicker(tray: FileTrayController, panel: NotchPanel, viewModel: NotchViewModel) {
        tray.onPickingFiles = { [weak panel, weak viewModel] picking in
            if picking {
                viewModel?.collapseNow()
                panel?.orderOut(nil)
            } else {
                viewModel?.collapseNow()
                panel?.orderFrontRegardless()
            }
        }
    }

    private func makeContentView(
        geometry: NotchGeometry,
        viewModel: NotchViewModel,
        music: MusicController,
        calendar: CalendarController,
        tray: FileTrayController,
        clipboard: ClipboardController,
        battery: BatteryMonitor,
        focus: FocusMonitor
    ) -> NSView {
        let hostingView = NSHostingView(
            rootView: NotchRootView(
                viewModel: viewModel,
                musicController: music,
                calendarController: calendar,
                trayController: tray,
                clipboardController: clipboard,
                batteryMonitor: battery,
                focusMonitor: focus,
                settings: settings
            )
        )
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let bounds = NSRect(origin: .zero, size: NotchGeometry.expandedSize)
        hostingView.frame = bounds

        let shelfHeight: CGFloat = 140
        let dropView = FileDropView(
            frame: NSRect(x: 0, y: 0, width: bounds.width, height: shelfHeight)
        )
        dropView.controller = tray

        let container = NSView(frame: bounds)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.autoresizingMask = [.width, .height]
        dropView.autoresizingMask = [.width, .maxYMargin]
        container.addSubview(hostingView)
        container.addSubview(dropView)
        return container
    }
}
