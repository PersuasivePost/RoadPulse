import MapKit

// MARK: - Camera helpers

/// Pure functions for where the map looks, so they can be unit-tested.
enum MapCamera {
    /// Kalyan to Ghatkopar, so the demo pins are visible on first launch.
    static let mumbaiRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.16, longitude: 73.02),
        span: MKCoordinateSpan(latitudeDelta: 0.28, longitudeDelta: 0.30)
    )

    /// A close view of a hazard. The centre sits slightly south of the pin so the pin shows in
    /// the upper part of the screen, clear of the bottom sheet.
    static func region(focusing coordinate: CLLocationCoordinate2D, span: Double = 0.02) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: coordinate.latitude - span * 0.2,
                                           longitude: coordinate.longitude),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
    }

    /// A neighbourhood-sized view of a search result.
    static func region(showing result: SearchResult) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: result.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    }
}
