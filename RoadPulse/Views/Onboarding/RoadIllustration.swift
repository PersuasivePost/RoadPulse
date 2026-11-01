import SwiftUI

// MARK: - Animated road illustration

/// A road in perspective with yellow lane dashes rolling toward you and a pulsing pothole.
/// Reduce Motion: the dashes and the pulse stay still.
struct RoadIllustration: View {
    // @Environment: custom animations must honour Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // @State: purely local animation drivers; nothing outside this view needs them
    @State private var dashPhase: CGFloat = 0
    @State private var pulse = false

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            ZStack {
                LinearGradient(colors: [Color.laneYellow.opacity(0.22), Color.clear],
                               startPoint: .top, endPoint: .center)
                RoadShape()
                    .fill(LinearGradient(colors: [Color.inkMuted.opacity(0.3), Color.inkMuted.opacity(0.8)],
                                         startPoint: .top, endPoint: .bottom))
                LaneDashesShape(phase: dashPhase)
                    .fill(Color.laneYellow)
                pothole(in: rect)
            }
        }
        .onAppear(perform: startAnimations)
        .accessibilityHidden(true) // decorative
    }

    // MARK: Pothole

    @ViewBuilder
    private func pothole(in rect: CGRect) -> some View {
        let t: CGFloat = 0.78
        let center = CGPoint(
            x: rect.midX - RoadGeometry.roadHalfWidth(at: t, in: rect) * 0.45,
            y: RoadGeometry.y(at: t, in: rect)
        )
        let width = rect.width * (0.05 + 0.14 * t * t)
        ZStack {
            Ellipse()
                .stroke(Severity.severe.color, lineWidth: 3)
                .scaleEffect(pulse ? 1.6 : 1)
                .opacity(pulse ? 0 : 0.9)
            Ellipse().fill(Color.asphalt)
            Ellipse().stroke(Color.ink.opacity(0.25), lineWidth: 1.5)
        }
        .frame(width: width, height: width * 0.4)
        .position(center)
    }

    // MARK: Animation

    private func startAnimations() {
        guard !reduceMotion else { return }
        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
            dashPhase = 1
        }
        withAnimation(Motion.pulse) {
            pulse = true
        }
    }
}

// MARK: - Preview

#Preview {
    RoadIllustration()
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .cardStyle()
        .padding()
        .background(Color.asphalt)
}
