# 01 - Environment setup

## Goal

Confirm the machine can build a SwiftUI macOS app without Xcode.

## Files created / changed

None.

## Steps

1. Check the toolchain:
   ```bash
   swift --version      # expect Apple Swift version 6.x
   uname -m             # expect arm64
   xcode-select -p      # /Library/Developer/CommandLineTools is fine
   ```
2. If `swift` is missing or broken after a macOS update, reinstall the tools:
   ```bash
   xcode-select --install
   ```
3. Confirm the repo and remote:
   ```bash
   cd ~/Documents/projects/notch-local
   git status
   git remote -v        # git@github.com:YuroslavPM/notch-local.git
   ```
4. Open the folder as its own Cursor workspace (File > Open Folder > `notch-local`).
5. Optional: install the Swift extension in Cursor for syntax highlighting and SourceKit diagnostics.

## Why no Xcode

- `xcodebuild` is not installed. Command Line Tools include the macOS SDK with SwiftUI and AppKit, which is everything this app needs.
- SwiftPM builds a plain executable. macOS treats permissions per app bundle, so step 02 adds a script that wraps the executable into `NotchLocal.app`.
- Installing Xcode later is fine. Nothing in this repo depends on it.

## Done when

- `swift --version` prints 6.x.
- The workspace is open in Cursor at `notch-local`.

## Pitfalls

- After big macOS updates the Command Line Tools sometimes need reinstalling (`xcode-select --install`).
- Do not run `sudo xcode-select -s` to point at a non-existent Xcode path.
