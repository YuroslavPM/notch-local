import AppKit
import Observation

@MainActor
@Observable
final class NotchViewModel {
    enum State {
        case collapsed
        case peek
        case expanded
    }

    private(set) var state: State = .collapsed
    private(set) var currentPeek: LivePeek?
    private(set) var isFileDragActive = false
    var geometry: NotchGeometry
    var onStateChange: ((State) -> Void)?

    private var collapseTask: Task<Void, Never>?
    private var peekTask: Task<Void, Never>?

    init(geometry: NotchGeometry) {
        self.geometry = geometry
    }

    func expand() {
        cancelCollapse()
        cancelPeek()
        guard state != .expanded else { return }
        currentPeek = nil
        state = .expanded
        onStateChange?(state)
    }

    func showPeek(_ peek: LivePeek) {
        guard state != .expanded else { return }
        currentPeek = peek
        state = .peek
        onStateChange?(state)
        schedulePeekDismiss()
    }

    func beginFileDrag() {
        isFileDragActive = true
        expand()
    }

    func endFileDrag() {
        isFileDragActive = false
    }

    func collapseNow() {
        cancelCollapse()
        cancelPeek()
        isFileDragActive = false
        currentPeek = nil
        guard state != .collapsed else {
            onStateChange?(.collapsed)
            return
        }
        state = .collapsed
        onStateChange?(.collapsed)
    }

    func scheduleCollapse() {
        guard state == .expanded, collapseTask == nil, !isFileDragActive else { return }
        collapseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }
            self.state = .collapsed
            self.currentPeek = nil
            self.collapseTask = nil
            self.onStateChange?(.collapsed)
        }
    }

    func cancelCollapse() {
        collapseTask?.cancel()
        collapseTask = nil
    }

    private func schedulePeekDismiss() {
        peekTask?.cancel()
        peekTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(3500))
            guard !Task.isCancelled, let self, self.state == .peek else { return }
            self.state = .collapsed
            self.currentPeek = nil
            self.peekTask = nil
            self.onStateChange?(.collapsed)
        }
    }

    private func cancelPeek() {
        peekTask?.cancel()
        peekTask = nil
    }
}
