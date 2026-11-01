import Foundation

// MARK: - Open-Meteo response (Codable)

/// The part of Open-Meteo's `daily` forecast response RoadPulse reads. Decoded with
/// `.convertFromSnakeCase`, so `precipitation_sum` arrives as `precipitationSum`.
struct WeatherResponse: Codable, Equatable {
    struct Daily: Codable, Equatable {
        let time: [String]
        /// Millimetres per day; a day can be `null` when the model has no value.
        let precipitationSum: [Double?]
    }

    let daily: Daily?

    /// Sum of the days that have a value; `nil` when there are none at all.
    var totalMM: Double? {
        let values = (daily?.precipitationSum ?? []).compactMap { $0 }.filter { $0.isFinite }
        guard !values.isEmpty else { return nil }
        return values.reduce(0) { $0 + max($1, 0) }
    }
}
