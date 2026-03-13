import Foundation

enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}

struct HealthResponse: Codable {
    let status: String
    let active: Bool
    let busy: Bool
}
