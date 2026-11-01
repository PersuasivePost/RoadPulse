import XCTest
@testable import RoadPulse

final class RiskLevelTests: XCTestCase {
    // MARK: Score

    func testScoreFollowsDocumentedFormula() {
        // severity/5 * 0.6 + min(rain/100, 1) * 0.4
        XCTAssertEqual(RiskLevel.score(severity: .severe, rainfallMM: 0), 0.6, accuracy: 0.0001)
        XCTAssertEqual(RiskLevel.score(severity: .severe, rainfallMM: 100), 1.0, accuracy: 0.0001)
        XCTAssertEqual(RiskLevel.score(severity: .medium, rainfallMM: 50), 0.56, accuracy: 0.0001)
        XCTAssertEqual(RiskLevel.score(severity: .minor, rainfallMM: 0), 0.12, accuracy: 0.0001)
    }

    func testRainfallIsCappedAtOneHundredMillimetres() {
        XCTAssertEqual(RiskLevel.score(severity: .low, rainfallMM: 100),
                       RiskLevel.score(severity: .low, rainfallMM: 500), accuracy: 0.0001)
    }

    func testBadRainfallValuesCountAsZero() {
        let none = RiskLevel.score(severity: .high, rainfallMM: 0)
        XCTAssertEqual(RiskLevel.score(severity: .high, rainfallMM: -20), none, accuracy: 0.0001)
        XCTAssertEqual(RiskLevel.score(severity: .high, rainfallMM: .nan), none, accuracy: 0.0001)
    }

    // MARK: Level thresholds

    func testLowMediumHigh() {
        XCTAssertEqual(RiskLevel.level(severity: .minor, rainfallMM: 10), .low)     // 0.16
        XCTAssertEqual(RiskLevel.level(severity: .medium, rainfallMM: 50), .medium) // 0.56
        XCTAssertEqual(RiskLevel.level(severity: .severe, rainfallMM: 100), .high)  // 1.0
    }

    func testSevereHazardWithNoRainIsAlreadyMedium() {
        XCTAssertEqual(RiskLevel.level(severity: .severe, rainfallMM: 0), .medium) // 0.6
    }

    func testRainRaisesRiskForTheSameHazard() {
        let dry = RiskLevel.level(severity: .high, rainfallMM: 0)     // 0.48
        let wet = RiskLevel.level(severity: .high, rainfallMM: 200)   // 0.88
        XCTAssertEqual(dry, .medium)
        XCTAssertEqual(wet, .high)
    }

    // MARK: Hazard integration

    func testHazardRiskIsNilUntilRainfallIsKnown() throws {
        let repo = HazardRepository(persistence: TestStore.make())
        var draft = TestStore.draft(severity: .severe)
        let unknown = try repo.create(draft)
        XCTAssertNil(unknown.monsoonRisk)

        draft.rainfallMM = 180
        let known = try repo.create(draft)
        XCTAssertEqual(known.monsoonRisk, .high)
    }
}
