import CoreGraphics
import Foundation

// MARK: - Donut chart maths

/// Slice fractions and tap hit-testing for `SeverityDonut`, kept out of the view for testing.
enum DonutGeometry {
    /// Start/end of each slice as fractions of a full turn (0...1), in input order.
    static func fractions(for counts: [Int]) -> [ClosedRange<Double>] {
        let total = counts.reduce(0, +)
        guard total > 0 else { return counts.map { _ in 0 ... 0 } }
        var start = 0.0
        return counts.map { count in
            let end = start + Double(count) / Double(total)
            defer { start = end }
            return start ... end
        }
    }

    /// Fraction of a turn (0 at 12 o'clock, clockwise) for a point in a square `size`;
    /// `nil` if the point is outside the ring.
    static func turnFraction(at point: CGPoint, in size: CGSize, ringWidth: CGFloat) -> Double? {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = min(size.width, size.height) / 2
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = (dx * dx + dy * dy).squareRoot()
        guard distance <= outer, distance >= outer - ringWidth else { return nil }
        var turn = Double(atan2(dx, -dy) / (2 * .pi)) // 0 at the top, increasing clockwise
        if turn < 0 { turn += 1 }
        return turn
    }

    /// Index of the slice under the touch, ignoring empty slices.
    static func sliceIndex(at point: CGPoint, in size: CGSize, ringWidth: CGFloat, counts: [Int]) -> Int? {
        guard let turn = turnFraction(at: point, in: size, ringWidth: ringWidth) else { return nil }
        return fractions(for: counts).enumerated().first { index, range in
            counts[index] > 0 && range.contains(turn) && turn < range.upperBound
        }?.offset
    }
}
