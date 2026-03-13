import Foundation

actor APIClient {
    private let session: URLSession
    private(set) var baseURL: URL?
    private var token: String?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
    }

    func configure(baseURL: URL, token: String? = nil) {
        self.baseURL = baseURL
        self.token = token
    }

    // MARK: - Endpoints

    /// GET /health → HealthResponse
    func health() async throws -> HealthResponse {
        let (data, _) = try await session.data(for: request(path: "/health"))
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }

    /// GET /messages → [ChatMessage]
    func messages() async throws -> [ChatMessage] {
        let (data, _) = try await session.data(for: request(path: "/messages"))
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return arr.compactMap { ChatMessage.fromJSON($0) }
    }

    /// POST /permission/respond
    func respondToPermission(requestId: String, decision: PermissionDecision) async throws {
        let body: [String: Any] = ["requestId": requestId, "decision": decision.rawValue]
        let req = try request(path: "/permission/respond", method: "POST", body: body)
        let (_, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }

    /// Build a URLRequest for POST /chat/stream (caller uses it with SSE delegate)
    func chatStreamRequest(prompt: String, imageBase64: String? = nil) throws -> URLRequest {
        var body: [String: Any] = ["prompt": prompt]
        if let imageBase64 {
            body["image"] = imageBase64
            body["image_media_type"] = "image/jpeg"
        }
        var req = try request(path: "/chat/stream", method: "POST", body: body)
        req.timeoutInterval = 300
        return req
    }

    // MARK: - Helpers

    private func request(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) throws -> URLRequest {
        guard let baseURL else { throw APIError.notConfigured }
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return req
    }

    enum APIError: Error, LocalizedError {
        case notConfigured
        case requestFailed

        var errorDescription: String? {
            switch self {
            case .notConfigured: return "API 未配置"
            case .requestFailed: return "请求失败"
            }
        }
    }
}
