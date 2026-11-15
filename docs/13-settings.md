# 13 - Launch at login and settings

## Goal

A Settings window from the menu bar: launch at login, hover delay, and toggles for music, calendar, file tray, clipboard, status, and the volume HUD. Choices persist across launches.

## Files created / changed

- `Sources/NotchLocal/Settings/SettingsStore.swift`
- `Sources/NotchLocal/Settings/SettingsView.swift`
- `Sources/NotchLocal/Settings/SettingsWindowController.swift`
- `Sources/NotchLocal/App/NotchLocalApp.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`
- `Sources/NotchLocal/Notch/MouseMonitor.swift`
- `Sources/NotchLocal/Notch/NotchRootView.swift`

## Steps

1. **SettingsStore** (`@Observable`, `@MainActor`). UserDefaults keys under `notchlocal.`. Properties: `launchAtLogin`, `hoverDelayMs` (0…400), `showMusic`, `showCalendar`, `showTray`, `showClipboard`, `showStatus`, `showHUD`. Default all widgets on, delay 0.

2. **Launch at login.** `ServiceManagement` `SMAppService.mainApp.register()` / `unregister()`. Read `SMAppService.mainApp.status == .enabled` on launch. The binary must be the `.app` from `make run`, not `swift run`.

3. **Settings window.** Dedicated `NSPanel` / `NSWindow`, not a sheet on the notch (the notch is status-bar level). Switch to `.regular` while it is open, `NSApp.activate()`, restore `.accessory` on close. Center on `visibleFrame`.

4. **Menu.** Menu bar: Settings…, Restart, Quit.

5. **Hover delay.** `MouseMonitor` waits `hoverDelayMs` before `expand()` when entering the collapsed notch. Cancel the wait if the pointer leaves.

6. **Widget toggles.** `NotchRootView` hides music, calendar, tray, clipboard, and status when their flags are off.

## Done when

- Settings… opens a window in front of the desktop, not under the notch.
- Launch at login survives Restart (`SMAppService.mainApp.status`).
- Hover delay is noticeable at 300 ms.
- Turning off File tray hides the shelf; turning it on brings it back.
- Quit still leaves no process.

## Pitfalls

- Accessory apps do not show Settings as a `Settings` scene reliably. Own the window.
- `SMAppService` only works for a copied `.app`, not the SPM `.build` binary.
- Do not use `@AppStorage` macros if the CLT SwiftPM plugin set is incomplete; write UserDefaults in the store.
