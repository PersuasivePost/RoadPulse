import Combine
import XCTest
@testable import RoadPulse

// MARK: - URLProtocol stub (no network)

final class StubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Mock provider for view-model tests

final class MockWeather: WeatherProviding {
    var result: Result<Double, WeatherError> = .success(50)
    private(set) var calls = 0

    func rainfall(latitude: Double, longitude: Double) async throws -> Double {
        calls += 1
        return try result.get()
    }

    func rainfallPublisher(latitude: Double, longitude: Double) -> AnyPublisher<Double, WeatherError> {
        calls += 1
        return result.publisher.eraseToAnyPublisher()
    }
}

// MARK: - Tests

final class WeatherServiceTests: XCTestCase {
    private var fixture: Data {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/open_meteo_week.json")
        return (try? Data(contentsOf: url)) ?? Data()
    }

    private func makeService() -> WeatherService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return WeatherService(session: URLSession(configuration: configuration))
    }

    private func respond(status: Int = 200, body: Data) {
        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (response, body)
        }
    }

    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    // MARK: Request + decoding

    func testURLAsksForSevenDaysOfPrecipitation() throws {
        let url = makeService().url(latitude: 19.0858, longitude: 72.9081)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }
        XCTAssertEqual(url.host, "api.open-meteo.com")
        XCTAssertEqual(value("latitude"), "19.0858")
        XCTAssertEqual(value("longitude"), "72.9081")
        XCTAssertEqual(value("daily"), "precipitation_sum")
        XCTAssertEqual(value("past_days"), "6")
        XCTAssertEqual(value("forecast_days"), "1")
    }

    func testFixtureDecodesAndSkipsNullDays() throws {
        XCTAssertFalse(fixture.isEmpty, "Fixture missing")
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(WeatherResponse.self, from: fixture)
        XCTAssertEqual(response.daily?.time.count, 7)
        XCTAssertEqual(response.totalMM ?? -1, 56.2, accuracy: 0.0001)
    }

    // MARK: async/await

    func testAsyncRainfallSumsTheWeek() async throws {
        respond(body: fixture)
        let mm = try await makeService().rainfall(latitude: 19.0858, longitude: 72.9081)
        XCTAssertEqual(mm, 56.2, accuracy: 0.0001)
    }

    func testServerErrorIsReported() async {
        respond(status: 500, body: Data())
        do {
            _ = try await makeService().rainfall(latitude: 0, longitude: 0)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .server(500))
        }
    }

    func testGarbageBodyIsInvalidData() async {
        respond(body: Data("not json".utf8))
        do {
            _ = try await makeService().rainfall(latitude: 0, longitude: 0)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .invalidData)
        }
    }

    func testAllNullDaysMeansNoData() async {
        respond(body: Data(#"{"daily":{"time":["2026-11-01"],"precipitation_sum":[null]}}"#.utf8))
        do {
            _ = try await makeService().rainfall(latitude: 0, longitude: 0)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .noData)
        }
    }

    func testNetworkFailureIsOffline() async {
        StubURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await makeService().rainfall(latitude: 0, longitude: 0)
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .offline)
        }
    }

    // MARK: Combine

    func testPublisherEmitsTotal() throws {
        respond(body: fixture)
        let done = expectation(description: "value")
        var received: Double?
        let cancellable = makeService().rainfallPublisher(latitude: 1, longitude: 2)
            .sink(receiveCompletion: { _ in }, receiveValue: { received = $0; done.fulfill() })
        wait(for: [done], timeout: 3)
        cancellable.cancel()
        XCTAssertEqual(try XCTUnwrap(received), 56.2, accuracy: 0.0001)
    }

    func testPublisherFailsWithWeatherError() {
        respond(status: 503, body: Data())
        let done = expectation(description: "failure")
        var failure: WeatherError?
        let cancellable = makeService().rainfallPublisher(latitude: 1, longitude: 2)
            .sink(receiveCompletion: { if case .failure(let error) = $0 { failure = error; done.fulfill() } },
                  receiveValue: { _ in })
        wait(for: [done], timeout: 3)
        cancellable.cancel()
        XCTAssertEqual(failure, .server(503))
    }
}

// MARK: - Rainfall view model

@MainActor
final class RainfallViewModelTests: XCTestCase {
    /// Managed objects only stay live while their store does, so the test keeps it alive.
    private var store: PersistenceController?

