import AppKit
import EventKit
import Foundation
import Observation

@MainActor
@Observable
final class CalendarController {
    enum Access {
        case unknown
        case granted
        case denied
    }

    private(set) var access: Access = .unknown
    private(set) var events: [EKEvent] = []

    private let store = EKEventStore()
    private var reloadTask: Task<Void, Never>?
    private var eventObserver: NSObjectProtocol?

    func start() {
        guard reloadTask == nil else { return }
        eventObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reload()
            }
        }
        reloadTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                self?.reload()
            }
        }
    }

    func shutdown() {
        reloadTask?.cancel()
        reloadTask = nil
        if let eventObserver {
            NotificationCenter.default.removeObserver(eventObserver)
            self.eventObserver = nil
        }
    }

    func requestAccessIfNeeded() async {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            access = .granted
        case .notDetermined:
            let granted = (try? await store.requestFullAccessToEvents()) ?? false
            access = granted ? .granted : .denied
        default:
            access = .denied
        }
        if access == .granted {
            reload()
        }
    }

    func open(_ event: EKEvent) {
        if let url = event.url, NSWorkspace.shared.open(url) {
            return
        }
        if let start = event.startDate {
            let stamp = Int(start.timeIntervalSinceReferenceDate)
            if let url = URL(string: "ical://ekevent/\(stamp)"), NSWorkspace.shared.open(url) {
                return
            }
        }
        if let url = URL(string: "ical://") {
            NSWorkspace.shared.open(url)
        }
    }

    func reload() {
        guard access == .granted else { return }
        let now = Date()
        let cal = Calendar.current
        guard let end = cal.date(byAdding: .day, value: 2, to: cal.startOfDay(for: now)) else { return }
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        events = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
            .prefix(4)
            .map { $0 }
    }
}
