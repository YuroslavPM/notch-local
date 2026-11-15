# 10 - File tray and AirDrop

## Goal

The expanded notch is a drop shelf for files. Dragging a file toward the notch expands the panel, the file lands as an icon, and it stays there across launches. Drag icons back to Finder or another app. Hover or right-click an icon to AirDrop it. Right-click also removes it.

This is a **shelf of references**, not a copy of the files. The tray stores bookmarks to the original URLs.

## Files created / changed

- `Sources/NotchLocal/Tray/TrayItem.swift`
- `Sources/NotchLocal/Tray/ResolvedBookmark.swift`
- `Sources/NotchLocal/Tray/FileTrayStore.swift`
- `Sources/NotchLocal/Tray/FileDragPasteboard.swift`
- `Sources/NotchLocal/Tray/FileTrayController.swift`
- `Sources/NotchLocal/Tray/FileDropView.swift`
- `Sources/NotchLocal/Tray/AirDropService.swift`
- `Sources/NotchLocal/Tray/FileTrayView.swift`
- `Sources/NotchLocal/Notch/MouseMonitor.swift`
- `Sources/NotchLocal/Notch/NotchViewModel.swift`
- `Sources/NotchLocal/Notch/NotchRootView.swift`
- `Sources/NotchLocal/Notch/ScreenGeometry.swift`
- `Sources/NotchLocal/App/AppDelegate.swift`

## Research (why this design)

The collapsed panel sets `ignoresMouseEvents = true` so clicks pass through to the menu bar. That also means **the window is invisible to a drag session**. SwiftUI `.onDrop` and AppKit `NSDraggingDestination` never fire while collapsed. Hover expand is also too late: Finder's drag cursor is already over the notch, and the 300 ms collapse timer would shrink the panel as soon as the pointer leaves the hover rect.

The working sequence is:

1. Global `.leftMouseDragged` (already in `MouseMonitor`) plus `NSPasteboard(name: .drag)` to detect a **file** drag.
2. Expand as soon as the pointer enters a **drop magnet** around the notch (taller than the hover hit, about 80 pt below the camera).
3. Turn `ignoresMouseEvents` **off** while expanded so the drop can land.
4. Hold expanded until `.leftMouseUp`, even if the pointer briefly leaves the panel.
5. Accept the drop on an AppKit view registered for `.fileURL`. Persist bookmarks. Render icons in SwiftUI.

AirDrop is the system picker, not a custom receiver list. `NSSharingService(named: .sendViaAirDrop)` + `canPerform(withItems:)` + `perform(withItems: [fileURL])`. Items must be existing file `URL`s (not path strings). The picker needs a source window; return `NotchPanel` from the sharing-service delegate.

The app is not sandboxed, so security-scoped bookmarks are unnecessary. Use `.minimalBookmark`. Resolve on load; drop or mark broken any bookmark that no longer exists.

Do not copy Boring Notch. Public APIs only: `NSPasteboard`, `NSDraggingInfo`, `NSURL` bookmarks, `NSItemProvider`, `NSSharingService`, `NSWorkspace`.

## Steps

1. **Drag-hold expand.** Add `.leftMouseUp` to `MouseMonitor`. When the drag pasteboard can read `NSURL` objects with `.fileURL`, and the pointer is inside `geometry.dropMagnetRect`, call `viewModel.beginFileDrag()`. That expands, sets `isFileDragActive = true`, and skips `scheduleCollapse` until `endFileDrag()` on mouse-up. `AppDelegate` already sets `ignoresMouseEvents = (state != .expanded)`; keep that.

2. **Geometry.** Grow `NotchGeometry.expandedSize` height by about 52 pt (shelf row + padding). Add `dropMagnetRect`: same width as the expanded panel, from the top of the screen down through the shelf, plus ~24 pt below. Music and calendar layout stay the same; the shelf sits under the divider.

3. **TrayItem / FileTrayStore.** One type per file.
   - `TrayItem`: `id: UUID`, `bookmark: Data`, `name: String`, `addedAt: Date`.
   - Persist JSON at `~/Library/Application Support/NotchLocal/tray.json`.
   - Bookmark with `url.bookmarkData(options: .minimalBookmark, …)`. Resolve off the main thread; publish on `@MainActor`.
   - Cap **12** items. Deduplicate by resolved path. Newest first.
   - If a file is gone, keep the row as a broken icon until the user removes it (do not silently delete on launch).

