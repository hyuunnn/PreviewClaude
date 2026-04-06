<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-04-04 | Updated: 2026-04-04 -->

# Sources

## Purpose
All Swift source files for the PreviewLLM application. Contains the app entry point, MVVM architecture (view + view model), LLM provider abstraction, floating panel window management, system-wide hotkey registration, screen region capture, settings UI, and localization helpers.

## Key Files

| File | Description |
|------|-------------|
| `PreviewLLMApp.swift` | `@main` entry point — `MenuBarExtra` scene, `AppDelegate` with hotkey wiring, screen capture via ScreenCaptureKit, OCR via Vision, clipboard-based text selection via Accessibility API |
| `ChatViewModel.swift` | MVVM view model — manages message list, spawns CLI processes (`claude`/`codex`), streams stdout into assistant messages, handles image-drop OCR, quick actions (translate/summarize/explain) |
| `ChatView.swift` | Main SwiftUI view — toolbar, language pickers, quick-action buttons, scrollable message list with bubbles, text input area, image drag-and-drop overlay |
| `LLMProvider.swift` | `LLMProvider` protocol and concrete implementations (`ClaudeProvider`, `CodexProvider`, `GeminiProvider`, `QwenProvider`, `ApfelProvider`), plus `LLMProviderRegistry` for lookup |
| `FloatingPanel.swift` | `NSPanel` subclass for always-on-top floating window; `PanelController` for show/hide/toggle lifecycle |
| `HotkeyManager.swift` | Singleton that registers four system-wide hotkeys via Carbon Event Manager (`Cmd+Shift+\`, `,`, `.`, `'`) |
| `RegionCaptureView.swift` | `NSWindow`/`NSView` subclasses for interactive rectangular screen region selection with crosshair cursor and rubber-band drawing |
| `SettingsView.swift` | SwiftUI sheet — permission status (Accessibility, Screen Recording), provider picker, model name field, system prompt editor, hotkey reference |
| `Localization.swift` | `L()` helper functions wrapping `NSLocalizedString` with resource bundle resolution for the SPM-built app bundle |

## For AI Agents

### Working In This Directory
- All files are in a flat structure (no subdirectories). Each file has a single clear responsibility.
- The app uses **MVVM**: `ChatView` observes `ChatViewModel` via `@StateObject`/`@Published`.
- LLM calls are **process-based** (not network): `Process()` launches a CLI binary, pipes stdin/stdout. Streaming output is read via `readabilityHandler`.
- Binary paths for CLI tools are resolved once with `zsh -li -c "which <binary>"` and cached in a static dictionary.

### Adding a New LLM Provider
1. Create a struct conforming to `LLMProvider` in `LLMProvider.swift`.
2. Implement `buildArguments()` and `formatPrompt()` for the CLI tool.
3. Add the instance to `LLMProviderRegistry.all`.
4. Add a `settings.modelPlaceholder.<id>` key to both `Localizable.strings` files.

### Key Hotkey IDs
| ID | Shortcut | Action |
|----|----------|--------|
| 1 | `Cmd+Shift+\` | Toggle floating panel |
| 2 | `Cmd+Shift+,` | Translate selected text |
| 3 | `Cmd+Shift+.` | Full-screen capture + OCR + translate |
| 4 | `Cmd+Shift+'` | Region capture + OCR + translate |

### Testing Requirements
- No automated tests. Verify manually by building and running the app.
- After modifying `ChatViewModel`, test all quick actions and direct message sending.
- After modifying `LLMProvider`, verify CLI invocation with all providers (`claude`, `codex`, `gemini`, `qwen`, `apfel`). Note: `apfel` passes the prompt as a CLI argument (not stdin) via `passesPromptViaArgument`.
- After modifying `HotkeyManager`, verify all four hotkeys still register and fire.

### Common Patterns
- `@AppStorage` for persistent user preferences (provider, model, system prompt, languages).
- `NotificationCenter` for cross-component communication (`.translateClipboard`, `.ocrError`).
- Translation prompts are hardcoded in Korean in `ChatViewModel.sendWithAction()`.
- Coordinate system conversion between Cocoa (bottom-left origin) and Core Graphics (top-left origin) in `RegionCaptureView.swift`.

## Dependencies

### Internal
- `Resources/` — Localization `.strings` files loaded via `Localization.swift`

### External (Apple Frameworks)
- `SwiftUI`, `AppKit` — UI
- `Vision` — OCR (`VNRecognizeTextRequest`)
- `ScreenCaptureKit` — Screen capture (`SCScreenshotManager`)
- `ApplicationServices` — Accessibility (`AXUIElement`)
- `Carbon.HIToolbox` — Hotkey registration (`RegisterEventHotKey`)
- `UniformTypeIdentifiers` — Image drop type matching

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
