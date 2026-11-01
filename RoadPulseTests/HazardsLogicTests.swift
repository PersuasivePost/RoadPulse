import CoreGraphics
import XCTest
@testable import RoadPulse

// MARK: - Swipe-to-resolve + pinch-zoom maths

final class GestureMathTests: XCTestCase {
    func testResolveProgressIsClampedToZeroAndOne() {
        XCTAssertEqual(ResolveGesture.progress(translation: -20, travel: 200), 0)
        XCTAssertEqual(ResolveGesture.progress(translation: 100, travel: 200), 0.5, accuracy: 0.0001)
        XCTAssertEqual(ResolveGesture.progress(translation: 500, travel: 200), 1)
        XCTAssertEqual(ResolveGesture.progress(translation: 50, travel: 0), 0)
    }

    func testResolveThresholdIsEightyPercent() {
        XCTAssertFalse(ResolveGesture.isResolved(progress: 0.79))
        XCTAssertTrue(ResolveGesture.isResolved(progress: 0.8))
        XCTAssertTrue(ResolveGesture.isResolved(progress: 1))
    }

    func testZoomScaleIsClamped() {
        XCTAssertEqual(ZoomState.clampedScale(0.3), 1)
        XCTAssertEqual(ZoomState.clampedScale(2), 2)
        XCTAssertEqual(ZoomState.clampedScale(9), 4)
    }

    func testZoomOffsetStaysInsideTheImage() {
        let size = CGSize(width: 300, height: 200)
        let clamped = ZoomState.clampedOffset(CGSize(width: 900, height: -900), scale: 2, in: size)
        XCTAssertEqual(clamped, CGSize(width: 150, height: -100))
        XCTAssertEqual(ZoomState.clampedOffset(CGSize(width: 40, height: 40), scale: 1, in: size), .zero)
    }

    func testDoubleTapZoomsInThenResets() {
        var zoom = ZoomState()
        zoom.toggle()
        XCTAssertEqual(zoom.scale, ZoomState.doubleTapScale)
        XCTAssertTrue(zoom.isZoomed)
        zoom.offset = CGSize(width: 30, height: 10)
        zoom.toggle()
        XCTAssertEqual(zoom, ZoomState())
    }

    func testPinchingBackToFitResetsThePan() {
        var zoom = ZoomState(scale: 2, offset: CGSize(width: 40, height: 0))
        zoom.commit(magnification: 0.4, drag: .zero, in: CGSize(width: 300, height: 200))
        XCTAssertEqual(zoom, ZoomState())
    }

    func testCommitAddsPanAndClampsIt() {
        var zoom = ZoomState(scale: 2, offset: .zero)
        zoom.commit(magnification: 1, drag: CGSize(width: 999, height: 20), in: CGSize(width: 300, height: 200))
        XCTAssertEqual(zoom.offset, CGSize(width: 150, height: 20))
    }
}

// MARK: - Hazards tab logic

@MainActor
final class HazardsLogicTests: XCTestCase {
    private func seed(_ drafts: [HazardDraft]) throws -> (PersistenceController, [Hazard]) {
        let store = TestStore.make()
        let repository = HazardRepository(persistence: store)
        let hazards = try drafts.map { try repository.create($0) }
        return (store, hazards)
    }

    // MARK: Edit

    func testEditDetectsChangesAndIgnoresWhitespace() throws {
        let (_, hazards) = try seed([TestStore.draft(notes: "Deep")])
        let original = HazardEdit(hazards[0])
        var edit = original
        XCTAssertFalse(edit.differs(from: original))
        edit.notes = "  Deep \n"
        XCTAssertFalse(edit.differs(from: original))
        edit.severity = .severe
        XCTAssertTrue(edit.differs(from: original))
    }

    func testApplyWritesTrimmedNotesAndClearsEmptyOnes() throws {
        let (_, hazards) = try seed([TestStore.draft(notes: "Old")])
        var edit = HazardEdit(hazards[0])
        edit.type = .waterlogging
        edit.severity = .high
        edit.notes = "  New note "
        edit.apply(to: hazards[0])
        XCTAssertEqual(hazards[0].hazardType, .waterlogging)
        XCTAssertEqual(hazards[0].severityLevel, .high)
        XCTAssertEqual(hazards[0].notes, "New note")
        edit.notes = "   "
        edit.apply(to: hazards[0])
        XCTAssertNil(hazards[0].notes)
    }

