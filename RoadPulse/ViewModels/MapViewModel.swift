import Combine
import CoreLocation
import Foundation

// MARK: - Map view model

/// Search (Combine debounce → geocode) and the hazard actions behind the map sheet.
/// Uses the main-queue view context and publishes to SwiftUI, so use it from the main thread.
final class MapViewModel: ObservableObject {
    enum SearchState: Equatable {
        case idle
        case searching
        case found(String)
        case notFound
        case failed(String)

        /// One line shown under the search bar; `nil` when there is nothing to say.
        var message: String? {
            switch self {
            case .idle, .searching: return nil
            case .found(let name): return "Showing \(name)"
            case .notFound: return "No place found. Try a different name."
            case .failed(let message): return message
            }
        }
    }

    // MARK: Published state

    /// Bound to the search field. Typing is debounced before anything is geocoded.
    @Published var searchText = ""
    @Published private(set) var searchState: SearchState = .idle
    /// The latest hit; the map watches it and flies the camera there.
    @Published private(set) var searchResult: SearchResult?
    /// A user-friendly failure message; the screen shows it in an alert and clears it.
    @Published var errorMessage: String?

    private let geocoder: GeocodingProviding
    private let repository: HazardRepository
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    private var lastQuery: String?

    /// Searching starts from this many characters, so single letters don't hit the network.
    static let minimumQueryLength = 3

    // MARK: Init

    init(persistence: PersistenceController,
         geocoder: GeocodingProviding = GeocodingService(),
         debounce: TimeInterval = 0.6) {
        self.geocoder = geocoder
        repository = HazardRepository(persistence: persistence)

        // Combine pipeline: trim → wait for a pause in typing → skip repeats → search.
        $searchText
            .dropFirst() // the initial empty value isn't a search
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(for: .seconds(debounce), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in self?.search(query) }
            .store(in: &cancellables)
    }

    deinit {
        searchTask?.cancel()
    }

    // MARK: Search

    /// The keyboard's Search key: skip the debounce wait.
    func submitSearch() {
        search(searchText.trimmingCharacters(in: .whitespacesAndNewlines), force: true)
    }

    /// `force` re-runs a query even if it matches the last one (Search key, retry after a failure).
    func search(_ query: String, force: Bool = false) {
        guard force || query != lastQuery else { return }
        lastQuery = query
        searchTask?.cancel()
        guard query.count >= Self.minimumQueryLength else {
            searchState = .idle
            return
        }
        searchState = .searching
        searchTask = Task { @MainActor [weak self, geocoder] in
            do {
                let results = try await geocoder.geocode(query)
                guard !Task.isCancelled, let self else { return }
                if let first = results.first {
                    searchResult = first
                    searchState = .found(first.displayName)
                } else {
                    searchState = .notFound
                }
            } catch {
                guard !Task.isCancelled, let self else { return }
                searchState = .failed(Self.message(for: error))
            }
        }
    }

    static func message(for error: Error) -> String {
        if let clError = error as? CLError, clError.code == .network {
            return "Search needs an internet connection."
        }
        return "Couldn't search right now. Please try again."
    }

    // MARK: Hazards

    func hazard(id: UUID) -> Hazard? {
        try? repository.hazard(id: id)
    }

    func toggleFixed(_ hazard: Hazard) {
        perform { try repository.setStatus(hazard.isFixed ? .open : .fixed, for: hazard) }
    }

    func delete(_ hazard: Hazard) {
        perform { try repository.delete(hazard) }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Please try again."
        }
    }
}
