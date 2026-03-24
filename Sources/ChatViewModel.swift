import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var content: String

    enum Role {
        case user, assistant
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var updateCounter = 0

    private var currentProcess: Process?
    private var isCancelled = false
    private var observer: Any?
    private var ocrErrorObserver: Any?

    private var model: String { UserDefaults.standard.string(forKey: "claudeModel") ?? "" }
    private var fastModel: String { UserDefaults.standard.string(forKey: "fastModel") ?? "haiku" }
    private var systemPrompt: String { UserDefaults.standard.string(forKey: "systemPrompt") ?? "" }
    private var sourceLang: String { UserDefaults.standard.string(forKey: "sourceLang") ?? "auto" }
    private var targetLang: String { UserDefaults.standard.string(forKey: "targetLang") ?? "ko" }

    static let langNames: [String: String] = [
        "auto": "Auto", "en": "English", "ko": "한국어", "ja": "日本語", "zh": "中文"
    ]

    private static let shellSetup: (path: String, env: [String: String]) = {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-li", "-c", "which claude && echo __ENV_SEPARATOR__ && env"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let parts = output.components(separatedBy: "__ENV_SEPARATOR__\n")

        let path = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "/usr/local/bin/claude"

        var env: [String: String] = [:]
        if parts.count > 1 {
            for line in parts[1].split(separator: "\n") {
                if let idx = line.firstIndex(of: "=") {
                    env[String(line[..<idx])] = String(line[line.index(after: idx)...])
                }
            }
        }
        return (path.isEmpty ? "/usr/local/bin/claude" : path, env)
    }()

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .translateClipboard, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, let text = self.pasteFromClipboard(), !text.isEmpty else { return }
                self.sendWithAction(.translate, text: text)
            }
        }
        ocrErrorObserver = NotificationCenter.default.addObserver(
            forName: .ocrError, object: nil, queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.errorMessage = notification.object as? String ?? L("error.ocrFail")
            }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        if let ocrErrorObserver { NotificationCenter.default.removeObserver(ocrErrorObserver) }
    }

    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    func sendMessage(_ text: String? = nil) {
        let content = (text ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        let idx = appendMessages(userContent: content)
        runClaude(prompt: buildPrompt(currentMessage: content), responseIndex: idx)
    }

    func sendWithAction(_ action: QuickAction, text: String) {
        let prompt: String
        switch action {
        case .translate:
            let target = Self.langNames[targetLang] ?? targetLang
            let langInstruction: String
            if sourceLang == "auto" {
                langInstruction = "\(target)로 번역해"
            } else {
                let source = Self.langNames[sourceLang] ?? sourceLang
                langInstruction = "\(source)를 \(target)로 번역해"
            }
            prompt = "<text> 안의 텍스트만 \(langInstruction). 부연설명, 원문 반복, 메모, 태그 없이 번역 결과만 출력해.\n\n<text>\(text)</text>"
        case .summarize: prompt = "<text> 안의 텍스트를 요약만 해. 부연설명 없이 요약 결과만 출력해.\n\n<text>\(text)</text>"
        case .explain: prompt = "<text> 안의 텍스트를 쉽게 설명해줘:\n\n<text>\(text)</text>"
        }
        let idx = appendMessages(userContent: prompt)
        runClaude(prompt: buildPrompt(currentMessage: prompt), responseIndex: idx, fast: true)
    }

    func pasteFromClipboard() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    func clearChat() {
        cancelCurrentRequest()
        messages.removeAll()
        errorMessage = nil
    }

    enum QuickAction {
        case translate, summarize, explain
    }

    // MARK: - Private

    private func appendMessages(userContent: String) -> Int {
        messages.append(ChatMessage(role: .user, content: userContent))
        inputText = ""
        isLoading = true
        isCancelled = false
        errorMessage = nil
        messages.append(ChatMessage(role: .assistant, content: ""))
        return messages.count - 1
    }

    func cancelCurrentRequest() {
        isCancelled = true
        currentProcess?.terminate()
        currentProcess = nil
        isLoading = false
    }

    private func buildPrompt(currentMessage: String) -> String {
        let history = Array(messages.dropLast(2).suffix(6))
        guard !history.isEmpty else { return currentMessage }

        var parts = history.map { "\($0.role == .user ? "Human" : "Assistant"): \($0.content)" }
        parts.append("Human: \(currentMessage)")
        return parts.joined(separator: "\n\n")
    }

    private func runClaude(prompt: String, responseIndex idx: Int, fast: Bool = false) {
        cancelCurrentRequest()
        isLoading = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.shellSetup.path)
        process.environment = Self.shellSetup.env

        var args = ["-p"]
        let effectiveModel = fast ? fastModel : model
        if !effectiveModel.isEmpty { args += ["--model", effectiveModel] }
        let sp = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sp.isEmpty { args += ["--system-prompt", sp] }
        process.arguments = args

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                guard let self, self.messages.indices.contains(idx) else { return }
                self.messages[idx].content = (self.messages[idx].content + str)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                self.updateCounter += 1
            }
        }

        process.terminationHandler = { [weak self] proc in
            outputPipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.currentProcess = nil
                if proc.terminationStatus != 0,
                   !self.isCancelled,
                   self.messages.indices.contains(idx),
                   self.messages[idx].content.isEmpty {
                    let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: errData, encoding: .utf8) ?? ""
                    self.errorMessage = errStr.isEmpty
                        ? L("error.cliFail") + " (exit \(proc.terminationStatus))"
                        : errStr
                    self.messages.remove(at: idx)
                }
            }
        }

        do {
            try process.run()
            currentProcess = process
            inputPipe.fileHandleForWriting.write(Data(prompt.utf8))
            inputPipe.fileHandleForWriting.closeFile()
        } catch {
            isLoading = false
            errorMessage = L("error.cliLaunch") + ": \(error.localizedDescription)"
            if messages.indices.contains(idx) {
                messages.remove(at: idx)
            }
        }
    }
}
