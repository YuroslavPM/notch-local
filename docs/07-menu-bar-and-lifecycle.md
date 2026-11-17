# 07 - Menu bar and lifecycle

## Goal

A menu bar icon with Restart and Quit, a single running instance, and a clean shutdown.

## Files created / changed

- `Sources/NotchLocal/App/NotchLocalApp.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`

## Steps

1. **MenuBarExtra.** Replace the placeholder `Settings` scene:
   ```swift
   @main
   struct NotchLocalApp: App {
       @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

       var body: some Scene {
           MenuBarExtra("NotchLocal", systemImage: "rectangle.topthird.inset.filled") {
               Button("Restart") { appDelegate.restart() }
               Divider()
               Button("Quit NotchLocal") { NSApp.terminate(nil) }
                   .keyboardShortcut("q")
           }
       }
   }
   ```

2. **Single instance.** At the start of `applicationDidFinishLaunching`:
   ```swift
   let me = NSRunningApplication.current
   let others = NSRunningApplication
       .runningApplications(withBundleIdentifier: "com.yuroslav.notchlocal")
       .filter { $0.processIdentifier != me.processIdentifier }
   if !others.isEmpty {
       NSApp.terminate(nil)
       return
   }
   ```

3. **Restart.** Relaunch the bundle and quit the current process:
   ```swift
   func restart() {
       let url = Bundle.main.bundleURL
       let config = NSWorkspace.OpenConfiguration()
       config.createsNewApplicationInstance = true
       NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
           Task { @MainActor in NSApp.terminate(nil) }
       }
   }
   ```
   The single-instance guard must not kill the new instance. Delay the guard check slightly (about 0.5 s) or skip it when launched with a `--restarted` argument passed via `config.arguments`.

4. **Clean shutdown.** In `applicationWillTerminate`: `mouseMonitor.stop()`, cancel music polling tasks, remove notification observers, `panel.close()`.

5. Run `make run`, verify, commit: `step 07: menu bar and lifecycle`.

## Done when

- A menu bar icon appears. Quit ends the process (`pgrep -x NotchLocal` returns nothing).
- Restart brings the app back within about 1 s with the panel in place.
- Running `open build/NotchLocal.app` twice leaves only one process.
- Still no Dock icon.

## Pitfalls

- Restart combined with the single-instance check is the classic loop or self-kill bug. Test it explicitly.
- If the menu bar is crowded, turn off **Show menu bar icon** in Settings. Open Settings again from the gear in the expanded notch.
