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
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .leftMouseUp]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handle(NSEvent.mouseLocation, type: event.type)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(NSEvent.mouseLocation, type: event.type)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ point: CGPoint, type: NSEvent.EventType) {
        if type == .leftMouseUp {
            viewModel.endFileDrag()
        }

        let g = viewModel.geometry
        if FileDragPasteboard.isDraggingFiles, g.dropMagnetRect.contains(point) {
            viewModel.beginFileDrag()
            return
        }

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
            if viewModel.isFileDragActive {
                viewModel.cancelCollapse()
            } else if g.expandedRect.contains(point) {
                viewModel.cancelCollapse()
            } else {
                viewModel.scheduleCollapse()
            }
        }
    }
}
