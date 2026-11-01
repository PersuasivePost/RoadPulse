import CoreLocation
import Foundation

// MARK: - Insights numbers

/// Everything the Insights tab shows, computed once from a list of hazards.
struct InsightsStats {
    struct AreaCount: Identifiable, Equatable {
        let name: String
        let count: Int
        var id: String { name }
    }

    struct SeverityCount: Identifiable, Equatable {
        let severity: Severity
        let count: Int
        var id: Int16 { severity.rawValue }
    }

    struct WorstRoad: Identifiable, Equatable {
        let name: String
        /// `Σ severity / (1 + distanceKm)` over the area's open hazards (docs/ARCHITECTURE.md).
        let score: Double
        let distanceKm: Double
        let openCount: Int
        var id: String { name }
    }

    let total: Int
    let open: Int
    let fixed: Int
    let averageSeverity: Double
    /// Hazards per Area, most first.
    let perArea: [AreaCount]
    /// One entry per severity 1...5 (zero counts included, so the legend is stable).
    let severityCounts: [SeverityCount]
    let worstRoads: [WorstRoad]

    static let maxBars = 6
    static let maxWorstRoads = 5

    init(hazards: [Hazard], origin: CLLocationCoordinate2D) {
        total = hazards.count
        open = hazards.filter { !$0.isFixed }.count
        fixed = total - open
        averageSeverity = hazards.isEmpty
            ? 0 : Double(hazards.reduce(0) { $0 + Int($1.severity) }) / Double(hazards.count)

        var counts: [String: Int] = [:]
        for hazard in hazards { counts[hazard.areaSectionName, default: 0] += 1 }
        perArea = counts
            .map { AreaCount(name: $0.key, count: $0.value) }
            .sorted { ($0.count, $1.name) > ($1.count, $0.name) }
            .prefix(Self.maxBars).map { $0 }

        severityCounts = Severity.allCases.map { level in
            SeverityCount(severity: level, count: hazards.filter { $0.severityLevel == level }.count)
        }

        worstRoads = Self.worstRoads(hazards: hazards, origin: origin)
    }

    // MARK: Worst roads near me

    static func worstRoads(hazards: [Hazard], origin: CLLocationCoordinate2D) -> [WorstRoad] {
        let here = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        var scores: [String: (score: Double, nearest: Double, count: Int)] = [:]
        for hazard in hazards where !hazard.isFixed {
            let km = here.distance(from: CLLocation(latitude: hazard.latitude, longitude: hazard.longitude)) / 1000
            var entry = scores[hazard.areaSectionName] ?? (0, .infinity, 0)
            entry.score += Double(hazard.severity) / (1 + km)
            entry.nearest = min(entry.nearest, km)
            entry.count += 1
            scores[hazard.areaSectionName] = entry
        }
        return scores
            .map { WorstRoad(name: $0.key, score: $0.value.score, distanceKm: $0.value.nearest, openCount: $0.value.count) }
            .sorted { ($0.score, $1.name) > ($1.score, $0.name) }
            .prefix(maxWorstRoads).map { $0 }
    }

    /// Share of hazards that are fixed, 0...100.
    var fixedPercent: Double {
        total == 0 ? 0 : Double(fixed) / Double(total) * 100
    }
}
