import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    var hoverDelayMs: Double {
        didSet { defaults.set(hoverDelayMs, forKey: Keys.hoverDelayMs) }
    }

    var showMusic: Bool {
        didSet { defaults.set(showMusic, forKey: Keys.showMusic) }
    }

    var showCalendar: Bool {
        didSet { defaults.set(showCalendar, forKey: Keys.showCalendar) }
    }

    var showTray: Bool {
        didSet { defaults.set(showTray, forKey: Keys.showTray) }
    }

    var showClipboard: Bool {
        didSet { defaults.set(showClipboard, forKey: Keys.showClipboard) }
    }

    var showStatus: Bool {
        didSet { defaults.set(showStatus, forKey: Keys.showStatus) }
    }

    var showHUD: Bool {
        didSet { defaults.set(showHUD, forKey: Keys.showHUD) }
    }

    var showMenuBarIcon: Bool {
        didSet {
            defaults.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon)
            onMenuBarIconChange?()
        }
    }

    var onMenuBarIconChange: (() -> Void)?

    var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin() }
    }

    private var isApplyingLogin = false
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hoverDelayMs = "notchlocal.hoverDelayMs"
        static let showMusic = "notchlocal.showMusic"
        static let showCalendar = "notchlocal.showCalendar"
        static let showTray = "notchlocal.showTray"
        static let showClipboard = "notchlocal.showClipboard"
        static let showStatus = "notchlocal.showStatus"
        static let showHUD = "notchlocal.showHUD"
        static let showMenuBarIcon = "notchlocal.showMenuBarIcon"
    }

    private init() {
        hoverDelayMs = defaults.object(forKey: Keys.hoverDelayMs) as? Double ?? 0
        showMusic = defaults.object(forKey: Keys.showMusic) as? Bool ?? true
        showCalendar = defaults.object(forKey: Keys.showCalendar) as? Bool ?? true
        showTray = defaults.object(forKey: Keys.showTray) as? Bool ?? true
        showClipboard = defaults.object(forKey: Keys.showClipboard) as? Bool ?? true
        showStatus = defaults.object(forKey: Keys.showStatus) as? Bool ?? true
        showHUD = defaults.object(forKey: Keys.showHUD) as? Bool ?? true
        showMenuBarIcon = defaults.object(forKey: Keys.showMenuBarIcon) as? Bool ?? true
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func applyLaunchAtLogin() {
        guard !isApplyingLogin else { return }
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            isApplyingLogin = true
            launchAtLogin = SMAppService.mainApp.status == .enabled
            isApplyingLogin = false
        }
    }
}
