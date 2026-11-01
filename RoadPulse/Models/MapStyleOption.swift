import Foundation

// MARK: - Map style setting

/// Stored as its raw `String` by `@AppStorage`. F4 maps it onto MapKit's `MapStyle`.
enum MapStyleOption: String, CaseIterable, Identifiable {
    case standard, hybrid, imagery

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Standard"
        case .hybrid: return "Hybrid"
        case .imagery: return "Satellite"
        }
    }
}
