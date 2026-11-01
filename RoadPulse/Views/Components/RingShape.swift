import SwiftUI

// MARK: - Ring arc

/// An arc that starts at 12 o'clock and sweeps clockwise by `trim` (0–1) of a full turn.
/// `animatableData` lets SwiftUI animate the sweep frame by frame.
struct RingShape: Shape {
    var trim: Double

    var animatableData: Double {
        get { trim }
        set { trim = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let clamped = min(max(trim, 0), 1)
        var path = Path()
        guard clamped > 0 else { return path }
        // Path's y-axis points down, so `clockwise: false` is clockwise on screen.
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90 + 360 * clamped),
                    clockwise: false)
        return path
    }
}
