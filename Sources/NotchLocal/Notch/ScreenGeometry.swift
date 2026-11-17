import AppKit

struct NotchGeometry {
    let screen: NSScreen
    let notchSize: CGSize
    let hasNotch: Bool

    static let expandedSize = CGSize(width: 520, height: 320)
    static let contentClearance: CGFloat = 6

    var contentTopInset: CGFloat { notchSize.height + Self.contentClearance }

    var peekSize: CGSize {
        CGSize(
            width: min(max(notchSize.width + 200, 320), 420),
            height: notchSize.height
        )
    }

    /// Physical notch, plus a few points so the pointer does not have to sit on the camera.
    var hoverRect: CGRect {
        collapsedRect.insetBy(dx: -6, dy: -4)
    }

    var collapsedRect: CGRect { rect(for: notchSize) }
    var peekRect: CGRect { rect(for: peekSize) }
    var expandedRect: CGRect { rect(for: Self.expandedSize) }

    /// Small band under the camera. File drags open here; the rest of the screen does not.
    var dropMagnetRect: CGRect {
        collapsedRect.insetBy(dx: -16, dy: -28)
    }

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
            let rawWidth = screen.frame.width - left.width - right.width
            let width = min(max(rawWidth, 120), 220)
            let height = min(max(screen.safeAreaInsets.top, 24), 40)
            return NotchGeometry(
                screen: screen,
                notchSize: CGSize(width: width, height: height),
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
