import AppKit
import Observation

@MainActor
@Observable
final class NotchViewModel {
    enum State {
        case collapsed
        case expanded
    }

    private(set) var state: State = .collapsed
    var geometry: NotchGeometry
    var onStateChange: ((State) -> Void)?

    private var collapseTask: Task<Void, Never>?

    init(geometry: NotchGeometry) {
        self.geometry = geometry
    }

    func expand() {
        cancelCollapse()
        guard state != .expanded else { return }
        state = .expanded
        onStateChange?(state)
    }

    func scheduleCollapse() {
        guard state == .expanded, collapseTask == nil else { return }
        collapseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self else { return }
            self.state = .collapsed
            self.collapseTask = nil
            self.onStateChange?(.collapsed)
        }
    }

    func cancelCollapse() {
        collapseTask?.cancel()
        collapseTask = nil
    }
}
