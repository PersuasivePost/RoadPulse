import SwiftUI

// MARK: - Severity (1–5)

/// Hazard severity. Stored as `Int16` on `Hazard.severity`.
/// The only place a severity colour comes from (docs/DESIGN.md).
enum Severity: Int16, CaseIterable, Identifiable, Comparable {
    case minor = 1, low, medium, high, severe

    var id: Int16 { rawValue }

    /// Maps any integer into 1...5 so bad input can never crash the UI.
    init(clamping value: Int) {
        let clamped = Int16(min(max(value, 1), 5))
        self = Severity(rawValue: clamped) ?? .medium
    }

    // MARK: Display

    var label: String {
        switch self {
        case .minor: return "Minor"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }

    var colorToken: ColorToken {
        switch self {
        case .minor: return .sev1
        case .low: return .sev2
        case .medium: return .sev3
        case .high: return .sev4
        case .severe: return .sev5
        }
    }

    var color: Color { Color(colorToken) }

    /// Resolved hazards are drawn grey regardless of severity (docs/DESIGN.md).
    func colorToken(isFixed: Bool) -> ColorToken {
        isFixed ? .fixedGrey : colorToken
    }

    func color(isFixed: Bool) -> Color {
        Color(colorToken(isFixed: isFixed))
    }

    /// Suggests a severity from the classifier (docs/ARCHITECTURE.md): a confident pothole is
    /// worse than a doubtful one; "normal" maps to the lowest level.
    static func prefill(isPothole: Bool, confidence: Double) -> Severity {
        guard isPothole else { return .minor }
        switch confidence {
        case 0.95...: return .severe
        case 0.85...: return .high
        case 0.7...: return .medium
        default: return .low
        }
    }

    /// High and severe hazards get a pulsing ring on the map.
    var pulses: Bool { self >= .high }

    static func < (lhs: Severity, rhs: Severity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
