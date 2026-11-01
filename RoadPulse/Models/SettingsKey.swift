import Foundation

// MARK: - Settings keys

/// Every UserDefaults / `@AppStorage` / `@SceneStorage` key in one place, so a typo can't
/// silently create a second setting.
enum SettingsKey {
    static let mapStyle = "mapStyle"
    static let defaultMinSeverity = "defaultMinSeverity"
    static let hapticsEnabled = "hapticsEnabled"
    static let driveThresholdG = "driveThresholdG"
    static let units = "units"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let hazardsLayout = "hazardsLayout"
    /// `@SceneStorage` key: per-scene, restored with the scene (not a user setting).
    static let selectedTab = "selectedTab"

    // MARK: Defaults

    enum Default {
        static let mapStyle = MapStyleOption.standard
        static let minSeverity = 1
        static let haptics = true
        /// Spike threshold in g for Drive Mode (docs/ARCHITECTURE.md).
        static let driveThresholdG = 0.35
        static let units = UnitSystem.metric
    }

    /// Valid range for the Drive Mode threshold Slider.
    static let driveThresholdRange: ClosedRange<Double> = 0.15 ... 0.80

    /// `@AppStorage` supplies defaults to views, but non-view code (`Haptics`, `AppState`)
    /// reads UserDefaults directly, so the same defaults are registered at launch.
    static func registerDefaults(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            mapStyle: Default.mapStyle.rawValue,
            defaultMinSeverity: Default.minSeverity,
            hapticsEnabled: Default.haptics,
            driveThresholdG: Default.driveThresholdG,
            units: Default.units.rawValue,
            hasCompletedOnboarding: false,
        ])
    }
}
