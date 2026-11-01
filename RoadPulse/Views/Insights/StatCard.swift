import SwiftUI

// MARK: - Stat card

/// One headline number that counts up when the tab opens.
struct StatCard: View {
    let title: String
    let value: Double
    var decimals = 0
    var suffix = ""
    let symbol: String
    var tint: Color = .laneYellow

    // @State: starts at 0 and animates to `value` on appear
    @State private var shown = 0.0
    // @Environment: no count-up under Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
            CountingNumber(value: shown, decimals: decimals, suffix: suffix)
                .font(.title.weight(.heavy))
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.inkMuted)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .onAppear { animate(to: value) }
        .onChange(of: value) { _, newValue in animate(to: newValue) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(String(format: "%.\(decimals)f", value) + suffix)
    }

    private func animate(to target: Double) {
        if reduceMotion {
            shown = target
        } else {
            withAnimation(Motion.reveal) { shown = target }
        }
    }
}

// MARK: - Preview

#Preview {
    HStack {
        StatCard(title: "Reports", value: 25, symbol: "list.bullet")
        StatCard(title: "Fixed", value: 32, suffix: "%", symbol: "checkmark.circle", tint: .sev1)
    }
    .padding()
    .background(Color.asphalt)
}
