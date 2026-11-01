import CoreLocation
import MapKit

// MARK: - Geocoding

/// Turns a search string into places. A protocol so the view model can be tested with a mock.
protocol GeocodingProviding {
    func geocode(_ query: String) async throws -> [SearchResult]
}

/// Turns a coordinate into an address and neighbourhood (used when saving a report).
protocol ReverseGeocodingProviding {
    func placeDetails(for location: CLLocation) async throws -> PlaceDetails?
}

/// Forward and reverse geocoding with `CLGeocoder`; forward search is biased toward Mumbai.
final class GeocodingService: GeocodingProviding, ReverseGeocodingProviding {
    // One geocoder per direction: CLGeocoder runs a single request at a time.
    private let geocoder = CLGeocoder()
    private let reverseGeocoder = CLGeocoder()

    /// Results near Mumbai rank first; places elsewhere are still found.
    private let bias = CLCircularRegion(
        center: CLLocationCoordinate2D(latitude: 19.076, longitude: 72.8777),
        radius: 80_000,
        identifier: "mumbai"
    )

    func geocode(_ query: String) async throws -> [SearchResult] {
        geocoder.cancelGeocode() // CLGeocoder allows one request at a time
        do {
            let placemarks = try await geocoder.geocodeAddressString(query, in: bias)
            return placemarks.compactMap(Self.result(from:))
        } catch let error as CLError where error.code == .geocodeFoundNoResult {
            return []
        }
    }

    func placeDetails(for location: CLLocation) async throws -> PlaceDetails? {
        reverseGeocoder.cancelGeocode()
        let placemarks = try await reverseGeocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else { return nil }
        return PlaceDetails.make(
            street: [placemark.subThoroughfare, placemark.thoroughfare].compactMap { $0 }.joined(separator: " "),
            subLocality: placemark.subLocality,
            locality: placemark.locality,
            administrativeArea: placemark.administrativeArea
        )
    }

    // MARK: Mapping

    /// `nil` when the placemark has no coordinate.
    static func result(from placemark: CLPlacemark) -> SearchResult? {
        guard let coordinate = placemark.location?.coordinate else { return nil }
        let name = placemark.name ?? placemark.locality ?? "Selected location"
        let subtitle = [placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .filter { $0 != name }
            .joined(separator: ", ")
        return SearchResult(name: name, subtitle: subtitle,
                            latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
