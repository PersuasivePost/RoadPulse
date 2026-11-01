import CoreGraphics

// MARK: - Swipe-to-resolve maths

/// The numbers behind `ResolveSlider`, kept out of the view so they can be unit tested.
enum ResolveGesture {
    /// Dragging past this fraction of the track resolves the hazard (docs/DESIGN.md: 80%).
    static let threshold = 0.8

    /// Drag distance as a 0...1 fraction of the thumb's travel.
    static func progress(translation: CGFloat, travel: CGFloat) -> Double {
        guard travel > 0 else { return 0 }
        return Double(min(max(translation / travel, 0), 1))
    }

    static func isResolved(progress: Double) -> Bool {
        progress >= threshold
    }
}
