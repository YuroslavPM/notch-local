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
                HStack(spacing: 12) {
                    artwork
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nowPlaying.title.isEmpty ? "Unknown" : nowPlaying.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(nowPlaying.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    controls(isPlaying: nowPlaying.isPlaying)
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

    private var artwork: some View {
        Group {
            if let image = controller.artwork {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.35))
                    Image(systemName: "music.note")
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func controls(isPlaying: Bool) -> some View {
        HStack(spacing: 16) {
            Button(action: controller.previousTrack) {
                Image(systemName: "backward.fill")
            }
            Button(action: controller.playPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            Button(action: controller.nextTrack) {
                Image(systemName: "forward.fill")
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .font(.title3)
    }
}
