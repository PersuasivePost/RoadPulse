import SwiftUI

// MARK: - Severity badge

/// Capsule with the severity colour at 18% behind coloured text (docs/DESIGN.md).
struct SeverityBadge: View {
    let severity: Severity
    var isFixed = false

    var body: some View {
        Text("\(severity.label) · \(severity.rawValue)/5")
            .font(.caption.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(severity.color(isFixed: isFixed))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Capsule().fill(severity.color(isFixed: isFixed).opacity(0.18)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Severity \(severity.rawValue) of 5, \(severity.label)")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        ForEach(Severity.allCases) { SeverityBadge(severity: $0) }
        SeverityBadge(severity: .severe, isFixed: true)
    }
    .padding()
    .background(Color.surface)
}
