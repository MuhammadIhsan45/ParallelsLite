import SwiftUI

public struct StatusBadgeView: View {
    public let state: VMState

    public init(state: VMState) {
        self.state = state
    }

    private var statusColor: Color {
        switch state {
        case .running:
            return .green
        case .paused:
            return .orange
        case .starting, .stopping:
            return .blue
        case .stopped:
            return .secondary
        case .error:
            return .red
        }
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.6), radius: state == .running ? 3 : 0)

            Text(state.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.12))
        )
    }
}
