import Combine
import Foundation

@MainActor
final class ConnectionViewModel: ObservableObject {
    @Published var status: ConnectionStatus = .disconnected
    @Published var serverURL: URL?
    @Published var healthResponse: HealthResponse?

    /// Wired by AppContainer → ChatViewModel.handleLiveEvent
    var onLiveEvent: ((LiveSSEEvent) -> Void)?
    /// Wired by AppContainer → PermissionViewModel.handleLiveEvent
    var onPermissionEvent: ((LiveSSEEvent) -> Void)?

    private let apiClient: APIClient
    private let discovery = ServerDiscovery()
    private var liveSSE: SSEClient?
    private var healthTimer: Timer?

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public

    func connect() async {
        status = .connecting

        // 1. Try saved / default port
        let port = UserDefaults.standard.serverPort
        let savedURL = URL(string: "http://localhost:\(port)")!
        if await probe(url: savedURL) {
            await setup(url: savedURL)
            return
        }

        // 2. Auto-discover
        if let found = await discovery.discover() {
            await setup(url: found)
            return
        }

        status = .disconnected
    }

    func disconnect() {
        liveSSE?.disconnect()
        liveSSE = nil
        healthTimer?.invalidate()
        healthTimer = nil
        status = .disconnected
        serverURL = nil
    }

    // MARK: - Internal

    private func probe(url: URL) async -> Bool {
        await apiClient.configure(baseURL: url, token: UserDefaults.standard.apiToken)
        do {
            let h = try await apiClient.health()
            return h.status == "ok"
        } catch { return false }
    }

    private func setup(url: URL) async {
        serverURL = url
        await apiClient.configure(baseURL: url, token: UserDefaults.standard.apiToken)

        do {
            healthResponse = try await apiClient.health()
            status = .connected
            startLiveSSE(baseURL: url)
            startHealthTimer()
        } catch {
            status = .error(error.localizedDescription)
        }
    }

    private func startLiveSSE(baseURL: URL) {
        liveSSE?.disconnect()
        liveSSE = SSEClient()

        let liveURL = baseURL.appendingPathComponent("/messages/live")
        let token = UserDefaults.standard.apiToken

        liveSSE?.connect(url: liveURL, token: token) { [weak self] data in
            guard let event = LiveSSEEvent.parse(data: data) else { return }
            Task { @MainActor in
                self?.onLiveEvent?(event)
                self?.onPermissionEvent?(event)
            }
        } onDisconnect: { [weak self] in
            Task { @MainActor in
                if self?.status == .connected {
                    self?.status = .connecting
                }
            }
        }
    }

    private func startHealthTimer() {
        healthTimer?.invalidate()
        healthTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refreshHealth() }
        }
    }

    private func refreshHealth() async {
        do {
            healthResponse = try await apiClient.health()
            if status != .connected { status = .connected }
        } catch {
            status = .error("连接中断")
        }
    }
}
