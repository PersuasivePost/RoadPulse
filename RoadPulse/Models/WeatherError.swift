import Foundation

// MARK: - Weather errors

/// Everything that can go wrong fetching rainfall, with a message safe to show in the UI.
enum WeatherError: LocalizedError, Equatable {
    case offline
    case server(Int)
    case invalidData
    case noData
    case cancelled

    var errorDescription: String? {
        switch self {
        case .offline: return "No internet connection. Check your network and try again."
        case .server: return "The weather service is unavailable right now. Please try again."
        case .invalidData: return "Couldn't read the weather data."
        case .noData: return "No rainfall data for this location."
        case .cancelled: return "The request was cancelled."
        }
    }

    /// Maps any thrown error onto one of the cases above.
    static func from(_ error: Error) -> WeatherError {
        if let weather = error as? WeatherError { return weather }
        if error is CancellationError { return .cancelled }
        if error is DecodingError { return .invalidData }
        if let url = error as? URLError {
            return url.code == .cancelled ? .cancelled : .offline
        }
        return .invalidData
    }
}
