import AppKit

@MainActor
final class MouseMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var workspaceObservers: [NSObjectProtocol] = []
    private let viewModel: NotchViewModel
    private let tray: FileTrayController
    private let settings: SettingsStore
    var onRevealPlayer: (() -> Void)?
    private var draggedURLs: [URL] = []
    private var dropGestureActive = false
    private var inboundDrop = false
    private var expandTask: Task<Void, Never>?
    private var pressOrigin: CGPoint?
    private let dragSlop: CGFloat = 8

    init(viewModel: NotchViewModel, tray: FileTrayController, settings: SettingsStore) {
        self.viewModel = viewModel
        self.tray = tray
        self.settings = settings
    }

    func start() {
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .leftMouseDragged, .leftMouseUp]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handle(NSEvent.mouseLocation, type: event.type)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(NSEvent.mouseLocation, type: event.type)
            return event
        }
        observeWorkspace()
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        let center = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers {
            center.removeObserver(observer)
        }
        workspaceObservers.removeAll()
        expandTask?.cancel()
        expandTask = nil
    }

    private func handle(_ point: CGPoint, type: NSEvent.EventType) {
        if tray.isPickingFiles { return }
        if systemOverviewActive {
            cancelScheduledExpand()
            if !viewModel.isFileDragActive {
                viewModel.collapseNow()
            }
            pressOrigin = nil
            return
        }

        switch type {
        case .leftMouseDown:
            pressOrigin = point
            cancelScheduledExpand()
        case .leftMouseDragged:
            trackFileDrag(at: point)
        case .leftMouseUp:
            let origin = pressOrigin
            pressOrigin = nil
            let wasFileDrag = viewModel.isFileDragActive
            finishFileDrag(at: point)
            if !wasFileDrag, let origin, distance(origin, point) < dragSlop {
                click(at: point)
            }
        case .mouseMoved:
            guard NSEvent.pressedMouseButtons == 0 else { return }
            hover(at: point)
        default:
            break
        }
    }

    private func hover(at point: CGPoint) {
        let g = viewModel.geometry
        switch viewModel.state {
        case .collapsed, .peek:
            if g.hoverRect.contains(point) {
                scheduleExpand()
            } else {
                cancelScheduledExpand()
            }
        case .expanded:
            if viewModel.isFileDragActive || tray.isPickingFiles || g.expandedRect.contains(point) {
                viewModel.cancelCollapse()
            } else {
                viewModel.scheduleCollapse()
            }
        }
    }

    private func click(at point: CGPoint) {
        let g = viewModel.geometry
        switch viewModel.state {
        case .collapsed:
            if g.hoverRect.contains(point) {
                viewModel.expand()
            }
        case .peek:
            if g.peekRect.contains(point) || g.hoverRect.contains(point) {
                if case .music = viewModel.currentPeek {
                    onRevealPlayer?()
                } else {
                    viewModel.expand()
                }
            }
        case .expanded:
            break
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

    private func trackFileDrag(at point: CGPoint) {
        guard FileDragPasteboard.isDraggingFiles else { return }
        let g = viewModel.geometry
        let origin = pressOrigin ?? point

        if !dropGestureActive {
            dropGestureActive = true
            inboundDrop = !g.expandedRect.contains(origin)
        }
        guard inboundDrop, distance(origin, point) >= dragSlop else { return }

        let urls = FileDragPasteboard.fileURLs(from: NSPasteboard(name: .drag))
        if !urls.isEmpty {
            draggedURLs = urls
        }

        let overMagnet = g.dropMagnetRect.contains(point)
        let overExpanded = viewModel.state == .expanded && g.expandedRect.contains(point)
        if overMagnet || overExpanded {
            cancelScheduledExpand()
            viewModel.beginFileDrag()
            tray.setTargeted(true)
        } else if viewModel.isFileDragActive {
            tray.setTargeted(false)
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

    private func observeWorkspace() {
        let center = NSWorkspace.shared.notificationCenter
        let activated = center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.suppressForSystemOverview()
            }
        }
        let space = center.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.cancelScheduledExpand()
                if !self.viewModel.isFileDragActive {
                    self.viewModel.collapseNow()
                }
            }
        }
        workspaceObservers = [activated, space]
    }

    private func suppressForSystemOverview() {
        guard systemOverviewActive else { return }
        cancelScheduledExpand()
        if !viewModel.isFileDragActive {
            viewModel.collapseNow()
        }
    }

    private var systemOverviewActive: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.dock"
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}
