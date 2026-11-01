import Combine
import XCTest
@testable import RoadPulse

// MARK: - Test double

/// Lets a test push samples by hand.
private final class ManualMotion: MotionProviding {
    let subject = PassthroughSubject<MotionSample, Never>()
    let finishSubject = PassthroughSubject<Void, Never>()
    var available = true
    private(set) var started = false
    private(set) var stopped = false

    var samples: AnyPublisher<MotionSample, Never> { subject.eraseToAnyPublisher() }
    var finished: AnyPublisher<Void, Never> { finishSubject.eraseToAnyPublisher() }
    var isAvailable: Bool { available }
    func start() { started = true }
    func stop() { stopped = true }
}

private let here = GeoPoint(latitude: 19.0, longitude: 72.9)

/// 50 Hz samples of a square wave with amplitude `z`.
private func samples(from start: TimeInterval, seconds: TimeInterval, z: Double, at point: GeoPoint? = here) -> [MotionSample] {
    (0 ..< Int(seconds * 50)).map { i in
        MotionSample(time: start + Double(i) / 50, z: i.isMultiple(of: 2) ? z : -z, position: point)
    }
}

// MARK: - Spike detector

final class SpikeDetectorTests: XCTestCase {
    func testRMSAndIntensity() {
        XCTAssertEqual(SpikeDetector.rms(of: [3, -4]), 12.5.squareRoot(), accuracy: 0.0001)
        XCTAssertEqual(SpikeDetector.rms(of: []), 0)
        XCTAssertEqual(SpikeDetector.intensity(forRMS: 0.5), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SpikeDetector.intensity(forRMS: 3), 1)
    }

    func testSmoothRoadProducesNoSpans() {
        var detector = SpikeDetector(thresholdG: 0.35)
        let spans = samples(from: 0, seconds: 5, z: 0.05).compactMap { detector.ingest($0) }
        XCTAssertTrue(spans.isEmpty)
        XCTAssertNil(detector.finish())
    }

    func testRoughPatchProducesOneSpanWithIntensity() {
        var detector = SpikeDetector(thresholdG: 0.35)
        var spans: [RoughSpan] = []
        for sample in samples(from: 0, seconds: 1, z: 0.05) + samples(from: 1, seconds: 1.5, z: 0.7)
            + samples(from: 2.5, seconds: 2, z: 0.05) {
            if let span = detector.ingest(sample) { spans.append(span) }
        }
        XCTAssertEqual(spans.count, 1)
        XCTAssertEqual(spans[0].intensity, 0.7, accuracy: 0.05)
        XCTAssertGreaterThan(spans[0].endTime, spans[0].startTime)
    }

    func testSpanIsClosedWhenTheDriveStops() {
        var detector = SpikeDetector(thresholdG: 0.35)
        for sample in samples(from: 0, seconds: 1, z: 0.8) { XCTAssertNil(detector.ingest(sample)) }
        XCTAssertNotNil(detector.finish())
        XCTAssertNil(detector.finish(), "finish clears the open span")
    }

    func testLongRoughStretchIsSplit() {
        var detector = SpikeDetector(thresholdG: 0.35)
        let spans = samples(from: 0, seconds: 7, z: 0.8).compactMap { detector.ingest($0) }
        XCTAssertEqual(spans.count, 2, "7 s of vibration with a 3 s cap closes twice")
    }

    func testSpanKeepsFirstAndLastPositions() {
        var detector = SpikeDetector(thresholdG: 0.35)
        let a = GeoPoint(latitude: 1, longitude: 1)
        let b = GeoPoint(latitude: 2, longitude: 2)
        _ = samples(from: 0, seconds: 0.5, z: 0.9, at: a).compactMap { detector.ingest($0) }
        _ = samples(from: 0.5, seconds: 0.5, z: 0.9, at: b).compactMap { detector.ingest($0) }
        let span = detector.finish()
        XCTAssertEqual(span?.start, a)
        XCTAssertEqual(span?.end, b)
    }
}

// MARK: - CSV, shapes, colours

