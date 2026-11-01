import SwiftUI

// MARK: - Rainfall row (loading / loaded / error + retry)

struct RainfallRow: View {
    let state: RainfallViewModel.State
    let units: UnitSystem
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                Text("Checking last 7 days of rain…")
                    .font(.caption)
                    .foregroundStyle(Color.inkMuted)
            }
            .accessibilityElement(children: .combine)
        case .loaded(let mm):
            Label("\(units.rainfall(mm: mm)) in 7 days", systemImage: "drop")
                .font(.caption)
                .foregroundStyle(Color.inkMuted)
        case .failed(let message):
            HStack(spacing: 8) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Color.inkMuted)
                Button("Retry") {
                    Haptics.tap()
                    onRetry()
                }
                .font(.caption.weight(.semibold))
                .tint(Color.laneYellow)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        RainfallRow(state: .loading, units: .metric) {}
        RainfallRow(state: .loaded(182.4), units: .metric) {}
        RainfallRow(state: .failed("No internet connection."), units: .metric) {}
    }
    .padding()
    .background(Color.surface)
}
