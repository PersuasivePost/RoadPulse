import SwiftUI

// MARK: - Filter chip

/// Capsule toggle: `surfaceRaised` when off, `laneYellow` with an `ink` label when on.
struct FilterChip: View {
    let title: String
    var systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    // @Environment: an unselected chip follows the real appearance; a selected one forces light
    @Environment(\.colorScheme) private var colorSchemeForUnselected

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(Color.ink)
            // As on PrimaryButton: dark ink on yellow in both appearances.
            .environment(\.colorScheme, isSelected ? .light : colorSchemeForUnselected)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(isSelected ? Color.laneYellow : Color.surfaceRaised))
            .overlay(Capsule().stroke(Color.inkMuted.opacity(isSelected ? 0 : 0.12), lineWidth: 1))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    HStack {
        FilterChip(title: "Open", systemImage: "circle", isSelected: false) {}
        FilterChip(title: "4+", isSelected: true) {}
    }
    .padding()
    .background(Color.asphalt)
}
