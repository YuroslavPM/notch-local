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
        VStack(spacing: 2) {
            Text("Drop files")
                .font(.caption.weight(.medium))
            Text("or click to browse")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .foregroundStyle(.white.opacity(0.85))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: controller.chooseFiles)
    }

    private var filledShelf: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(controller.items) { item in
                        fileCell(item)
                    }
                }
                .padding(.vertical, 4)
            }
            addMoreButton
            sendAllButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var addMoreButton: some View {
        Button(action: controller.chooseFiles) {
            VStack(spacing: 3) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                Text("Add")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(.white.opacity(0.85))
            .frame(width: 52, height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Choose more files")
    }

    private func fileCell(_ item: TrayItem) -> some View {
        let missing = controller.isMissing(item)

        return VStack(spacing: 3) {
            ZStack(alignment: .topTrailing) {
                Button {
                    controller.open(item)
                } label: {
                    Image(nsImage: controller.icon(for: item))
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                        .opacity(missing ? 0.4 : 1)
                        .frame(width: 36, height: 32)
                }
                .buttonStyle(.plain)
                .disabled(missing)

                Button {
                    controller.remove(id: item.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.black.opacity(0.72))
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: -2)
                .help("Remove")
            }

            Text(item.name)
                .font(.caption2)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.white.opacity(missing ? 0.45 : 0.85))
                .frame(width: 56)
                .help(item.name)
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

    private var sendAllButton: some View {
        Button(action: controller.airDropAll) {
            VStack(spacing: 3) {
                Image(systemName: "airdrop")
                    .font(.system(size: 13, weight: .semibold))
                Text("Send all")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(.white.opacity(controller.canAirDropAll ? 0.95 : 0.35))
            .frame(width: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!controller.canAirDropAll)
        .help("AirDrop every file in the tray")
    }

    private var shelfBackground: Color {
        controller.isTargeted ? Color.white.opacity(0.16) : Color.white.opacity(0.06)
    }

    private var borderColor: Color {
        controller.isTargeted ? Color.white.opacity(0.7) : Color.white.opacity(0.22)
    }
}
