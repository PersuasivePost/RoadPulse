import XCTest
@testable import RoadPulse

final class AppStateTests: XCTestCase {
    private func freshDefaults(minSeverity: Int? = nil) -> UserDefaults {
        let name = "roadpulse.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        if let minSeverity {
            defaults.set(minSeverity, forKey: SettingsKey.defaultMinSeverity)
        }
        return defaults
    }

    // MARK: Initial state

    func testStartsWithNoFiltersByDefault() {
        let state = AppState(defaults: freshDefaults())
        XCTAssertEqual(state.minSeverity, .minor)
        XCTAssertFalse(state.hasActiveFilters)
        XCTAssertNil(state.query.predicate)
        XCTAssertFalse(state.isDriveActive)
        XCTAssertNil(state.selectedHazardID)
    }

    func testStartsAtSettingsDefaultSeverity() {
        let state = AppState(defaults: freshDefaults(minSeverity: 3))
        XCTAssertEqual(state.minSeverity, .medium)
        XCTAssertTrue(state.hasActiveFilters)
    }

    func testOutOfRangeStoredSeverityIsClamped() {
        XCTAssertEqual(AppState(defaults: freshDefaults(minSeverity: 99)).minSeverity, .severe)
        XCTAssertEqual(AppState(defaults: freshDefaults(minSeverity: -4)).minSeverity, .minor)
    }

    // MARK: Filters → query

    func testQueryReflectsFilters() {
        let state = AppState(defaults: freshDefaults())
        state.minSeverity = .high
        state.statusFilter = .open

        XCTAssertEqual(state.query.severity, Severity.high ... Severity.severe)
        XCTAssertEqual(state.query.status, .open)
        XCTAssertNotNil(state.query.predicate)
    }

    func testClearFiltersResetsEverything() {
        let state = AppState(defaults: freshDefaults(minSeverity: 4))
        state.statusFilter = .fixed

        state.clearFilters()

        XCTAssertFalse(state.hasActiveFilters)
        XCTAssertNil(state.query.predicate)
    }

    /// The AppState query must actually filter Core Data, not just build a predicate.
    func testQueryFiltersRealHazards() throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)
        try repo.create(TestStore.draft(severity: .low))
        try repo.create(TestStore.draft(severity: .severe))
        try repo.create(TestStore.draft(severity: .high, status: .fixed))

        let state = AppState(defaults: freshDefaults())
        state.minSeverity = .high
        XCTAssertEqual(try repo.count(state.query), 2)

        state.statusFilter = .open
        XCTAssertEqual(try repo.count(state.query), 1)
    }

    // MARK: Showing a hazard on the map

    func testShowOnMapSelectsHazardClearsFiltersAndRequestsMapTab() {
        let state = AppState(defaults: freshDefaults(minSeverity: 4))
        state.statusFilter = .fixed
        let id = UUID()

        state.showOnMap(id)

        XCTAssertEqual(state.selectedHazardID, id)
        XCTAssertEqual(state.requestedTab, .map)
        XCTAssertFalse(state.hasActiveFilters, "a filter must not hide the pin we're jumping to")
    }
}
