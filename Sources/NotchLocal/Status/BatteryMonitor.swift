import Foundation
import IOKit.ps
import Observation

@MainActor
@Observable
final class BatteryMonitor {
    private(set) var percent: Int?
    private(set) var isCharging = false

    private var pollTask: Task<Void, Never>?

    func start() {
        guard pollTask == nil else { return }
        refresh()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    func shutdown() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh() {
        guard let snapshot = Self.read() else {
            percent = nil
            isCharging = false
            return
        }
        percent = snapshot.percent
        isCharging = snapshot.charging
    }

    struct Snapshot {
        var percent: Int
        var charging: Bool
    }

    static func read() -> Snapshot? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }
        for source in list {
            guard let info = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            let type = info[kIOPSTypeKey as String] as? String
            guard type == kIOPSInternalBatteryType as String else { continue }
            let percent = info[kIOPSCurrentCapacityKey as String] as? Int
                ?? Int(info[kIOPSCurrentCapacityKey as String] as? Double ?? 0)
            let charging = info[kIOPSIsChargingKey as String] as? Bool ?? false
            return Snapshot(percent: percent, charging: charging)
        }
        return nil
    }
}
