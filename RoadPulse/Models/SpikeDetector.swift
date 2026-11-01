import Foundation

// MARK: - Rough stretch found by the detector

struct RoughSpan: Equatable {
    var start: GeoPoint?
    var end: GeoPoint?
    /// 0...1, where 1 = RMS of 1 g.
    var intensity: Double
    var startTime: TimeInterval
    var endTime: TimeInterval
}

// MARK: - Spike detector (docs/ARCHITECTURE.md)

/// Rolling RMS of vertical acceleration over a 0.5 s window. While the RMS is above the threshold
/// a span is open; when it drops below (or the span gets too long) the span is returned.
struct SpikeDetector {
    let thresholdG: Double
    var windowSeconds: TimeInterval = 0.5
    /// A long rough stretch is cut into pieces, so a polyline never cuts a corner for long.
    var maxSpanSeconds: TimeInterval = 3
    /// Ignore the first few samples, when the window isn't yet representative.
    var minSamples = 5

    private(set) var rms = 0.0
    private var window: [(time: TimeInterval, z: Double)] = []
    private var open: RoughSpan?

    init(thresholdG: Double) {
        self.thresholdG = thresholdG
    }

    // MARK: Maths

    /// Intensity = RMS clamped to 0...1 g.
    static func intensity(forRMS rms: Double) -> Double {
        min(max(rms / 1.0, 0), 1)
    }

    static func rms(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return (values.reduce(0) { $0 + $1 * $1 } / Double(values.count)).squareRoot()
    }

    // MARK: Streaming

    /// Feeds one sample; returns a span when one has just ended.
    mutating func ingest(_ sample: MotionSample) -> RoughSpan? {
        window.append((sample.time, sample.z))
        while let first = window.first, sample.time - first.time > windowSeconds {
            window.removeFirst()
        }
        rms = Self.rms(of: window.map { $0.z })
        guard window.count >= minSamples else { return nil }

        if rms > thresholdG {
            let intensity = Self.intensity(forRMS: rms)
            if var span = open {
                span.end = sample.position ?? span.end
                span.endTime = sample.time
                span.intensity = max(span.intensity, intensity)
                open = span
                if span.endTime - span.startTime >= maxSpanSeconds { return close() }
            } else {
                open = RoughSpan(start: sample.position, end: sample.position, intensity: intensity,
                                 startTime: sample.time, endTime: sample.time)
            }
            return nil
        }
        return close()
    }

    /// Ends the open span, if any (call when the drive stops).
    mutating func finish() -> RoughSpan? {
        close()
    }

    private mutating func close() -> RoughSpan? {
        defer { open = nil }
        return open
    }
}
