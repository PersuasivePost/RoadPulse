import SwiftUI

// MARK: - Empty state

/// Road illustration, one line and one action (docs/DESIGN.md). Eases in; with Reduce Motion it
/// simply fades.
struct EmptyState: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    // @State: drives the one-off entrance animation
    @State private var appeared = false
    // @Environment: no movement when Reduce Motion is on
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            RoadIllustration()
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            Text(title)
                .font(.title3.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            Text(message)
                .font(.body)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
            PrimaryButton(title: actionTitle, action: action)
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: 420)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 16)
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Motion.smooth) { appeared = true }
        }
    }
}

// MARK: - Preview

#Preview {
    EmptyState(title: "No reports yet",
               message: "Photograph a pothole and it shows up here.",
               actionTitle: "Report a hazard") {}
        .background(Color.asphalt)
}