final class DriveSupportTests: XCTestCase {
    func testCSVParsingSkipsHeaderAndBadRows() {
        let csv = "t,lat,lon,z\n0.00,19.1,73.1,0.25\nbroken,row\n0.02,19.2,73.2,-0.5\n"
        let parsed = SampleDrive.parse(csv)
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed[1], MotionSample(time: 0.02, z: -0.5, position: GeoPoint(latitude: 19.2, longitude: 73.2)))
    }

    func testBundledSampleDriveFileParses() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("RoadPulse/Resources/sample_drive.csv")
        let parsed = SampleDrive.parse(try String(contentsOf: url, encoding: .utf8))
        XCTAssertEqual(parsed.count, 4500) // 90 s at 50 Hz
        XCTAssertEqual(parsed.last?.time ?? 0, 89.98, accuracy: 0.001)
        // Running the detector over it must find the rough patches.
        var detector = SpikeDetector(thresholdG: 0.35)
        let spans = parsed.compactMap { detector.ingest($0) }
        XCTAssertGreaterThanOrEqual(spans.count, 3)
        XCTAssertTrue(spans.allSatisfy { $0.start != nil })
    }

    func testWaveformMapsReadingsToHeight() {
        XCTAssertEqual(WaveformShape.y(for: 0, range: 1, height: 100), 50)
        XCTAssertEqual(WaveformShape.y(for: 1, range: 1, height: 100), 0)
        XCTAssertEqual(WaveformShape.y(for: -1, range: 1, height: 100), 100)
        XCTAssertEqual(WaveformShape.y(for: 9, range: 1, height: 100), 0, "clamped")
        XCTAssertTrue(WaveformShape(samples: [0.1]).path(in: CGRect(x: 0, y: 0, width: 100, height: 50)).isEmpty)
        XCTAssertFalse(WaveformShape(samples: [0.1, 0.2]).path(in: CGRect(x: 0, y: 0, width: 100, height: 50)).isEmpty)
    }

    func testTrailColourGrowsWithIntensity() {
        XCTAssertEqual(RoughSegment.level(forIntensity: 0.35), .medium)
        XCTAssertEqual(RoughSegment.level(forIntensity: 1), .severe)
        XCTAssertEqual(RoughSegment.level(forIntensity: 0), .low)
        XCTAssertEqual(RoughSegment.level(forIntensity: 5), .severe)
    }

    func testVerticalIsAccelerationAlongGravity() {
        // Phone lying flat: gravity along -z, so vertical = -az.
        XCTAssertEqual(MotionService.verticalComponent(ax: 0.3, ay: 0, az: 0.5, gx: 0, gy: 0, gz: -1), -0.5, accuracy: 0.0001)
        // Phone upright in a holder: gravity along -y, so the bump shows up in y.
        XCTAssertEqual(MotionService.verticalComponent(ax: 0, ay: 0.4, az: 0.9, gx: 0, gy: -1, gz: 0), -0.4, accuracy: 0.0001)
        // No gravity reading: fall back to z.
        XCTAssertEqual(MotionService.verticalComponent(ax: 0, ay: 0, az: 0.2, gx: 0, gy: 0, gz: 0), 0.2)
    }

    func testGeoPointDistance() {
        let metres = GeoPoint(latitude: 19, longitude: 72.9).distance(to: GeoPoint(latitude: 19.001, longitude: 72.9))
        XCTAssertEqual(metres, 111, accuracy: 2)
    }
}

// MARK: - Trip repository + view model

@MainActor
final class DriveViewModelTests: XCTestCase {
    private var store: PersistenceController!

