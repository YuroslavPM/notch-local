import AppKit

@MainActor
final class MouseMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let viewModel: NotchViewModel

    init(viewModel: NotchViewModel) {
        self.viewModel = viewModel
    }

    func start() {
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handle(NSEvent.mouseLocation)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(NSEvent.mouseLocation)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ point: CGPoint) {
        let g = viewModel.geometry
        switch viewModel.state {
        case .collapsed:
            if g.collapsedRect.insetBy(dx: -8, dy: -4).contains(point) {
                viewModel.expand()
            }
        case .peek:
            if g.peekRect.insetBy(dx: -8, dy: -4).contains(point) {
                viewModel.expand()
            }
        case .expanded:
            if g.expandedRect.contains(point) {
                viewModel.cancelCollapse()
            } else {
                viewModel.scheduleCollapse()
            }
        }
    }
}
