import Foundation

// MARK: - Monsoon risk

/// How dangerous a hazard becomes in the rains: severity combined with the last 7 days of rain.
enum RiskLevel: String, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: return "Low monsoon risk"
        case .medium: return "Medium monsoon risk"
        case .high: return "High monsoon risk"
        }
    }

    /// Uses the severity scale's colours so risk and severity read the same way.
    var colorToken: ColorToken {
        switch self {
        case .low: return .sev1
        case .medium: return .sev3
        case .high: return .sev5
        }
    }

    // MARK: Calculation (docs/ARCHITECTURE.md)

    /// `severity/5 * 0.6 + min(rain7d/100, 1) * 0.4`
    static func score(severity: Severity, rainfallMM: Double) -> Double {
        let rain = rainfallMM.isFinite ? max(rainfallMM, 0) : 0
        return Double(severity.rawValue) / 5 * 0.6 + min(rain / 100, 1) * 0.4
    }

    /// low < 0.4 ≤ medium < 0.7 ≤ high
    static func level(severity: Severity, rainfallMM: Double) -> RiskLevel {
        let score = score(severity: severity, rainfallMM: rainfallMM)
        if score < 0.4 { return .low }
        if score < 0.7 { return .medium }
        return .high
    }
}
