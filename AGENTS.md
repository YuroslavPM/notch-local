# Agent rules for NotchLocal

## How to work in this repo

- Implement the guides in `docs/` strictly in order (`01` to `08`). One guide per session.
- Before starting a step, read `docs/00-overview.md` and the step's guide in full.
- A step is finished only when every item in its **Done when** list passes after `make run`.
- Commit after each step: `git commit -m "step NN: <short summary>"`.
- If behavior differs from the guide, update the guide in the same commit.

## Tech constraints

- Swift 6 with strict concurrency. UI types and view models are `@MainActor`.
- SwiftUI for views, AppKit for windowing (`NSPanel`, `NSScreen`, `NSEvent` monitors).
- Swift Package Manager only. Do not create `.xcodeproj` / `.xcworkspace` files.
- Build and run with `make run`. Never rely on `swift run` for anything that needs permissions.
- No third-party dependencies in the MVP.
- Do not copy code from Boring Notch (GPL-3.0). It is a behavior reference only.

## Code style

- One type per file, files grouped by feature under `Sources/NotchLocal/`.
- Use `@Observable` (Observation framework) instead of `ObservableObject`.
- Keep AppleScript and EventKit work off the main thread; publish results on the main actor.
- No force unwraps on system APIs that can fail (screens, permissions, scripts).
