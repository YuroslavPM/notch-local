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
        return CGRect(
            x: f.midX - size.width / 2,
            y: f.maxY - size.height,
            width: size.width,
            height: size.height
        )
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
            return NotchGeometry(
                screen: screen,
                notchSize: CGSize(width: width, height: screen.safeAreaInsets.top),
                hasNotch: true
            )
        }
        return NotchGeometry(
            screen: screen,
            notchSize: CGSize(width: 200, height: 24),
            hasNotch: false
        )
    }
}
