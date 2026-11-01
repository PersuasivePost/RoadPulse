import Foundation

// MARK: - Units setting

/// Metric or imperial display. Data is always stored in metres / millimetres.
enum UnitSystem: String, CaseIterable, Identifiable {
    case metric, imperial

    var id: String { rawValue }

    var label: String {
        switch self {
        case .metric: return "Metric (km, mm)"
        case .imperial: return "Imperial (mi, in)"
        }
    }

    // MARK: Formatting

    /// "250 m", "1.5 km", "328 ft", "1.2 mi". Invalid input shows an en dash.
    func distance(meters: Double) -> String {
        guard meters.isFinite, meters >= 0 else { return "–" }
        switch self {
        case .metric:
            let rounded = meters.rounded()
            return rounded < 1000 ? "\(Int(rounded)) m" : String(format: "%.1f km", meters / 1000)
        case .imperial:
            let feet = (meters * 3.28084).rounded()
            return feet < 1000 ? "\(Int(feet)) ft" : String(format: "%.1f mi", meters / 1609.344)
        }
    }

    /// "182 mm" or "7.2 in".
    func rainfall(mm: Double) -> String {
        guard mm.isFinite, mm >= 0 else { return "–" }
        switch self {
        case .metric: return String(format: "%.0f mm", mm)
        case .imperial: return String(format: "%.1f in", mm / 25.4)
        }
    }
}
