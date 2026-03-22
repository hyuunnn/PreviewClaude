import SwiftUI
import ApplicationServices
import Vision
import ScreenCaptureKit

@main
struct PreviewClaudeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("PreviewClaude", systemImage: "text.bubble") {
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        let chatView = ChatView()
        panelController.setup(with: chatView)

        HotkeyManager.shared.onTogglePanel = { [weak self] in
            self?.panelController.toggle()
        }
        HotkeyManager.shared.onTranslate = { [weak self] in
            if AXIsProcessTrusted(), let text = Self.getSelectedText(), !text.isEmpty {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
            self?.panelController.show()
            NotificationCenter.default.post(name: .translateClipboard, object: nil)
        }
        HotkeyManager.shared.onLiveText = { [weak self] in
            Self.captureAndOCR { result in
                self?.panelController.show()
                switch result {
                case .success(let text):
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    NotificationCenter.default.post(name: .translateClipboard, object: nil)
                case .failure(let error):
                    NotificationCenter.default.post(name: .ocrError, object: error.localizedDescription)
                }
            }
        }
        HotkeyManager.shared.register()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.panelController.show()
        }
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

    private static func captureAndOCR(completion: @escaping (Result<String, OCRError>) -> Void) {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
                let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
                let myPID = ProcessInfo.processInfo.processIdentifier
                let targetPID = frontPID != myPID ? frontPID : 0

                guard let target = content.windows
                    .filter({ $0.isOnScreen })
                    .first(where: { targetPID != 0 ? $0.owningApplication?.processID == targetPID : $0.owningApplication?.processID != myPID })
                else {
                    await MainActor.run { completion(.failure(.noWindow)) }
                    return
                }

                let filter = SCContentFilter(desktopIndependentWindow: target)
                let config = SCStreamConfiguration()
                config.width = Int(target.frame.width * 2)
                config.height = Int(target.frame.height * 2)

                let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["en", "ko", "ja", "zh-Hans", "zh-Hant"]
                request.usesLanguageCorrection = true

                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                try handler.perform([request])

                let text = request.results?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""

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

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }
}
