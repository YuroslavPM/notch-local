import Foundation
import Intents
import Observation

@MainActor
@Observable
final class FocusMonitor {
    private(set) var isFocused = false
    private(set) var isAuthorized = false

    private var pollTask: Task<Void, Never>?

    func start() {
        guard pollTask == nil else { return }
        requestAccess()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func shutdown() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func requestAccess() {
        INFocusStatusCenter.default.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.isAuthorized = status == .authorized
                self?.refresh()
            }
        }
    }

    private func refresh() {
        let center = INFocusStatusCenter.default
        isAuthorized = center.authorizationStatus == .authorized
        guard isAuthorized else {
            isFocused = false
            return
        }
        isFocused = center.focusStatus.isFocused ?? false
    }
}
