import Foundation

// MARK: - App state

/// Cross-screen state shared through `.environmentObject`: map filters, the selected hazard
/// and whether Drive Mode is running. Screens read/write it; nothing here touches Core Data.
final class AppState: ObservableObject {
    // MARK: Published state

    /// Lowest severity shown (1 = everything). Starts at the Settings default.
    @Published var minSeverity: Severity
    @Published var statusFilter: HazardStatus?
    @Published var selectedHazardID: UUID?
    @Published var isDriveActive = false
    /// Set by code that wants another tab shown (e.g. after saving a report); RootTabView
    /// switches to it and clears the request.
    @Published var requestedTab: AppTab?

    // MARK: Init

    init(defaults: UserDefaults = .standard) {
        let stored = defaults.object(forKey: SettingsKey.defaultMinSeverity) as? Int
        minSeverity = Severity(clamping: stored ?? SettingsKey.Default.minSeverity)
    }

    // MARK: Filters → predicate

    var query: HazardQuery {
        var query = HazardQuery()
        if minSeverity > .minor {
            query.severity = minSeverity ... Severity.severe
        }
        query.status = statusFilter
        return query
    }

    var hasActiveFilters: Bool {
        minSeverity > .minor || statusFilter != nil
    }

    /// Filter chips: tapping the active one switches it off.
    func toggleMinSeverity(_ severity: Severity) {
        minSeverity = minSeverity == severity ? .minor : severity
    }

    func toggleStatus(_ status: HazardStatus) {
        statusFilter = statusFilter == status ? nil : status
    }

    /// Jumps to the Map with this hazard selected. Filters are cleared so its pin is visible.
    func showOnMap(_ id: UUID) {
        clearFilters()
        selectedHazardID = id
        requestedTab = .map
    }

    func clearFilters() {
        minSeverity = .minor
        statusFilter = nil
    }
}
