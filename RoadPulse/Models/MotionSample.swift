import CoreLocation
import Foundation

// MARK: - Motion sample

/// A latitude/longitude pair that is `Equatable` (unlike `CLLocationCoordinate2D`).
struct GeoPoint: Equatable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distance(to other: GeoPoint) -> Double {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}

/// One vertical-acceleration reading (in g), optionally with the position it was taken at.
/// Replayed samples carry their own position; live ones get the latest GPS fix.
struct MotionSample: Equatable {
    var time: TimeInterval
    var z: Double
    var position: GeoPoint?
}
