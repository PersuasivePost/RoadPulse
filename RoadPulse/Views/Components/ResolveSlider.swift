import SwiftUI

// MARK: - Swipe-to-resolve slider (custom DragGesture)

/// Track with a lane-dash pattern; drag the thumb right. Past 80% it turns into a green check and
/// fires `onResolve`; otherwise it springs back (docs/DESIGN.md).
struct ResolveSlider: View {
    let title: String
    let onResolve: () -> Void

    // @State: the drag offset and "done" flag belong to this control only
    @State private var dragX: CGFloat = 0
    @State private var isResolved = false
    // @Environment: the spring-back is skipped when Reduce Motion is on
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let thumbSize: CGFloat = 52
    private let inset: CGFloat = 4

    // MARK: Body

    var body: some View {
        GeometryReader { proxy in
            let travel = max(proxy.size.width - thumbSize - inset * 2, 1)
            let progress = ResolveGesture.progress(translation: dragX, travel: travel)
            ZStack(alignment: .leading) {
                track(progress: progress)
                thumb
                    .offset(x: inset + dragX)
                    .gesture(drag(travel: travel))
            }
        }
        .frame(height: thumbSize + inset * 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { complete(travel: nil) }
    }

    // MARK: Parts

    private func track(progress: Double) -> some View {
        ZStack {
            Capsule().fill(Color.surfaceRaised)
            DashTrack()
                .stroke(Color.laneYellow.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
                .padding(.horizontal, thumbSize)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(Color.inkMuted)
                .padding(.horizontal, 8)
                .background(Capsule().fill(Color.surfaceRaised))
                .opacity(1 - progress)
        }
        .overlay(Capsule().stroke(Color.inkMuted.opacity(0.12), lineWidth: 1))
    }

    private var thumb: some View {
        Circle()
            .fill(isResolved ? Color.sev1 : Color.laneYellow)
            .frame(width: thumbSize, height: thumbSize)
            .overlay(
                Image(systemName: isResolved ? "checkmark" : "chevron.right.2")
                    .font(.headline)
                    .foregroundStyle(isResolved ? Color.white : Color.ink)
                    .environment(\.colorScheme, .light) // dark ink on yellow in both appearances
                    .contentTransition(.symbolEffect(.replace))
            )
    }

    // MARK: Gesture

    private func drag(travel: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isResolved else { return }
                dragX = min(max(value.translation.width, 0), travel)
            }
            .onEnded { _ in
                guard !isResolved else { return }
                let progress = ResolveGesture.progress(translation: dragX, travel: travel)
                if ResolveGesture.isResolved(progress: progress) {
                    complete(travel: travel)
                } else {
                    withAnimation(reduceMotion ? nil : Motion.snappy) { dragX = 0 }
                }
            }
    }

    /// `travel` is nil for the VoiceOver action, which resolves without dragging.
    private func complete(travel: CGFloat?) {
        guard !isResolved else { return }
        withAnimation(reduceMotion ? nil : Motion.snappy) {
            if let travel { dragX = travel }
            isResolved = true
        }
        Haptics.success()
        // Let the green check show before the parent swaps this control out.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onResolve() }
    }
}

// MARK: - Dash track

private struct DashTrack: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Preview

#Preview {
    ResolveSlider(title: "Slide to mark fixed") {}
        .padding()
        .background(Color.asphalt)
}
