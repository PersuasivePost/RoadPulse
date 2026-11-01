import SwiftUI

// MARK: - Motion tokens (docs/DESIGN.md)

/// Shared animation curves. Every custom animation must also check
/// `@Environment(\.accessibilityReduceMotion)` and fall back to an opacity fade.
enum Motion {
    /// Taps, selection, chips.
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)

    /// Sheets, layout changes, matched geometry.
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.85)

    /// Rings and chart bars growing.
    static let reveal = Animation.easeOut(duration: 0.8)

    /// Severe pins.
    static let pulse = Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)

    /// Delay per item for staggered chart bars and list appearance, in seconds.
    static let stagger: Double = 0.05

    /// Delay for the item at `index` in a staggered sequence.
    static func staggerDelay(at index: Int) -> Double {
        Double(index) * stagger
    }
}
