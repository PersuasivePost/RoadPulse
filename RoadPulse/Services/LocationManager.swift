import CoreLocation

// MARK: - Location manager

/// Wraps `CLLocationManager` and publishes the authorization state and latest fix, so views
/// can react to every state: not asked, allowed, denied, restricted.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: Published state

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?
    /// A user-friendly message when location fails for a reason other than permission.
    @Published private(set) var errorMessage: String?

    private let manager: CLLocationManager
    private var wantsUpdates = false

    // MARK: Init

    override init() {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10 // metres; avoids a delegate call for every tiny jitter
        self.manager = manager
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    // MARK: Permission

    /// Shows the system prompt once; later calls do nothing (iOS remembers the answer).
    func requestWhenInUse() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: Updates

    /// Starts live updates, asking for permission first if it hasn't been decided yet.
    func start() {
        wantsUpdates = true
        switch authorizationStatus {
        case .notDetermined:
            requestWhenInUse()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break // denied or restricted: the UI shows LocationDeniedView
        }
    }

    func stop() {
        wantsUpdates = false
        manager.stopUpdatingLocation()
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized {
            errorMessage = nil
            if wantsUpdates { manager.startUpdatingLocation() }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        errorMessage = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // `.denied` is already reflected by `authorizationStatus`; don't double-report it.
        if (error as? CLError)?.code == .denied { return }
        errorMessage = "Couldn't find your location right now."
    }

    // MARK: Describing a status

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    static func describe(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Location hasn't been requested yet"
        case .authorizedWhenInUse, .authorizedAlways: return "Location is on"
        case .denied: return "Location is off. You can turn it on in Settings."
        case .restricted: return "Location is restricted on this device"
        @unknown default: return "Location status unknown"
        }
    }

    static func symbol(for status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways: return "location.fill"
        case .denied, .restricted: return "location.slash"
        default: return "location"
        }
    }
}
