# 02 - Project scaffold

## Goal

A buildable SwiftPM app that `make run` launches as a signed `.app` with no Dock icon.

## Files created / changed

- `Package.swift`
- `Resources/Info.plist`
- `scripts/build-app.sh`
- `Makefile`
- `.gitignore`
- `Sources/NotchLocal/App/NotchLocalApp.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`

## Steps

1. Create `Package.swift`:
   ```swift
   // swift-tools-version: 6.0
   import PackageDescription

   let package = Package(
       name: "NotchLocal",
       platforms: [.macOS(.v14)],
       targets: [
           .executableTarget(
               name: "NotchLocal",
               path: "Sources/NotchLocal"
           )
       ]
   )
   ```

2. Create `Resources/Info.plist`:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>CFBundleIdentifier</key><string>com.yuroslav.notchlocal</string>
       <key>CFBundleName</key><string>NotchLocal</string>
       <key>CFBundleExecutable</key><string>NotchLocal</string>
       <key>CFBundlePackageType</key><string>APPL</string>
       <key>CFBundleShortVersionString</key><string>0.1.0</string>
       <key>CFBundleVersion</key><string>1</string>
       <key>LSMinimumSystemVersion</key><string>14.0</string>
       <key>LSUIElement</key><true/>
       <key>NSHighResolutionCapable</key><true/>
       <key>NSCalendarsFullAccessUsageDescription</key>
       <string>NotchLocal shows your upcoming events in the notch.</string>
       <key>NSAppleEventsUsageDescription</key>
       <string>NotchLocal reads and controls playback in Spotify and Music.</string>
   </dict>
   </plist>
   ```

3. Create `scripts/build-app.sh` and `chmod +x` it:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   cd "$(dirname "$0")/.."

   swift build -c release
   BIN="$(swift build -c release --show-bin-path)/NotchLocal"
   APP="build/NotchLocal.app"

   rm -rf "$APP"
   mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
   cp "$BIN" "$APP/Contents/MacOS/NotchLocal"
   cp Resources/Info.plist "$APP/Contents/Info.plist"

   codesign --force --deep --sign - "$APP"
   echo "Built $APP"
   ```

4. Create `Makefile` (recipe lines must start with a tab):
   ```make
   .PHONY: build app run clean

   build:
   	swift build

   app:
   	./scripts/build-app.sh

   run: app
   	-pkill -x NotchLocal
   	open build/NotchLocal.app

   clean:
   	rm -rf .build build
   ```

5. Create `.gitignore`:
   ```
   .build/
   build/
   .swiftpm/
   .DS_Store
   *.xcodeproj/
   xcuserdata/
   ```

6. `Sources/NotchLocal/App/NotchLocalApp.swift`:
   ```swift
   import SwiftUI

   @main
   struct NotchLocalApp: App {
       @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

       var body: some Scene {
           Settings { EmptyView() }
       }
   }
   ```

7. `Sources/NotchLocal/App/AppDelegate.swift`:
   ```swift
   import AppKit

   @MainActor
   final class AppDelegate: NSObject, NSApplicationDelegate {
       func applicationDidFinishLaunching(_ notification: Notification) {
           NSApp.setActivationPolicy(.accessory)
       }
   }
   ```

8. Run `make run` and commit: `step 02: SwiftPM scaffold and app bundling`.

## Key code notes

- `LSUIElement` plus `.accessory` keeps the app out of the Dock and Cmd+Tab.
- The `Settings` scene exists only because a SwiftUI `App` needs at least one scene. The menu bar UI arrives in step 07.

## Done when

- `make run` finishes without errors and prints `Built build/NotchLocal.app`.
- `pgrep -x NotchLocal` shows a running process.
- No Dock icon appears.
- `codesign -dv build/NotchLocal.app` shows `Signature=adhoc`.

## Pitfalls

- With no visible UI yet, the only way to quit is `pkill -x NotchLocal`. That is expected until step 07.
- Ad-hoc signatures change on every build. macOS may ask for Calendar / Automation permissions again after a rebuild. That is normal for local development.
- If `make` says "missing separator", the Makefile has spaces instead of tabs.
