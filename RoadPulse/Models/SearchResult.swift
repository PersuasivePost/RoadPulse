import CoreLocation

// MARK: - Place search result

/// One geocoded place. A plain value so tests and the view model never touch `CLPlacemark`.
struct SearchResult: Equatable, Identifiable {
    let name: String
    let subtitle: String
    let latitude: Double
    let longitude: Double

    var id: String { "\(name)|\(latitude)|\(longitude)" }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// "Thane, Maharashtra" style line for the status text under the search bar.
    var displayName: String {
        subtitle.isEmpty ? name : "\(name), \(subtitle)"
    }
}