    override func setUp() {
        super.setUp()
        store = TestStore.make()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    private func wait(_ description: String, until condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(3)
        while !condition(), Date() < deadline { try? await Task.sleep(nanoseconds: 10_000_000) }
        XCTAssertTrue(condition(), "Timed out: \(description)")
    }

    // MARK: Repository

    func testRepositoryStoresSegmentsOnATripAndCascadesOnDelete() throws {
        let repository = TripRepository(persistence: store)
        let trip = try repository.startTrip()
        let span = RoughSpan(start: here, end: GeoPoint(latitude: 19.001, longitude: 72.9), intensity: 0.6,
                             startTime: 0, endTime: 1)
        let segment = try XCTUnwrap(try repository.add(span, to: trip))
        XCTAssertEqual(segment.trip, trip)
        XCTAssertEqual(segment.intensity, 0.6, accuracy: 0.0001)
        XCTAssertGreaterThan(segment.lengthMeters, 100)
        try repository.finish(trip, distanceMeters: 1234)
        XCTAssertEqual(try repository.trips().first?.distanceMeters, 1234)
        XCTAssertNotNil(trip.endedAt)

        try repository.delete(trip)
        XCTAssertTrue(try repository.segments().isEmpty)
    }

    func testSpanWithoutAnyPositionIsNotStored() throws {
        let repository = TripRepository(persistence: store)
        let trip = try repository.startTrip()
        let span = RoughSpan(start: nil, end: nil, intensity: 0.5, startTime: 0, endTime: 1)
        XCTAssertNil(try repository.add(span, to: trip))
    }

    // MARK: View model

    func testDriveRecordsRoughSpotsAndSummary() async throws {
        let motion = ManualMotion()
        let drive = DriveViewModel(persistence: store, live: motion, makeReplay: { nil })
        drive.start(replay: false, thresholdG: 0.35)
        XCTAssertTrue(drive.isRunning)
        XCTAssertTrue(motion.started)

        let route = [GeoPoint(latitude: 19.000, longitude: 72.9), GeoPoint(latitude: 19.001, longitude: 72.9)]
        for sample in samples(from: 0, seconds: 1, z: 0.05, at: route[0])
            + samples(from: 1, seconds: 1, z: 0.8, at: route[1])
            + samples(from: 2, seconds: 1, z: 0.05, at: route[1]) {
            motion.subject.send(sample)
        }
        await wait("all samples ingested") { drive.waveform.count == DriveViewModel.waveformLength }
        await wait("a rough spot") { drive.roughSpots >= 1 }
        XCTAssertEqual(drive.distanceMeters, 111, accuracy: 3)
        XCTAssertLessThanOrEqual(drive.waveform.count, DriveViewModel.waveformLength)

        drive.stop()
        XCTAssertTrue(motion.stopped)
        guard case .finished(let summary) = drive.phase else { return XCTFail("Expected finished") }
        XCTAssertGreaterThanOrEqual(summary.roughSpots, 1)
        let repository = TripRepository(persistence: store)
        XCTAssertEqual(try repository.trips().count, 1)
        XCTAssertNotNil(try repository.trips().first?.endedAt)
        XCTAssertEqual(try repository.segments().count, summary.roughSpots)

        drive.dismissSummary()
        XCTAssertEqual(drive.phase, .idle)
        XCTAssertEqual(drive.roughSpots, 0)
    }

    func testLiveSamplesTakeTheLocationProviderPosition() async {
        let motion = ManualMotion()
        let drive = DriveViewModel(persistence: store, live: motion, makeReplay: { nil })
        var calls = 0
        drive.locationProvider = { calls += 1; return here }
        drive.start(replay: false, thresholdG: 0.35)
        motion.subject.send(MotionSample(time: 0, z: 0.1, position: nil))
        await wait("sample ingested") { !drive.waveform.isEmpty }
        XCTAssertEqual(calls, 1)
        drive.stop()
    }

    func testReplayFinishingStopsTheDrive() async {
        let replay = ManualMotion()
        let drive = DriveViewModel(persistence: store, live: ManualMotion(), makeReplay: { replay })
        drive.start(replay: true, thresholdG: 0.35)
        XCTAssertEqual(drive.phase, .running(isReplay: true))
        replay.finishSubject.send()
        await wait("drive stopped") { !drive.isRunning }
        if case .finished = drive.phase {} else { XCTFail("Expected finished") }
    }

    func testUnavailableSensorsShowAMessageAndStayIdle() {
        let motion = ManualMotion()
        motion.available = false
        let drive = DriveViewModel(persistence: store, live: motion, makeReplay: { nil })
        drive.start(replay: false, thresholdG: 0.35)
        XCTAssertEqual(drive.phase, .idle)
        XCTAssertNotNil(drive.errorMessage)
        drive.start(replay: true, thresholdG: 0.35)
        XCTAssertNotNil(drive.errorMessage)
        XCTAssertEqual(drive.phase, .idle)
    }

    func testReplayServicePlaysSamplesInOrderAndFinishes() {
        let recorded = samples(from: 0, seconds: 0.2, z: 0.3)
        let replay = ReplayMotionService(samples: recorded, speed: 20)
        var received: [MotionSample] = []
        let done = expectation(description: "finished")
        let a = replay.samples.sink { received.append($0) }
        let b = replay.finished.sink { done.fulfill() }
        replay.start()
        wait(for: [done], timeout: 3)
        a.cancel(); b.cancel()
        XCTAssertEqual(received, recorded)
        XCTAssertFalse(ReplayMotionService(samples: []).isAvailable)
    }
}
