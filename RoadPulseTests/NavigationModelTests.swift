import XCTest
@testable import RoadPulse

final class NavigationModelTests: XCTestCase {
    // MARK: Tabs

    func testTabsAreInDesignOrder() {
        XCTAssertEqual(AppTab.allCases.map(\.title), ["Map", "Report", "Hazards", "Insights", "Settings"])
    }

    func testEveryTabHasUniqueSymbolAndId() {
        XCTAssertEqual(Set(AppTab.allCases.map(\.symbol)).count, AppTab.allCases.count)
        XCTAssertEqual(Set(AppTab.allCases.map(\.id)).count, AppTab.allCases.count)
    }

    func testResolveRestoresKnownTabsAndFallsBackToMap() {
        XCTAssertEqual(AppTab.resolve("insights"), .insights)
        XCTAssertEqual(AppTab.resolve("not-a-tab"), .map)
        XCTAssertEqual(AppTab.resolve(""), .map)
    }

    // MARK: Onboarding

    func testOnboardingHasThreePagesAndOnlyTheLastAsksForPermission() {
        let pages = OnboardingPage.all
        XCTAssertEqual(pages.count, 3)
        XCTAssertEqual(pages.map(\.asksForPermission), [false, false, true])
        XCTAssertEqual(pages.map(\.id), [0, 1, 2])
        XCTAssertEqual(Set(pages.map(\.title)).count, 3)
    }

    // MARK: Road geometry

    func testRoadWidensTowardTheViewerAndDashesStayInside() {
        let rect = CGRect(x: 0, y: 0, width: 400, height: 260)
        let far = RoadGeometry.roadHalfWidth(at: 0, in: rect)
        let near = RoadGeometry.roadHalfWidth(at: 1, in: rect)
        XCTAssertLessThan(far, near)
        XCTAssertEqual(RoadGeometry.y(at: 0, in: rect), rect.height * RoadGeometry.horizon, accuracy: 0.001)
        XCTAssertEqual(RoadGeometry.y(at: 1, in: rect), rect.height, accuracy: 0.001)
        for t in stride(from: CGFloat(0), through: 1, by: 0.25) {
            XCTAssertLessThan(RoadGeometry.dashHalfWidth(at: t, in: rect), RoadGeometry.roadHalfWidth(at: t, in: rect))
        }
    }

    func testLaneDashesLoopSeamlessly() {
        // Phase 0 and phase 1 are the same picture, so the repeat-forever animation has no jump.
        let rect = CGRect(x: 0, y: 0, width: 400, height: 260)
        let start = LaneDashesShape(phase: 0).path(in: rect).boundingRect
        let end = LaneDashesShape(phase: 1).path(in: rect).boundingRect
        XCTAssertEqual(start.minY, end.minY, accuracy: 0.001)
        XCTAssertEqual(start.maxY, end.maxY, accuracy: 0.5)
        XCTAssertEqual(start.width, end.width, accuracy: 0.5)
    }
}
