import SwiftUI

struct StatusBarView: View {
    var battery: BatteryMonitor
    var focus: FocusMonitor

    var body: some View {
        HStack(spacing: 10) {
            if focus.isAuthorized, focus.isFocused {
                Label("Focus", systemImage: "moon.fill")
                    .font(.caption.weight(.medium))
            }
            if let percent = battery.percent {
                Label(
                    "\(percent)%",
                    systemImage: battery.isCharging ? "battery.100.bolt" : batterySymbol(percent)
                )
                .font(.caption.weight(.medium))
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.85))
        .labelStyle(.titleAndIcon)
    }

    private func batterySymbol(_ percent: Int) -> String {
        switch percent {
        case 0..<15: "battery.0"
        case 15..<40: "battery.25"
        case 40..<70: "battery.50"
        case 70..<90: "battery.75"
        default: "battery.100"
        }
    }
}
