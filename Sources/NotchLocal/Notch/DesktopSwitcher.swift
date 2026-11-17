import AppKit

@MainActor
enum DesktopSwitcher {
    private static var cached = false
    private static var cachedAt = Date.distantPast

    static func isActive() -> Bool {
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.dock" {
            return true
        }
        let now = Date()
        if now.timeIntervalSince(cachedAt) < 0.3 {
            return cached
        }
        cachedAt = now
        cached = missionControlVisible()
        return cached
    }

    private static func missionControlVisible() -> Bool {
        guard let infos = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for info in infos {
            let owner = info[kCGWindowOwnerName as String] as? String ?? ""
            guard owner == "Dock" else { continue }
            let name = info[kCGWindowName as String] as? String ?? ""
            if name == "Mission Control" || name.hasPrefix("Desktop") {
                return true
            }
        }
        return false
    }
}
