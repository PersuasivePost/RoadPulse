import Foundation

// MARK: - Hazard type

/// Stored as a `String` on `Hazard.type` so new cases never need a migration.
enum HazardType: String, CaseIterable, Identifiable {
    case pothole, crack, waterlogging, debris

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pothole: return "Pothole"
        case .crack: return "Crack"
        case .waterlogging: return "Waterlogging"
        case .debris: return "Debris"
        }
    }

    /// SF Symbol drawn inside map pins and badges.
    var symbol: String {
        switch self {
        case .pothole: return "exclamationmark.triangle.fill"
        case .crack: return "line.diagonal"
        case .waterlogging: return "drop.fill"
        case .debris: return "shippingbox.fill"
        }
    }
}
