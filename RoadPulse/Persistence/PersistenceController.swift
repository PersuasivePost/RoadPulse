import CoreData

// MARK: - Persistence controller

/// Owns the Core Data stack.
/// - UI reads use `viewContext` (main queue).
/// - Writes go through `performBackgroundTask` / `newBackgroundContext()`; the view context
///   merges those saves automatically.
final class PersistenceController {
    static let shared = PersistenceController()

    /// In-memory store pre-filled with demo hazards, for SwiftUI previews.
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        try? DemoSeeder.seed(in: controller.viewContext)
        return controller
    }()

    let container: NSPersistentContainer

    /// Set when the store failed to load; the UI shows `errorDescription` instead of crashing.
    private(set) var loadError: PersistenceError?

    var viewContext: NSManagedObjectContext { container.viewContext }

    // MARK: Init

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RoadPulse", managedObjectModel: ModelBuilder.model)

        let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        if inMemory {
            // An SQLite store at /dev/null lives only in memory but behaves like the real store.
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        // Lightweight migration (see ModelBuilder for how a v2 model is added).
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        var failure: Error?
        container.loadPersistentStores { _, error in
            failure = error
        }
        loadError = failure.map { PersistenceError.storeUnavailable($0.localizedDescription) }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.name = "viewContext"
    }

    // MARK: Background work

    /// A private-queue context for long-lived background work (e.g. a Drive Mode trip).
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Runs `block` on a fresh private-queue context. Save inside the block.
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await container.performBackgroundTask { (context) throws -> T in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return try block(context)
        }
    }
}

// MARK: - Saving

extension NSManagedObjectContext {
    /// Saves only when there are changes; wraps failures in a user-friendly error.
    func saveIfNeeded() throws {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            rollback()
            throw PersistenceError.saveFailed(error.localizedDescription)
        }
    }
}