    private func makeHazard(rainfall: Double? = nil) throws -> (PersistenceController, Hazard) {
        var draft = TestStore.draft()
        draft.rainfallMM = rainfall
        let store = TestStore.make()
        self.store = store
        return (store, try HazardRepository(persistence: store).create(draft))
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    private func wait(until condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(3)
        while !condition(), Date() < deadline { try? await Task.sleep(nanoseconds: 10_000_000) }
    }

    func testLoadFetchesStoresAndPublishesRainfall() async throws {
        let (_, hazard) = try makeHazard()
        let weather = MockWeather()
        weather.result = .success(120)
        let viewModel = RainfallViewModel(weather: weather)
        viewModel.load(for: hazard)
        await wait { viewModel.state == .loaded(120) }
        XCTAssertEqual(viewModel.state, .loaded(120))
        XCTAssertEqual(hazard.rainfall, 120)
        XCTAssertNotNil(hazard.monsoonRisk)
    }

    func testStoredRainfallSkipsTheNetwork() throws {
        let (_, hazard) = try makeHazard(rainfall: 42)
        let weather = MockWeather()
        let viewModel = RainfallViewModel(weather: weather)
        viewModel.load(for: hazard)
        XCTAssertEqual(viewModel.state, .loaded(42))
        XCTAssertEqual(weather.calls, 0)
    }

    func testFailureThenRetrySucceeds() async throws {
        let (_, hazard) = try makeHazard()
        let weather = MockWeather()
        weather.result = .failure(.offline)
        let viewModel = RainfallViewModel(weather: weather)
        viewModel.load(for: hazard)
        await wait { if case .failed = viewModel.state { return true } else { return false } }
        XCTAssertEqual(viewModel.state, .failed(WeatherError.offline.errorDescription ?? ""))
        XCTAssertNil(hazard.rainfall)

        weather.result = .success(10)
        viewModel.retry(for: hazard)
        await wait { viewModel.state == .loaded(10) }
        XCTAssertEqual(viewModel.state, .loaded(10))
    }

    func testRetryRefetchesEvenWhenStored() throws {
        let (_, hazard) = try makeHazard(rainfall: 5)
        let weather = MockWeather()
        let viewModel = RainfallViewModel(weather: weather)
        viewModel.retry(for: hazard)
        XCTAssertEqual(weather.calls, 1)
    }

    func testCancelDropsLoadingState() throws {
        let (_, hazard) = try makeHazard()
        // A publisher that never finishes keeps the view model in `.loading`.
        let viewModel = RainfallViewModel(weather: HangingWeather())
        viewModel.load(for: hazard)
        XCTAssertEqual(viewModel.state, .loading)
        viewModel.cancel()
        XCTAssertEqual(viewModel.state, .idle)
    }

    // MARK: Pull-to-refresh backfill

    func testRefreshFillsOnlyMissingRainfall() async throws {
        var withRain = TestStore.draft()
        withRain.rainfallMM = 7
        let store = TestStore.make()
        let repository = HazardRepository(persistence: store)
        let kept = try repository.create(withRain)
        let missing = try repository.create(TestStore.draft())
        let weather = MockWeather()
        weather.result = .success(33)
        await HazardsViewModel(persistence: store, weather: weather).refresh()
        XCTAssertEqual(kept.rainfall, 7)
        XCTAssertEqual(missing.rainfall, 33)
        XCTAssertEqual(weather.calls, 1)
    }

    func testRefreshReportsFailureWhenNothingLoaded() async throws {
        let store = TestStore.make()
        _ = try HazardRepository(persistence: store).create(TestStore.draft())
        let weather = MockWeather()
        weather.result = .failure(.offline)
        let viewModel = HazardsViewModel(persistence: store, weather: weather)
        await viewModel.refresh()
        XCTAssertEqual(viewModel.errorMessage, WeatherError.offline.errorDescription)
    }
}

private final class HangingWeather: WeatherProviding {
    func rainfall(latitude: Double, longitude: Double) async throws -> Double { 0 }
    func rainfallPublisher(latitude: Double, longitude: Double) -> AnyPublisher<Double, WeatherError> {
        Empty<Double, WeatherError>(completeImmediately: false).eraseToAnyPublisher()
    }
}
