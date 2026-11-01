import SwiftUI

// MARK: - Moving lane dashes

/// The dashed centre line. Animating `phase` from 0 to 1 slides every dash one slot toward the
/// viewer, and because the pattern repeats each slot, a linear repeat-forever loop is seamless.
struct LaneDashesShape: Shape {
    var phase: CGFloat
    private let slots = 8

    // Animatable: SwiftUI interpolates `phase` frame by frame.
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    init(phase: CGFloat) {
        self.phase = phase
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = CGFloat(slots)
        // Start at -1 so a dash is always entering at the horizon as the others move down.
        for index in -1 ..< slots {
            let start = (CGFloat(index) + phase) / count
            let end = start + 0.5 / count // dash length = half a slot
            guard end > 0, start < 1 else { continue }
            let t0 = max(start, 0)
            let t1 = min(end, 1)

            let y0 = RoadGeometry.y(at: t0, in: rect)
            let y1 = RoadGeometry.y(at: t1, in: rect)
            let w0 = RoadGeometry.dashHalfWidth(at: t0, in: rect)
            let w1 = RoadGeometry.dashHalfWidth(at: t1, in: rect)

            path.move(to: CGPoint(x: rect.midX - w0, y: y0))
            path.addLine(to: CGPoint(x: rect.midX + w0, y: y0))
            path.addLine(to: CGPoint(x: rect.midX + w1, y: y1))
            path.addLine(to: CGPoint(x: rect.midX - w1, y: y1))
            path.closeSubpath()
        }
        return path
    }
}
