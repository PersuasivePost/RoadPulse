import CoreData
import XCTest
@testable import RoadPulse

final class HazardRepositoryTests: XCTestCase {
    // MARK: Create / read

    func testCreatePersistsAllFields() throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)
        var draft = TestStore.draft(.crack, severity: .high, notes: "Near the bus stop", landmark: "LBS Marg")
        draft.confidence = 0.91
        draft.address = "LBS Marg, Ghatkopar"
        draft.rainfallMM = 123.5
        draft.photo = Data([0x1, 0x2, 0x3])

        let created = try repo.create(draft)
        store.viewContext.reset() // force a real read back from the store
        let fetched = try XCTUnwrap(repo.hazard(id: created.id))

        XCTAssertEqual(fetched.hazardType, .crack)
        XCTAssertEqual(fetched.severityLevel, .high)
        XCTAssertEqual(fetched.confidence, 0.91, accuracy: 0.0001)
        XCTAssertEqual(fetched.hazardStatus, .open)
        XCTAssertEqual(fetched.notes, "Near the bus stop")
        XCTAssertEqual(fetched.landmark, "LBS Marg")
        XCTAssertEqual(fetched.address, "LBS Marg, Ghatkopar")
        XCTAssertEqual(fetched.rainfall ?? -1, 123.5, accuracy: 0.0001)
        XCTAssertEqual(fetched.photo, Data([0x1, 0x2, 0x3]))
        XCTAssertEqual(fetched.area?.name, "Ghatkopar")
    }

    func testUnknownRainfallStaysNil() throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)
        let created = try repo.create(TestStore.draft())
        store.viewContext.reset()
        XCTAssertNil(try XCTUnwrap(repo.hazard(id: created.id)).rainfall)
    }

    func testAreaIsReusedCaseInsensitively() throws {
        let repo = HazardRepository(persistence: TestStore.make())
        try repo.create(TestStore.draft(area: "Ghatkopar"))
        try repo.create(TestStore.draft(area: "ghatkopar"))
        try repo.create(TestStore.draft(area: "Thane"))

        let areas = try repo.areas()
        XCTAssertEqual(areas.map(\.name), ["Ghatkopar", "Thane"])
        XCTAssertEqual(areas.first?.hazards.count, 2)
    }

    // MARK: Update

    func testUpdateChangesFieldsAndStampsUpdatedAt() throws {
        let repo = HazardRepository(persistence: TestStore.make())
        let hazard = try repo.create(TestStore.draft(createdAt: Date(timeIntervalSinceNow: -3600)))
        let before = hazard.updatedAt

        try repo.update(hazard) { $0.notes = "Edited" }
        try repo.setStatus(.fixed, for: hazard)

        let fetched = try XCTUnwrap(repo.hazard(id: hazard.id))
        XCTAssertEqual(fetched.notes, "Edited")
        XCTAssertTrue(fetched.isFixed)
        XCTAssertGreaterThan(fetched.updatedAt, before)
    }

    // MARK: Delete

    func testDeleteRemovesHazardButKeepsArea() throws {
        let repo = HazardRepository(persistence: TestStore.make())
        let keep = try repo.create(TestStore.draft())
        let remove = try repo.create(TestStore.draft())

        try repo.delete(remove)

        XCTAssertEqual(try repo.count(), 1)
        XCTAssertEqual(try repo.areas().first?.hazards, [keep])
    }

    func testDeleteAllClearsHazardsAndAreas() throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)
        try DemoSeeder.seed(in: store.viewContext)
        try repo.create(TestStore.draft(area: nil)) // orphan hazard

        try repo.deleteAll()

        XCTAssertEqual(try repo.count(), 0)
        XCTAssertEqual(try repo.areas().count, 0)
    }

    // MARK: Validation

    func testSaveFailureSurfacesFriendlyError() throws {
        let store = TestStore.make()
        _ = Area(context: store.viewContext) // name and city are required, so save must fail

        XCTAssertThrowsError(try store.viewContext.saveIfNeeded()) { error in
            guard case .saveFailed = error as? PersistenceError else {
                return XCTFail("Expected PersistenceError.saveFailed, got \(error)")
            }
            XCTAssertNotNil((error as? LocalizedError)?.errorDescription)
        }
        XCTAssertFalse(store.viewContext.hasChanges, "Failed save should roll back")
    }
}
