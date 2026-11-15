import AppKit
import EventKit
import SwiftUI

struct CalendarPeekView: View {
    var controller: CalendarController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Up next")
                .font(.caption)
                .foregroundStyle(.secondary)

            switch controller.access {
            case .denied:
                VStack(alignment: .leading, spacing: 6) {
                    Text("Calendar access is off")
                        .font(.subheadline)
                    Button("Open Settings") {
                        openCalendarSettings()
                    }
                    .modifier(GlassControlButton())
                }
            case .granted where controller.events.isEmpty:
                Text("No more events today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .granted:
                ForEach(controller.events, id: \.calendarItemIdentifier) { event in
                    Button {
                        controller.open(event)
                    } label: {
                        eventRow(event)
                    }
                    .buttonStyle(.plain)
                    .help("Open in Calendar")
                }
            case .unknown:
                Text("Expand to load events")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eventRow(_ event: EKEvent) -> some View {
        let now = Date()
        let start = event.startDate ?? now
        let end = event.endDate ?? start
        let ongoing = start <= now && now < end
        let color = event.calendar?.color ?? .systemGray

        return HStack(spacing: 8) {
            Circle()
                .fill(Color(nsColor: color))
                .frame(width: 8, height: 8)
            Text(event.title ?? "Event")
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 4)
            if ongoing {
                Text("Now")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.85))
                    .clipShape(Capsule())
            } else {
                Text(Self.timeLabel(start: start, now: now))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func openCalendarSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private static func timeLabel(start: Date, now: Date) -> String {
        let minutes = Int(start.timeIntervalSince(now) / 60)
        if minutes >= 0 && minutes < 60 {
            return "in \(max(minutes, 1)) min"
        }

        let calendar = Calendar.current
        let time = start.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(start) {
            return time
        }
        if calendar.isDateInTomorrow(start) {
            return "Tomorrow \(time)"
        }
        return start.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}
