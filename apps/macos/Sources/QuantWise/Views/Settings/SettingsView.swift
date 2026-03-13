import SwiftUI

struct SettingsView: View {
    @Binding var showSettings: Bool
    @EnvironmentObject var connectionVM: ConnectionViewModel
    @State private var port: String = String(UserDefaults.standard.serverPort)
    @State private var token: String = UserDefaults.standard.apiToken ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Back button
            HStack {
                Button(action: { showSettings = false }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                Text("设置")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // ── Connection ──
            GroupBox("连接") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("端口")
                            .frame(width: 60, alignment: .leading)
                        TextField("3001", text: $port)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("Token")
                            .frame(width: 60, alignment: .leading)
                        SecureField("可选", text: $token)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack {
                        Button("保存并重连") {
                            if let p = Int(port) {
                                UserDefaults.standard.serverPort = p
                            }
                            UserDefaults.standard.apiToken = token.isEmpty ? nil : token
                            Task { await connectionVM.connect() }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        statusBadge
                    }
                }
                .padding(4)
            }

            // ── Hotkey ──
            GroupBox("快捷键") {
                HStack {
                    Text("切换面板")
                        .frame(width: 80, alignment: .leading)
                    Text("⌘⇧Q")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(4)
            }

            Spacer()

            Divider()

            Button(action: { NSApp.terminate(nil) }) {
                Label("退出 QuantWise", systemImage: "power")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }

    // MARK: - Status badge

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 6, height: 6)
            Text(badgeText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var badgeColor: Color {
        switch connectionVM.status {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }

    private var badgeText: String {
        switch connectionVM.status {
        case .connected: return "已连接"
        case .connecting: return "连接中…"
        case .disconnected: return "未连接"
        case .error(let msg): return "错误: \(msg)"
        }
    }
}
