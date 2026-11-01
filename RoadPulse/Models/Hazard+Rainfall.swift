import CoreData

extension Hazard {
    /// Stores fetched rainfall. Not a user edit, so `updatedAt` is left alone.
    func storeRainfall(_ mm: Double) throws {
        rainfall = mm
        try managedObjectContext?.saveIfNeeded()
    }

    /// False once the object was deleted or its context went away.
    var isLive: Bool {
        !isDeleted && managedObjectContext != nil
    }
}
