import SwiftUI

@main
struct QuantWiseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var container = AppContainer()

    var body: some Scene {
        MenuBarExtra {
            PopoverContentView()
                .environmentObject(container.chatVM)
                .environmentObject(container.connectionVM)
                .environmentObject(container.permissionVM)
                .environmentObject(container.speechService)
                .environmentObject(container.ttsService)
                .environmentObject(container.cameraService)
        } label: {
            MenuBarIcon(status: container.connectionVM.status)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Shared Dependency Container

@MainActor
final class AppContainer: ObservableObject {
    let apiClient = APIClient()
    let chatVM: ChatViewModel
    let connectionVM: ConnectionViewModel
    let permissionVM: PermissionViewModel
    let speechService = SpeechService()
    let ttsService = TTSService()
    let cameraService = CameraService()

    init() {
        chatVM = ChatViewModel(apiClient: apiClient)
        connectionVM = ConnectionViewModel(apiClient: apiClient)
        permissionVM = PermissionViewModel(apiClient: apiClient)

        // Wire live SSE → view models
        connectionVM.onLiveEvent = { [weak self] event in
            self?.chatVM.handleLiveEvent(event)
        }
        connectionVM.onPermissionEvent = { [weak self] event in
            self?.permissionVM.handleLiveEvent(event)
        }

        // Auto-connect on launch
        Task {
            await connectionVM.connect()
            await chatVM.loadMessages()
        }
    }
}

// MARK: - Menubar Icon

struct MenuBarIcon: View {
    let status: ConnectionStatus

    var body: some View {
        Image(systemName: "terminal.fill")
            .symbolRenderingMode(.palette)
            .foregroundStyle(color)
    }

    private var color: Color {
        switch status {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
