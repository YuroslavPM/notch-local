# 09 - Roadmap (after MVP)

Each item should get its own `docs/NN-*.md` guide in the same format (Goal, Files, Steps, Done when, Pitfalls) before implementing.

## 10 - File tray

- Drop zone in the expanded panel. Dragging files toward the notch auto-expands it (`NSDraggingDestination` on the hosting view; also expand on `.leftMouseDragged` near the notch).
- Store file bookmarks (security-scoped not needed outside the sandbox) in `~/Library/Application Support/NotchLocal/tray.json`.
- Drag items back out with `NSItemProvider` / `onDrag`. Remove from the tray on right-click.
- AirDrop via `NSSharingService(named: .sendViaAirDrop)`.

## 11 - Generic Now Playing

See [11-generic-now-playing.md](11-generic-now-playing.md). Uses `media-control` (BSD-3-Clause) for any Now Playing source; AppleScript remains the fallback.

## 12 - Live activity sneak peeks

See [12-live-activities.md](12-live-activities.md). Collapsed peeks for track changes, meetings within 5 minutes, and battery.

## 13 - Launch at login and settings

- `SMAppService.mainApp.register()` for launch at login.
- Settings window: expanded size, hover delay, which widgets to show, preferred music source.
- Persist with `@AppStorage`.

## 14 - Volume and brightness HUD

- Replace the system HUD with one that grows out of the notch.
- Needs Accessibility permission and media key interception (`CGEventTap`). This is the most fragile feature; do it last.

## 15 - Distribution polish

- App icon (`AppIcon.icns` in `Contents/Resources`, `CFBundleIconFile` in Info.plist).
- Optional: free Apple developer certificate signing so permissions survive rebuilds.
