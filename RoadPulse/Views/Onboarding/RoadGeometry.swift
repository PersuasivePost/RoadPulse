import CoreGraphics

// MARK: - Road perspective maths

/// Shared geometry so the road, its lane dashes and the pothole line up.
/// `t` runs from 0 (horizon) to 1 (bottom edge). `t * t` makes things bunch up toward the
/// horizon, which is what gives the flat drawing its sense of depth.
enum RoadGeometry {
    /// Fraction of the height above the horizon.
    static let horizon: CGFloat = 0.12
    /// Road half-width at the horizon and at the bottom edge, as a fraction of the width.
    static let topHalfWidth: CGFloat = 0.07
    static let bottomHalfWidth: CGFloat = 0.62

    static func y(at t: CGFloat, in rect: CGRect) -> CGFloat {
        rect.minY + rect.height * (horizon + (1 - horizon) * t * t)
    }

    static func roadHalfWidth(at t: CGFloat, in rect: CGRect) -> CGFloat {
        rect.width * (topHalfWidth + (bottomHalfWidth - topHalfWidth) * t * t)
    }

    /// Half-width of a centre-line dash at `t`.
    static func dashHalfWidth(at t: CGFloat, in rect: CGRect) -> CGFloat {
        rect.width * (0.004 + 0.03 * t * t)
    }
}
