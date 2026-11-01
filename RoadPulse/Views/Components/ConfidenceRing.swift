import SwiftUI

// MARK: - Confidence ring

/// 160 pt ring, 14 pt stroke, track `inkMuted` @ 15%, round caps. The arc grows and the centre
/// number counts up together (docs/DESIGN.md). Reduce Motion: the final value fades in.
struct ConfidenceRing: View {
    /// 0–1.
    let progress: Double
    let color: Color

    // @State: the animated value; it starts at 0 and is driven to `progress` on appear
    @State private var shown = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.inkMuted.opacity(0.15), lineWidth: 14)
            RingShape(trim: shown)
                .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
            CountingPercent(value: shown * 100)
                // Fixed size on purpose: the number must fit inside the fixed 160 pt ring.
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.ink)
        }
        .frame(width: 160, height: 160)
        .padding(7) // keeps the round caps inside the view's bounds
        .opacity(reduceMotion ? (shown > 0 ? 1 : 0) : 1)
        .onAppear {
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.2)) { shown = progress }
            } else {
                withAnimation(Motion.reveal) { shown = progress }
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Motion.reveal) { shown = newValue }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confidence")
        .accessibilityValue("\(Int((progress * 100).rounded(.down))) percent")
    }
}

// MARK: - Counting number

/// A number that SwiftUI can animate: while `value` changes, every frame shows the in-between
/// number, which is what makes the count-up.
struct CountingPercent: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value.rounded(.down)))%")
            .monospacedDigit()
    }
}

// MARK: - Preview

#Preview {
    HStack {
        ConfidenceRing(progress: 0.94, color: Severity.severe.color)
        ConfidenceRing(progress: 0.62, color: Severity.minor.color)
    }
    .padding()
    .background(Color.asphalt)
}
