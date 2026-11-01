import Foundation

// MARK: - List or gallery

/// How the Hazards tab shows its reports. Stored as text in `@AppStorage`.
enum HazardsLayout: String, CaseIterable, Identifiable {
    case list, grid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .list: return "List"
        case .grid: return "Gallery"
        }
    }

    var symbol: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}
