import CoreData

// MARK: - Trip (Core Data entity)

/// One Drive Mode session. Deleting a Trip cascades to its rough segments.
final class Trip: NSManagedObject {
    static let entityName = "Trip"

    static func makeFetchRequest() -> NSFetchRequest<Trip> {
        NSFetchRequest<Trip>(entityName: entityName)
    }

    // MARK: Stored attributes

    @NSManaged var id: UUID
    @NSManaged var startedAt: Date
    @NSManaged var endedAt: Date?
    @NSManaged var distanceMeters: Double

    // MARK: Relationships

    @NSManaged var roughSegments: Set<RoughSegment>

    // MARK: Lifecycle

    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(Date(), forKey: "startedAt")
    }

    // MARK: Derived

    var segmentsInOrder: [RoughSegment] {
        roughSegments.sorted { $0.timestamp < $1.timestamp }
    }
}
