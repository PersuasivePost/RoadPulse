import CoreLocation
import XCTest
@testable import RoadPulse

final class SettingsTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        let name = "roadpulse.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    // MARK: Registered defaults

    func testRegisterDefaultsMatchesDocumentedValues() {
        let defaults = freshDefaults()
        SettingsKey.registerDefaults(in: defaults)

        XCTAssertEqual(defaults.string(forKey: SettingsKey.mapStyle), "standard")
        XCTAssertEqual(defaults.integer(forKey: SettingsKey.defaultMinSeverity), 1)
        XCTAssertTrue(defaults.bool(forKey: SettingsKey.hapticsEnabled))
        XCTAssertEqual(defaults.double(forKey: SettingsKey.driveThresholdG), 0.35, accuracy: 0.0001)
        XCTAssertEqual(defaults.string(forKey: SettingsKey.units), "metric")
        XCTAssertFalse(defaults.bool(forKey: SettingsKey.hasCompletedOnboarding))
        XCTAssertTrue(SettingsKey.driveThresholdRange.contains(SettingsKey.Default.driveThresholdG))
    }

    func testStoredEnumValuesRoundTripThroughRawValues() {
        for style in MapStyleOption.allCases {
            XCTAssertEqual(MapStyleOption(rawValue: style.rawValue), style)
        }
        for units in UnitSystem.allCases {
            XCTAssertEqual(UnitSystem(rawValue: units.rawValue), units)
        }
    }

    // MARK: Haptics gate

    func testHapticsEnabledByDefaultAndWhenOn() {
        let defaults = freshDefaults()
        XCTAssertTrue(Haptics.isEnabled(defaults: defaults), "unset should mean on")
        defaults.set(true, forKey: SettingsKey.hapticsEnabled)
        XCTAssertTrue(Haptics.isEnabled(defaults: defaults))
    }

    func testHapticsDisabledWhenSettingIsOff() {
        let defaults = freshDefaults()
        defaults.set(false, forKey: SettingsKey.hapticsEnabled)
        XCTAssertFalse(Haptics.isEnabled(defaults: defaults))
    }

    // MARK: Units

    func testMetricDistance() {
        XCTAssertEqual(UnitSystem.metric.distance(meters: 0), "0 m")
        XCTAssertEqual(UnitSystem.metric.distance(meters: 250.4), "250 m")
        XCTAssertEqual(UnitSystem.metric.distance(meters: 999.6), "1.0 km")
        XCTAssertEqual(UnitSystem.metric.distance(meters: 1500), "1.5 km")
    }

    func testImperialDistance() {
        XCTAssertEqual(UnitSystem.imperial.distance(meters: 100), "328 ft")
        XCTAssertEqual(UnitSystem.imperial.distance(meters: 1609.344), "1.0 mi")
    }

    func testInvalidDistanceShowsDash() {
        XCTAssertEqual(UnitSystem.metric.distance(meters: -5), "–")
        XCTAssertEqual(UnitSystem.imperial.distance(meters: .nan), "–")
    }

    func testRainfall() {
        XCTAssertEqual(UnitSystem.metric.rainfall(mm: 182.4), "182 mm")
        XCTAssertEqual(UnitSystem.imperial.rainfall(mm: 25.4), "1.0 in")
        XCTAssertEqual(UnitSystem.metric.rainfall(mm: -1), "–")
    }

    // MARK: Location status text

    func testLocationStatusDescriptions() {
        XCTAssertTrue(LocationManager.describe(.notDetermined).contains("hasn't been requested"))
        XCTAssertEqual(LocationManager.describe(.authorizedWhenInUse), "Location is on")
        XCTAssertTrue(LocationManager.describe(.denied).contains("Settings"))
        XCTAssertEqual(LocationManager.symbol(for: .denied), "location.slash")
        XCTAssertEqual(LocationManager.symbol(for: .authorizedWhenInUse), "location.fill")
    }
}
