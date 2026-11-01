import Combine
import Foundation

// MARK: - Weather service (Open-Meteo, no API key)

/// Rainfall over the last 7 days at a coordinate. Two flavours of the same request: `async`
/// (used for the bulk refresh) and a Combine publisher (used by `RainfallViewModel`).
protocol WeatherProviding {
    func rainfall(latitude: Double, longitude: Double) async throws -> Double
    func rainfallPublisher(latitude: Double, longitude: Double) -> AnyPublisher<Double, WeatherError>
}

final class WeatherService: WeatherProviding {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared,
         baseURL: URL = URL(string: "https://api.open-meteo.com/v1/forecast")!) {
        self.session = session
        self.baseURL = baseURL
    }

    // MARK: Request

    /// Today plus the 6 days before it = the last 7 days of daily precipitation totals.
    func url(latitude: Double, longitude: Double) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", longitude)),
            URLQueryItem(name: "daily", value: "precipitation_sum"),
            URLQueryItem(name: "past_days", value: "6"),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        return components.url ?? baseURL
    }

    // MARK: async/await

    func rainfall(latitude: Double, longitude: Double) async throws -> Double {
        do {
            let (data, response) = try await session.data(from: url(latitude: latitude, longitude: longitude))
            return try Self.parse(data: data, response: response)
        } catch {
            throw WeatherError.from(error)
        }
    }

    // MARK: Combine

    func rainfallPublisher(latitude: Double, longitude: Double) -> AnyPublisher<Double, WeatherError> {
        session.dataTaskPublisher(for: url(latitude: latitude, longitude: longitude))
            .tryMap { try Self.parse(data: $0.data, response: $0.response) }
            .mapError { WeatherError.from($0) }
            .eraseToAnyPublisher()
    }

    // MARK: Parsing (shared by both)

    static func parse(data: Data, response: URLResponse) throws -> Double {
        if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
            throw WeatherError.server(http.statusCode)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let decoded = try? decoder.decode(WeatherResponse.self, from: data) else {
            throw WeatherError.invalidData
        }
        guard let total = decoded.totalMM else { throw WeatherError.noData }
        return total
    }
}
