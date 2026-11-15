# 15 - Status row and calendar open

## Goal

The expanded panel shows Focus (Do Not Disturb) and battery. Clicking a calendar event opens it in Calendar.

## Files created / changed

- `Sources/NotchLocal/Status/BatteryMonitor.swift`
- `Sources/NotchLocal/Status/FocusMonitor.swift`
- `Sources/NotchLocal/Status/StatusBarView.swift`
- `Sources/NotchLocal/Notch/LiveActivityController.swift`
- `Sources/NotchLocal/Calendar/CalendarController.swift`
- `Sources/NotchLocal/Calendar/CalendarPeekView.swift`
- `Resources/Info.plist`

## Steps

1. **BatteryMonitor.** Move `IOPSCopyPowerSourcesInfo` out of `LiveActivityController`. Publish `percent` and `isCharging`. Live peeks keep using it.

2. **FocusMonitor.** `INFocusStatusCenter.default`. Request authorization. `focusStatus.isFocused`. Poll every few seconds. Info.plist: `NSFocusStatusUsageDescription`.

3. **StatusBarView.** One line: Focus icon + “Focus” when on, battery icon + percent, bolt when charging. Hide when `showStatus` is false.

4. **Open event.** Click a row. Prefer `event.url`. Otherwise `ical://ekevent/` with the start date, or launch Calendar. No force unwraps.

## Done when

- Battery percent in the expanded panel matches System Settings ±1.
- Enabling a Focus mode shows Focus in the notch after authorization.
- Clicking an event opens Calendar (or the event’s URL).
- Low-battery and charging peeks still work.

## Pitfalls

- Focus authorization is a one-time prompt. Denied means hide the Focus chip, still show battery.
- `ical://` URLs are best-effort; never crash if Calendar is missing.
