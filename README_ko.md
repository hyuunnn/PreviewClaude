# PreviewLLM

macOS 미리보기(Preview) 앱 위에서 사용하기 위한 멀티 LLM 번역 패널입니다.

여러 LLM CLI 도구(Claude, Codex, Gemini, Qwen, Apfel, Copilot)를 지원하며, 별도 API 키 없이 기존 CLI 인증을 그대로 사용합니다.

OCR로 추출한 텍스트는 잘못된 개행, 누락된 글자, 깨진 단어 등이 포함되는 경우가 많아 번역기를 사용하면 번역 품질이 떨어집니다. LLM을 사용하면 문맥을 이해하여 자연스러운 번역을 제공합니다.

[Claude Code](https://github.com/anthropics/claude-code)에서 **Claude Opus 4.6**을 사용하여 바이브 코딩했습니다.

## 스크린샷

| 화면 캡처 번역 (⌘⇧.) | 선택 번역 (⌘⇧,) |
|:---:|:---:|
| ![화면 캡처 번역](images/1.png) | ![선택 번역](images/2.png) |

| 영역 캡처 번역 (⌘⇧') |
|:---:|
| ![영역 캡처 번역](images/5.png) |

| 이미지 드롭 번역 | 설정 |
|:---:|:---:|
| <img src="images/4.png"> | <img src="images/03.png"> |

## 주요 기능

- **패널 표시/숨김 (⌘⇧\\)** — 플로팅 패널 표시/숨김
- **선택 번역 (⌘⇧,)** — 텍스트를 드래그하면 자동 복사 + 번역 (손쉬운 사용 권한 필요)
- **화면 캡처 번역 (⌘⇧.)** — 현재 화면 전체를 캡처(패널 제외)하고 Vision OCR로 텍스트 추출 후 번역 (화면 기록 권한 필요)
- **영역 캡처 번역 (⌘⇧')** — 드래그로 화면 영역을 선택하고 Vision OCR로 텍스트 추출 후 번역 (화면 기록 권한 필요)
- **이미지 드롭 번역** — 이미지를 패널에 드래그앤드롭하면 Vision OCR로 텍스트를 추출하고 번역
- **퀵 액션** — 번역 / 요약 / 설명 버튼
- **제공자 선택** — 설정에서 Claude, Codex, Gemini, Qwen, Apfel, Copilot 전환 가능
- **모델 선택** — 자유 입력 방식의 모델명 설정 (제공자별 독립, 예: sonnet, gpt-5.4-mini, gemini-2.5-flash, qwen-flash-latest)
  - Claude와 Codex는 빠른 번역 응답을 위해 reasoning effort를 `low`로 설정
  - Apfel은 Apple Intelligence 기본 모델 사용 (모델 선택 불가)
- **음성 읽기 (TTS)** — macOS `say` 명령어로 응답을 소리 내어 읽어줍니다. 속도 조절 가능. 시스템 기본 음성을 사용하며, 음성을 변경하려면 **시스템 설정 > 손쉬운 사용 > 읽기 및 말하기 > 시스템 음성**에서 변경할 수 있습니다
- **시스템 프롬프트** — 번역 스타일 커스텀 가능 (ex: IT 용어 원문 유지)
- **다국어 UI** — 시스템 언어에 따라 한국어/영어 자동 전환
- **플로팅 패널** — 항상 위에 떠 있어 미리보기와 함께 사용 가능

## 요구사항

- **macOS 14.0+**
- 지원되는 LLM CLI 도구 중 하나 이상 설치 및 인증 완료:
  - [Claude Code CLI](https://github.com/anthropics/claude-code) (`claude`)
  - [Codex CLI](https://github.com/openai/codex) (`codex`)
  - [Gemini CLI](https://github.com/google-gemini/gemini-cli) (`gemini`)
  - [Qwen CLI](https://github.com/QwenLM/qwen-code) (`qwen`)
  - [Copilot CLI](https://github.com/github/gh-copilot) (`copilot`)
  - [Apfel CLI](https://github.com/Arthur-Ficial/apfel) (`apfel`)
- Swift 5.10+

## 빌드 및 설치

```bash
# 빌드
bash build.sh

# 실행
open build/PreviewLLM.app

# 설치 (Applications 폴더로 복사)
cp -r build/PreviewLLM.app /Applications/
```

## 권한 설정

앱 설정(⚙)에서 권한을 요청할 수 있습니다.

| 권한 | 용도 | 필수 여부 |
|------|------|-----------|
| 손쉬운 사용 | ⌘⇧, 드래그 텍스트 자동 추출 | 선택 (없으면 수동 복사 후 번역) |
| 화면 기록 | ⌘⇧. 화면 캡처, ⌘⇧' 영역 캡처 번역 | ⌘⇧. / ⌘⇧' 사용 시 필수 (앱 재시작 필요) |

## 제한사항

- **macOS 전용** — ScreenCaptureKit, Vision, Accessibility API 등 macOS 네이티브 프레임워크를 사용합니다
- 지원되는 LLM CLI 도구 중 하나 이상 설치 필요
- Claude의 `claude -p` 사용 관련: ([Thariq's Post](https://x.com/trq212/status/2024212380142752025), [archive](images/post.png))
- 화면 캡처 번역은 macOS의 Live Text와 동일한 Vision OCR 엔진을 사용합니다
- 화면 캡처 시 PreviewLLM 패널은 자동으로 제외되므로, 패널을 열어놓은 상태에서도 캡처가 가능합니다

