import CoreLocation
import XCTest
@testable import RoadPulse

// MARK: - Test double

/// Records every query and returns canned results, so no network is involved.
private final class MockGeocoder: GeocodingProviding {
    var queries: [String] = []
    var results: [SearchResult] = []
    var error: Error?

    func geocode(_ query: String) async throws -> [SearchResult] {
        queries.append(query)
        if let error { throw error }
        return results
    }
}

private let thane = SearchResult(name: "Thane", subtitle: "Maharashtra", latitude: 19.2183, longitude: 72.9781)

@MainActor
final class MapViewModelTests: XCTestCase {
    private func makeViewModel(_ geocoder: MockGeocoder, debounce: TimeInterval = 0.05) -> MapViewModel {
        MapViewModel(persistence: TestStore.make(), geocoder: geocoder, debounce: debounce)
    }

    /// Waits until `condition` holds, polling briefly; fails the test on timeout.
    private func wait(_ description: String, timeout: TimeInterval = 3, until condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertTrue(condition(), "Timed out waiting for: \(description)")
    }

    // MARK: Search

    func testSearchFindsPlaceAndPublishesIt() async {
        let geocoder = MockGeocoder()
        geocoder.results = [thane]
        let viewModel = makeViewModel(geocoder)

        viewModel.searchText = "Thane"
        await wait("result") { viewModel.searchResult != nil }

        XCTAssertEqual(viewModel.searchResult, thane)
        XCTAssertEqual(viewModel.searchState, .found("Thane, Maharashtra"))
        XCTAssertEqual(viewModel.searchState.message, "Showing Thane, Maharashtra")
    }

    func testTypingIsDebouncedToASingleSearch() async {
        let geocoder = MockGeocoder()
        geocoder.results = [thane]
        let viewModel = makeViewModel(geocoder, debounce: 0.15)

        for text in ["Tha", "Than", "Thane"] {
            viewModel.searchText = text
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        await wait("result") { viewModel.searchResult != nil }

        XCTAssertEqual(geocoder.queries, ["Thane"], "only the final text should be geocoded")
    }

    func testShortQueriesAreNotSearched() async {
        let geocoder = MockGeocoder()
        let viewModel = makeViewModel(geocoder)

        viewModel.search("Th")

        XCTAssertTrue(geocoder.queries.isEmpty)
        XCTAssertEqual(viewModel.searchState, .idle)
    }

    func testNoResultsShowsNotFound() async {
        let geocoder = MockGeocoder()
        let viewModel = makeViewModel(geocoder)

        viewModel.search("Nowhereville")
        await wait("notFound") { viewModel.searchState == .notFound }

        XCTAssertNil(viewModel.searchResult)
        XCTAssertNotNil(viewModel.searchState.message)
    }

    func testNetworkFailureShowsFriendlyMessage() async {
        let geocoder = MockGeocoder()
        geocoder.error = CLError(.network)
        let viewModel = makeViewModel(geocoder)

        viewModel.search("Thane")
        await wait("failure") { viewModel.searchState == .failed("Search needs an internet connection.") }
    }

    func testOtherFailuresUseGenericMessage() {
        XCTAssertEqual(MapViewModel.message(for: CLError(.geocodeFoundNoResult)),
                       "Couldn't search right now. Please try again.")
    }

    func testSubmitSkipsDebounceAndIsNotRepeatedByIt() async {
        let geocoder = MockGeocoder()
        geocoder.results = [thane]
        let viewModel = makeViewModel(geocoder, debounce: 0.1)

        viewModel.searchText = "Thane"
        viewModel.submitSearch() // immediately, without waiting 0.1 s
        await wait("result") { viewModel.searchResult != nil }
        try? await Task.sleep(nanoseconds: 250_000_000) // let the debounce fire too

        XCTAssertEqual(geocoder.queries, ["Thane"], "the debounced repeat must not search again")
    }

    func testClearingTextReturnsToIdle() async {
        let geocoder = MockGeocoder()
        geocoder.results = [thane]
        let viewModel = makeViewModel(geocoder)
        viewModel.searchText = "Thane"
        await wait("found") { viewModel.searchResult != nil }

        viewModel.searchText = ""
        await wait("idle") { viewModel.searchState == .idle }
    }

    // MARK: Hazard actions

    func testToggleFixedFlipsStatusBothWays() throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)
        let hazard = try repo.create(TestStore.draft())
        let viewModel = MapViewModel(persistence: store, geocoder: MockGeocoder())

        viewModel.toggleFixed(hazard)
        XCTAssertTrue(hazard.isFixed)
        viewModel.toggleFixed(hazard)
        XCTAssertFalse(hazard.isFixed)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteRemovesHazardAndLookupReturnsNil() throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)
        let hazard = try repo.create(TestStore.draft())
        let id = hazard.id
        let viewModel = MapViewModel(persistence: store, geocoder: MockGeocoder())
        XCTAssertNotNil(viewModel.hazard(id: id))

        viewModel.delete(hazard)

        XCTAssertNil(viewModel.hazard(id: id))
        XCTAssertEqual(try repo.count(), 0)
    }
}
