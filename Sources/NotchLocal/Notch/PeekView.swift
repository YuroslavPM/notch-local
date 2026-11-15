import AppKit
import SwiftUI

struct PeekView: View {
    let peek: LivePeek
    var artwork: NSImage?

    var body: some View {
        HStack(spacing: 8) {
            switch peek {
            case .music(let title, let artist):
                peekArtwork
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                if !artist.isEmpty {
                    Text(artist)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            case .meeting(let title, let startsAt):
                Image(systemName: "calendar")
                    .font(.caption.weight(.semibold))
                Text(Self.countdown(until: startsAt))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
            case .battery(let percent, let charging):
                Image(systemName: charging ? "battery.100.bolt" : "battery.25")
                    .font(.caption.weight(.semibold))
                Text(charging ? "Charging \(percent)%" : "Low battery \(percent)%")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var peekArtwork: some View {
        if let artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        } else {
            Image(systemName: "music.note")
                .font(.caption)
        }
    }

    private static func countdown(until date: Date, now: Date = Date()) -> String {
        let minutes = max(1, Int(ceil(date.timeIntervalSince(now) / 60)))
        return minutes == 1 ? "in 1 min" : "in \(minutes) min"
    }
}
