import SwiftUI

protocol LLMProvider {
    var id: String { get }
    var displayName: String { get }
    var avatarLetter: String { get }
    var avatarColor: Color { get }
    var defaultModel: String { get }
    var binaryName: String { get }

    var passesPromptViaArgument: Bool { get }

    func buildArguments(model: String, systemPrompt: String) -> [String]
    func formatPrompt(_ prompt: String, systemPrompt: String) -> String
}

extension LLMProvider {
    var passesPromptViaArgument: Bool { false }
}

// MARK: - Claude

struct ClaudeProvider: LLMProvider {
    let id = "claude"
    let displayName = "Claude"
    let avatarLetter = "C"
    let avatarColor = Color.orange
    let defaultModel = "sonnet"
    let binaryName = "claude"
    func buildArguments(model: String, systemPrompt: String) -> [String] {
        var args = ["-p", "--no-session-persistence", "--effort", "low"]
        if !model.isEmpty { args += ["--model", model] }
        let sp = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sp.isEmpty { args += ["--system-prompt", sp] }
        return args
    }

    func formatPrompt(_ prompt: String, systemPrompt: String) -> String {
        prompt
    }
}

// MARK: - Codex

struct CodexProvider: LLMProvider {
    let id = "codex"
    let displayName = "Codex"
    let avatarLetter = "X"
    let avatarColor = Color.green
    let defaultModel = "gpt-5.4"
    let binaryName = "codex"

    func buildArguments(model: String, systemPrompt: String) -> [String] {
        var args = ["exec", "--skip-git-repo-check", "--ephemeral", "-c", "model_reasoning_effort=\"low\""]
        if !model.isEmpty { args += ["-m", model] }
        return args
    }

    func formatPrompt(_ prompt: String, systemPrompt: String) -> String {
        let sp = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if sp.isEmpty { return prompt }
        return "System instructions: \(sp)\n\n\(prompt)"
    }
}

// MARK: - Gemini

struct GeminiProvider: LLMProvider {
    let id = "gemini"
    let displayName = "Gemini"
    let avatarLetter = "G"
    let avatarColor = Color.blue
    let defaultModel = "gemini-2.5-flash"
    let binaryName = "gemini"

    func buildArguments(model: String, systemPrompt: String) -> [String] {
        let sp = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        var args = [String]()
        if !sp.isEmpty { args += ["-p", sp] }
        args += ["--output-format", "text"]
        if !model.isEmpty { args += ["-m", model] }
        return args
    }

    func formatPrompt(_ prompt: String, systemPrompt: String) -> String {
        prompt
    }
}

// MARK: - Qwen

struct QwenProvider: LLMProvider {
    let id = "qwen"
    let displayName = "Qwen"
    let avatarLetter = "Q"
    let avatarColor = Color.purple
    let defaultModel = "qwen-flash-latest"
    let binaryName = "qwen"

    func buildArguments(model: String, systemPrompt: String) -> [String] {
        var args = ["-p", "--output-format", "text"]
        if !model.isEmpty { args += ["-m", model] }
        let sp = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sp.isEmpty { args += ["--system-prompt", sp] }
        args += ["--chat-recording", "false"]
        return args
    }

    func formatPrompt(_ prompt: String, systemPrompt: String) -> String {
        prompt
    }
}

// MARK: - Apfel

struct ApfelProvider: LLMProvider {
    let id = "apfel"
    let displayName = "Apfel"
    let avatarLetter = "A"
    let avatarColor = Color.red
    let defaultModel = ""
    let binaryName = "apfel"
    let passesPromptViaArgument = true

    func buildArguments(model: String, systemPrompt: String) -> [String] {
        var args = [String]()
        let sp = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sp.isEmpty { args += ["-s", sp] }
        args += ["-o", "plain"]
        return args
    }

    func formatPrompt(_ prompt: String, systemPrompt: String) -> String {
        prompt
    }
}

// MARK: - Registry

enum LLMProviderRegistry {
    static let all: [LLMProvider] = [ClaudeProvider(), CodexProvider(), GeminiProvider(), QwenProvider(), ApfelProvider()]

    static func provider(forId id: String) -> LLMProvider {
        all.first { $0.id == id } ?? all[0]
    }
}