    func testViewModelUpdateSavesAndStampsUpdatedAt() throws {
        let past = Date(timeIntervalSince1970: 1_000)
        let (store, hazards) = try seed([TestStore.draft(severity: .low, createdAt: past)])
        let viewModel = HazardsViewModel(persistence: store, weather: MockWeather())
        var edit = HazardEdit(hazards[0])
        edit.severity = .severe
        XCTAssertTrue(viewModel.update(hazards[0], with: edit))
        XCTAssertEqual(hazards[0].severityLevel, .severe)
        XCTAssertGreaterThan(hazards[0].updatedAt, past)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: Actions

    func testToggleFixedAndDeleteById() throws {
        let (store, hazards) = try seed([TestStore.draft()])
        let viewModel = HazardsViewModel(persistence: store, weather: MockWeather())
        let id = hazards[0].id
        viewModel.toggleFixed(hazards[0])
        XCTAssertTrue(hazards[0].isFixed)
        viewModel.toggleFixed(hazards[0])
        XCTAssertFalse(hazards[0].isFixed)
        viewModel.delete(id: id)
        XCTAssertNil(viewModel.hazard(id: id))
    }

    func testRefreshCompletes() async throws {
        let (store, _) = try seed([TestStore.draft()])
        await HazardsViewModel(persistence: store, weather: MockWeather()).refresh()
    }

    // MARK: Query

    func testQueryCombinesFiltersSearchAndSort() {
        let viewModel = HazardsViewModel(persistence: TestStore.make(), weather: MockWeather())
        viewModel.searchText = "kalyan"
        viewModel.sort = .mostSevere
        var filters = HazardQuery()
        filters.status = .open
        let query = viewModel.query(filters: filters)
        XCTAssertEqual(query.text, "kalyan")
        XCTAssertEqual(query.sort, .mostSevere)
        XCTAssertEqual(query.status, .open)
    }

    func testGroupedRequestOrdersByAreaThenQuerySort() throws {
        let now = Date()
        let (store, _) = try seed([
            TestStore.draft(severity: .low, area: "Thane", createdAt: now),
            TestStore.draft(severity: .severe, area: "Kalyan", createdAt: now.addingTimeInterval(-60)),
            TestStore.draft(severity: .high, area: "Kalyan", createdAt: now),
            TestStore.draft(severity: .medium, area: nil, createdAt: now),
        ])
        let request = HazardQuery(sort: .mostSevere).groupedByAreaRequest()
        let result = try store.viewContext.fetch(request)
        XCTAssertEqual(result.map(\.areaSectionName), ["Unassigned", "Kalyan", "Kalyan", "Thane"])
        XCTAssertEqual(result.map(\.severityLevel), [.medium, .severe, .high, .low])
    }

    func testGroupedRequestKeepsTheFilters() throws {
        let (store, _) = try seed([
            TestStore.draft(severity: .minor, area: "Thane"),
            TestStore.draft(severity: .severe, area: "Thane"),
        ])
        var query = HazardQuery()
        query.severity = Severity.high ... Severity.severe
        XCTAssertEqual(try store.viewContext.fetch(query.groupedByAreaRequest()).count, 1)
    }

    // MARK: Index strip

    func testIndexStripMapsTouchesTopToBottomSevereToMinor() {
        XCTAssertEqual(SeverityIndex.severity(atY: -10, height: 100), .severe)
        XCTAssertEqual(SeverityIndex.severity(atY: 0, height: 100), .severe)
        XCTAssertEqual(SeverityIndex.severity(atY: 50, height: 100), .medium)
        XCTAssertEqual(SeverityIndex.severity(atY: 99, height: 100), .minor)
        XCTAssertEqual(SeverityIndex.severity(atY: 500, height: 100), .minor)
        XCTAssertEqual(SeverityIndex.severity(atY: 10, height: 0), .severe)
    }

    func testFirstHazardWithSeverityFollowsDisplayOrder() throws {
        let (_, hazards) = try seed([
            TestStore.draft(severity: .low),
            TestStore.draft(severity: .high),
            TestStore.draft(severity: .high),
        ])
        XCTAssertEqual(SeverityIndex.firstHazardID(with: .high, in: hazards), hazards[1].id)
        XCTAssertNil(SeverityIndex.firstHazardID(with: .severe, in: hazards))
    }

    // MARK: Sharing + display

    func testShareSummaryContainsKeyFacts() throws {
        let (_, hazards) = try seed([TestStore.draft(severity: .high, notes: "Near the bus stop", landmark: "Station Road")])
        let text = hazards[0].shareSummary
        XCTAssertTrue(text.contains("Pothole"))
        XCTAssertTrue(text.contains("High (4/5)"))
        XCTAssertTrue(text.contains("Station Road"))
        XCTAssertTrue(text.contains("Near the bus stop"))
        XCTAssertTrue(text.contains("maps.apple.com/?ll=19.08580,72.90810"))
    }

    func testDisplayTitleFallsBackToType() throws {
        let (_, hazards) = try seed([TestStore.draft(landmark: nil), TestStore.draft(landmark: "Shivaji Chowk")])
        XCTAssertEqual(hazards[0].displayTitle, "Pothole")
        XCTAssertEqual(hazards[1].displayTitle, "Shivaji Chowk")
    }

    func testLayoutRawValuesRoundTrip() {
        for layout in HazardsLayout.allCases {
            XCTAssertEqual(HazardsLayout(rawValue: layout.rawValue), layout)
        }
    }
}
