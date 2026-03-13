import Foundation

struct PermissionRequest: Identifiable, Equatable {
    /// `requestId` from the server SSE event
    let id: String
    let toolName: String
    let description: String
    let input: [String: String]

    static func == (lhs: PermissionRequest, rhs: PermissionRequest) -> Bool {
        lhs.id == rhs.id
    }
}

enum PermissionDecision: String, Codable {
    case allow
    case allowPermanent = "allow-permanent"
    case reject
}
