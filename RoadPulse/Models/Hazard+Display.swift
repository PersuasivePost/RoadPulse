import Foundation

// MARK: - Display helpers for lists and sharing

extension Hazard {
    static let unassignedAreaName = "Unassigned"

    /// Section key for `SectionedFetchRequest`. `@objc` because SwiftUI turns the key path into
    /// a KVC string for the fetched results controller.
    @objc var areaSectionName: String {
        area?.name ?? Self.unassignedAreaName
    }

    /// Row and detail headline: the landmark if known, otherwise the hazard type.
    var displayTitle: String {
        landmark ?? hazardType.label
    }

    /// Plain-text report for `ShareLink`.
    var shareSummary: String {
        var lines = ["\(hazardType.label) · \(severityLevel.label) (\(severity)/5) · \(hazardStatus.label)"]
        if let landmark { lines.append(landmark) }
        if let address { lines.append(address) }
        if let area { lines.append("\(area.name), \(area.city)") }
        if let notes, !notes.isEmpty { lines.append(notes) }
        lines.append(String(format: "https://maps.apple.com/?ll=%.5f,%.5f", latitude, longitude))
        lines.append("Reported with RoadPulse")
        return lines.joined(separator: "\n")
    }
}
