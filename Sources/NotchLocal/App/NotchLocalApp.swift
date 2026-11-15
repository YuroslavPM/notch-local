import AppKit
import SwiftUI

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
