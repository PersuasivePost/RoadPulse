import Combine
import Foundation

// MARK: - Rainfall view model (Combine)

/// Loads the 7-day rainfall for one hazard, shows loading / error / retry, and stores the result.
/// Subscribes to the weather publisher; `cancel()` drops the request when the view disappears.
final class RainfallViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded(Double)
        case failed(String)
    }

    // MARK: Published state

    @Published private(set) var state: State = .idle

    private let weather: WeatherProviding
    private var cancellable: AnyCancellable?

    init(weather: WeatherProviding = WeatherService()) {
        self.weather = weather
    }

    // MARK: Loading

    /// Uses the stored value when there is one; otherwise fetches. `force` refetches (Retry).
    func load(for hazard: Hazard, force: Bool = false) {
        guard hazard.isLive else { return }
        if !force, let stored = hazard.rainfall {
            cancel()
            state = .loaded(stored)
            return
        }
        cancellable?.cancel()
        state = .loading
        cancellable = weather
            .rainfallPublisher(latitude: hazard.latitude, longitude: hazard.longitude)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion, error != .cancelled {
                    self?.state = .failed(error.errorDescription ?? "Couldn't load rainfall.")
                }
            } receiveValue: { [weak self, weak hazard] mm in
                guard let self else { return }
                guard let hazard, hazard.isLive else { self.state = .idle; return }
                do {
                    try hazard.storeRainfall(mm)
                    self.state = .loaded(mm)
                } catch {
                    self.state = .failed("Couldn't save the rainfall data.")
                }
            }
    }

    func retry(for hazard: Hazard) {
        load(for: hazard, force: true)
    }

    /// Called on disappear: drops an in-flight request.
    func cancel() {
        cancellable?.cancel()
        cancellable = nil
        if state == .loading { state = .idle }
    }
}
