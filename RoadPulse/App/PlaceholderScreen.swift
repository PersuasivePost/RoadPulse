import SwiftUI

// MARK: - Placeholder for tabs that ship in later tasks

struct PlaceholderScreen: View {
    let tab: AppTab
    var detail: String?

    var body: some View {
        ZStack {
            Color.asphalt.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 44))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.laneYellow)
                Text(tab.title)
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.ink)
                LaneDivider()
                    .frame(width: 120)
                Text(tab.placeholderMessage)
                    .font(.body)
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Color.inkMuted)
                        .padding(12)
                        .cardStyle()
                }
            }
            .padding(24)
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Preview

#Preview {
    PlaceholderScreen(tab: .map, detail: "Showing severity 1 and up")
}
