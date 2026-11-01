import SwiftUI

// MARK: - Placeholder root (replaced by the real TabView in F3)

struct RootTabView: View {
    // MARK: Body

    var body: some View {
        ZStack {
            Color.asphalt.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "road.lanes")
                    .font(.system(size: 56))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.laneYellow)
                Text("RoadPulse")
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.ink)
                Text("AI road hazard mapper")
                    .font(.body)
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootTabView()
}
