# 14 - Clipboard shelf

## Goal

A second shelf under the file tray shows the last few clipboard items (text, files, images). Click copies that item back to the pasteboard. History is in-memory only.

## Files created / changed

- `Sources/NotchLocal/Clipboard/ClipboardItem.swift`
- `Sources/NotchLocal/Clipboard/ClipboardController.swift`
- `Sources/NotchLocal/Clipboard/ClipboardView.swift`
- `Sources/NotchLocal/Notch/NotchRootView.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`
- `Sources/NotchLocal/Notch/ScreenGeometry.swift`

## Steps

1. **ClipboardController.** Poll `NSPasteboard.general.changeCount` off a 0.4 s loop (or on expand). Ignore NotchLocal’s own writes. Cap **8** items, newest first.

2. **Kinds.** String, file URLs (`NSFilenamesPboardType` / `.fileURL`), and a PNG/TIFF image. Skip empty strings. Do not persist to disk.

3. **ClipboardView.** Horizontal shelf: snippet / icon / thumbnail. Click calls `pasteboard.clearContents()` then writes that item. X removes from history only.

4. Hide when `settings.showClipboard` is false.

## Done when

- Copy text in another app, expand the notch, the snippet appears.
- Clicking it puts that text back on the clipboard.
- Copying a Finder file shows the file name.
- Restart clears history.

## Pitfalls

- Writing the pasteboard bumps `changeCount`. Ignore the next poll after a restore or you duplicate the item.
- Do not store clipboard history in `tray.json` or Application Support.
