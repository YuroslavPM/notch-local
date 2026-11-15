import SwiftUI

struct ClipboardView: View {
    var controller: ClipboardController

    var body: some View {
        HStack(spacing: 8) {
            if controller.items.isEmpty {
                Text("Clipboard")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer(minLength: 0)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(controller.items) { item in
                            cell(item)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func cell(_ item: ClipboardItem) -> some View {
        HStack(spacing: 4) {
            Button {
                controller.restore(item)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: iconName(item))
                        .font(.caption2)
                    Text(item.preview)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08), in: Capsule())
            }
            .buttonStyle(.plain)
            .help(item.preview)

            Button {
                controller.remove(id: item.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
            .help("Remove")
        }
    }

    private func iconName(_ item: ClipboardItem) -> String {
        switch item.kind {
        case .text: "doc.on.clipboard"
        case .files: "doc"
        case .image: "photo"
        }
    }
}
