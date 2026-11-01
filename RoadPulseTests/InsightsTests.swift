import CoreLocation
import XCTest
@testable import RoadPulse

@MainActor
final class InsightsTests: XCTestCase {
    private let ghatkopar = CLLocationCoordinate2D(latitude: 19.0858, longitude: 72.9081)

    private func hazards(_ drafts: [HazardDraft]) throws -> (PersistenceController, [Hazard]) {
        let store = TestStore.make()
        let repository = HazardRepository(persistence: store)
        return (store, try drafts.map { try repository.create($0) })
    }

    // MARK: Stats

    func testTotalsAverageAndFixedShare() throws {
        let (_, list) = try hazards([
            TestStore.draft(severity: .severe),
            TestStore.draft(severity: .low, status: .fixed),
            TestStore.draft(severity: .medium),
            TestStore.draft(severity: .minor, status: .fixed),
        ])
        let stats = InsightsStats(hazards: list, origin: ghatkopar)
        XCTAssertEqual(stats.total, 4)
        XCTAssertEqual(stats.open, 2)
        XCTAssertEqual(stats.fixed, 2)
        XCTAssertEqual(stats.fixedPercent, 50, accuracy: 0.001)
        XCTAssertEqual(stats.averageSeverity, 2.75, accuracy: 0.001) // (5 + 2 + 3 + 1) / 4
    }

    func testEmptyStatsAreZeroNotNaN() {
        let stats = InsightsStats(hazards: [], origin: ghatkopar)
        XCTAssertEqual(stats.total, 0)
        XCTAssertEqual(stats.averageSeverity, 0)
        XCTAssertEqual(stats.fixedPercent, 0)
        XCTAssertTrue(stats.perArea.isEmpty)
        XCTAssertTrue(stats.worstRoads.isEmpty)
        XCTAssertEqual(stats.severityCounts.count, 5)
    }

    func testPerAreaCountsAreSortedAndIncludeUnassigned() throws {
        let (_, list) = try hazards([
            TestStore.draft(area: "Thane"), TestStore.draft(area: "Kalyan"), TestStore.draft(area: "Kalyan"),
            TestStore.draft(area: nil),
        ])
        let stats = InsightsStats(hazards: list, origin: ghatkopar)
        XCTAssertEqual(stats.perArea.map(\.name), ["Kalyan", "Thane", "Unassigned"])
        XCTAssertEqual(stats.perArea.map(\.count), [2, 1, 1])
    }

    func testSeverityCountsCoverEveryLevel() throws {
        let (_, list) = try hazards([TestStore.draft(severity: .high), TestStore.draft(severity: .high),
                                     TestStore.draft(severity: .minor)])
        let counts = InsightsStats(hazards: list, origin: ghatkopar).severityCounts
        XCTAssertEqual(counts.map(\.count), [1, 0, 0, 2, 0])
    }

    // MARK: Worst roads

    func testWorstRoadsWeighSeverityByDistanceAndSkipFixed() throws {
        var near = TestStore.draft(severity: .severe, area: "Near")
        near.latitude = ghatkopar.latitude
        near.longitude = ghatkopar.longitude
        var far = TestStore.draft(severity: .severe, area: "Far")
        far.latitude = 19.2403 // Kalyan, roughly 25 km away
        far.longitude = 73.1305
        var fixed = TestStore.draft(severity: .severe, status: .fixed, area: "Fixed")
        fixed.latitude = ghatkopar.latitude
        fixed.longitude = ghatkopar.longitude
        let (_, list) = try hazards([far, near, fixed])
        let roads = InsightsStats.worstRoads(hazards: list, origin: ghatkopar)
        XCTAssertEqual(roads.map(\.name), ["Near", "Far"])
        XCTAssertEqual(roads[0].score, 5, accuracy: 0.01) // 5 / (1 + 0 km)
        XCTAssertLessThan(roads[1].score, 1)
        XCTAssertEqual(roads[0].openCount, 1)
    }

    func testWorstRoadsAreCappedAtFive() throws {
        let (_, list) = try hazards((0 ..< 8).map { TestStore.draft(area: "Area \($0)") })
        XCTAssertEqual(InsightsStats.worstRoads(hazards: list, origin: ghatkopar).count, 5)
    }

    // MARK: Donut

    func testDonutFractionsSumToOneAndSkipNothing() {
        let fractions = DonutGeometry.fractions(for: [1, 1, 2])
        XCTAssertEqual(fractions[0], 0 ... 0.25)
        XCTAssertEqual(fractions[2].upperBound, 1, accuracy: 0.0001)
        XCTAssertEqual(DonutGeometry.fractions(for: [0, 0]), [0 ... 0, 0 ... 0])
    }

    func testDonutHitTestFindsTheSliceUnderTheTap() {
        let size = CGSize(width: 100, height: 100)
        let counts = [1, 1, 2] // quarter, quarter, half
        // Ring is 20 pt wide: radius 30...50 from the centre. Top-right of the ring = first slice.
        XCTAssertEqual(DonutGeometry.sliceIndex(at: CGPoint(x: 70, y: 20), in: size, ringWidth: 20, counts: counts), 0)
        // Bottom-right = second slice (3 o'clock to 6 o'clock).
        XCTAssertEqual(DonutGeometry.sliceIndex(at: CGPoint(x: 80, y: 80), in: size, ringWidth: 20, counts: counts), 1)
        // Left side = third slice.
        XCTAssertEqual(DonutGeometry.sliceIndex(at: CGPoint(x: 10, y: 50), in: size, ringWidth: 20, counts: counts), 2)
    }

    func testDonutIgnoresTapsInTheHoleAndOutside() {
        let size = CGSize(width: 100, height: 100)
        XCTAssertNil(DonutGeometry.sliceIndex(at: CGPoint(x: 50, y: 50), in: size, ringWidth: 20, counts: [1]))
        XCTAssertNil(DonutGeometry.sliceIndex(at: CGPoint(x: 1, y: 1), in: size, ringWidth: 20, counts: [1]))
    }

    func testDonutIgnoresEmptySlices() {
        let size = CGSize(width: 100, height: 100)
        // First slice has zero hazards, so a tap at 1 o'clock lands on the second one.
        XCTAssertEqual(DonutGeometry.sliceIndex(at: CGPoint(x: 70, y: 20), in: size, ringWidth: 20, counts: [0, 4]), 1)
    }

    // MARK: Shapes

    func testBarShapeHeightFollowsFraction() {
        let rect = CGRect(x: 0, y: 0, width: 40, height: 100)
        XCTAssertEqual(BarShape(fraction: 0.5).path(in: rect).boundingRect.height, 50, accuracy: 0.5)
        XCTAssertTrue(BarShape(fraction: 0).path(in: rect).isEmpty)
        XCTAssertEqual(BarShape(fraction: 3).path(in: rect).boundingRect.height, 100, accuracy: 0.5)
    }

    func testDonutSliceAnimatesBothEnds() {
        var slice = DonutSliceShape(start: 0.1, end: 0.4)
        slice.animatableData = .init(0.2, 0.9)
        XCTAssertEqual(slice.start, 0.2, accuracy: 0.0001)
        XCTAssertEqual(slice.end, 0.9, accuracy: 0.0001)
        XCTAssertTrue(DonutSliceShape(start: 0.5, end: 0.5).path(in: CGRect(x: 0, y: 0, width: 10, height: 10)).isEmpty)
    }
}
