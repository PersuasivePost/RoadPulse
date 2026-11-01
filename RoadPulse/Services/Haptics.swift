import UIKit

// MARK: - Haptics

/// Thin wrapper over UIKit feedback generators. Every call checks the Settings toggle first.
enum Haptics {
    /// Defaults to on when the user has never touched the setting.
    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: SettingsKey.hapticsEnabled) as? Bool ?? SettingsKey.Default.haptics
    }

    @MainActor static func tap() {
        guard isEnabled() else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor static func success() {
        guard isEnabled() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor static func warning() {
        guard isEnabled() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
