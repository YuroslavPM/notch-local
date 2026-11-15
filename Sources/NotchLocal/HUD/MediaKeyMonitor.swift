import AppKit

@MainActor
final class MediaKeyMonitor {
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private let settings: SettingsStore
    private let viewModel: NotchViewModel

    init(settings: SettingsStore, viewModel: NotchViewModel) {
        self.settings = settings
        self.viewModel = viewModel
    }

    func start() {
        let mask: NSEvent.EventTypeMask = .systemDefined
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handle(event)
            }
        }
    }

    func stop() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        localMonitor = nil
        globalMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        guard settings.showHUD else { return }
        guard event.subtype.rawValue == 8 else { return }
        let keyCode = Int32((event.data1 & 0xFFFF0000) >> 16)
        let keyFlags = event.data1 & 0x0000FFFF
        let isKeyDown = ((keyFlags & 0xFF00) >> 8) == 0x0A
        guard isKeyDown else { return }

        switch keyCode {
        case 0, 1, 7:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                let percent = Int(((VolumeService.outputVolume() ?? 0) * 100).rounded())
                self.viewModel.showPeek(
                    .volume(percent: percent, muted: VolumeService.isMuted()),
                    durationMs: 1600
                )
            }
        case 2, 3:
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                let percent = Int(((BrightnessService.level() ?? 0) * 100).rounded())
                self.viewModel.showPeek(.brightness(percent: percent), durationMs: 1600)
            }
        default:
            break
        }
    }
}
