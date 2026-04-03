# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PreviewClaude is a macOS menu-bar/floating-panel app that provides translation, summarization, and explanation features using the Claude Code CLI (`claude -p`). It uses macOS native frameworks (ScreenCaptureKit, Vision, Accessibility API) for screen capture and OCR. No separate API key needed — it reuses the user's existing Claude Code authentication.

## Build & Development Commands

```bash
# Build release .app bundle
bash build.sh

# Run the built app
open build/PreviewClaude.app

# Install to Applications
cp -r build/PreviewClaude.app /Applications/

# SwiftPM build (intermediate step, usually called via build.sh)
swift build -c release
```

There is no test suite — the app is validated by building and running manually. The build script handles creating the `.app` bundle structure, copying resources, generating `Info.plist`, and code-signing.

## Architecture

This is a Swift/macOS SwiftUI app managed via Swift Package Manager (`Package.swift`). The target uses an unusual layout — `path: "."` with `sources: ["Sources"]` and `resources: [process("Resources")]`.

### File Structure

| File | Purpose |
|------|---------|
| `Sources/PreviewClaudeApp.swift` | `@main` entry point, `AppDelegate`, menu bar setup, hotkey action routing, ScreenCaptureKit OCR pipeline |
| `Sources/ChatView.swift` | SwiftUI chat UI with toolbar, quick actions, messages list, text input, image drag-and-drop |
| `Sources/ChatViewModel.swift` | `@MainActor` ViewModel: clipboard handling, Claude CLI subprocess management (`claude -p`), streaming response handling, Vision OCR for dropped images |
| `Sources/FloatingPanel.swift` | Custom `NSPanel` subclass (always-on-top, non-activating) and `PanelController` for show/hide |
| `Sources/HotkeyManager.swift` | Carbon `EventHotKey` registration for global shortcuts |
| `Sources/RegionCaptureView.swift` | Full-screen overlay window with crosshair cursor for region selection (drag-to-select rectangle) |
| `Sources/SettingsView.swift` | Settings sheet: permissions status, model input, system prompt editor, hotkey reference |
| `Sources/Localization.swift` | `L()` helper wrapping `NSLocalizedString` with custom bundle resolution |
| `Resources/en.lproj/` / `Resources/ko.lproj/` | `.strings` files for Korean/English localization |

### Key Flows

1. **Toggle Panel** (`⌘⇧\`) — Show/hide `FloatingPanel` via `PanelController`
2. **Select Translate** (`⌘⇧,`) — Uses Accessibility API (`AXUIElement`) to get selected text from focused element, copies to pasteboard, triggers translation via notification
3. **Capture Translate** (`⌘⇧.`) — Uses `SCShareableContent` + `SCScreenshotManager` to capture full screen (excluding app's own windows), runs Vision `VNRecognizeTextRequest` OCR, then sends extracted text to Claude for translation
4. **Region Capture Translate** (`⌘⇧'`) — Shows a full-screen overlay (`RegionCaptureWindow`), user drags to select rectangle, then captures only that region via ScreenCaptureKit with `sourceRect`
5. **Image Drop** — Drag image onto panel → Vision OCR → translation
6. **Free-text chat** — Type in input, send to Claude via `claude -p` subprocess with streaming output

### Claude CLI Integration

`ChatViewModel.runClaude()` spawns a `Process` running `claude -p` (located via login shell). Key details:
- Claude path and environment are resolved once at startup via `Self.shellSetup` lazy property (runs `zsh -li` to get PATH and env)
- Prompt is piped to stdin, streaming stdout is read character-by-character and appended to the assistant message
- `--model` and `--system-prompt` args are added from `UserDefaults` settings
- Chat history (last 6 exchanges) is included in prompts using `Human:/Assistant:` format

### Messaging Between Components

`AppDelegate` and `ChatViewModel` communicate via `NotificationCenter`:

- `.translateClipboard` — Triggers clipboard text translation (posted by `Select Translate` hotkey handler and `handleOCRResult`)
- `.ocrError` — Displays OCR errors in UI (posted on `captureScreenAndOCR` failure)

### Persistence

Settings are stored via `@AppStorage` / `UserDefaults`:
- `claudeModel` — model name (default: `"sonnet"`)
- `systemPrompt` — custom system prompt
- `sourceLang` / `targetLang` — translation language codes

### Permissions

- **Screen Recording** — required for `⌘⇧.` and `⌘⇧'` capture features (ScreenCaptureKit)
- **Accessibility** — required for `⌘⇧,` select translate (Accessibility API to read selected text)
- Permissions are requested/checked in `SettingsView`
