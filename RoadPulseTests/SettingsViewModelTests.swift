import XCTest
@testable import RoadPulse

final class SettingsViewModelTests: XCTestCase {
    func testLoadDemoDataSeedsAnEmptyStore() throws {
        let store = TestStore.make()
        let viewModel = SettingsViewModel(persistence: store)

        viewModel.loadDemoData()

        XCTAssertEqual(try HazardRepository(persistence: store).count(), DemoSeeder.hazards.count)
        XCTAssertEqual(viewModel.statusMessage, "Loaded 25 demo hazards.")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadDemoDataDoesNotDuplicateExistingReports() throws {
        let store = TestStore.make()
        let viewModel = SettingsViewModel(persistence: store)
        viewModel.loadDemoData()

        viewModel.loadDemoData()

        XCTAssertEqual(try HazardRepository(persistence: store).count(), 25)
        XCTAssertTrue(viewModel.statusMessage?.contains("already have reports") == true)
    }

    func testDeleteAllClearsStoreAndReportsCount() throws {
        let store = TestStore.make()
        let viewModel = SettingsViewModel(persistence: store)
        viewModel.loadDemoData()

        viewModel.deleteAll()

        let repo = HazardRepository(persistence: store)
        XCTAssertEqual(try repo.count(), 0)
        XCTAssertEqual(try repo.areas().count, 0)
        XCTAssertEqual(viewModel.statusMessage, "Deleted 25 reports.")
    }

    func testDeleteAllOnEmptyStoreSaysSo() {
        let viewModel = SettingsViewModel(persistence: TestStore.make())
        viewModel.deleteAll()
        XCTAssertEqual(viewModel.statusMessage, "There were no reports to delete.")
    }

    func testDeleteSingleReportUsesSingularWording() throws {
        let store = TestStore.make()
        try HazardRepository(persistence: store).create(TestStore.draft())
        let viewModel = SettingsViewModel(persistence: store)

        viewModel.deleteAll()

        XCTAssertEqual(viewModel.statusMessage, "Deleted 1 report.")
    }
}
