import AppKit
import SwiftUI

struct MusicView: View {
    var controller: MusicController

    var body: some View {
        Group {
            if controller.permissionDenied {
                Text("Allow NotchLocal in System Settings > Privacy & Security > Automation")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            } else if let nowPlaying = controller.nowPlaying {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        revealControl(nowPlaying)
                            .help("Show \(nowPlaying.source.displayName)")
                        Spacer(minLength: 6)
                        controls(isPlaying: nowPlaying.isPlaying)
                    }
                    progressBar(for: nowPlaying)
                }
            } else {
                Text("Nothing playing")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
    }

    private func revealControl(_ nowPlaying: NowPlaying) -> some View {
        HStack(spacing: 10) {
            artwork
            VStack(alignment: .leading, spacing: 2) {
                Text(nowPlaying.title.isEmpty ? "Unknown" : nowPlaying.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(nowPlaying.artist.isEmpty ? nowPlaying.source.displayName : nowPlaying.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: controller.revealPlayer)
        .help("Show \(nowPlaying.source.displayName)")
    }

    private var artwork: some View {
        Group {
            if let image = controller.artwork {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .compositingGroup()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.35))
                    Image(systemName: "music.note")
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func controls(isPlaying: Bool) -> some View {
        let buttons = HStack(spacing: 8) {
            Button(action: controller.previousTrack) {
                Image(systemName: "backward.fill")
                    .frame(width: 24, height: 24)
            }
            Button(action: controller.playPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 28, height: 28)
            }
            Button(action: controller.nextTrack) {
                Image(systemName: "forward.fill")
                    .frame(width: 24, height: 24)
            }
        }
        .font(.body)

        if #available(macOS 26.0, *) {
            buttons.buttonStyle(.glass)
        } else {
            buttons
                .buttonStyle(.plain)
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private func progressBar(for nowPlaying: NowPlaying) -> some View {
        let duration = nowPlaying.duration
        if duration > 1 {
            TimelineView(.periodic(from: .now, by: 0.25)) { _ in
                let elapsed = controller.isScrubbing
                    ? controller.scrubPosition
                    : nowPlaying.displayedElapsed()
                VStack(spacing: 3) {
                    Slider(
                        value: Binding(
                            get: { min(max(0, elapsed), duration) },
                            set: { controller.updateScrub($0) }
                        ),
                        in: 0...duration,
                        onEditingChanged: { editing in
                            if editing {
                                controller.beginScrub(at: nowPlaying.displayedElapsed())
                            } else {
                                controller.endScrub()
                            }
                        }
                    )
                    .controlSize(.small)
                    .tint(.white)
                    HStack {
                        Text(Self.clock(elapsed))
                        Spacer()
                        Text(Self.clock(duration))
                    }
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.65))
                }
            }
        }
    }

    private static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let minutes = total / 60
        let remain = total % 60
        return String(format: "%d:%02d", minutes, remain)
    }
}
