import AppKit
import SwiftUI

@main
struct NotchLocalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Keeps SwiftUI happy without opening a window. The real menu is the status item.
        MenuBarExtra("NotchLocal", systemImage: "rectangle.topthird.inset.filled", isInserted: .constant(false)) {
            EmptyView()
        }
    }
}
