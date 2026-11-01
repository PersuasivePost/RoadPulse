import CoreData

// MARK: - Trip repository

/// Drive Mode reads and writes. Uses the main-queue `viewContext`; call from the main thread.
final class TripRepository {
    private let persistence: PersistenceController
    private var context: NSManagedObjectContext { persistence.viewContext }

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: Create

    func startTrip(at date: Date = Date()) throws -> Trip {
        let trip = Trip(context: context)
        trip.startedAt = date
        try context.saveIfNeeded()
        return trip
    }

    @discardableResult
    func add(_ span: RoughSpan, to trip: Trip) throws -> RoughSegment? {
        // A span with no position (no GPS fix yet) can't be drawn, so it isn't stored.
        guard let start = span.start ?? span.end, let end = span.end ?? span.start else { return nil }
        let segment = RoughSegment(context: context)
        segment.startLat = start.latitude
        segment.startLon = start.longitude
        segment.endLat = end.latitude
        segment.endLon = end.longitude
        segment.intensity = span.intensity
        segment.timestamp = Date()
        segment.trip = trip
        try context.saveIfNeeded()
        return segment
    }

    func finish(_ trip: Trip, distanceMeters: Double, at date: Date = Date()) throws {
        trip.endedAt = date
        trip.distanceMeters = distanceMeters
        try context.saveIfNeeded()
    }

    // MARK: Read

    func trips() throws -> [Trip] {
        let request = Trip.makeFetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startedAt", ascending: false)]
        return try context.fetch(request)
    }

    func segments() throws -> [RoughSegment] {
        try context.fetch(RoughSegment.makeFetchRequest())
    }

    // MARK: Delete

    func delete(_ trip: Trip) throws {
        context.delete(trip)
        try context.saveIfNeeded()
    }
}
