import SwiftUI

// MARK: - Root tabs + first-launch onboarding

struct RootTabView: View {
    let persistence: PersistenceController

    // @SceneStorage: the selected tab is restored with the scene, not saved as a user setting
    @SceneStorage(SettingsKey.selectedTab) private var selectedTab = AppTab.map.rawValue
    // @AppStorage: "has seen the intro" must survive relaunch, so it lives in UserDefaults
    @AppStorage(SettingsKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    // @EnvironmentObject: shared state; other screens ask for a tab through `requestedTab`
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    // MARK: Body

    var body: some View {
        TabView(selection: tabSelection) {
            ForEach(AppTab.allCases) { tab in
                content(for: tab)
                    .tabItem { Label(tab.title, systemImage: tab.symbol) }
                    .tag(tab.rawValue)
            }
        }
        .tint(Color.laneYellow)
        .onAppear { locationManager.start() }
        .onChange(of: appState.requestedTab) { _, tab in
            guard let tab else { return }
            selectedTab = tab.rawValue
            appState.requestedTab = nil
        }
        .fullScreenCover(isPresented: onboardingPresented) {
            OnboardingView(hasCompleted: $hasCompletedOnboarding)
        }
    }

    // MARK: Tab content

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .settings:
            SettingsScreen(persistence: persistence)
        case .map:
            MapScreen(persistence: persistence)
        case .report:
            ReportFlow(persistence: persistence)
        case .hazards:
            HazardsScreen(persistence: persistence)
        default:
            PlaceholderScreen(tab: tab)
        }
    }

    /// Reads through `AppTab.resolve` so a stale or invalid stored value falls back to the map.
    private var tabSelection: Binding<String> {
        Binding(
            get: { AppTab.resolve(selectedTab).rawValue },
            set: { selectedTab = $0 }
        )
    }

    // MARK: Onboarding

    /// The cover shows until onboarding is completed; dismissing it marks it completed.
    private var onboardingPresented: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )
    }
}

// MARK: - Preview

#Preview {
    RootTabView(persistence: .preview)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(AppState())
        .environmentObject(LocationManager())
}
