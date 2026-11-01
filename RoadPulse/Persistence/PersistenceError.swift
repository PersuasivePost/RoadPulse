import Foundation

// MARK: - Persistence errors

/// Errors the persistence layer surfaces to the UI. Messages are written for users, not developers.
enum PersistenceError: LocalizedError, Equatable {
    case storeUnavailable(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .storeUnavailable:
            return "RoadPulse couldn't open its saved reports. Restart the app; if it keeps happening, free up some storage."
        case .saveFailed:
            return "Your changes couldn't be saved. Please try again."
        }
    }

    /// Underlying system message, for logs only.
    var debugDetail: String {
        switch self {
        case .storeUnavailable(let detail), .saveFailed(let detail):
            return detail
        }
    }
}
