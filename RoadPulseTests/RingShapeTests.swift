import SwiftUI
import XCTest
@testable import RoadPulse

final class RingShapeTests: XCTestCase {
    private let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

    func testZeroTrimDrawsNothing() {
        XCTAssertTrue(RingShape(trim: 0).path(in: rect).isEmpty)
    }

    func testQuarterTurnSweepsClockwiseFromTwelveToThreeOClock() {
        let bounds = RingShape(trim: 0.25).path(in: rect).boundingRect
        // Top (50, 0) → right (100, 50): the top-right quadrant only.
        XCTAssertEqual(bounds.minX, 50, accuracy: 1)
        XCTAssertEqual(bounds.maxX, 100, accuracy: 1)
        XCTAssertEqual(bounds.minY, 0, accuracy: 1)
        XCTAssertEqual(bounds.maxY, 50, accuracy: 1)
    }

    func testFullTurnFillsTheSquare() {
        let bounds = RingShape(trim: 1).path(in: rect).boundingRect
        XCTAssertEqual(bounds.width, 100, accuracy: 1)
        XCTAssertEqual(bounds.height, 100, accuracy: 1)
    }

    func testTrimIsClamped() {
        XCTAssertEqual(RingShape(trim: 3).path(in: rect).boundingRect.width, 100, accuracy: 1)
        XCTAssertTrue(RingShape(trim: -1).path(in: rect).isEmpty)
    }

    func testAnimatableDataIsTheTrim() {
        var shape = RingShape(trim: 0.2)
        XCTAssertEqual(shape.animatableData, 0.2, accuracy: 0.0001)
        shape.animatableData = 0.8
        XCTAssertEqual(shape.trim, 0.8, accuracy: 0.0001)

        var counter = CountingPercent(value: 10)
        counter.animatableData = 87.4
        XCTAssertEqual(counter.value, 87.4, accuracy: 0.0001)
    }

    func testCheckmarkStaysInsideItsRect() {
        let bounds = CheckmarkShape().path(in: rect).boundingRect
        XCTAssertTrue(rect.contains(bounds))
    }
}
