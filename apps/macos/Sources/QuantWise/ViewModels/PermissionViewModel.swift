import Foundation
import UserNotifications

@MainActor
final class PermissionViewModel: ObservableObject {
    @Published var pendingRequests: [PermissionRequest] = []
    @Published var showModal = false

    var currentRequest: PermissionRequest? { pendingRequests.first }

    private let apiClient: APIClient
    private var notificationsAvailable = false

    init(apiClient: APIClient) {
        self.apiClient = apiClient
        // Defer notification setup — UNUserNotificationCenter crashes without a bundle
        Task { @MainActor in self.setupNotifications() }
    }

    // MARK: - Public

    func respond(to request: PermissionRequest, decision: PermissionDecision) async {
        do {
            try await apiClient.respondToPermission(requestId: request.id, decision: decision)
        } catch {
            // may have been resolved already
        }
        resolveRequest(id: request.id)
    }

    /// Called by ConnectionViewModel on live SSE events
    func handleLiveEvent(_ event: LiveSSEEvent) {
        switch event {
        case .permissionRequest(let req):
            addRequest(req)
        case .permissionResolved(let reqId):
            resolveRequest(id: reqId)
        default:
            break
        }
    }

    // MARK: - Internal

    private func addRequest(_ request: PermissionRequest) {
        guard !pendingRequests.contains(where: { $0.id == request.id }) else { return }
        pendingRequests.append(request)
        showModal = true
        sendSystemNotification(for: request)
    }

    private func resolveRequest(id: String) {
        pendingRequests.removeAll { $0.id == id }
        if pendingRequests.isEmpty { showModal = false }
    }

    // MARK: - macOS Notifications

    private func setupNotifications() {
        // Guard: UNUserNotificationCenter requires a valid bundle identifier
        guard Bundle.main.bundleIdentifier != nil else { return }
        notificationsAvailable = true
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendSystemNotification(for request: PermissionRequest) {
        guard notificationsAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = "QuantWise 权限请求"
        content.body = "\(request.toolName): \(request.description)"
        content.sound = .default
        content.categoryIdentifier = "PERMISSION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let notif = UNNotificationRequest(identifier: request.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(notif)
    }
}
