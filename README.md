# NotchLocal

A personal, local-only macOS app that turns the MacBook notch into a small control panel, inspired by NotchNook. Hover the notch and it expands to show Now Playing, upcoming events, a file shelf, clipboard history, Focus, and battery. Volume and brightness keys peek a HUD from the notch. While collapsed it can also peek a new track, a meeting, or a battery warning.

Built with Swift 6, SwiftUI and AppKit using Swift Package Manager. Xcode is not required.

## Requirements

- macOS 14 Sonoma or later (developed on macOS 27, Apple Silicon)
- Swift 6 toolchain (Xcode Command Line Tools are enough)
- Optional: `brew install media-control` for YouTube, Podcasts, and other Now Playing sources (Spotify and Apple Music still work without it)

## Run

```bash
make run
```

This builds a release binary, wraps it into `build/NotchLocal.app`, signs it (ad-hoc by default) and launches it. The app lives in the menu bar (no Dock icon). Quit it from the menu bar icon.

To sign with a local identity so TCC prompts survive rebuilds:

```bash
NOTCHLOCAL_SIGN_IDENTITY="Apple Development: Your Name" make run
```

Always launch through `make run` / the `.app`. `swift run` will start the binary, but macOS permission prompts (Calendar, Automation) only work for a real app bundle.

## Permissions

On first use macOS will ask for:

- **Calendar** to show upcoming events
- **Automation** (Spotify / Music) to read and control playback
- **Focus** (optional) to show Do Not Disturb in the notch

Open **Settings…** from the menu bar icon, or the gear in the expanded notch, for launch at login, hover delay, widget toggles, and hiding the menu bar icon.

If you denied one, re-enable it in System Settings > Privacy & Security.

## Docs

The build is split into step-by-step guides. Start with [docs/00-overview.md](docs/00-overview.md).
