import SwiftUI

// MARK: - App entry point

@main
struct RoadPulseApp: App {
    // @StateObject: the app owns AppState for its whole lifetime and shares it via the environment
    @StateObject private var appState = AppState()
    // @StateObject: one location manager for the whole app (Map and Report share it)
    @StateObject private var locationManager = LocationManager()

    private let persistence = PersistenceController.shared

    init() {
        SettingsKey.registerDefaults()
    }

    // MARK: Scene

    var body: some Scene {
        WindowGroup {
            if let error = persistence.loadError {
                StoreErrorView(error: error)
            } else {
                RootTabView(persistence: persistence)
                    .environment(\.managedObjectContext, persistence.viewContext)
                    .environmentObject(appState)
                    .environmentObject(locationManager)
            }
        }
    }
}
