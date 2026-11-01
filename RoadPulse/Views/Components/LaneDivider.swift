import SwiftUI

// MARK: - Lane divider (signature motif)

/// 2 pt dashed line `[10, 8]` in `laneYellow` @ 60% (docs/DESIGN.md).
struct LaneDivider: View {
    var body: some View {
        HorizontalLine()
            .stroke(Color.laneYellow.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
            .frame(height: 2)
            .accessibilityHidden(true) // purely decorative
    }

    private struct HorizontalLine: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

// MARK: - Preview

#Preview {
    LaneDivider()
        .padding()
        .background(Color.asphalt)
}
