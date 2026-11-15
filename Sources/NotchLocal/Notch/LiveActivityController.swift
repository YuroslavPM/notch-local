import EventKit
import Foundation
import IOKit.ps
import Observation

@MainActor
@Observable
final class LiveActivityController {
    private var viewModel: NotchViewModel?
    private var calendar: CalendarController?
    private var pollTask: Task<Void, Never>?
    private var lastMusicKey: String?
    private var announcedMeetings: Set<String> = []
    private var wasCharging: Bool?
    private var announcedLowBattery = false

    func attach(viewModel: NotchViewModel, calendar: CalendarController) {
        self.viewModel = viewModel
        self.calendar = calendar
    }

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            await self?.calendar?.requestAccessIfNeeded()
            while !Task.isCancelled {
                self?.checkMeetings()
                self?.checkBattery()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    func shutdown() {
        pollTask?.cancel()
        pollTask = nil
    }

    func handleMusicChange(_ playing: NowPlaying?) {
        guard let playing, playing.isPlaying else { return }
        let key = "\(playing.title)|\(playing.artist)"
        let isFirst = lastMusicKey == nil
        if key == lastMusicKey { return }
        lastMusicKey = key
        guard !isFirst else { return }
        viewModel?.showPeek(.music(title: playing.title, artist: playing.artist))
    }

    private func checkMeetings() {
        guard let calendar, calendar.access == .granted else { return }
        let now = Date()
        for event in calendar.events {
            guard let start = event.startDate, start > now else { continue }
            let seconds = start.timeIntervalSince(now)
            guard seconds <= 5 * 60 else { continue }
            let id = event.calendarItemIdentifier
            guard !announcedMeetings.contains(id) else { continue }
            announcedMeetings.insert(id)
            viewModel?.showPeek(.meeting(title: event.title ?? "Event", startsAt: start))
            return
        }
    }

    private func checkBattery() {
        guard let snapshot = Self.readBattery() else { return }
        if wasCharging == false && snapshot.charging {
            viewModel?.showPeek(.battery(percent: snapshot.percent, charging: true))
        }
        if snapshot.percent <= 20 && !snapshot.charging {
            if !announcedLowBattery {
                announcedLowBattery = true
                viewModel?.showPeek(.battery(percent: snapshot.percent, charging: false))
            }
        } else if snapshot.percent > 25 {
            announcedLowBattery = false
        }
        wasCharging = snapshot.charging
    }

    private struct BatterySnapshot {
        var percent: Int
        var charging: Bool
    }

    private static func readBattery() -> BatterySnapshot? {
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
            return BatterySnapshot(percent: percent, charging: charging)
        }
        return nil
    }
}
