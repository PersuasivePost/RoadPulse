import SwiftUI

// MARK: - Hold to start (custom long-press control)

/// Press and hold for a second; a yellow ring fills while you hold and the drive starts when it
/// closes. Letting go early drains the ring. Prevents starting a drive by accident.
struct HoldToStartButton: View {
    var title = "Hold to start"
    var holdDuration: TimeInterval = 1
    let onStart: () -> Void

    // @State: ring progress and whether this press already fired
    @State private var progress = 0.0
    @State private var fired = false
    // @Environment: the drain animation is skipped under Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size: CGFloat = 96

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(Color.inkMuted.opacity(0.15), lineWidth: 8)
                RingShape(trim: progress)
                    .stroke(Color.laneYellow, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                Image(systemName: "play.fill")
                    .font(.title)
                    .foregroundStyle(Color.laneYellow)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
            .scaleEffect(progress > 0 && !reduceMotion ? 0.96 : 1)
            .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 60) {
                fired = true
                Haptics.success()
                onStart()
            } onPressingChanged: { pressing in
                if pressing {
                    fired = false
                    withAnimation(.linear(duration: holdDuration)) { progress = 1 }
                } else if fired {
                    progress = 0 // the drive started; reset the ring without animation
                } else {
                    withAnimation(reduceMotion ? nil : Motion.snappy) { progress = 0 }
                }
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(Color.inkMuted)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Start drive")
        .accessibilityHint("Press and hold to start")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onStart() }
    }
}

// MARK: - Preview

#Preview {
    HoldToStartButton {}
        .padding()
        .background(Color.surface)
}
