import EventKit
import Foundation
import Observation

@MainActor
@Observable
final class LiveActivityController {
    private var viewModel: NotchViewModel?
    private var calendar: CalendarController?
    private var battery: BatteryMonitor?
    private var pollTask: Task<Void, Never>?
    private var lastMusicKey: String?
    private var announcedMeetings: Set<String> = []
    private var wasCharging: Bool?
    private var announcedLowBattery = false

    func attach(viewModel: NotchViewModel, calendar: CalendarController, battery: BatteryMonitor) {
        self.viewModel = viewModel
        self.calendar = calendar
        self.battery = battery
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
        battery?.refresh()
        guard let percent = battery?.percent else { return }
        let charging = battery?.isCharging ?? false
        if wasCharging == false && charging {
            viewModel?.showPeek(.battery(percent: percent, charging: true))
        }
        if percent <= 20 && !charging {
            if !announcedLowBattery {
                announcedLowBattery = true
                viewModel?.showPeek(.battery(percent: percent, charging: false))
            }
        } else if percent > 25 {
            announcedLowBattery = false
        }
        wasCharging = charging
    }
}
