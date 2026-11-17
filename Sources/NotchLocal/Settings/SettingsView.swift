import SwiftUI

struct SettingsView: View {
    var store: SettingsStore

    var body: some View {
        Form {
            Section("General") {
                Toggle("Open at login", isOn: bind(\.launchAtLogin))
                Toggle("Show menu bar icon", isOn: bind(\.showMenuBarIcon))
                HStack {
                    Text("Hover delay")
                    Slider(value: bind(\.hoverDelayMs), in: 0...400, step: 50)
                    Text("\(Int(store.hoverDelayMs)) ms")
                        .foregroundStyle(.secondary)
                        .frame(width: 56, alignment: .trailing)
                }
            }
            Section("Widgets") {
                Toggle("Now Playing", isOn: bind(\.showMusic))
                Toggle("Calendar", isOn: bind(\.showCalendar))
                Toggle("File tray", isOn: bind(\.showTray))
                Toggle("Clipboard", isOn: bind(\.showClipboard))
                Toggle("Focus and battery", isOn: bind(\.showStatus))
                Toggle("Volume and brightness HUD", isOn: bind(\.showHUD))
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 420)
        .padding(8)
    }

    private func bind(_ keyPath: ReferenceWritableKeyPath<SettingsStore, Bool>) -> Binding<Bool> {
        Binding(
            get: { store[keyPath: keyPath] },
            set: { store[keyPath: keyPath] = $0 }
        )
    }

    private func bind(_ keyPath: ReferenceWritableKeyPath<SettingsStore, Double>) -> Binding<Double> {
        Binding(
            get: { store[keyPath: keyPath] },
            set: { store[keyPath: keyPath] = $0 }
        )
    }
}
