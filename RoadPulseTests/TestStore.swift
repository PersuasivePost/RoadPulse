import CoreData
import XCTest
@testable import RoadPulse

// MARK: - Test helpers

enum TestStore {
    /// A fresh in-memory stack per test, so tests never share data.
    static func make(file: StaticString = #filePath, line: UInt = #line) -> PersistenceController {
        let controller = PersistenceController(inMemory: true)
        XCTAssertNil(controller.loadError, "In-memory store failed to load", file: file, line: line)
        return controller
    }

    static func draft(
        _ type: HazardType = .pothole,
        severity: Severity = .medium,
        status: HazardStatus = .open,
        area: String? = "Ghatkopar",
        notes: String? = nil,
        landmark: String? = nil,
        createdAt: Date = Date()
    ) -> HazardDraft {
        var draft = HazardDraft()
        draft.type = type
        draft.severity = severity
        draft.status = status
        draft.areaName = area
        draft.notes = notes
        draft.landmark = landmark
        draft.latitude = 19.0858
        draft.longitude = 72.9081
        draft.createdAt = createdAt
        return draft
    }
}
