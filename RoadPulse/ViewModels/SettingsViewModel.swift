import Foundation

// MARK: - Settings view model

/// Owns the Settings screen's data actions (demo data, delete all) and their feedback text.
/// The toggles and sliders themselves live in `@AppStorage`, not here.
/// Uses the main-queue view context, so call it from the main thread (SwiftUI actions do).
final class SettingsViewModel: ObservableObject {
    // MARK: Published state

    /// Result of the last action, shown under the Data section.
    @Published private(set) var statusMessage: String?
    /// A user-friendly failure message; the screen shows it in an alert and clears it.
    @Published var errorMessage: String?

    private let persistence: PersistenceController
    private let repository: HazardRepository

    // MARK: Init

    init(persistence: PersistenceController) {
        self.persistence = persistence
        repository = HazardRepository(persistence: persistence)
    }

    // MARK: Actions

    func loadDemoData() {
        do {
            let seeded = try DemoSeeder.seedIfEmpty(in: persistence.viewContext)
            statusMessage = seeded
                ? "Loaded \(DemoSeeder.hazards.count) demo hazards."
                : "Demo data not loaded because you already have reports. Delete all reports first to reload it."
        } catch {
            fail(error)
        }
    }

    func deleteAll() {
        do {
            let removed = try repository.count()
            try repository.deleteAll()
            statusMessage = removed == 0
                ? "There were no reports to delete."
                : "Deleted \(removed) report\(removed == 1 ? "" : "s")."
        } catch {
            fail(error)
        }
    }

    // MARK: Errors

    private func fail(_ error: Error) {
        statusMessage = nil
        errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}
