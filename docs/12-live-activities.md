# 12 - Live activity sneak peeks

## Goal

While collapsed, the notch briefly widens to show a live peek: a new track title, a meeting starting within 5 minutes, or a battery plug-in / low-battery warning. Hovering the peek still expands the full panel.

## Files created / changed

- `Sources/NotchLocal/Notch/LivePeek.swift`
- `Sources/NotchLocal/Notch/PeekView.swift`
- `Sources/NotchLocal/Notch/LiveActivityController.swift`
- `Sources/NotchLocal/Notch/NotchViewModel.swift`
- `Sources/NotchLocal/Notch/NotchRootView.swift`
- `Sources/NotchLocal/Notch/MouseMonitor.swift`
- `Sources/NotchLocal/Notch/ScreenGeometry.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`

## Steps

1. Add `NotchViewModel.State.peek` and `currentPeek`. `showPeek` is a no-op while expanded. Auto-dismiss after 3.5 s. Expanding cancels the timer.

2. `peekSize` is the notch height and about 320–420 pt wide, centered like the collapsed rect.

3. **LiveActivityController**
   - Music: peek on title/artist change after the first known track (do not flash at launch).
   - Calendar: peek once per event when it starts in the next 5 minutes. Request access at start so peeks work before the first expand.
   - Battery: peek when charging begins, or when capacity drops to 20% or below. Read `IOPSCopyPowerSourcesInfo`.

4. **PeekView.** One line: icon or tiny artwork, then the message. Same NotchShape as collapsed, slightly wider.

5. Mouse: hovering the peek rect expands. `ignoresMouseEvents` stays true while peeked so the rest of the screen stays click-through.

## Done when

- Changing the track widens the notch with the new title, then it shrinks after a few seconds.
- A meeting starting within 5 minutes peeks once.
- Plugging in power or hitting low battery peeks once.
- Hovering a peek opens the full panel. Clicks next to it still reach the app below.

## Pitfalls

- Do not re-announce the same track, event, or low-battery state in a loop.
- Keep peek height equal to the hardware notch so it still covers the camera.
