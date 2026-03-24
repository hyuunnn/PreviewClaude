import SwiftUI
import UniformTypeIdentifiers

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showSettings = false
    @State private var isDropTargeted = false
    @AppStorage("sourceLang") private var sourceLang = "auto"
    @AppStorage("targetLang") private var targetLang = "ko"

    private static let sourceOptions = ["auto", "en", "ko", "ja", "zh"]
    private static let targetOptions = ["ko", "en", "ja", "zh"]
    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "tiff", "tif", "bmp", "gif", "heic", "webp"]

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            quickActions
            Divider()
            messagesList
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
            Divider()
            inputArea
        }
        .overlay {
            if isDropTargeted {
                dropOverlay
            }
        }
        .onDrop(of: [.image, .fileURL], isTargeted: $isDropTargeted) { providers in
            handleImageDrop(providers)
        }
        .frame(minWidth: 320, minHeight: 400)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var toolbar: some View {
        HStack {
            Text("PreviewClaude")
                .font(.headline)
            Spacer()
            Button(action: { viewModel.clearChat() }) {
                Image(systemName: "plus.message")
            }
            .buttonStyle(.borderless)
            .help(L("toolbar.newChat"))

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help(L("toolbar.settings"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var quickActions: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Picker("", selection: $sourceLang) {
                    ForEach(Self.sourceOptions, id: \.self) { code in
                        Text(ChatViewModel.langNames[code] ?? code).tag(code)
                    }
                }
                .frame(width: 100)

                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Picker("", selection: $targetLang) {
                    ForEach(Self.targetOptions, id: \.self) { code in
                        Text(ChatViewModel.langNames[code] ?? code).tag(code)
                    }
                }
                .frame(width: 100)

                Spacer()

                quickActionButton(L("action.translate"), action: .translate)
                quickActionButton(L("action.summarize"), action: .summarize)
                quickActionButton(L("action.explain"), action: .explain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func quickActionButton(_ title: String, action: ChatViewModel.QuickAction) -> some View {
        Button(title) {
            if let text = viewModel.pasteFromClipboard(), !text.isEmpty {
                viewModel.sendWithAction(action, text: text)
            } else {
                viewModel.errorMessage = L("input.noClipboard")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(viewModel.isLoading)
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    }
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: viewModel.updateCounter) { _, _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.and.wrench")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(L("empty.guide"))
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var inputArea: some View {
        HStack(spacing: 8) {
            Button(action: {
                if let text = viewModel.pasteFromClipboard() {
                    viewModel.inputText += text
                }
            }) {
                Image(systemName: "doc.on.clipboard")
            }
            .buttonStyle(.borderless)
            .help(L("input.paste"))

            ZStack(alignment: .leading) {
                if viewModel.inputText.isEmpty {
                    Text(L("input.placeholder"))
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.leading, 4)
                }
                TextEditor(text: $viewModel.inputText)
                    .font(.body)
                    .frame(minHeight: 20, maxHeight: 80)
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollContentBackground(.hidden)
                    .onKeyPress(.return) {
                        if NSEvent.modifierFlags.contains(.shift) {
                            return .ignored
                        }
                        viewModel.sendMessage()
                        return .handled
                    }
            }

            Button(action: {
                if viewModel.isLoading {
                    viewModel.cancelCurrentRequest()
                } else {
                    viewModel.sendMessage()
                }
            }) {
                Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.isLoading ? .red : (viewModel.canSend ? .accentColor : .secondary))
            }
            .buttonStyle(.borderless)
            .disabled(!viewModel.isLoading && !viewModel.canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Image Drop

    private var dropOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .padding(4)
            VStack(spacing: 8) {
                Image(systemName: "doc.text.image")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)
                Text(L("drop.imageToTranslate"))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding(8)
    }

    private func handleImageDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url: URL?
                if let u = item as? URL {
                    url = u
                } else if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    url = nil
                }
                guard let url, Self.imageExtensions.contains(url.pathExtension.lowercased()) else { return }
                Task { @MainActor in
                    viewModel.handleDroppedImage(url)
                }
            }
            return true
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                let data: Data?
                if let d = item as? Data {
                    data = d
                } else if let url = item as? URL {
                    data = try? Data(contentsOf: url)
                } else {
                    data = nil
                }
                guard let data else { return }
                Task { @MainActor in
                    viewModel.handleDroppedImageData(data)
                }
            }
            return true
        }

        return false
    }
}

private struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant { avatar("C", color: .orange) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content.isEmpty ? "..." : message.content)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.role == .user
                                  ? Color.accentColor.opacity(0.15)
                                  : Color.secondary.opacity(0.1))
                    )

                if message.role == .assistant && !message.content.isEmpty {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(message.content, forType: .string)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copied = false
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied" : "Copy")
                        }
                        .font(.caption2)
                        .foregroundColor(copied ? .green : .secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user { avatar("U", color: .blue) }
        }
        .padding(.horizontal, 12)
    }

    private func avatar(_ letter: String, color: Color) -> some View {
        Circle()
            .fill(color.opacity(0.8))
            .frame(width: 24, height: 24)
            .overlay(Text(letter).font(.caption2.bold()).foregroundColor(.white))
    }
}
