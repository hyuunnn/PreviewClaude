import SwiftUI
import ApplicationServices

struct SettingsView: View {
    @AppStorage("claudeModel") private var model = "sonnet"
    @AppStorage("systemPrompt") private var systemPrompt = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("settings.title"))
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 4) {
                Text(L("settings.permissions"))
                    .font(.headline)
                HStack(spacing: 8) {
                    Image(systemName: AXIsProcessTrusted() ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(AXIsProcessTrusted() ? .green : .secondary)
                    Text(L("settings.accessibility"))
                        .font(.callout)
                    Spacer()
                    Button(L("settings.requestAccess")) {
                        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
                        AXIsProcessTrustedWithOptions(opts)
                    }
                    .font(.callout)
                }
                HStack(spacing: 8) {
                    Image(systemName: CGPreflightScreenCaptureAccess() ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(CGPreflightScreenCaptureAccess() ? .green : .secondary)
                    Text(L("settings.screenCapture"))
                        .font(.callout)
                    Spacer()
                    Button(L("settings.requestAccess")) {
                        CGRequestScreenCaptureAccess()
                    }
                    .font(.callout)
                }
                Text(L("settings.permDesc"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("settings.model"))
                    .font(.headline)
                TextField(L("settings.modelPlaceholder"), text: $model)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                Text(L("settings.modelDesc"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("settings.systemPrompt"))
                    .font(.headline)
                TextEditor(text: $systemPrompt)
                    .font(.body)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L("settings.hotkeys"))
                    .font(.headline)
                VStack(alignment: .leading, spacing: 4) {
                    Label("⌘⇧\\ \(L("menu.toggle"))", systemImage: "macwindow")
                    Label("⌘⇧, \(L("settings.selectTranslate"))", systemImage: "character.book.closed")
                    Label("⌘⇧. \(L("settings.captureTranslate"))", systemImage: "camera.viewfinder")
                    Label("⌘⇧' \(L("settings.regionCaptureTranslate"))", systemImage: "rectangle.dashed")
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Spacer()
                Button(L("settings.close")) { dismiss() }
                    .keyboardShortcut(.escape)
            }
        }
        .padding(20)
        .frame(width: 440, height: 560)
    }
}
