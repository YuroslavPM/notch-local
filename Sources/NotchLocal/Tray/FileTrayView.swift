import SwiftUI

struct FileTrayView: View {
    var controller: FileTrayController

    var body: some View {
        Group {
            if controller.items.isEmpty {
                emptyShelf
            } else {
                filledShelf
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(shelfBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 1, dash: controller.items.isEmpty ? [5, 4] : []))
        )
    }

    private var emptyShelf: some View {
        Text("Drop files")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filledShelf: some View {
        HStack(spacing: 8) {
            ForEach(controller.items) { item in
                icon(for: item)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
    }

    private func icon(for item: TrayItem) -> some View {
        let missing = controller.isMissing(item)
        let showAirDrop = controller.hoveredID == item.id && controller.canAirDrop(item)

        return ZStack {
            Image(nsImage: controller.icon(for: item))
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .opacity(missing ? 0.4 : 1)

            if showAirDrop {
                Button {
                    controller.airDrop(item)
                } label: {
                    Image(systemName: "airdrop")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 32, height: 32)
        .help(item.name)
        .onHover { hovering in
            controller.setHovered(hovering ? item.id : nil)
        }
        .onTapGesture {
            controller.open(item)
        }
        .onDrag {
            controller.dragProvider(for: item)
        }
        .contextMenu {
            Button("Open") { controller.open(item) }
                .disabled(missing)
            Button("Reveal in Finder") { controller.reveal(item) }
                .disabled(missing)
            if controller.canAirDrop(item) {
                Button("AirDrop") { controller.airDrop(item) }
            }
            Divider()
            Button("Remove", role: .destructive) {
                controller.remove(id: item.id)
            }
        }
    }

    private var shelfBackground: Color {
        controller.isTargeted ? Color.white.opacity(0.16) : Color.white.opacity(0.06)
    }

    private var borderColor: Color {
        controller.isTargeted ? Color.white.opacity(0.7) : Color.white.opacity(0.22)
    }
}
