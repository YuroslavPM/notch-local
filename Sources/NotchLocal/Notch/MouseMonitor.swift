import AppKit

@MainActor
final class MouseMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private let viewModel: NotchViewModel
    private let tray: FileTrayController
    private let settings: SettingsStore
    private var draggedURLs: [URL] = []
    private var dropGestureActive = false
    private var inboundDrop = false
    private var expandTask: Task<Void, Never>?

    init(viewModel: NotchViewModel, tray: FileTrayController, settings: SettingsStore) {
        self.viewModel = viewModel
        self.tray = tray
        self.settings = settings
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
        expandTask?.cancel()
        expandTask = nil
    }

    private func handle(_ point: CGPoint, type: NSEvent.EventType) {
        if tray.isPickingFiles { return }

        let g = viewModel.geometry

        if type == .leftMouseDragged {
            trackInboundDrop(at: point)
            if inboundDrop, g.dropMagnetRect.contains(point) {
                cancelScheduledExpand()
                viewModel.beginFileDrag()
                tray.setTargeted(true)
                return
            }
            if inboundDrop {
                tray.setTargeted(g.expandedRect.contains(point) || g.dropMagnetRect.contains(point))
            }
        } else if type == .leftMouseUp {
            finishFileDrag(at: point)
        } else if viewModel.isFileDragActive {
            tray.setTargeted(g.expandedRect.contains(point) || g.dropMagnetRect.contains(point))
        }

        switch viewModel.state {
        case .collapsed:
            if g.collapsedRect.insetBy(dx: -8, dy: -4).contains(point) {
                scheduleExpand()
            } else {
                cancelScheduledExpand()
            }
        case .peek:
            if g.peekRect.insetBy(dx: -8, dy: -4).contains(point) {
                cancelScheduledExpand()
                viewModel.expand()
            }
        case .expanded:
            if viewModel.isFileDragActive || tray.isPickingFiles {
                viewModel.cancelCollapse()
            } else if g.expandedRect.contains(point) {
                viewModel.cancelCollapse()
            } else {
                viewModel.scheduleCollapse()
            }
        }
    }

    private func scheduleExpand() {
        let delay = Int(settings.hoverDelayMs)
        if delay <= 0 {
            expandTask?.cancel()
            expandTask = nil
            viewModel.expand()
            return
        }
        guard expandTask == nil else { return }
        expandTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(delay))
            guard !Task.isCancelled, let self else { return }
            self.viewModel.expand()
            self.expandTask = nil
        }
    }

    private func cancelScheduledExpand() {
        expandTask?.cancel()
        expandTask = nil
    }

    private func trackInboundDrop(at point: CGPoint) {
        guard FileDragPasteboard.isDraggingFiles else { return }
        let g = viewModel.geometry

        if !dropGestureActive {
            dropGestureActive = true
            // A click inside the shelf is not a Finder drop. Finder drags start
            // outside the expanded panel; leftover pasteboard files must not count.
            inboundDrop = !g.expandedRect.contains(point)
        }

        guard inboundDrop else { return }
        let urls = FileDragPasteboard.fileURLs(from: NSPasteboard(name: .drag))
        if !urls.isEmpty {
            draggedURLs = urls
        }
    }

    private func finishFileDrag(at point: CGPoint) {
        let g = viewModel.geometry
        let overTray = g.expandedRect.contains(point) || g.dropMagnetRect.contains(point)
        if inboundDrop, viewModel.isFileDragActive, overTray, !draggedURLs.isEmpty {
            tray.add(urls: draggedURLs)
        }
        dropGestureActive = false
        inboundDrop = false
        draggedURLs = []
        tray.setTargeted(false)
        viewModel.endFileDrag()
    }
}
