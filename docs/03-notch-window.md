# 03 - Notch window

## Goal

A transparent, always-on-top panel pinned to the top center of the screen that draws a black shape exactly over the hardware notch, on every Space and above fullscreen apps.

## Files created / changed

- `Sources/NotchLocal/Notch/ScreenGeometry.swift`
- `Sources/NotchLocal/Notch/NotchPanel.swift`
- `Sources/NotchLocal/Notch/NotchShape.swift`
- `Sources/NotchLocal/Notch/NotchRootView.swift` (static placeholder for now)
- `Sources/NotchLocal/App/AppDelegate.swift`

## Steps

1. **ScreenGeometry.** Find the notch and compute two rects in global screen coordinates (AppKit origin is bottom-left):
   ```swift
   import AppKit

   struct NotchGeometry {
       let screen: NSScreen
       let notchSize: CGSize
       let hasNotch: Bool

       static let expandedSize = CGSize(width: 520, height: 220)

       var collapsedRect: CGRect { rect(for: notchSize) }
       var expandedRect: CGRect { rect(for: Self.expandedSize) }

       private func rect(for size: CGSize) -> CGRect {
           let f = screen.frame
           return CGRect(x: f.midX - size.width / 2,
                         y: f.maxY - size.height,
                         width: size.width,
                         height: size.height)
       }
   }

   enum ScreenGeometry {
       static func current() -> NotchGeometry? {
           let notched = NSScreen.screens.first { $0.safeAreaInsets.top > 0 }
           guard let screen = notched ?? NSScreen.main else { return nil }

           if let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea,
              screen.safeAreaInsets.top > 0 {
               let width = screen.frame.width - left.width - right.width
               return NotchGeometry(screen: screen,
                                    notchSize: CGSize(width: width, height: screen.safeAreaInsets.top),
                                    hasNotch: true)
           }
           return NotchGeometry(screen: screen,
                                notchSize: CGSize(width: 200, height: 24),
                                hasNotch: false)
       }
   }
   ```

2. **NotchPanel.** A borderless, non-activating panel:
   ```swift
   import AppKit

   final class NotchPanel: NSPanel {
       init(contentRect: CGRect) {
           super.init(contentRect: contentRect,
                      styleMask: [.borderless, .nonactivatingPanel],
                      backing: .buffered,
                      defer: false)
           level = .statusBar
           collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
           isOpaque = false
           backgroundColor = .clear
           hasShadow = false
           isMovable = false
           isReleasedWhenClosed = false
           hidesOnDeactivate = false
       }

       override var canBecomeKey: Bool { true }
       override var canBecomeMain: Bool { false }
   }
   ```

3. **NotchShape.** A `Shape` with a flat top and rounded bottom corners (radius about 10 collapsed, 24 expanded) so it blends into the hardware notch. Make `cornerRadius` animatable via `animatableData`.

4. **NotchRootView (placeholder).** Top-aligned `ZStack` that draws `NotchShape().fill(.black)` at the collapsed notch size inside a frame of the expanded size. Everything else is transparent:
   ```swift
   struct NotchRootView: View {
       let geometry: NotchGeometry

       var body: some View {
           VStack(spacing: 0) {
               NotchShape(cornerRadius: 10)
                   .fill(.black)
                   .frame(width: geometry.notchSize.width, height: geometry.notchSize.height)
               Spacer(minLength: 0)
           }
           .frame(width: NotchGeometry.expandedSize.width,
                  height: NotchGeometry.expandedSize.height)
       }
   }
   ```

5. **Wire it up in AppDelegate.**
   - Keep `panel: NotchPanel?` as a property.
   - In `applicationDidFinishLaunching`: get `ScreenGeometry.current()`, create the panel with `expandedRect`, set `contentView = NSHostingView(rootView: NotchRootView(geometry:))`, then `orderFrontRegardless()`.
   - Set `panel.ignoresMouseEvents = true` for now so it never blocks clicks.
   - Observe `NSApplication.didChangeScreenParametersNotification` and re-run layout (`setFrame(geometry.expandedRect, display: true)` and rebuild the root view).

6. Run `make run`, verify, then commit: `step 03: notch-aligned panel`.

## Key code notes

- `.statusBar` level sits above normal windows and the menu bar. If fullscreen apps cover it, try `NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 3)`.
- `.fullScreenAuxiliary` lets the panel appear over fullscreen spaces. `.canJoinAllSpaces` keeps it on every desktop.
- `NSHostingView` should have a clear background. If you see a gray box, set `hostingView.wantsLayer = true` and `hostingView.layer?.backgroundColor = .clear`.

## Done when

- A black shape sits exactly on the notch. It is the same width and the edges are invisible or nearly invisible.
- Switching Spaces and entering fullscreen (Safari video) keeps it in place.
- Nothing else of the panel is visible, and clicking menu bar items next to the notch still works.
- On an external display without a notch, a 200 x 24 black handle appears at top center of the chosen screen.

## Pitfalls

- AppKit Y grows upward. The top of the screen is `frame.maxY`, not `0`.
- `NSScreen.main` is the screen with the key window, not always the built-in one. That is why we prefer the screen with `safeAreaInsets.top > 0`.
- Do not use `visibleFrame` for the notch. It excludes the menu bar.
