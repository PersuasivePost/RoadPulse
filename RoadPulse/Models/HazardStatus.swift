import Foundation

// MARK: - Hazard status

/// Stored as a `String` on `Hazard.status`.
enum HazardStatus: String, CaseIterable, Identifiable {
    case open, fixed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .open: return "Open"
        case .fixed: return "Fixed"
        }
    }
}
