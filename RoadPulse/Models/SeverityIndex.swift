import CoreGraphics
import Foundation

// MARK: - Severity index strip maths

/// Maps touches on the index strip to a severity, and a severity to the first matching hazard.
enum SeverityIndex {
    /// Top to bottom, as drawn: severe first.
    static let order: [Severity] = Severity.allCases.reversed()

    /// The severity under a touch at `y` in a strip `height` points tall (clamped to the strip).
    static func severity(atY y: CGFloat, height: CGFloat) -> Severity {
        guard height > 0 else { return order[0] }
        let fraction = min(max(y / height, 0), 0.999_999)
        return order[Int(fraction * CGFloat(order.count))]
    }

    /// First hazard of `severity` in display order, so the list can scroll to it.
    static func firstHazardID(with severity: Severity, in hazards: [Hazard]) -> UUID? {
        hazards.first { $0.severityLevel == severity }?.id
    }
}
