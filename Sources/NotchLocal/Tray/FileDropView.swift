import AppKit

final class FileDropView: NSView {
    weak var controller: FileTrayController?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL, FileDragPasteboard.filenamesType])
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard FileDragPasteboard.isDraggingFiles else { return nil }
        return super.hitTest(point)
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

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        accepts(sender)
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
