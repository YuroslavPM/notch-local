# 16 - Volume and brightness HUD

## Goal

Volume and brightness keys briefly grow the collapsed notch into a peek with a bar, instead of (or as well as) the system HUD. Settings can turn this off.

## Files created / changed

- `Sources/NotchLocal/HUD/VolumeService.swift`
- `Sources/NotchLocal/HUD/BrightnessService.swift`
- `Sources/NotchLocal/HUD/MediaKeyMonitor.swift`
- `Sources/NotchLocal/Notch/LivePeek.swift`
- `Sources/NotchLocal/Notch/PeekView.swift`
- `Sources/NotchLocal/Notch/NotchViewModel.swift`
- `Resources/Info.plist`

## Steps

1. **VolumeService.** Default output device, `kAudioHardwareServiceDeviceProperty_VirtualMainVolume` (0…1). Mute via the mute property when present.

2. **BrightnessService.** `IODisplayGetFloatParameter` / `IODisplaySetFloatParameter` with `kDisplayBrightness` on `IODisplayConnect`. No-op on external-only setups.

3. **MediaKeyMonitor.** `NSEvent` `.systemDefined` (and a listen-only `CGEventTap` if the monitor is empty). Key down for NX sound up/down/mute and brightness up/down. After the system applies the change, read the new value and `showPeek` for ~1.6 s.

4. **Peek.** `LivePeek.volume(percent:muted:)` and `.brightness(percent:)`. Draw a 80 pt capsule bar. `showPeek` duration parameter so HUDs dismiss faster than meeting peeks.

5. If `settings.showHUD` is false, do not subscribe.

6. Full suppression of the system HUD needs Accessibility and swallowing keys; **do not swallow** in this step. Show our peek; the system HUD may still flash. Info.plist: `NSAccessibilityUsageDescription` only if a tap is installed in listen-only mode.

## Done when

- Volume keys show a notch peek with a bar that matches the new level.
- Brightness keys do the same on the built-in display.
- The toggle in Settings stops the peeks.
- Expanded music/calendar still work; HUD peek is a no-op while expanded.

## Pitfalls

- Do not consume media key events. Swallowing them without applying volume ourselves mutes the machine.
- `IODisplayConnect` can be missing on clamshell + external. Return nil.
- Global `systemDefined` monitors can be silent without Accessibility; the listen-only tap is the fallback.
