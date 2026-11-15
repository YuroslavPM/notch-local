# NotchLocal

A personal, local-only macOS app that turns the MacBook notch into a small control panel, inspired by NotchNook. Hover the notch and it expands to show what is playing (any Now Playing source), your next calendar events, and a file shelf you can drop onto or AirDrop from. While collapsed it can peek a new track, an upcoming meeting, or a battery warning.

Built with Swift 6, SwiftUI and AppKit using Swift Package Manager. Xcode is not required.

## Requirements

- macOS 14 Sonoma or later (developed on macOS 27, Apple Silicon)
- Swift 6 toolchain (Xcode Command Line Tools are enough)
- Optional: `brew install media-control` for YouTube, Podcasts, and other Now Playing sources (Spotify and Apple Music still work without it)

## Run

```bash
make run
```

This builds a release binary, wraps it into `build/NotchLocal.app`, ad-hoc signs it and launches it. The app lives in the menu bar (no Dock icon). Quit it from the menu bar icon.

Always launch through `make run` / the `.app`. `swift run` will start the binary, but macOS permission prompts (Calendar, Automation) only work for a real app bundle.

## Permissions

On first use macOS will ask for:

- **Calendar** to show upcoming events
- **Automation** (Spotify / Music) to read and control playback

If you denied one, re-enable it in System Settings > Privacy & Security.

## Docs

The build is split into step-by-step guides. Start with [docs/00-overview.md](docs/00-overview.md).
