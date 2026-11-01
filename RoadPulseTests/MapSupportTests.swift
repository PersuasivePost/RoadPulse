import MapKit
import XCTest
@testable import RoadPulse

final class MapSupportTests: XCTestCase {
    // MARK: Pin rules

    func testOnlyHighAndSevereHazardsPulse() {
        XCTAssertEqual(Severity.allCases.filter(\.pulses), [.high, .severe])
    }

    func testFixedHazardsAreGreyAtEverySeverity() {
        for severity in Severity.allCases {
            XCTAssertEqual(severity.colorToken(isFixed: true), .fixedGrey)
            XCTAssertEqual(severity.colorToken(isFixed: false), severity.colorToken)
        }
    }

    // MARK: Filter chips

    func testSeverityChipTogglesOnAndOff() {
        let state = AppState(defaults: UserDefaults(suiteName: "roadpulse.tests.\(UUID())")!)
        state.toggleMinSeverity(.high)
        XCTAssertEqual(state.minSeverity, .high)
        state.toggleMinSeverity(.severe) // switching chips replaces the filter
        XCTAssertEqual(state.minSeverity, .severe)
        state.toggleMinSeverity(.severe)
        XCTAssertEqual(state.minSeverity, .minor)
    }

    func testStatusChipTogglesOnAndOff() {
        let state = AppState(defaults: UserDefaults(suiteName: "roadpulse.tests.\(UUID())")!)
        state.toggleStatus(.open)
        XCTAssertEqual(state.statusFilter, .open)
        state.toggleStatus(.fixed)
        XCTAssertEqual(state.statusFilter, .fixed)
        state.toggleStatus(.fixed)
        XCTAssertNil(state.statusFilter)
    }

    // MARK: Camera

    func testFocusRegionPutsPinAboveCentre() {
        let pin = CLLocationCoordinate2D(latitude: 19.1, longitude: 72.9)
        let region = MapCamera.region(focusing: pin, span: 0.02)
        XCTAssertEqual(region.center.latitude, 19.1 - 0.004, accuracy: 0.00001)
        XCTAssertEqual(region.center.longitude, 72.9, accuracy: 0.00001)
        XCTAssertEqual(region.span.latitudeDelta, 0.02, accuracy: 0.00001)
    }

    func testSearchRegionIsCentredOnResult() {
        let result = SearchResult(name: "Thane", subtitle: "", latitude: 19.2183, longitude: 72.9781)
        let region = MapCamera.region(showing: result)
        XCTAssertEqual(region.center.latitude, 19.2183, accuracy: 0.00001)
        XCTAssertEqual(region.center.longitude, 72.9781, accuracy: 0.00001)
    }

    func testDefaultRegionShowsEveryDemoHazard() {
        let region = MapCamera.mumbaiRegion
        for demo in DemoSeeder.hazards {
            XCTAssertLessThanOrEqual(abs(demo.latitude - region.center.latitude), region.span.latitudeDelta / 2,
                                     "\(demo.landmark) is off-screen vertically")
            XCTAssertLessThanOrEqual(abs(demo.longitude - region.center.longitude), region.span.longitudeDelta / 2,
                                     "\(demo.landmark) is off-screen horizontally")
        }
    }

    // MARK: Map style

    func testMapStyleCyclesThroughAllOptions() {
        XCTAssertEqual(MapStyleOption.standard.next, .hybrid)
        XCTAssertEqual(MapStyleOption.hybrid.next, .imagery)
        XCTAssertEqual(MapStyleOption.imagery.next, .standard)
    }

    // MARK: Geocoding results

    func testPlacemarkWithoutNameFallsBackToGenericName() throws {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 19.2, longitude: 72.97))
        let result = try XCTUnwrap(GeocodingService.result(from: placemark))
        XCTAssertEqual(result.name, "Selected location")
        XCTAssertEqual(result.latitude, 19.2, accuracy: 0.00001)
        XCTAssertEqual(result.displayName, "Selected location")
    }

    func testSearchResultDisplayNameIncludesSubtitle() {
        let result = SearchResult(name: "Thane", subtitle: "Maharashtra", latitude: 0, longitude: 0)
        XCTAssertEqual(result.displayName, "Thane, Maharashtra")
    }

    // MARK: GPX route

    func testBundledGPXRunsFromKalyanToGhatkopar() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "MumbaiCommute", withExtension: "gpx"),
                                "MumbaiCommute.gpx is missing from the app bundle")
        let parser = XMLParser(contentsOf: url)
        let collector = WaypointCollector()
        parser?.delegate = collector
        XCTAssertEqual(parser?.parse(), true)

        XCTAssertGreaterThanOrEqual(collector.points.count, 20, "needs enough points to look like movement")
        let first = try XCTUnwrap(collector.points.first)
        let last = try XCTUnwrap(collector.points.last)
        XCTAssertEqual(first.lat, 19.2353, accuracy: 0.01, "starts at Kalyan")
        XCTAssertEqual(last.lat, 19.0864, accuracy: 0.01, "ends at Ghatkopar")
        XCTAssertGreaterThan(first.lon, last.lon, "travels west")
    }
}

// MARK: - GPX helper

private final class WaypointCollector: NSObject, XMLParserDelegate {
    var points: [(lat: Double, lon: Double)] = []

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        guard elementName == "wpt", let lat = attributeDict["lat"].flatMap(Double.init),
              let lon = attributeDict["lon"].flatMap(Double.init) else { return }
        points.append((lat, lon))
    }
}
