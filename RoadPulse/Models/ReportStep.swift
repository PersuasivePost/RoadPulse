import Foundation

// MARK: - Report flow steps

/// Pushed onto the `NavigationPath`. Capture is the root, so it isn't a case.
enum ReportStep: Hashable {
    case analyze, details, confirm

    /// 1-based position for the four-dash progress indicator (Capture = 1).
    var number: Int {
        switch self {
        case .analyze: return 2
        case .details: return 3
        case .confirm: return 4
        }
    }

    static let total = 4
}
