import Foundation

// MARK: - Live SSE Events (GET /messages/live)

enum LiveSSEEvent {
    case messages([ChatMessage])
    case permissionRequest(PermissionRequest)
    case permissionResolved(requestId: String)

    static func parse(data: String) -> LiveSSEEvent? {
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let type = json["type"] as? String
        else { return nil }

        switch type {
        case "messages":
            guard let arr = json["messages"] as? [[String: Any]] else { return nil }
            return .messages(arr.compactMap { ChatMessage.fromJSON($0) })

        case "permission_request":
            guard let reqId = json["requestId"] as? String,
                  let tool = json["toolName"] as? String
            else { return nil }
            let desc = json["description"] as? String ?? ""
            var input: [String: String] = [:]
            if let inputDict = json["input"] as? [String: Any] {
                for (k, v) in inputDict { input[k] = String(describing: v) }
            }
            return .permissionRequest(
                PermissionRequest(id: reqId, toolName: tool, description: desc, input: input)
            )

        case "permission_resolved":
            guard let reqId = json["requestId"] as? String else { return nil }
            return .permissionResolved(requestId: reqId)

        default:
            return nil
        }
    }
}

// MARK: - Chat Stream Events (POST /chat/stream)

enum ChatStreamEvent {
    case text(String)
    case thinking(String)
    case toolUse(String)
    case done(String)
    case error(String)

    static func parse(data: String) -> ChatStreamEvent? {
        guard let jsonData = data.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let type = json["type"] as? String
        else { return nil }

        switch type {
        case "text": return .text(json["text"] as? String ?? "")
        case "thinking": return .thinking(json["thinking"] as? String ?? "")
        case "tool_use": return .toolUse(json["tool"] as? String ?? "")
        case "done": return .done(json["response"] as? String ?? "")
        case "error": return .error(json["message"] as? String ?? "Unknown error")
        default: return nil
        }
    }
}
