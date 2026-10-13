import SwiftUI

public struct GaugeProgressView: View {
    public let title: String
    public let valueString: String
    public let percentage: Double
    public let icon: String
    public let tintColor: Color

    public init(
        title: String,
        valueString: String,
        percentage: Double,
        icon: String,
        tintColor: Color = .blue
    ) {
        self.title = title
        self.valueString = valueString
        self.percentage = max(0.0, min(1.0, percentage))
        self.icon = icon
        self.tintColor = tintColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tintColor)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(valueString)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(tintColor)
                        .frame(width: geo.size.width * CGFloat(percentage), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
}
