import CoreData
import CoreLocation

// MARK: - RoughSegment (Core Data entity)

/// A stretch of road where Drive Mode measured vibration above the threshold.
final class RoughSegment: NSManagedObject {
    static let entityName = "RoughSegment"

    static func makeFetchRequest() -> NSFetchRequest<RoughSegment> {
        NSFetchRequest<RoughSegment>(entityName: entityName)
    }

    // MARK: Stored attributes

    @NSManaged var startLat: Double
    @NSManaged var startLon: Double
    @NSManaged var endLat: Double
    @NSManaged var endLon: Double
    /// 0–1, where 1 = RMS of 1 g.
    @NSManaged var intensity: Double
    @NSManaged var timestamp: Date

    // MARK: Relationships

    @NSManaged var trip: Trip?

    // MARK: Lifecycle

    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: "timestamp")
    }

    // MARK: Derived

    var coordinates: [CLLocationCoordinate2D] {
        [CLLocationCoordinate2D(latitude: startLat, longitude: startLon),
         CLLocationCoordinate2D(latitude: endLat, longitude: endLon)]
    }
}
