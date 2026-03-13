import Combine
import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isStreaming = false
    @Published var currentThinking = ""
    @Published var currentTools: [String] = []
    @Published var errorMessage: String?

    private let apiClient: APIClient
    private var streamDelegate: ChatStreamDelegate?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public

    func loadMessages() async {
        guard !isStreaming else { return }
        do {
            messages = try await apiClient.messages()
        } catch {
            // will retry on next sync
        }
    }

    func sendMessage(_ text: String, imageData: Data? = nil) async {
        messages.append(ChatMessage(role: .user, content: text, imageData: imageData))
        isStreaming = true
        currentThinking = ""
        currentTools = []
        errorMessage = nil

        // Placeholder for streamed assistant reply
        let placeholder = ChatMessage(role: .assistant, content: "")
        messages.append(placeholder)

        do {
            let imageBase64 = imageData?.base64EncodedString()
            let request = try await apiClient.chatStreamRequest(prompt: text, imageBase64: imageBase64)
            await streamResponse(request: request)
        } catch {
            errorMessage = error.localizedDescription
            isStreaming = false
        }
    }

    /// Called by ConnectionViewModel when a live SSE event arrives
    func handleLiveEvent(_ event: LiveSSEEvent) {
        switch event {
        case .messages(let msgs):
            if !isStreaming { messages = msgs }
        default:
            break
        }
    }

    // MARK: - Streaming

    private func streamResponse(request: URLRequest) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let delegate = ChatStreamDelegate(
                onEvent: { [weak self] event in
                    Task { @MainActor in self?.handleStreamEvent(event) }
                },
                onComplete: { [weak self] in
                    Task { @MainActor in
                        self?.isStreaming = false
                        self?.currentThinking = ""
                        self?.currentTools = []
                        await self?.loadMessages()
                        cont.resume()
                    }
                }
            )
            self.streamDelegate = delegate
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            session.dataTask(with: request).resume()
        }
    }

    private func handleStreamEvent(_ event: ChatStreamEvent) {
        switch event {
        case .text(let text):
            guard let last = messages.last, last.role == .assistant else { return }
            let updated = ChatMessage(
                id: last.id, role: .assistant,
                content: last.content + text, timestamp: last.timestamp
            )
            messages[messages.count - 1] = updated

        case .thinking(let thinking):
            currentThinking = thinking

        case .toolUse(let tool):
            if !currentTools.contains(tool) { currentTools.append(tool) }

        case .done:
            break

        case .error(let msg):
            errorMessage = msg
        }
    }
}

// MARK: - URLSession delegate for chat stream SSE

private final class ChatStreamDelegate: NSObject, URLSessionDataDelegate {
    private var buffer = ""
    private let onEvent: (ChatStreamEvent) -> Void
    private let onComplete: () -> Void

    init(onEvent: @escaping (ChatStreamEvent) -> Void, onComplete: @escaping () -> Void) {
        self.onEvent = onEvent
        self.onComplete = onComplete
    }

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text

        while let range = buffer.range(of: "\n\n") {
            let raw = String(buffer[buffer.startIndex ..< range.lowerBound])
            buffer = String(buffer[range.upperBound...])

            var eventData = ""
            for line in raw.components(separatedBy: "\n") {
                if line.hasPrefix("data: ") {
                    eventData += String(line.dropFirst(6))
                }
            }
            if !eventData.isEmpty, let event = ChatStreamEvent.parse(data: eventData) {
                onEvent(event)
            }
        }
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError _: Error?) {
        onComplete()
    }
}
