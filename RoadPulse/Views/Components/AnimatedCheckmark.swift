import SwiftUI

// MARK: - Checkmark path

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.8, y: rect.minY + rect.height * 0.3))
        return path
    }
}

// MARK: - Animated success mark

/// A green circle that draws itself, then the checkmark draws on. Reduce Motion: it just fades in.
struct AnimatedCheckmark: View {
    // @State: local animation driver, flipped once on appear
    @State private var drawn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.sev1.opacity(0.18))
            Circle()
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(Color.sev1, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            CheckmarkShape()
                .trim(from: 0, to: drawn ? 1 : 0)
                .stroke(Color.sev1, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .padding(30)
        }
        .frame(width: 120, height: 120)
        .opacity(reduceMotion ? (drawn ? 1 : 0) : 1)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Motion.reveal) { drawn = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Saved")
    }
}

// MARK: - Preview

#Preview {
    AnimatedCheckmark()
        .padding()
        .background(Color.asphalt)
}
