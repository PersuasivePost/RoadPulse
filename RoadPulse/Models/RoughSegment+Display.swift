import Foundation

extension RoughSegment {
    /// Trail colour comes from the severity scale: threshold-level vibration is amber, 1 g is red.
    static func level(forIntensity intensity: Double) -> Severity {
        Severity(clamping: Int((min(max(intensity, 0), 1) * 3).rounded()) + 2)
    }

    var level: Severity { Self.level(forIntensity: intensity) }

    /// Metres between the two ends; tiny segments are drawn as dots instead of lines.
    var lengthMeters: Double {
        GeoPoint(latitude: startLat, longitude: startLon).distance(to: GeoPoint(latitude: endLat, longitude: endLon))
    }
}
