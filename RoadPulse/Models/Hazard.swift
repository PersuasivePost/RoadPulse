import CoreData
import CoreLocation

// MARK: - Hazard (Core Data entity)

/// One reported road hazard. Attributes match `ModelBuilder.hazardEntity()`.
final class Hazard: NSManagedObject {
    static let entityName = "Hazard"

    static func makeFetchRequest() -> NSFetchRequest<Hazard> {
        NSFetchRequest<Hazard>(entityName: entityName)
    }

    // MARK: Stored attributes

    @NSManaged var id: UUID
    @NSManaged var type: String
    @NSManaged var severity: Int16
    @NSManaged var confidence: Double
    @NSManaged var status: String
    @NSManaged var notes: String?
    @NSManaged var landmark: String?
    @NSManaged var photo: Data?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var address: String?
    /// 7-day rainfall in mm; `nil` = unknown. Optional NSNumber rather than a NaN Double
    /// because SQLite stores NaN as NULL, which would read back as 0.
    @NSManaged var rainfallMM: NSNumber?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date

    // MARK: Relationships

    @NSManaged var area: Area?

    // MARK: Lifecycle

    override func awakeFromInsert() {
        super.awakeFromInsert()
        let now = Date()
        setPrimitiveValue(UUID(), forKey: "id")
        setPrimitiveValue(now, forKey: "createdAt")
        setPrimitiveValue(now, forKey: "updatedAt")
    }

    // MARK: Typed accessors

    var hazardType: HazardType {
        get { HazardType(rawValue: type) ?? .pothole }
        set { type = newValue.rawValue }
    }

    var hazardStatus: HazardStatus {
        get { HazardStatus(rawValue: status) ?? .open }
        set { status = newValue.rawValue }
    }

    var severityLevel: Severity {
        get { Severity(clamping: Int(severity)) }
        set { severity = newValue.rawValue }
    }

    var rainfall: Double? {
        get { rainfallMM?.doubleValue }
        set { rainfallMM = newValue.map { NSNumber(value: $0) } }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isFixed: Bool { hazardStatus == .fixed }
}
