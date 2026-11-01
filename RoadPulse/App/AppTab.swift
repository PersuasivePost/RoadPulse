import Foundation

// MARK: - Tabs

/// The five root tabs. Stored as the raw `String` in `@SceneStorage`.
enum AppTab: String, CaseIterable, Identifiable {
    case map, report, hazards, insights, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .map: return "Map"
        case .report: return "Report"
        case .hazards: return "Hazards"
        case .insights: return "Insights"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .map: return "map.fill"
        case .report: return "camera.viewfinder"
        case .hazards: return "list.bullet.rectangle.fill"
        case .insights: return "chart.bar.xaxis"
        case .settings: return "gearshape.fill"
        }
    }

    /// Shown by `PlaceholderScreen` until the real screen ships.
    var placeholderMessage: String {
        switch self {
        case .map: return "The hazard map is on its way."
        case .report: return "Photograph a hazard and let the on-device AI check it. Coming soon."
        case .hazards: return "Every report you make will be listed here. Coming soon."
        case .insights: return "Charts of the worst stretches near you. Coming soon."
        case .settings: return ""
        }
    }

    /// Restores a tab from stored text; anything unrecognised falls back to the map.
    static func resolve(_ raw: String) -> AppTab {
        AppTab(rawValue: raw) ?? .map
    }
}