4. **FileDropView.** `NSView` subclass, `registerForDraggedTypes([.fileURL])`, implement `draggingEntered` / `draggingUpdated` / `performDragOperation`. Read `[URL]` via `draggingPasteboard.readObjects(forClasses: [NSURL.self])`. Skip promised-file drags (Photos, Safari in-progress downloads) in this step. Bridge `isTargeted` and dropped URLs into `FileTrayController`.

   SwiftUI `.onDrop` on a nonactivating `NSPanel` is flaky. AppKit is the source of truth for **incoming** drops. SwiftUI `.onDrag` is fine for **outgoing** drags.

5. **FileTrayController** (`@Observable`, `@MainActor`). Load store at start. `add(urls:)`, `remove(id:)`, `resolvedURL(for:)`, `icon(for:)`. Icons from `NSWorkspace.shared.icon(forFile:)`. Open with `NSWorkspace.shared.open`. Reveal with `activateFileViewerSelecting`.

6. **FileTrayView.** Bottom of `expandedContent`:
   - Empty: dashed “Drop files” zone.
   - Filled: horizontal icon shelf. Click opens. Drag out with `NSItemProvider(contentsOf:)`. Do **not** remove on drag-out (copy, not move).
   - Context menu: Open, Reveal in Finder, AirDrop, Remove.
   - Hover overlay: AirDrop button on the icon.

7. **AirDropService.**
   ```swift
   guard let service = NSSharingService(named: .sendViaAirDrop),
         service.canPerform(withItems: [fileURL]) else { return }
   service.delegate = … // sourceWindowForShareItems → NotchPanel
   service.perform(withItems: [fileURL])
   ```
   Do not remove the tray item after a successful share. If AirDrop is off, `canPerform` is false: hide or disable the button. Activate the app (`NSApp.activate`) before presenting the picker from an accessory process.

8. Wire `FileTrayController` in `AppDelegate` the same way as music and calendar. Overlay `FileDropView` on the hosting view (full expanded frame, or at least the shelf). Pass it into `NotchRootView`.

## Done when

- Dragging a Finder file toward the notch expands the panel before the cursor arrives, and the drop lands on the shelf.
- Dropped files survive `make run` / Restart; icons show the correct Finder artwork.
- Dragging an icon out copies it; the shelf still holds it.
- Right-click Remove deletes only the bookmark.
- AirDrop opens the system picker for a real file; cancelling does nothing to the tray.
- Collapsed notch still click-through when no file drag is in progress.
- Missing files show a broken state instead of crashing.

## Pitfalls

- **Click-through vs drop.** Never leave `ignoresMouseEvents = true` during an active file drag. Never leave it `false` after mouse-up if the panel has collapsed.
- **Collapse timer.** `scheduleCollapse` must not fire while `isFileDragActive`.
- **Pasteboard name.** Use `NSPasteboard(name: .drag)`, not the general pasteboard. The drag pasteboard is empty when the user is not dragging.
- **File URLs only.** Finder also puts filenames on the pasteboard; persist `URL`s, not path strings, so iCloud / spaces / non-ASCII names survive.
- **Promised files.** `NSFilePromiseReceiver` is a later slice. Reject them rather than hanging `performDragOperation`.
- **AirDrop items.** Pass `URL` objects. Path `String`s fail `canPerform`. Folders work; app bundles work; unsaved documents without a file URL do not.
- **Accessory + picker.** The AirDrop UI needs a key-capable window. `NotchPanel.canBecomeKey` is already `true`. Call `NSApp.activate` before `perform(withItems:)`.
- **Bookmark I/O off the main actor.** Resolve and write JSON in a detached task; publish results on `@MainActor`. No force unwraps on `Application Support` or bookmark resolution.
- **Height vs glass.** Growing `expandedSize` changes the always-on panel frame. Keep the window sized to the expanded rect; only the `NotchShape` clip grows.
- **Duplicates.** Dropping the same file twice should not add a second icon.
- **GPL.** Behavior reference only. Do not copy Boring Notch source.
