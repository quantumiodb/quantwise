import SwiftUI

struct ToolPillView: View {
    let toolName: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "wrench.fill")
                .font(.caption2)
            Text(toolName)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.15))
        .foregroundStyle(.secondary)
        .clipShape(Capsule())
    }
}
