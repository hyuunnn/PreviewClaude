import AppKit
import Carbon.HIToolbox

class RegionCaptureWindow: NSWindow {
    var onComplete: ((CGRect?) -> Void)?

    init() {
        let frame = NSScreen.screens.reduce(CGRect.zero) { $0.union($1.frame) }
        super.init(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let captureView = RegionCaptureNSView(frame: frame)
        captureView.onComplete = { [weak self] cocoaRect in
            guard let self else { return }
            if let rect = cocoaRect {
                let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
                let cgRect = CGRect(x: rect.origin.x,
                                    y: primaryHeight - rect.origin.y - rect.height,
                                    width: rect.width, height: rect.height)
                onComplete?(cgRect)
            } else {
                onComplete?(nil)
            }
        }
        contentView = captureView
    }

    func beginCapture() {
        NSApp.activate()
        makeKeyAndOrderFront(nil)
        if let view = contentView { makeFirstResponder(view) }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

private class RegionCaptureNSView: NSView {
    var onComplete: ((CGRect?) -> Void)?

    private var dragStart: NSPoint?
    private var dragCurrent: NSPoint?
    private var completed = false

    override var acceptsFirstResponder: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        dragStart = event.locationInWindow
        dragCurrent = dragStart
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        dragCurrent = event.locationInWindow
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard !completed else { return }
        dragCurrent = event.locationInWindow
        guard let s = dragStart, let e = dragCurrent, let window else {
            completed = true; onComplete?(nil); return
        }
        let rect = makeRect(s, e)
        guard rect.width > 5, rect.height > 5 else {
            completed = true; onComplete?(nil); return
        }
        completed = true
        let origin = window.convertPoint(toScreen: rect.origin)
        let topRight = window.convertPoint(toScreen: CGPoint(x: rect.maxX, y: rect.maxY))
        onComplete?(CGRect(x: origin.x, y: origin.y,
                           width: topRight.x - origin.x, height: topRight.y - origin.y))
    }

    override func keyDown(with event: NSEvent) {
        guard !completed else { return }
        if event.keyCode == UInt16(kVK_Escape) {
            completed = true
            onComplete?(nil)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.2).setFill()
        bounds.fill()

        guard let s = dragStart, let e = dragCurrent else { return }
        let rect = makeRect(s, e)

        NSColor.clear.setFill()
        rect.fill(using: .copy)

        NSColor.white.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 1.5
        path.stroke()
    }

    private func makeRect(_ a: NSPoint, _ b: NSPoint) -> CGRect {
        CGRect(x: min(a.x, b.x), y: min(a.y, b.y),
               width: abs(b.x - a.x), height: abs(b.y - a.y))
    }
}
