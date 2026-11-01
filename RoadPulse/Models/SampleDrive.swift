import Foundation

// MARK: - Bundled sample drive

/// Parses `sample_drive.csv` (`t,lat,lon,z` at 50 Hz): a made-up drive along the commute route
/// with six rough patches, used for the simulator fallback and the demo video.
enum SampleDrive {
    static let resourceName = "sample_drive"

    /// Malformed lines are skipped, so a bad row can't break the replay.
    static func parse(_ csv: String) -> [MotionSample] {
        csv.split(whereSeparator: \.isNewline).compactMap { line in
            let fields = line.split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard fields.count == 4,
                  let time = Double(fields[0]), let lat = Double(fields[1]),
                  let lon = Double(fields[2]), let z = Double(fields[3]) else { return nil }
            return MotionSample(time: time, z: z, position: GeoPoint(latitude: lat, longitude: lon))
        }
    }

    static func load(bundle: Bundle = .main) -> [MotionSample] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return parse(text)
    }
}
