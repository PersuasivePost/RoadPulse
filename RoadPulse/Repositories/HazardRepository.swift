import CoreData

// MARK: - Hazard repository

/// All hazard reads and writes go through here, so view models never touch Core Data directly.
/// Synchronous methods use the main-queue `viewContext`; call them from the main thread.
final class HazardRepository {
    private let persistence: PersistenceController
    private var context: NSManagedObjectContext { persistence.viewContext }

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: Create

    @discardableResult
    func create(_ draft: HazardDraft) throws -> Hazard {
        let hazard = try Self.insert(draft, into: context)
        try context.saveIfNeeded()
        return hazard
    }

    /// Saves on a background context (photos can be large). The view context picks the change
    /// up through `automaticallyMergesChangesFromParent`.
    func createInBackground(_ draft: HazardDraft) async throws -> NSManagedObjectID {
        try await persistence.performBackgroundTask { (context) throws -> NSManagedObjectID in
            let hazard = try Self.insert(draft, into: context)
            try context.saveIfNeeded()
            return hazard.objectID
        }
    }

    /// Inserts without saving. Shared by `create`, `createInBackground` and `DemoSeeder`.
    static func insert(_ draft: HazardDraft, into context: NSManagedObjectContext) throws -> Hazard {
        let hazard = Hazard(context: context)
        hazard.hazardType = draft.type
        hazard.severityLevel = draft.severity
        hazard.confidence = draft.confidence
        hazard.hazardStatus = draft.status
        hazard.notes = draft.notes
        hazard.landmark = draft.landmark
        hazard.photo = draft.photo
        hazard.latitude = draft.latitude
        hazard.longitude = draft.longitude
        hazard.address = draft.address
        hazard.rainfall = draft.rainfallMM
        hazard.createdAt = draft.createdAt
        hazard.updatedAt = draft.createdAt
        if let name = draft.areaName?.trimmingCharacters(in: .whitespaces), !name.isEmpty {
            hazard.area = try Area.findOrCreate(name: name, city: draft.city, ward: draft.ward,
                                                latitude: draft.latitude, longitude: draft.longitude,
                                                in: context)
        }
        return hazard
    }

    // MARK: Read

    func fetch(_ query: HazardQuery = HazardQuery()) throws -> [Hazard] {
        try context.fetch(query.fetchRequest())
    }

    func count(_ query: HazardQuery = HazardQuery()) throws -> Int {
        try context.count(for: query.fetchRequest())
    }

    func hazard(id: UUID) throws -> Hazard? {
        let request = Hazard.makeFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func hazard(objectID: NSManagedObjectID) -> Hazard? {
        try? context.existingObject(with: objectID) as? Hazard
    }

    func areas() throws -> [Area] {
        let request = Area.makeFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return try context.fetch(request)
    }

    // MARK: Update

    /// Applies `changes`, stamps `updatedAt` and saves.
    func update(_ hazard: Hazard, _ changes: (Hazard) -> Void) throws {
        changes(hazard)
        hazard.updatedAt = Date()
        try context.saveIfNeeded()
    }

    func setStatus(_ status: HazardStatus, for hazard: Hazard) throws {
        try update(hazard) { $0.hazardStatus = status }
    }

    // MARK: Delete

    func delete(_ hazard: Hazard) throws {
        context.delete(hazard)
        try context.saveIfNeeded()
    }

    /// Removes every hazard and area (areas cascade to their hazards; orphans are deleted too).
    func deleteAll() throws {
        for area in try context.fetch(Area.makeFetchRequest()) {
            context.delete(area)
        }
        for hazard in try context.fetch(Hazard.makeFetchRequest()) {
            context.delete(hazard)
        }
        try context.saveIfNeeded()
    }
}
