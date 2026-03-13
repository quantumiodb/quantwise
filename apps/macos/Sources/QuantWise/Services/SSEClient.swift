import Foundation

/// Lightweight SSE client with auto-reconnect.
/// Parses `data:` lines, ignores comments (`:` prefix / keepalive).
final class SSEClient: NSObject, URLSessionDataDelegate {
    private var task: URLSessionDataTask?
    private var session: URLSession?
    private var buffer = ""
    private var reconnectURL: URL?
    private var token: String?
    private var shouldReconnect = true

    private var onEvent: ((String) -> Void)?
    private var onDisconnect: (() -> Void)?

    /// Start streaming from `url`. Callbacks fire on the main queue.
    func connect(
        url: URL,
        token: String? = nil,
        onEvent: @escaping (String) -> Void,
        onDisconnect: @escaping () -> Void
    ) {
        self.reconnectURL = url
        self.token = token
        self.onEvent = onEvent
        self.onDisconnect = onDisconnect
        self.shouldReconnect = true
        startConnection()
    }

    func disconnect() {
        shouldReconnect = false
        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
    }

    // MARK: - Internal

    private func startConnection() {
        guard let url = reconnectURL else { return }
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = .infinity
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        var req = URLRequest(url: url)
        req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        task = session?.dataTask(with: req)
        task?.resume()
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(_: URLSession, dataTask _: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        buffer += text

        // Split on double newline (SSE event boundary)
        while let range = buffer.range(of: "\n\n") {
            let raw = String(buffer[buffer.startIndex ..< range.lowerBound])
            buffer = String(buffer[range.upperBound...])
            processRawEvent(raw)
        }
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didCompleteWithError _: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.onDisconnect?()
        }
        guard shouldReconnect else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.startConnection()
        }
    }

    // MARK: - SSE Parsing

    private func processRawEvent(_ raw: String) {
        var data = ""
        for line in raw.components(separatedBy: "\n") {
            if line.hasPrefix("data: ") {
                data += String(line.dropFirst(6))
            } else if line.hasPrefix(":") {
                return // comment / keepalive
            }
        }
        guard !data.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onEvent?(data)
        }
    }
}
