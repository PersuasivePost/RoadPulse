import MapKit

// MARK: - Directions

/// Hands a destination to the Maps app with driving directions.
enum DirectionsLauncher {
    static func openInMaps(to coordinate: CLLocationCoordinate2D, name: String) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
