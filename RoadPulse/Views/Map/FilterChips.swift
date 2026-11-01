import SwiftUI

// MARK: - Filter chips under the search bar

/// Reads and writes `AppState`; the map's `@FetchRequest` turns the result into an `NSPredicate`.
struct FilterChips: View {
    // @EnvironmentObject: the filters live in the shared AppState
    @EnvironmentObject private var appState: AppState
    // @Environment: animations are skipped when Reduce Motion is on
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let severityChoices: [Severity] = [.medium, .high, .severe]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Open", systemImage: "exclamationmark.circle",
                           isSelected: appState.statusFilter == .open) {
                    appState.toggleStatus(.open)
                }
                FilterChip(title: "Fixed", systemImage: "checkmark.circle",
                           isSelected: appState.statusFilter == .fixed) {
                    appState.toggleStatus(.fixed)
                }
                ForEach(Self.severityChoices) { severity in
                    FilterChip(title: severity == .severe ? "Severe" : "\(severity.rawValue)+",
                               isSelected: appState.minSeverity == severity) {
                        appState.toggleMinSeverity(severity)
                    }
                    .accessibilityLabel(severity == .severe ? "Severe only" : "Severity \(severity.rawValue) and up")
                }
                if appState.hasActiveFilters {
                    FilterChip(title: "Clear", systemImage: "xmark", isSelected: false) {
                        appState.clearFilters()
                    }
                    .transition(.opacity)
                }
            }
            .padding(.vertical, 2)
        }
        .animation(reduceMotion ? nil : Motion.snappy, value: appState.hasActiveFilters)
    }
}

// MARK: - Preview

#Preview {
    FilterChips()
        .environmentObject(AppState())
        .padding()
        .background(Color.asphalt)
}
