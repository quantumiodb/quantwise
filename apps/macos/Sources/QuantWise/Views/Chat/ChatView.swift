import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var connectionVM: ConnectionViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ── Message list ──
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(chatVM.messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }

                        // Streaming indicators
                        if chatVM.isStreaming {
                            if !chatVM.currentThinking.isEmpty {
                                ThinkingBlockView(text: chatVM.currentThinking)
                            }
                            ForEach(chatVM.currentTools, id: \.self) { tool in
                                ToolPillView(toolName: tool)
                            }
                        }
                    }
                    .padding(12)
                }
                .onChange(of: chatVM.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: chatVM.messages.last?.content) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            // ── Error banner ──
            if let error = chatVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }

            Divider()

            // ── Input ──
            InputBarView()
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = chatVM.messages.last {
            withAnimation(.easeOut(duration: 0.15)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}
