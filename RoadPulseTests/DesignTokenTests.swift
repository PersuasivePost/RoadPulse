import XCTest
import UIKit
@testable import RoadPulse

final class DesignTokenTests: XCTestCase {
    // MARK: Helpers

    /// Asset catalogue lives in the host app, which is `Bundle.main` for hosted unit tests.
    private func uiColor(_ token: ColorToken, style: UIUserInterfaceStyle) -> UIColor? {
        UIColor(named: token.rawValue, in: .main, compatibleWith: nil)?
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    // MARK: Tests

    func testEveryColourTokenResolvesInAssetCatalogue() {
        for token in ColorToken.allCases {
            XCTAssertNotNil(uiColor(token, style: .light), "Missing light colour: \(token.rawValue)")
            XCTAssertNotNil(uiColor(token, style: .dark), "Missing dark colour: \(token.rawValue)")
        }
    }

    func testLaneYellowHasDistinctLightAndDarkValues() {
        XCTAssertNotEqual(uiColor(.laneYellow, style: .light), uiColor(.laneYellow, style: .dark))
    }

    func testStaggerDelayScalesWithIndex() {
        XCTAssertEqual(Motion.staggerDelay(at: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(Motion.staggerDelay(at: 4), 0.2, accuracy: 0.0001)
    }
}
