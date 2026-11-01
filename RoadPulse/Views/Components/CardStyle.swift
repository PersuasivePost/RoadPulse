import SwiftUI

// MARK: - Card style (custom ViewModifier)

/// `surface` fill, radius 20, hairline stroke, soft shadow in light mode only (docs/DESIGN.md).
struct CardStyle: ViewModifier {
    // @Environment: the shadow depends on the system appearance
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.inkMuted.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: colorScheme == .light ? Color.shadowTint.opacity(0.08) : .clear, radius: 12, y: 4)
        )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Preview

#Preview {
    Text("Card")
        .padding(24)
        .cardStyle()
        .padding()
        .background(Color.asphalt)
}
