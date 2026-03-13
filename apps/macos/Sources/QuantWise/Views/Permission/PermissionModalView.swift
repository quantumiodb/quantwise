import SwiftUI

struct PermissionModalView: View {
    let request: PermissionRequest
    @EnvironmentObject var permissionVM: PermissionViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("权限请求")
                    .font(.headline)
            }

            Divider()

            // Tool info
            VStack(alignment: .leading, spacing: 8) {
                Label(request.toolName, systemImage: "wrench.fill")
                    .font(.subheadline.bold())

                if !request.description.isEmpty {
                    Text(request.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Input details
                if !request.input.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(request.input.keys.sorted()), id: \.self) { key in
                            HStack(alignment: .top, spacing: 4) {
                                Text("\(key):")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                Text(request.input[key] ?? "")
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.textBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Divider()

            // Actions
            HStack(spacing: 12) {
                Button("拒绝") {
                    Task { await permissionVM.respond(to: request, decision: .reject) }
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("允许") {
                    Task { await permissionVM.respond(to: request, decision: .allow) }
                }
                .keyboardShortcut(.return)

                Button("允许并记住") {
                    Task { await permissionVM.respond(to: request, decision: .allowPermanent) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
