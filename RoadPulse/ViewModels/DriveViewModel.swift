import Combine
import Foundation

// MARK: - Drive view model

/// Runs one drive: feeds motion samples through the spike detector, keeps the live waveform and
/// stats for the sheet, and saves rough stretches into a `Trip`. Use from the main thread.
final class DriveViewModel: ObservableObject {
    struct Summary: Equatable {
        let roughSpots: Int
        let distanceMeters: Double
        let duration: TimeInterval
    }

    enum Phase: Equatable {
        case idle
        case running(isReplay: Bool)
        case finished(Summary)
    }

    // MARK: Published state

    @Published private(set) var phase: Phase = .idle
    /// Most recent vertical readings in g, for the waveform.
    @Published private(set) var waveform: [Double] = []
    @Published private(set) var rms = 0.0
    @Published private(set) var roughSpots = 0
    @Published private(set) var distanceMeters = 0.0
    @Published var errorMessage: String?

    /// Waveform window: about 3 seconds at 50 Hz.
    static let waveformLength = 150

    /// Live drives take their position from here (set by the view from `LocationManager`).
    var locationProvider: () -> GeoPoint? = { nil }

    private let repository: TripRepository
    private let live: MotionProviding
    private let makeReplay: () -> MotionProviding?
    private var provider: MotionProviding?
    private var detector = SpikeDetector(thresholdG: SettingsKey.Default.driveThresholdG)
    private var trip: Trip?
    private var lastPosition: GeoPoint?
    private var startedAt = Date()
    private var cancellables = Set<AnyCancellable>()

    init(persistence: PersistenceController,
         live: MotionProviding = MotionService(),
         makeReplay: @escaping () -> MotionProviding? = { ReplayMotionService.bundled() }) {
        repository = TripRepository(persistence: persistence)
        self.live = live
        self.makeReplay = makeReplay
    }

    var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    /// Real sensors exist (false on the simulator, where only the replay works).
    var isLiveAvailable: Bool { live.isAvailable }

    // MARK: Start / stop

    func start(replay: Bool, thresholdG: Double) {
        guard phase == .idle || isFinished else { return }
        let candidate: MotionProviding? = replay ? makeReplay() : live
        guard let source = candidate, source.isAvailable else {
            errorMessage = replay
                ? "The sample drive couldn't be loaded."
                : "Motion sensors aren't available on this device. Try the sample drive."
            return
        }
        do {
            trip = try repository.startTrip()
        } catch {
            errorMessage = "Couldn't start a trip. Please try again."
            return
        }
        errorMessage = nil
        resetStats()
        detector = SpikeDetector(thresholdG: thresholdG)
        startedAt = Date()
        provider = source
        source.samples
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.ingest($0) }
            .store(in: &cancellables)
        source.finished
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.stop() }
            .store(in: &cancellables)
        phase = .running(isReplay: replay)
        source.start()
    }

    func stop() {
        guard isRunning else { return }
        provider?.stop()
        provider = nil
        cancellables.removeAll()
        if let span = detector.finish() { save(span) }
        if let trip {
            do { try repository.finish(trip, distanceMeters: distanceMeters) } catch {
                errorMessage = "Couldn't save the trip."
            }
        }
        trip = nil
        phase = .finished(Summary(roughSpots: roughSpots,
                                  distanceMeters: distanceMeters,
                                  duration: Date().timeIntervalSince(startedAt)))
    }

    /// Back to the start screen after reading the summary.
    func dismissSummary() {
        guard isFinished else { return }
        phase = .idle
        resetStats()
    }

    private var isFinished: Bool {
        if case .finished = phase { return true }
        return false
    }

    // MARK: Samples

    func ingest(_ raw: MotionSample) {
        guard isRunning else { return }
        var sample = raw
        sample.position = raw.position ?? locationProvider()
        waveform.append(sample.z)
        if waveform.count > Self.waveformLength { waveform.removeFirst(waveform.count - Self.waveformLength) }
        if let position = sample.position {
            if let last = lastPosition { distanceMeters += last.distance(to: position) }
            lastPosition = position
        }
        let span = detector.ingest(sample)
        rms = detector.rms
        if let span { save(span) }
    }

    private func save(_ span: RoughSpan) {
        guard let trip else { return }
        do {
            if try repository.add(span, to: trip) != nil { roughSpots += 1 }
        } catch {
            errorMessage = "Couldn't save a rough stretch."
        }
    }

    private func resetStats() {
        waveform = []
        rms = 0
        roughSpots = 0
        distanceMeters = 0
        lastPosition = nil
    }
}
