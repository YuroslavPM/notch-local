# 06 - Calendar peek

## Goal

Below the music controls, show up to 4 upcoming events (now until the end of tomorrow) from every calendar configured in Calendar.app, including Google accounts.

## Files created / changed

- `Sources/NotchLocal/Calendar/CalendarController.swift`
- `Sources/NotchLocal/Calendar/CalendarPeekView.swift`
- `Sources/NotchLocal/Notch/NotchRootView.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`

## Steps

1. **CalendarController** (`@MainActor @Observable`):
   ```swift
   import EventKit

   @MainActor
   @Observable
   final class CalendarController {
       enum Access { case unknown, granted, denied }

       private(set) var access: Access = .unknown
       private(set) var events: [EKEvent] = []
       private let store = EKEventStore()

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
           if access == .granted { reload() }
       }

       func reload() {
           let now = Date()
           let cal = Calendar.current
           guard let end = cal.date(byAdding: .day, value: 2, to: cal.startOfDay(for: now)) else { return }
           let predicate = store.predicateForEvents(withStart: now, end: end, calendars: nil)
           events = store.events(matching: predicate)
               .filter { !$0.isAllDay }
               .sorted { $0.startDate < $1.startDate }
               .prefix(4)
               .map { $0 }
       }
   }
   ```

2. **Refresh triggers.**
   - Call `requestAccessIfNeeded()` the first time the panel expands, not on launch, so the prompt appears when it makes sense.
   - Observe `.EKEventStoreChanged` and call `reload()`.
   - Reload every 60 s while the app runs (cheap, local query).

3. **Relative time formatting.**
   - Ongoing (`startDate <= now < endDate`): green "Now" badge.
   - Under 60 min: "in 25 min".
   - Today: "14:30".
   - Tomorrow: "Tomorrow 10:00".
   - Use `Date.FormatStyle` / `RelativeDateTimeFormatter`; respect the 24-hour setting via the user locale.

4. **CalendarPeekView.**
   - Section header "Up next" in `.caption`, secondary.
   - Rows: 8 pt circle in `Color(nsColor: event.calendar.color)`, title (1 line), time on the right.
   - `granted` with no events: "No more events today".
   - `denied`: "Calendar access is off" plus a button that opens `x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars` with `NSWorkspace.shared.open`.

5. **Layout in NotchRootView.** Use a horizontal split: music on the left (about 55%), calendar on the right, separated by a thin divider. `NotchGeometry.expandedSize` is `520 × 220` so four event rows fit under the camera inset.

6. Run `make run`, verify, commit: `step 06: calendar peek`.

## Key code notes

- macOS 14+ uses `requestFullAccessToEvents()` and needs `NSCalendarsFullAccessUsageDescription` in Info.plist (added in step 02).
- `EKEvent` is not `Sendable`. Keep the store and events on the main actor. The query is fast enough for 2 days of events.

## Done when

- First expand triggers the Calendar permission prompt.
- After granting, upcoming events appear with correct colors and times.
- Creating an event in Calendar.app updates the panel within a few seconds.
- Denying shows the "access is off" message and the button opens the right settings pane.

## Pitfalls

- If the prompt never appears, the app is probably not running from the `.app` bundle, or Info.plist is missing the usage key.
- To re-test the prompt: `tccutil reset Calendar com.yuroslav.notchlocal`.
- All-day events are filtered out to keep the peek compact. Change this in `reload()` if you want them.
