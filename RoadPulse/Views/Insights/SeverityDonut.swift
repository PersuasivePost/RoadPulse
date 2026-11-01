import SwiftUI

// MARK: - Donut slice

/// One arc of the donut between two fractions of a turn. Both ends are animatable.
struct DonutSliceShape: Shape {
    var start: Double
    var end: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(start, end) }
        set { start = newValue.first; end = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard end > start else { return path }
        let radius = min(rect.width, rect.height) / 2
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: radius,
                    startAngle: .degrees(-90 + 360 * start),
                    endAngle: .degrees(-90 + 360 * end),
                    clockwise: false)
        return path
    }
}

// MARK: - Severity donut

struct SeverityDonut: View {
    let counts: [InsightsStats.SeverityCount]

    // @State: the tapped severity is highlighted; `sweep` animates the slices in
    @State private var selected: Severity?
    @State private var sweep = 0.0
    // @Environment: no sweep animation under Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let ringWidth: CGFloat = 26
    private var numbers: [Int] { counts.map(\.count) }
    private var total: Int { numbers.reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By severity")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            HStack(spacing: 24) {
                donut
                legend
            }
        }
        .padding(16)
        .cardStyle()
        .onAppear {
            if reduceMotion { sweep = 1 } else { withAnimation(Motion.reveal) { sweep = 1 } }
        }
    }

    // MARK: Ring

    private var donut: some View {
        let fractions = DonutGeometry.fractions(for: numbers)
        return ZStack {
            ForEach(Array(counts.enumerated()), id: \.element.id) { index, item in
                let range = fractions[index]
                DonutSliceShape(start: range.lowerBound * sweep, end: range.upperBound * sweep)
                    .stroke(item.severity.color,
                            style: StrokeStyle(lineWidth: selected == item.severity ? ringWidth + 8 : ringWidth))
                    .opacity(selected == nil || selected == item.severity ? 1 : 0.35)
                    .padding(ringWidth / 2 + 4)
            }
            centre
        }
        .frame(width: 150, height: 150)
        .contentShape(Rectangle())
        .gesture(
            SpatialTapGesture().onEnded { value in
                let index = DonutGeometry.sliceIndex(at: value.location, in: CGSize(width: 150, height: 150),
                                                     ringWidth: ringWidth + 8, counts: numbers)
                select(index.map { counts[$0].severity })
            }
        )
        .animation(reduceMotion ? nil : Motion.snappy, value: selected)
    }

    private var centre: some View {
        VStack(spacing: 0) {
            Text("\(selected.map { count(for: $0) } ?? total)")
                .font(.title.weight(.heavy))
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(Color.ink)
            Text(selected?.label ?? "reports")
                .font(.caption)
                .foregroundStyle(Color.inkMuted)
        }
    }

    // MARK: Legend

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(counts.reversed()) { item in
                Button { select(item.severity) } label: {
                    HStack(spacing: 8) {
                        Circle().fill(item.severity.color).frame(width: 10, height: 10)
                        Text(item.severity.label)
                            .font(.caption)
                            .foregroundStyle(Color.ink)
                        Spacer(minLength: 4)
                        Text("\(item.count)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color.inkMuted)
                    }
                    .opacity(selected == nil || selected == item.severity ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected == item.severity ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Helpers

    private func count(for severity: Severity) -> Int {
        counts.first { $0.severity == severity }?.count ?? 0
    }

    /// Tapping the highlighted slice again, or the hole, clears the highlight.
    private func select(_ severity: Severity?) {
        Haptics.tap()
        selected = severity == selected ? nil : severity
    }
}

// MARK: - Preview

#Preview {
    SeverityDonut(counts: Severity.allCases.enumerated().map { InsightsStats.SeverityCount(severity: $1, count: $0 + 2) })
        .padding()
        .background(Color.asphalt)
}
