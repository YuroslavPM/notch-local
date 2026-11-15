import SwiftUI

struct FileTrayView: View {
    var controller: FileTrayController

    var body: some View {
        Group {
            if controller.isOpen {
                expandedShelf
            } else {
                compactShelf
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: controller.isOpen ? 64 : 26)
        .background(shelfBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(borderColor, style: StrokeStyle(lineWidth: 1, dash: dashPattern))
        )
        .animation(.easeInOut(duration: 0.18), value: controller.isOpen)
        .onDisappear {
            controller.collapseShelf()
        }
    }

    private var dashPattern: [CGFloat] {
        controller.items.isEmpty && !controller.isTargeted ? [5, 4] : []
    }

    private var compactShelf: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.caption.weight(.semibold))
            if controller.items.isEmpty {
                Text("Files")
                    .font(.caption.weight(.medium))
                Text("Drop or click")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            } else {
                compactIcons
                Text(fileCountLabel)
                    .font(.caption.weight(.medium))
                Spacer(minLength: 0)
                Image(systemName: "chevron.up")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .foregroundStyle(.white.opacity(0.85))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if controller.items.isEmpty {
                controller.chooseFiles()
            } else {
                controller.expandShelf()
            }
        }
        .help(controller.items.isEmpty ? "Drop files or click to browse" : "Show files")
    }

    private var compactIcons: some View {
        HStack(spacing: -6) {
            ForEach(controller.items.prefix(4)) { item in
                Image(nsImage: controller.icon(for: item))
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .opacity(controller.isMissing(item) ? 0.4 : 1)
            }
        }
    }

    private var fileCountLabel: String {
        let count = controller.items.count
        return count == 1 ? "1 file" : "\(count) files"
    }

    private var expandedShelf: some View {
        Group {
            if controller.items.isEmpty {
                emptyShelf
            } else {
                filledShelf
            }
        }
    }

    private var emptyShelf: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.caption.weight(.semibold))
            VStack(alignment: .leading, spacing: 1) {
                Text("Drop files")
                    .font(.caption.weight(.medium))
                Text("or click to browse")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .foregroundStyle(.white.opacity(0.85))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: controller.chooseFiles)
    }

    private var filledShelf: some View {
        HStack(spacing: 8) {
            Button(action: controller.collapseShelf) {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 16, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Hide files")

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
            .frame(width: 44, height: 48)
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
                        .frame(width: 26, height: 26)
                        .opacity(missing ? 0.4 : 1)
                        .frame(width: 32, height: 30)
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
                .frame(width: 52)
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
