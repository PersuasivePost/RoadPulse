import SwiftUI

// MARK: - Lane-dash page indicator

/// Page dots drawn as lane dashes: the current page is a longer yellow dash.
struct LanePageIndicator: View {
    let count: Int
    let current: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.laneYellow : Color.inkMuted.opacity(0.25))
                    .frame(width: index == current ? 36 : 20, height: 4)
            }
        }
        .animation(reduceMotion ? nil : Motion.snappy, value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

// MARK: - Preview

#Preview {
    LanePageIndicator(count: 3, current: 1)
        .padding()
        .background(Color.asphalt)
}
