import CoreData
import XCTest
@testable import RoadPulse

final class PersistenceControllerTests: XCTestCase {
    // MARK: Model

    func testModelHasAllEntitiesAndRelationships() {
        let entities = ModelBuilder.model.entitiesByName
        XCTAssertEqual(Set(entities.keys), ["Area", "Hazard", "Trip", "RoughSegment"])

        let areaHazards = entities["Area"]?.relationshipsByName["hazards"]
        XCTAssertEqual(areaHazards?.isToMany, true)
        XCTAssertEqual(areaHazards?.deleteRule, .cascadeDeleteRule)
        XCTAssertEqual(areaHazards?.inverseRelationship?.name, "area")
        XCTAssertEqual(entities["Hazard"]?.relationshipsByName["area"]?.deleteRule, .nullifyDeleteRule)
        XCTAssertEqual(entities["Trip"]?.relationshipsByName["roughSegments"]?.deleteRule, .cascadeDeleteRule)
        XCTAssertEqual(entities["Hazard"]?.attributesByName["photo"]?.allowsExternalBinaryDataStorage, true)
        XCTAssertEqual(ModelBuilder.model.versionIdentifiers, ["\(ModelBuilder.modelVersion)"])
    }

    func testStoreUsesLightweightMigration() {
        let description = TestStore.make().container.persistentStoreDescriptions.first
        XCTAssertEqual(description?.shouldMigrateStoreAutomatically, true)
        XCTAssertEqual(description?.shouldInferMappingModelAutomatically, true)
    }

    // MARK: Cascade delete

    func testDeletingAreaCascadesToHazards() throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)
        try repo.create(TestStore.draft(area: "Thane"))
        try repo.create(TestStore.draft(area: "Thane"))
        try repo.create(TestStore.draft(area: "Ghatkopar"))

        let thane = try XCTUnwrap(repo.areas().first { $0.name == "Thane" })
        store.viewContext.delete(thane)
        try store.viewContext.saveIfNeeded()

        XCTAssertEqual(try repo.count(), 1)
        XCTAssertEqual(try repo.fetch().first?.area?.name, "Ghatkopar")
    }

    func testDeletingTripCascadesToSegments() throws {
        let context = TestStore.make().viewContext
        let trip = Trip(context: context)
        for _ in 0..<3 {
            RoughSegment(context: context).trip = trip
        }
        try context.saveIfNeeded()
        XCTAssertEqual(trip.segmentsInOrder.count, 3)

        context.delete(trip)
        try context.saveIfNeeded()
        XCTAssertEqual(try context.count(for: RoughSegment.makeFetchRequest()), 0)
    }

    // MARK: Background save merging

    /// A hazard already loaded in the view context must reflect a background save without
    /// being re-fetched; that is what `automaticallyMergesChangesFromParent` guarantees.
    @MainActor
    func testBackgroundSaveMergesIntoViewContext() async throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)
        let onMain = try repo.create(TestStore.draft())
        XCTAssertFalse(onMain.isFixed)

        let merged = expectation(forNotification: .NSManagedObjectContextObjectsDidChange,
                                 object: store.viewContext)
        let objectID = onMain.objectID
        try await store.performBackgroundTask { (context) throws -> Void in
            let hazard = try XCTUnwrap(context.existingObject(with: objectID) as? Hazard)
            hazard.hazardStatus = .fixed
            try context.saveIfNeeded()
        }
        await fulfillment(of: [merged], timeout: 2)

        XCTAssertTrue(onMain.isFixed, "view-context object should be updated in place")
    }

    @MainActor
    func testCreateInBackgroundIsVisibleOnViewContext() async throws {
        let store = TestStore.make()
        let repo = HazardRepository(persistence: store)

        let objectID = try await repo.createInBackground(TestStore.draft(area: "Dombivli"))

        let hazard = try XCTUnwrap(repo.hazard(objectID: objectID))
        XCTAssertEqual(hazard.area?.name, "Dombivli")
        XCTAssertFalse(objectID.isTemporaryID)
    }
}
