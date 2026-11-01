import CoreData
import XCTest
@testable import RoadPulse

final class HazardQueryTests: XCTestCase {
    private var repo: HazardRepository!
    private let now = Date()

    override func setUpWithError() throws {
        repo = HazardRepository(persistence: TestStore.make())
        let day: TimeInterval = 86_400
        try repo.create(TestStore.draft(.pothole, severity: .severe, area: "Ghatkopar",
                                        notes: "Deep pothole near LBS Marg", createdAt: now))
        try repo.create(TestStore.draft(.pothole, severity: .high, status: .fixed, area: "Thane",
                                        landmark: "Kopri Bridge", createdAt: now - 3 * day))
        try repo.create(TestStore.draft(.crack, severity: .low, area: "Thane",
                                        notes: "Hairline crack", createdAt: now - 10 * day))
        try repo.create(TestStore.draft(.waterlogging, severity: .medium, area: "Vidyavihar",
                                        notes: "Pâni bharlela rasta", createdAt: now - 30 * day))
    }

    // MARK: Individual filters

    func testEmptyQueryHasNoPredicateAndReturnsAll() throws {
        XCTAssertNil(HazardQuery().predicate)
        XCTAssertEqual(try repo.count(), 4)
    }

    func testSeverityRange() throws {
        XCTAssertEqual(try repo.count(HazardQuery(severity: Severity.high ... Severity.severe)), 2)
        XCTAssertEqual(try repo.count(HazardQuery(severity: Severity.low ... Severity.low)), 1)
    }

    func testStatus() throws {
        XCTAssertEqual(try repo.count(HazardQuery(status: .fixed)), 1)
        XCTAssertEqual(try repo.count(HazardQuery(status: .open)), 3)
    }

    func testType() throws {
        XCTAssertEqual(try repo.count(HazardQuery(type: .pothole)), 2)
    }

    func testAreaIsCaseInsensitive() throws {
        XCTAssertEqual(try repo.count(HazardQuery(areaName: "thane")), 2)
    }

    func testDateRange() throws {
        let lastWeek = now.addingTimeInterval(-7 * 86_400) ... now
        XCTAssertEqual(try repo.count(HazardQuery(dateRange: lastWeek)), 2)
    }

    func testTextSearchCoversNotesLandmarkAndArea() throws {
        XCTAssertEqual(try repo.count(HazardQuery(text: "  POTHOLE ")), 1, "notes, trimmed + case-insensitive")
        XCTAssertEqual(try repo.count(HazardQuery(text: "kopri")), 1, "landmark")
        XCTAssertEqual(try repo.count(HazardQuery(text: "vidya")), 1, "area name")
        XCTAssertEqual(try repo.count(HazardQuery(text: "pani")), 1, "diacritic-insensitive")
    }

    // MARK: Combined + sorting

    func testFiltersCombineWithAnd() throws {
        let query = HazardQuery(severity: Severity.medium ... Severity.severe, status: .open, areaName: "Ghatkopar")
        let results = try repo.fetch(query)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.severityLevel, .severe)
    }

    func testSortOrders() throws {
        let newest = try repo.fetch(HazardQuery(sort: .newest)).map(\.createdAt)
        XCTAssertEqual(newest, newest.sorted(by: >))

        let severities = try repo.fetch(HazardQuery(sort: .mostSevere)).map(\.severity)
        XCTAssertEqual(severities, [5, 4, 3, 2])
    }
}
