import SwiftUI

// MARK: - Monsoon risk badge

/// Tinted capsule for the monsoon risk. `nil` means rainfall hasn't been fetched yet.
struct RiskBadge: View {
    let risk: RiskLevel?

    private var tint: Color {
        risk.map { Color($0.colorToken) } ?? Color.inkMuted
    }

    var body: some View {
        Label(risk?.label ?? "Rain data pending", systemImage: risk == nil ? "cloud" : "cloud.rain.fill")
            .font(.caption.weight(.semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.18)))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        ForEach(RiskLevel.allCases) { RiskBadge(risk: $0) }
        RiskBadge(risk: nil)
    }
    .padding()
    .background(Color.surface)
}
