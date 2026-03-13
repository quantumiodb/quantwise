import SwiftUI

struct PopoverContentView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var connectionVM: ConnectionViewModel
    @EnvironmentObject var permissionVM: PermissionViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text("QuantWise")
                    .font(.headline)
                Spacer()

                if let health = connectionVM.healthResponse, health.busy {
                    Text("处理中…")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // ── Content ──
            if showSettings {
                SettingsView(showSettings: $showSettings)
            } else {
                ChatView()
            }
        }
        .frame(width: 420, height: 600)
        .sheet(isPresented: $permissionVM.showModal) {
            if let req = permissionVM.currentRequest {
                PermissionModalView(request: req)
            }
        }
    }

    private var statusColor: Color {
        switch connectionVM.status {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
}
