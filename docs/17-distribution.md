# 17 - Distribution polish

## Goal

The `.app` has a real icon. Signing uses a local identity when `NOTCHLOCAL_SIGN_IDENTITY` is set, otherwise ad-hoc so `make run` still works.

## Files created / changed

- `Resources/AppIcon.icns`
- `Resources/AppIcon-1024.png`
- `Resources/Info.plist`
- `scripts/build-app.sh`
- `scripts/generate-app-icon.swift`
- `README.md`

## Steps

1. **Icon.** Silver squircle with a hardware-style notch, cyan inner glow, and an amber live-activity bar. Master is `Resources/AppIcon-1024.png` (transparent corners). `iconutil` writes `AppIcon.icns`. No text. Remask a new square concept with `swift scripts/generate-app-icon.swift <source> Resources/AppIcon-1024.png`.

2. **Info.plist.** `CFBundleIconFile` = `AppIcon`.

3. **build-app.sh.** Copy icns into `Contents/Resources`. Sign with `"${NOTCHLOCAL_SIGN_IDENTITY:--}"`.

## Done when

- Finder shows the icon on `build/NotchLocal.app`.
- `make run` still launches after ad-hoc sign.
- README mentions the optional identity env var.

## Pitfalls

- Ad-hoc signatures change every build; TCC prompts may return. A stable local identity is optional, not required for the MVP.
