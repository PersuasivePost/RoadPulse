import SwiftUI

// MARK: - Bar shape

/// A bar that grows from the bottom; `fraction` (0...1) is its height. Animatable, so a spring
/// on `fraction` grows the bar frame by frame.
struct BarShape: Shape {
    var fraction: Double

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let height = rect.height * CGFloat(min(max(fraction, 0), 1))
        guard height > 0 else { return Path() }
        let bar = CGRect(x: rect.minX, y: rect.maxY - height, width: rect.width, height: height)
        return Path(roundedRect: bar, cornerRadius: min(8, rect.width / 2), style: .continuous)
    }
}

// MARK: - Bar chart of hazards per Area

struct BarChart: View {
    let data: [InsightsStats.AreaCount]

    // @State: false → bars at zero height; flipped on appear to spring them up one by one
    @State private var grown = false
    // @Environment: bars appear instantly under Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var maxCount: Int { max(data.map(\.count).max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hazards per area")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    column(item, index: index)
                }
            }
            .frame(height: 170)
        }
        .padding(16)
        .cardStyle()
        .onAppear { grown = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hazards per area")
        .accessibilityValue(data.map { "\($0.name) \($0.count)" }.joined(separator: ", "))
    }

    private func column(_ item: InsightsStats.AreaCount, index: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(item.count)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Color.ink)
            BarShape(fraction: grown ? Double(item.count) / Double(maxCount) : 0)
                .fill(Color.laneYellow)
                .animation(reduceMotion ? nil : Motion.smooth.delay(Motion.staggerDelay(at: index)), value: grown)
            Text(item.name)
                .font(.caption2)
                .foregroundStyle(Color.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    BarChart(data: [.init(name: "Kalyan", count: 8), .init(name: "Thane", count: 5), .init(name: "Ghatkopar", count: 3)])
        .padding()
        .background(Color.asphalt)
}
