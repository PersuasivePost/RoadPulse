import SwiftUI

// MARK: - Worst roads near me

struct WorstRoadsList: View {
    let roads: [InsightsStats.WorstRoad]
    let units: UnitSystem

    /// Rank column (20) + HStack spacing (8).
    private static let indent: CGFloat = 28

    private var topScore: Double { max(roads.map(\.score).max() ?? 1, 0.001) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Worst roads near me")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            if roads.isEmpty {
                Text("No open hazards. Nice roads!")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkMuted)
            }
            ForEach(Array(roads.enumerated()), id: \.element.id) { index, road in
                row(road, rank: index + 1)
                if index < roads.count - 1 { LaneDivider() }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func row(_ road: InsightsStats.WorstRoad, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(rank)")
                    .font(.subheadline.weight(.heavy))
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.laneYellow)
                    .frame(width: 20)
                Text(road.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                    .layoutPriority(1) // the name keeps its width; the "open · distance" text shrinks first
                Spacer()
                Text("\(road.openCount) open · \(units.distance(meters: road.distanceKm * 1000))")
                    .font(.caption)
                    .foregroundStyle(Color.inkMuted)
            }
            GeometryReader { proxy in
                Capsule()
                    .fill(Severity(clamping: 1 + Int((road.score / topScore * 4).rounded())).color)
                    .frame(width: max(proxy.size.width * CGFloat(road.score / topScore), 6))
            }
            .frame(height: 6)
            .padding(.trailing, Self.indent)
            // Alignment guide: start the bar under the road name instead of under the rank number
            .alignmentGuide(.leading) { $0[.leading] - Self.indent }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    WorstRoadsList(roads: [.init(name: "Kalyan", score: 9.2, distanceKm: 1.2, openCount: 4),
                           .init(name: "Thane", score: 4.1, distanceKm: 8, openCount: 2)],
                   units: .metric)
        .padding()
        .background(Color.asphalt)
}
