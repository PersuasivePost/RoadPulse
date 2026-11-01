import SwiftUI

// MARK: - Primary button

/// Full-width capsule in `laneYellow` with an `ink` label and a haptic on tap (docs/DESIGN.md).
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.headline)
            .fontDesign(.rounded)
            .foregroundStyle(Color.ink)
            // `ink` flips to near-white in dark mode, which is unreadable on yellow, so the label
            // always uses its light-mode (dark) value.
            .environment(\.colorScheme, .light)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color.laneYellow))
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Press style

/// Press = scale 0.96 (docs/DESIGN.md). With Reduce Motion it dims instead of scaling.
struct PressScaleButtonStyle: ButtonStyle {
    // @Environment: every custom animation must honour Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
            .animation(reduceMotion ? nil : Motion.snappy, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PrimaryButton(title: "Get started", systemImage: "arrow.right") {}
        PrimaryButton(title: "Next") {}
    }
    .padding()
    .background(Color.asphalt)
}
