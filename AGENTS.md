<!-- Generated: 2026-04-04 | Updated: 2026-04-04 -->

# PreviewLLM

## Purpose
A macOS menu-bar utility that pairs with Preview.app to provide LLM-powered translation, summarization, and explanation of OCR-extracted text. It captures screen content or selected text via system-wide hotkeys, runs OCR through Apple Vision, and streams the result to a CLI-based LLM (Claude, Codex, Gemini, Qwen, or Apfel) displayed in a floating panel.

## Key Files

| File | Description |
|------|-------------|
| `Package.swift` | SPM manifest — macOS 14+, Swift 5.10, single executable target |
| `build.sh` | Builds release binary and assembles a signed `.app` bundle with Info.plist |
| `.gitignore` | Ignores `.build/`, `build/`, `.swiftpm/` |
| `LICENSE` | Project license |
| `README.md` | English documentation |
| `README_ko.md` | Korean documentation |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `Sources/` | All Swift source files — app entry point, views, view model, providers, hotkeys (see `Sources/AGENTS.md`) |
| `Resources/` | Localization string files for Korean and English (see `Resources/AGENTS.md`) |
| `images/` | Screenshot assets used in README documentation |

## For AI Agents

### Working In This Directory
- This is a Swift Package Manager project. Build with `swift build` or `./build.sh` for a full `.app` bundle.
- The app runs as `LSUIElement` (no Dock icon) — it lives in the menu bar.
- No external dependencies beyond Apple frameworks. LLM inference is delegated to CLI tools (`claude`, `codex`, `gemini`, `qwen`, `apfel`) already installed on the user's machine.
- Bundle identifier: `com.preview.llm`

### Build & Run
```bash
./build.sh                          # builds release .app bundle
open build/PreviewLLM.app           # launch
swift build                         # debug build only
```

### Testing Requirements
- No test target exists. Manual testing is required.
- Verify hotkeys work: `Cmd+Shift+\` (toggle), `Cmd+Shift+,` (translate selection), `Cmd+Shift+.` (full-screen OCR), `Cmd+Shift+'` (region OCR).
- Accessibility and Screen Recording permissions must be granted for full functionality.

### Architecture Overview
- **MVVM pattern**: `ChatViewModel` is the single view model driving `ChatView`.
- **Provider protocol**: `LLMProvider` abstracts CLI tools. Add new providers by conforming to the protocol and registering in `LLMProviderRegistry`.
- **Hotkeys**: Registered via Carbon Event Manager (`HotkeyManager`), not SwiftUI keyboard shortcuts.
- **OCR**: Apple Vision framework (`VNRecognizeTextRequest`) with multi-language support (en, ko, ja, zh-Hans, zh-Hant).
- **Screen capture**: `ScreenCaptureKit` — the app excludes its own windows from captures.
- **Localization**: `L()` helper function wrapping `NSLocalizedString` with a resource bundle lookup.

### Common Patterns
- Settings are stored in `UserDefaults` via `@AppStorage`.
- CLI binary paths are resolved once via `zsh -li -c "which <binary>"` and cached.
- Prompts are written in Korean (hardcoded translation instructions).

## Dependencies

### External (Apple Frameworks)
- `SwiftUI` — UI layer
- `AppKit` — NSPanel, NSPasteboard, NSImage
- `Vision` — OCR text recognition
- `ScreenCaptureKit` — Screen capture
- `ApplicationServices` — Accessibility API (AXUIElement)
- `Carbon.HIToolbox` — System-wide hotkey registration

### External (CLI Tools, runtime)
- `claude` CLI — Claude Code for LLM inference
- `codex` CLI — OpenAI Codex for LLM inference
- `gemini` CLI — Google Gemini for LLM inference
- `qwen` CLI — Qwen Code for LLM inference
- `apfel` CLI — Apple Intelligence from the command line

<!-- MANUAL: Any manually added notes below this line are preserved on regeneration -->
