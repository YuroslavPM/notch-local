# 04 - Hover expand

## Goal

Hovering the notch expands the panel with a spring animation. Moving the pointer away collapses it after a short delay. While collapsed, clicks pass through to whatever is underneath.

## Files created / changed

- `Sources/NotchLocal/Notch/NotchViewModel.swift`
- `Sources/NotchLocal/Notch/MouseMonitor.swift`
- `Sources/NotchLocal/Notch/NotchRootView.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`

## Steps

1. **NotchViewModel.**
   ```swift
   import Observation
   import AppKit

   @MainActor
   @Observable
   final class NotchViewModel {
       enum State { case collapsed, expanded }

       private(set) var state: State = .collapsed
       var geometry: NotchGeometry
       var onStateChange: ((State) -> Void)?

       private var collapseTask: Task<Void, Never>?

       init(geometry: NotchGeometry) { self.geometry = geometry }

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
   ```

2. **MouseMonitor.** Use both a global monitor (pointer over other apps) and a local monitor (pointer over our own panel, where global events are not delivered):
   ```swift
   import AppKit

   @MainActor
   final class MouseMonitor {
       private var globalMonitor: Any?
       private var localMonitor: Any?
       private let viewModel: NotchViewModel

       init(viewModel: NotchViewModel) { self.viewModel = viewModel }

       func start() {
           let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged]
           globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] _ in
               MainActor.assumeIsolated { self?.handle(NSEvent.mouseLocation) }
           }
           localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
               self?.handle(NSEvent.mouseLocation)
               return event
           }
       }

       func stop() {
           if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
           if let localMonitor { NSEvent.removeMonitor(localMonitor) }
           globalMonitor = nil
           localMonitor = nil
       }

       private func handle(_ point: CGPoint) {
           let g = viewModel.geometry
           switch viewModel.state {
           case .collapsed:
               if g.collapsedRect.insetBy(dx: -8, dy: -4).contains(point) { viewModel.expand() }
           case .expanded:
               if g.expandedRect.contains(point) { viewModel.cancelCollapse() }
               else { viewModel.scheduleCollapse() }
           }
       }
   }
   ```

3. **Click-through toggle in AppDelegate.**
   ```swift
   viewModel.onStateChange = { [weak panel] state in
       panel?.ignoresMouseEvents = (state == .collapsed)
   }
   ```
   Start with `ignoresMouseEvents = true`. Call `mouseMonitor.start()` after the panel is shown.

4. **Animate in NotchRootView.** Pass the view model instead of raw geometry:
   - Shape size: `notchSize` when collapsed, `expandedSize` when expanded.
   - Corner radius: 10 collapsed, 24 expanded.
   - `.animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.state)`.
   - Expanded content area (placeholder `Text("NotchLocal")` for now) uses `.opacity` + `.transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))` and only renders when expanded.
   - Pad expanded content by `notchSize.height` at the top so nothing hides behind the camera.

5. Keep `viewModel.geometry` in sync when screen parameters change (step 03 observer).

6. Run `make run`, verify, commit: `step 04: hover expand and click-through`.

## Key code notes

- Global mouse-moved monitoring does **not** need Accessibility permission. Only key event monitoring does.
- The collapse delay prevents flicker when the pointer briefly leaves the edge.
- The panel frame never changes size. Only the SwiftUI shape animates. That avoids window resize jank.

## Done when

- Hovering the notch opens the panel smoothly within about 100 ms.
- Moving the pointer away closes it after about 300 ms. Coming back inside cancels the close.
- When collapsed, you can click a browser tab or menu bar item directly under the expanded area.
- When expanded, clicking inside the panel does not activate or focus another app.
- CPU stays near 0% in Activity Monitor while idle.

## Pitfalls

- Global monitor handlers can run off the main thread in strict concurrency. Keep `MainActor.assumeIsolated` (they are delivered on the main thread) or hop with `Task { @MainActor in ... }`.
- If hover never triggers in fullscreen apps, confirm `.fullScreenAuxiliary` is set and the panel level is high enough.
- Remember to call `stop()` on quit (step 07).
