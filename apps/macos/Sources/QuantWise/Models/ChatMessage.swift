import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    let imageData: Data?

    enum Role: String, Codable {
        case user
        case assistant
        case thinking
        case tool
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), imageData: Data? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.imageData = imageData
    }

    /// Create from server JSON: `{ "role": "user"|"assistant"|"thinking"|"tool", "content": "..." }`
    static func fromJSON(_ dict: [String: Any]) -> ChatMessage? {
        guard let roleStr = dict["role"] as? String,
              let content = dict["content"] as? String,
              let role = Role(rawValue: roleStr)
        else { return nil }
        return ChatMessage(role: role, content: content)
    }
}
