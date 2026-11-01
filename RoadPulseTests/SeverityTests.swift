import XCTest
@testable import RoadPulse

final class SeverityTests: XCTestCase {
    func testClampingKeepsValuesInRange() {
        XCTAssertEqual(Severity(clamping: -3), .minor)
        XCTAssertEqual(Severity(clamping: 3), .medium)
        XCTAssertEqual(Severity(clamping: 99), .severe)
    }

    func testEachLevelUsesItsOwnColourToken() {
        XCTAssertEqual(Severity.allCases.map(\.colorToken), [.sev1, .sev2, .sev3, .sev4, .sev5])
    }

    func testOrdering() {
        XCTAssertLessThan(Severity.low, Severity.high)
        XCTAssertEqual(Severity.allCases.max(), .severe)
    }
}
