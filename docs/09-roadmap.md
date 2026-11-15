# 09 - Roadmap (after MVP)

Each item should get its own `docs/NN-*.md` guide in the same format (Goal, Files, Steps, Done when, Pitfalls) before implementing.

## 10 - File tray

- Drop zone in the expanded panel. Dragging files toward the notch auto-expands it (`NSDraggingDestination` on the hosting view; also expand on `.leftMouseDragged` near the notch).
- Store file bookmarks (security-scoped not needed outside the sandbox) in `~/Library/Application Support/NotchLocal/tray.json`.
- Drag items back out with `NSItemProvider` / `onDrag`. Remove from the tray on right-click.
- AirDrop via `NSSharingService(named: .sendViaAirDrop)`.

## 11 - Generic Now Playing

- Support browsers, YouTube, Podcasts and others through [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter), which works around the macOS 15.4+ MediaRemote restriction. Check its license before bundling.
- Keep the AppleScript path as a fallback.

## 12 - Live activity sneak peeks

- While collapsed, briefly widen the notch to show the track title on track change, or a countdown 5 minutes before a meeting.
- Requires a third view model state: `.peek` with its own size and auto-dismiss timer.

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
