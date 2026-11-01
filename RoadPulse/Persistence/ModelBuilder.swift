import CoreData

// MARK: - Programmatic Core Data model

/// Builds the RoadPulse `NSManagedObjectModel` in code (no .xcdatamodeld).
///
/// How a v2 attribute would be added, e.g. `Hazard.reportedBy: String?`:
/// 1. Copy `makeModel()` to `makeModelV1()` and leave it unchanged forever.
/// 2. In `makeModel()`, append `attribute("reportedBy", .stringAttributeType, optional: true)`
///    to the Hazard entity and bump `modelVersion` to 2. Never rename entities or attributes
///    without setting `renamingIdentifier` to the old name.
/// 3. Because there is no .momd in the bundle, Core Data cannot find the v1 model by itself.
///    Register both with an `NSStagedMigrationManager` using an `NSLightweightMigrationStage`
///    (iOS 17) and pass it on the store description under
///    `NSPersistentStoreStagedMigrationManagerOptionKey`. The flags set in
///    `PersistenceController` then infer the mapping (an added optional attribute is lightweight).
enum ModelBuilder {
    static let modelVersion = 1

    /// One shared instance: several models claiming the same classes break `init(context:)`.
    static let model: NSManagedObjectModel = makeModel()

    // MARK: Model

    static func makeModel() -> NSManagedObjectModel {
        let area = entity(Area.entityName, Area.self, [
            attribute("name", .stringAttributeType),
            attribute("city", .stringAttributeType),
            attribute("ward", .stringAttributeType, optional: true),
            attribute("latitude", .doubleAttributeType, default: 0.0),
            attribute("longitude", .doubleAttributeType, default: 0.0),
        ])

        let photo = attribute("photo", .binaryDataAttributeType, optional: true)
        photo.allowsExternalBinaryDataStorage = true
        let hazard = entity(Hazard.entityName, Hazard.self, [
            attribute("id", .UUIDAttributeType),
            attribute("type", .stringAttributeType, default: HazardType.pothole.rawValue),
            attribute("severity", .integer16AttributeType, default: Int16(1)),
            attribute("confidence", .doubleAttributeType, default: 0.0),
            attribute("status", .stringAttributeType, default: HazardStatus.open.rawValue),
            attribute("notes", .stringAttributeType, optional: true),
            attribute("landmark", .stringAttributeType, optional: true),
            photo,
            attribute("latitude", .doubleAttributeType, default: 0.0),
            attribute("longitude", .doubleAttributeType, default: 0.0),
            attribute("address", .stringAttributeType, optional: true),
            attribute("rainfallMM", .doubleAttributeType, optional: true),
            attribute("createdAt", .dateAttributeType),
            attribute("updatedAt", .dateAttributeType),
        ])

        let trip = entity(Trip.entityName, Trip.self, [
            attribute("id", .UUIDAttributeType),
            attribute("startedAt", .dateAttributeType),
            attribute("endedAt", .dateAttributeType, optional: true),
            attribute("distanceMeters", .doubleAttributeType, default: 0.0),
        ])

        let segment = entity(RoughSegment.entityName, RoughSegment.self, [
            attribute("startLat", .doubleAttributeType, default: 0.0),
            attribute("startLon", .doubleAttributeType, default: 0.0),
            attribute("endLat", .doubleAttributeType, default: 0.0),
            attribute("endLon", .doubleAttributeType, default: 0.0),
            attribute("intensity", .doubleAttributeType, default: 0.0),
            attribute("timestamp", .dateAttributeType),
        ])

        // Area ↔ Hazard: deleting an Area deletes its hazards; deleting a Hazard leaves the Area.
        link(area, "hazards", toMany: hazard, deleteRule: .cascadeDeleteRule,
             inverse: "area", inverseDeleteRule: .nullifyDeleteRule)
        // Trip ↔ RoughSegment: same shape.
        link(trip, "roughSegments", toMany: segment, deleteRule: .cascadeDeleteRule,
             inverse: "trip", inverseDeleteRule: .nullifyDeleteRule)

        let model = NSManagedObjectModel()
        model.entities = [area, hazard, trip, segment]
        model.versionIdentifiers = ["\(modelVersion)"]
        return model
    }

    // MARK: Helpers

    private static func entity(
        _ name: String,
        _ type: NSManagedObject.Type,
        _ attributes: [NSAttributeDescription]
    ) -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = name
        entity.managedObjectClassName = NSStringFromClass(type)
        entity.properties = attributes
        return entity
    }

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = false,
        default value: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = value
        return attribute
    }

    /// Adds a to-many relationship on `parent` and its to-one inverse on `child`.
    private static func link(
        _ parent: NSEntityDescription,
        _ name: String,
        toMany child: NSEntityDescription,
        deleteRule: NSDeleteRule,
        inverse inverseName: String,
        inverseDeleteRule inverseRule: NSDeleteRule
    ) {
        let toMany = NSRelationshipDescription()
        toMany.name = name
        toMany.destinationEntity = child
        toMany.minCount = 0
        toMany.maxCount = 0 // 0 = unbounded, i.e. to-many
        toMany.isOptional = true
        toMany.deleteRule = deleteRule

        let toOne = NSRelationshipDescription()
        toOne.name = inverseName
        toOne.destinationEntity = parent
        toOne.minCount = 0
        toOne.maxCount = 1
        toOne.isOptional = true
        toOne.deleteRule = inverseRule

        toMany.inverseRelationship = toOne
        toOne.inverseRelationship = toMany
        parent.properties.append(toMany)
        child.properties.append(toOne)
    }
}
