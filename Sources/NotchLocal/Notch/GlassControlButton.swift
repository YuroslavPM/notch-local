import SwiftUI

struct GlassControlButton: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
        }
    }
}
