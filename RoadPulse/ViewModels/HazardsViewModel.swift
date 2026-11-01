import CoreData
import Foundation

// MARK: - Hazards view model

/// Search text, sort and the actions behind the Hazards tab. Reads go through `@FetchRequest`s
/// in the views; writes go through the repository. Uses the main-queue view context.
final class HazardsViewModel: ObservableObject {
    // MARK: Published state

    /// Bound to `.searchable`; becomes part of the fetch predicate.
    @Published var searchText = ""
    @Published var sort: HazardQuery.Sort = .newest
    @Published var errorMessage: String?

    private let persistence: PersistenceController
    private let repository: HazardRepository
    private let weather: WeatherProviding

    /// Most hazards fetched per pull-to-refresh, to stay polite to the free API.
    static let backfillLimit = 10

    init(persistence: PersistenceController, weather: WeatherProviding = WeatherService()) {
        self.persistence = persistence
        self.weather = weather
        repository = HazardRepository(persistence: persistence)
    }

    // MARK: Query

    /// The shared filters from `AppState` plus this screen's search and sort.
    func query(filters: HazardQuery) -> HazardQuery {
        var query = filters
        query.text = searchText
        query.sort = sort
        return query
    }

    // MARK: Actions

    func hazard(id: UUID) -> Hazard? {
        try? repository.hazard(id: id)
    }

    func toggleFixed(_ hazard: Hazard) {
        perform { try repository.setStatus(hazard.isFixed ? .open : .fixed, for: hazard) }
    }

    func delete(_ hazard: Hazard) {
        perform { try repository.delete(hazard) }
    }

    func delete(id: UUID) {
        guard let hazard = hazard(id: id) else { return }
        delete(hazard)
    }

    /// Applies the detail screen's edits. Returns whether the save succeeded.
    @discardableResult
    func update(_ hazard: Hazard, with edit: HazardEdit) -> Bool {
        perform { try repository.update(hazard) { edit.apply(to: $0) } }
    }

    /// Pull-to-refresh: re-reads every object from the store, then fetches rainfall (async/await)
    /// for hazards that don't have it yet.
    @MainActor
    func refresh() async {
        persistence.viewContext.refreshAllObjects()
        let missing = ((try? repository.fetch()) ?? []).filter { $0.rainfall == nil }.prefix(Self.backfillLimit)
        var failure: WeatherError?
        var succeeded = false
        for hazard in missing {
            if Task.isCancelled { return }
            do {
                let mm = try await weather.rainfall(latitude: hazard.latitude, longitude: hazard.longitude)
                if hazard.isLive { try hazard.storeRainfall(mm) }
                succeeded = true
            } catch {
                let weatherError = WeatherError.from(error)
                if weatherError == .cancelled { return }
                failure = weatherError
            }
        }
        if !succeeded, let failure {
            errorMessage = failure.errorDescription
        }
    }

    @discardableResult
    private func perform(_ action: () throws -> Void) -> Bool {
        do {
            try action()
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
            return false
        }
    }
}
