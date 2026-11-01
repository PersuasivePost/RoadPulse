import SwiftUI

// MARK: - Step progress (four lane dashes)

/// Four dashes at the top of each report step; the dashes up to `step` fill yellow.
struct StepProgress: View {
    let step: Int
    var total = ReportStep.total

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1 ... total, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? Color.laneYellow : Color.inkMuted.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .animation(reduceMotion ? nil : Motion.smooth, value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(step) of \(total)")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ForEach(1 ... 4, id: \.self) { StepProgress(step: $0) }
    }
    .padding()
    .background(Color.asphalt)
}
