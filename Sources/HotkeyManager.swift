import AppKit
import Carbon.HIToolbox

private func hotkeyCallback(_: EventHandlerCallRef?, _ event: EventRef?, _: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event else { return OSStatus(eventNotHandledErr) }
    var hotkeyID = EventHotKeyID()
    GetEventParameter(event, UInt32(kEventParamDirectObject), UInt32(typeEventHotKeyID),
                      nil, MemoryLayout<EventHotKeyID>.size, nil, &hotkeyID)
    switch hotkeyID.id {
    case 1: HotkeyManager.shared.onTogglePanel?()
    case 2: HotkeyManager.shared.onTranslate?()
    case 3: HotkeyManager.shared.onLiveText?()
    case 4: HotkeyManager.shared.onRegionCapture?()
    default: break
    }
    return noErr
}

class HotkeyManager {
    static let shared = HotkeyManager()

    var onTogglePanel: (() -> Void)?
    var onTranslate: (() -> Void)?
    var onLiveText: (() -> Void)?
    var onRegionCapture: (() -> Void)?

    private var hotKeyRefs: [EventHotKeyRef?] = []

    func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetApplicationEventTarget(), hotkeyCallback, 1, &eventType, nil, nil)

        // ⌘⇧\ — toggle panel
        registerKey(keyCode: UInt32(kVK_ANSI_Backslash), modifiers: UInt32(cmdKey | shiftKey), id: 1)
        // ⌘⇧, — translate selection
        registerKey(keyCode: UInt32(kVK_ANSI_Comma), modifiers: UInt32(cmdKey | shiftKey), id: 2)
        // ⌘⇧. — capture + OCR + translate
        registerKey(keyCode: UInt32(kVK_ANSI_Period), modifiers: UInt32(cmdKey | shiftKey), id: 3)
        // ⌘⇧' — region capture + OCR + translate
        registerKey(keyCode: UInt32(kVK_ANSI_Quote), modifiers: UInt32(cmdKey | shiftKey), id: 4)
    }

    func unregister() {
        hotKeyRefs.forEach { ref in
            if let ref { UnregisterEventHotKey(ref) }
        }
        hotKeyRefs.removeAll()
    }

    private func registerKey(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        var ref: EventHotKeyRef?
        let hotkeyID = EventHotKeyID(signature: 0x50434C44, id: id)
        RegisterEventHotKey(keyCode, modifiers, hotkeyID,
                            GetApplicationEventTarget(), 0, &ref)
        hotKeyRefs.append(ref)
    }
}
