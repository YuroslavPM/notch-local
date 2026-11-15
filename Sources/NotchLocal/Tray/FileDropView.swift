import AppKit

final class FileDropView: NSView {
    weak var controller: FileTrayController?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if FileDragPasteboard.isDraggingFiles {
            return super.hitTest(point)
        }
        return nil
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard accepts(sender) else {
            controller?.setTargeted(false)
            return []
        }
        controller?.setTargeted(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        draggingEntered(sender)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        controller?.setTargeted(false)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        controller?.setTargeted(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        controller?.setTargeted(false)
        let urls = FileDragPasteboard.fileURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else { return false }
        controller?.add(urls: urls)
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        controller?.setTargeted(false)
    }

    private func accepts(_ sender: NSDraggingInfo) -> Bool {
        !FileDragPasteboard.fileURLs(from: sender.draggingPasteboard).isEmpty
    }
}
