import CoreData

// MARK: - Area (Core Data entity)

/// A neighbourhood that groups hazards (e.g. "Ghatkopar"). Deleting an Area cascades to its hazards.
final class Area: NSManagedObject {
    static let entityName = "Area"

    static func makeFetchRequest() -> NSFetchRequest<Area> {
        NSFetchRequest<Area>(entityName: entityName)
    }

    // MARK: Stored attributes

    @NSManaged var name: String
    @NSManaged var city: String
    @NSManaged var ward: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double

    // MARK: Relationships

    @NSManaged var hazards: Set<Hazard>

    // MARK: Derived

    var openHazardCount: Int {
        hazards.filter { !$0.isFixed }.count
    }

    // MARK: Find or create

    /// Returns the Area with this name in `city` (case-insensitive), creating it if needed.
    /// Works on any context, so the report flow can call it from a background save.
    static func findOrCreate(
        name: String,
        city: String,
        ward: String? = nil,
        latitude: Double,
        longitude: Double,
        in context: NSManagedObjectContext
    ) throws -> Area {
        let request = makeFetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@ AND city ==[c] %@", name, city)
        request.fetchLimit = 1
        if let existing = try context.fetch(request).first {
            return existing
        }
        let area = Area(context: context)
        area.name = name
        area.city = city
        area.ward = ward
        area.latitude = latitude
        area.longitude = longitude
        return area
    }
}
