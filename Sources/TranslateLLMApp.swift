import SwiftUI
import ApplicationServices
import ScreenCaptureKit

@main
struct TranslateLLMApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("TranslateLLM", systemImage: "text.bubble") {
            Button("⌘⇧\\  \(L("menu.toggle"))") {
                appDelegate.panelController.toggle()
            }
            Divider()
            Button(L("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

extension Notification.Name {
    static let translateClipboard = Notification.Name("translateClipboard")
    static let ocrError = Notification.Name("ocrError")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let panelController = PanelController()
    private var regionCaptureWindow: RegionCaptureWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let chatView = ChatView()
        panelController.setup(with: chatView)

        HotkeyManager.shared.onTogglePanel = { [weak self] in
            self?.panelController.toggle()
        }
        HotkeyManager.shared.onTranslate = { [weak self] in
            if AXIsProcessTrusted() {
                if let text = Self.getSelectedText(), !text.isEmpty {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } else {
                    Self.simulateCopy()
                }
            }
            self?.panelController.show()
            NotificationCenter.default.post(name: .translateClipboard, object: nil)
        }
        HotkeyManager.shared.onLiveText = { [weak self] in
            Self.captureScreenAndOCR { result in self?.handleOCRResult(result) }
        }
        HotkeyManager.shared.onRegionCapture = { [weak self] in
            self?.startRegionCapture()
        }
        HotkeyManager.shared.register()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.panelController.show()
        }
    }

    private func handleOCRResult(_ result: Result<String, OCRError>) {
        panelController.show()
        switch result {
        case .success(let text):
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            NotificationCenter.default.post(name: .translateClipboard, object: nil)
        case .failure(let error):
            NotificationCenter.default.post(name: .ocrError, object: error.localizedDescription)
        }
    }

    private func startRegionCapture() {
        let overlay = RegionCaptureWindow()
        regionCaptureWindow = overlay
        overlay.onComplete = { [weak self] cgRect in
            let overlayID = CGWindowID(overlay.windowNumber)
            overlay.orderOut(nil)
            self?.regionCaptureWindow = nil
            guard let cgRect else { return }
            Self.captureScreenAndOCR(region: cgRect, extraExcludeWindowID: overlayID) { result in
                self?.handleOCRResult(result)
            }
        }
        overlay.beginCapture()
    }

    private static func captureScreenAndOCR(region: CGRect? = nil, extraExcludeWindowID: CGWindowID? = nil, completion: @escaping (Result<String, OCRError>) -> Void) {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let myPID = ProcessInfo.processInfo.processIdentifier

                let display: SCDisplay?
                if let region {
                    let center = CGPoint(x: region.midX, y: region.midY)
                    display = content.displays.first(where: { $0.frame.contains(center) }) ?? content.displays.first
                } else {
                    display = content.displays.first
                }
                guard let display else {
                    await MainActor.run { completion(.failure(.noWindow)) }
                    return
                }

                var excludeWindows = content.windows.filter { $0.owningApplication?.processID == myPID }
                if let extraID = extraExcludeWindowID {
                    excludeWindows += content.windows.filter { $0.windowID == extraID && !excludeWindows.contains(where: { $0.windowID == extraID }) }
                }

                let filter = SCContentFilter(display: display, excludingWindows: excludeWindows)
                let config = SCStreamConfiguration()
                if let region {
                    config.sourceRect = CGRect(x: region.origin.x - display.frame.origin.x,
                                               y: region.origin.y - display.frame.origin.y,
                                               width: region.width, height: region.height)
                    config.width = Int(region.width * 2)
                    config.height = Int(region.height * 2)
                } else {
                    config.width = Int(display.frame.width * 2)
                    config.height = Int(display.frame.height * 2)
                }

                let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                let text = try OCRHelper.performOCR(on: image)

                if text.isEmpty {
                    await MainActor.run { completion(.failure(.noText)) }
                } else {
                    await MainActor.run { completion(.success(text)) }
                }
            } catch {
                await MainActor.run { completion(.failure(.captureError(error.localizedDescription))) }
            }
        }
    }

    private static func simulateCopy() {
        let src = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true)   // 0x08 = kVK_ANSI_C
        let keyUp   = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        usleep(100_000) // 100ms — 대상 앱이 클립보드에 쓸 시간
    }

    private static func getSelectedText() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success else {
            return nil
        }
        let focused = focusedElement as! AXUIElement
        var selectedText: CFTypeRef?
        guard AXUIElementCopyAttributeValue(focused, kAXSelectedTextAttribute as CFString, &selectedText) == .success else {
            return nil
        }
        return selectedText as? String
    }

    enum OCRError: LocalizedError {
        case noWindow, noText, captureError(String)
        var errorDescription: String? {
            switch self {
            case .noWindow: return L("error.noWindow")
            case .noText: return L("error.noText")
            case .captureError(let msg): return L("error.capture", msg)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }
}
