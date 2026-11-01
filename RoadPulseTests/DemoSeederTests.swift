import CoreData
import XCTest
@testable import RoadPulse

final class DemoSeederTests: XCTestCase {
    func testSeedsTwentyFiveHazardsAcrossFiveAreas() throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)

        try DemoSeeder.seed(in: store.viewContext)

        XCTAssertEqual(try repo.count(), 25)
        let areas = try repo.areas()
        XCTAssertEqual(Set(areas.map(\.name)), ["Kalyan", "Dombivli", "Thane", "Ghatkopar", "Vidyavihar"])
        XCTAssertTrue(areas.allSatisfy { $0.hazards.count == 5 })
        XCTAssertGreaterThan(try repo.count(HazardQuery(status: .fixed)), 0)
        XCTAssertGreaterThan(try repo.count(HazardQuery(severity: Severity.severe ... Severity.severe)), 0)
    }

    func testSeedIfEmptyOnlySeedsOnce() throws {
        let store = TestStore.make()
        XCTAssertTrue(try DemoSeeder.seedIfEmpty(in: store.viewContext))
        XCTAssertFalse(try DemoSeeder.seedIfEmpty(in: store.viewContext))
        XCTAssertEqual(try store.viewContext.count(for: Hazard.makeFetchRequest()), 25)
    }

    func testPreviewStoreIsSeeded() throws {
        let count = try PersistenceController.preview.viewContext.count(for: Hazard.makeFetchRequest())
        XCTAssertEqual(count, 25)
    }
}
