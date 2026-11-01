import SwiftUI

// MARK: - Severity index strip

/// A thin A-to-Z style index down the right edge: tap or drag to jump to the first hazard of
/// that severity. Levels with no hazards are dimmed.
struct SeverityIndexStrip: View {
    /// Severities that currently have at least one hazard.
    let available: Set<Severity>
    let onSelect: (Severity) -> Void

    // @GestureState: highlights the level under the finger and resets itself when the touch ends
    @GestureState private var touched: Severity?
    // @State: which level VoiceOver last jumped to
    @State private var voiceOverIndex = 0
    // @State: the last level sent, so a drag within one level doesn't repeat the jump
    @State private var lastSent: Severity?
    private let height: CGFloat = 170

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SeverityIndex.order) { severity in
                Text("\(severity.rawValue)")
                    .font(.caption2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(available.contains(severity) ? severity.color : Color.inkMuted.opacity(0.5))
                    .frame(width: 22, height: height / CGFloat(SeverityIndex.order.count))
                    .background(Circle().fill(severity.color.opacity(touched == severity ? 0.25 : 0)))
            }
        }
        .frame(width: 24, height: height)
        .background(Capsule().fill(Color.surfaceRaised.opacity(0.9)))
        .overlay(Capsule().stroke(Color.inkMuted.opacity(0.12), lineWidth: 1))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($touched) { value, state, _ in
                    state = SeverityIndex.severity(atY: value.location.y, height: height)
                }
                .onChanged { value in
                    let severity = SeverityIndex.severity(atY: value.location.y, height: height)
                    guard severity != lastSent else { return }
                    lastSent = severity
                    if available.contains(severity) { onSelect(severity) }
                }
                .onEnded { _ in lastSent = nil }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Jump to severity")
        .accessibilityHint("Swipe up or down to choose a severity")
        .accessibilityAdjustableAction { direction in
            // VoiceOver: step through the levels that have hazards
            let levels = SeverityIndex.order.filter(available.contains)
            guard !levels.isEmpty else { return }
            let step = direction == .increment ? -1 : 1
            voiceOverIndex = min(max(voiceOverIndex + step, 0), levels.count - 1)
            onSelect(levels[voiceOverIndex])
        }
    }
}

// MARK: - Preview

#Preview {
    SeverityIndexStrip(available: [.severe, .medium, .minor]) { _ in }
        .padding()
        .background(Color.asphalt)
}
