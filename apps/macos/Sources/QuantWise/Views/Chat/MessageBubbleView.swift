import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    @EnvironmentObject var ttsService: TTSService

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            content
                .frame(maxWidth: .infinity, alignment: alignment)

            if message.role != .user { Spacer(minLength: 60) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.role {
        case .thinking:
            ThinkingBlockView(text: message.content)

        case .tool:
            ToolPillView(toolName: message.content)

        case .user:
            VStack(alignment: .trailing, spacing: 6) {
                if let imageData = message.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 200, maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if !message.content.isEmpty {
                    Text(message.content)
                        .font(.body)
                        .textSelection(.enabled)
                }
            }
            .padding(10)
            .background(bubbleColor)
            .foregroundStyle(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))

        case .assistant:
            VStack(alignment: .leading, spacing: 6) {
                Text(markdownAttributed(message.content))
                    .font(.body)
                    .textSelection(.enabled)

                // TTS button
                if !message.content.isEmpty {
                    HStack {
                        Spacer()
                        Button(action: { ttsService.speak(message.content, messageId: message.id) }) {
                            Image(systemName: isSpeakingThis ? "stop.circle.fill" : "speaker.wave.2")
                                .font(.caption)
                                .foregroundStyle(isSpeakingThis ? .red : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help(isSpeakingThis ? "停止朗读" : "朗读")
                    }
                }
            }
            .padding(10)
            .background(bubbleColor)
            .foregroundStyle(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var isSpeakingThis: Bool {
        ttsService.isSpeaking && ttsService.currentMessageId == message.id
    }

    private var alignment: Alignment {
        message.role == .user ? .trailing : .leading
    }

    private var bubbleColor: Color {
        message.role == .user ? .blue : Color(.controlBackgroundColor)
    }

    private var textColor: Color {
        message.role == .user ? .white : .primary
    }

    private func markdownAttributed(_ source: String) -> AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        if let result = try? AttributedString(markdown: source, options: options) {
            return result
        }
        return AttributedString(source)
    }
}
