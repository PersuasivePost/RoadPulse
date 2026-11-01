import SwiftUI

// MARK: - Hazard pin

/// 34 pt circle in the severity colour with a white symbol and a `surfaceRaised` halo.
/// Selected: 1.3× scale and a yellow ring. Severe and high: a pulsing outer ring. Fixed: grey.
struct HazardPin: View {
    let severity: Severity
    let type: HazardType
    var isFixed = false
    var isSelected = false

    // @Environment: every custom animation must honour Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // @State: the pulse is a local, repeating animation driver
    @State private var pulse = false

    private var tint: Color { severity.color(isFixed: isFixed) }
    private var shouldPulse: Bool { severity.pulses && !isFixed }

    var body: some View {
        ZStack {
            if shouldPulse {
                Circle()
                    .stroke(tint, lineWidth: 3)
                    .frame(width: 34, height: 34)
                    .scaleEffect(pulse ? 1.9 : 1)
                    .opacity(pulse ? 0 : 0.7)
            }
            Circle()
                .fill(Color.surfaceRaised)
                .frame(width: 42, height: 42)
                .shadow(color: Color.black.opacity(0.18), radius: 3, y: 1)
            Circle()
                .fill(tint)
                .frame(width: 34, height: 34)
            Image(systemName: type.symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
            Circle()
                .stroke(Color.laneYellow, lineWidth: 3)
                .frame(width: 46, height: 46)
                .opacity(isSelected ? 1 : 0)
        }
        .scaleEffect(isSelected && !reduceMotion ? 1.3 : 1)
        .animation(reduceMotion ? .easeOut(duration: 0.15) : Motion.snappy, value: isSelected)
        .onAppear {
            guard shouldPulse, !reduceMotion else { return }
            withAnimation(Motion.pulse) { pulse = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(type.label), severity \(severity.rawValue) of 5\(isFixed ? ", fixed" : "")")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 24) {
        ForEach(Severity.allCases) { HazardPin(severity: $0, type: .pothole) }
        HazardPin(severity: .severe, type: .crack, isFixed: true)
        HazardPin(severity: .high, type: .pothole, isSelected: true)
    }
    .padding(32)
    .background(Color.asphalt)
}
