import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    init<Content: View>(content: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 620),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        contentView = NSHostingView(rootView: content)
        level = .floating
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        title = "TranslateLLM"
        minSize = NSSize(width: 320, height: 400)
        isReleasedWhenClosed = false
        setFrameAutosaveName("TranslateLLMPanel")
        center()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

class PanelController {
    private var panel: FloatingPanel?

    func setup<Content: View>(with content: Content) {
        panel = FloatingPanel(content: content)
    }

    func toggle() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
        }
    }

    func show() {
        panel?.makeKeyAndOrderFront(nil)
    }
}
