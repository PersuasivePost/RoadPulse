import SwiftUI

// MARK: - Road surface

/// A trapezoid that narrows toward the horizon.
struct RoadShape: Shape {
    func path(in rect: CGRect) -> Path {
        let top = RoadGeometry.y(at: 0, in: rect)
        let bottom = RoadGeometry.y(at: 1, in: rect)
        let topHalf = RoadGeometry.roadHalfWidth(at: 0, in: rect)
        let bottomHalf = RoadGeometry.roadHalfWidth(at: 1, in: rect)

        var path = Path()
        path.move(to: CGPoint(x: rect.midX - topHalf, y: top))
        path.addLine(to: CGPoint(x: rect.midX + topHalf, y: top))
        path.addLine(to: CGPoint(x: rect.midX + bottomHalf, y: bottom))
        path.addLine(to: CGPoint(x: rect.midX - bottomHalf, y: bottom))
        path.closeSubpath()
        return path
    }
}
