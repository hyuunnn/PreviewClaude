# PreviewClaude

A Claude translation panel designed to use on top of macOS Preview app.

Uses [`claude -p`](https://code.claude.com/docs/ko/cli-reference) CLI, so no separate API key is needed — it uses your existing Claude authentication.

OCR-extracted text often contains broken line breaks, missing characters, or garbled words, which degrades translation quality when using conventional translators. By using an LLM, the app understands context and delivers natural translations.

Vibe coded with **Claude Opus 4.6** via [Claude Code](https://github.com/anthropics/claude-code).

[한국어](README_ko.md)

## Screenshots

| Capture Translate (⌘⇧.) | Select Translate (⌘⇧,) |
|:---:|:---:|
| ![Capture Translate](images/01.png) | ![Select Translate](images/02.png) |

| Region Capture Translate (⌘⇧') | Image Drop Translate |
|:---:|:---:|
| ![Region Capture Translate](images/06.png) | <img src="images/04.png" width="80%"> |

| Settings |
|:---:|
| <img src="images/03.png" width="80%"> |

## Features

- **Toggle Panel (⌘⇧\\)** — Show/hide the floating panel
- **Select Translate (⌘⇧,)** — Drag to select text, auto-copy + translate (requires Accessibility permission)
- **Capture Translate (⌘⇧.)** — Captures the full screen (excluding the panel) and extracts text via Vision OCR, then translates (requires Screen Recording permission)
- **Region Capture Translate (⌘⇧')** — Drag to select a screen region, extracts text via Vision OCR, then translates (requires Screen Recording permission)
- **Image Drop Translate** — Drag & drop an image onto the panel to extract text via Vision OCR and translate
- **Quick Actions** — Translate / Summarize / Explain buttons
- **Model Selection** — Free-form model name input (default: sonnet)
- **System Prompt** — Customize translation style (e.g., keep IT terms in original)
- **Localized UI** — Automatically switches between Korean/English based on system language
- **Floating Panel** — Always-on-top window for use alongside Preview

## Requirements

- **macOS 14.0+**
- **[Claude Code CLI](https://github.com/anthropics/claude-code)** installed and authenticated
- Swift 5.10+

## Build & Install

```bash
# Build
bash build.sh

# Run
open build/PreviewClaude.app

# Install (copy to Applications)
cp -r build/PreviewClaude.app /Applications/
```

## Permissions

Permissions can be requested from the app settings (⚙).

| Permission | Purpose | Required |
|------------|---------|----------|
| Accessibility | ⌘⇧, auto text extraction from selection | Optional (without it, manually copy first) |
| Screen Recording | ⌘⇧. screen capture, ⌘⇧' region capture translate | Required for ⌘⇧. / ⌘⇧' (app restart needed) |

## Limitations

- **Claude only** — Uses [`claude -p`](https://code.claude.com/docs/ko/cli-reference) CLI, so Claude Code must be installed ([Thariq's Post](https://x.com/trq212/status/2024212380142752025), [archive](images/post.png))
- **macOS only** — Uses macOS native frameworks: ScreenCaptureKit, Vision, Accessibility API
- Capture translate uses the same Vision OCR engine as macOS Live Text
- Screen capture automatically excludes the PreviewClaude panel, so it works even while the panel is open

