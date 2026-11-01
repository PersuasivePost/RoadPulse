import Combine
import CoreMotion
import Foundation

// MARK: - Motion source

/// Anything that produces vertical-acceleration samples: the real sensors or a recorded drive.
protocol MotionProviding: AnyObject {
    var samples: AnyPublisher<MotionSample, Never> { get }
    /// Fires once when a replay reaches its end (never for live sensors).
    var finished: AnyPublisher<Void, Never> { get }
    var isAvailable: Bool { get }
    func start()
    func stop()
}

// MARK: - CoreMotion (50 Hz)

final class MotionService: MotionProviding {
    static let updateInterval: TimeInterval = 1.0 / 50.0

    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    private let subject = PassthroughSubject<MotionSample, Never>()

    var samples: AnyPublisher<MotionSample, Never> { subject.eraseToAnyPublisher() }
    var finished: AnyPublisher<Void, Never> { Empty<Void, Never>().eraseToAnyPublisher() }
    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    init() {
        queue.name = "roadpulse.motion"
        queue.maxConcurrentOperationCount = 1
    }

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = Self.updateInterval
        manager.startDeviceMotionUpdates(to: queue) { [subject] motion, _ in
            guard let motion else { return }
            subject.send(MotionSample(time: motion.timestamp, z: Self.vertical(motion), position: nil))
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }

    /// Vertical acceleration in g, whatever way the phone is mounted: `userAcceleration` (gravity
    /// already removed) projected onto the gravity direction.
    static func vertical(_ motion: CMDeviceMotion) -> Double {
        let a = motion.userAcceleration
        let g = motion.gravity
        return verticalComponent(ax: a.x, ay: a.y, az: a.z, gx: g.x, gy: g.y, gz: g.z)
    }

    static func verticalComponent(ax: Double, ay: Double, az: Double,
                                  gx: Double, gy: Double, gz: Double) -> Double {
        let length = (gx * gx + gy * gy + gz * gz).squareRoot()
        guard length > 0 else { return az }
        return (ax * gx + ay * gy + az * gz) / length
    }
}

// MARK: - Replay of a recorded drive

/// Plays recorded samples back in (scaled) real time. Works on the simulator, which has no sensors.
final class ReplayMotionService: MotionProviding {
    private let recorded: [MotionSample]
    private let speed: Double
    private let subject = PassthroughSubject<MotionSample, Never>()
    private let finishedSubject = PassthroughSubject<Void, Never>()
    private var timer: Timer?
    private var index = 0
    private var startedAt = Date()

    var samples: AnyPublisher<MotionSample, Never> { subject.eraseToAnyPublisher() }
    var finished: AnyPublisher<Void, Never> { finishedSubject.eraseToAnyPublisher() }
    var isAvailable: Bool { !recorded.isEmpty }

    init(samples: [MotionSample], speed: Double = 1) {
        recorded = samples
        self.speed = max(speed, 0.1)
    }

    /// The CSV in the app bundle; `nil` if it's missing.
    static func bundled(speed: Double = 1) -> ReplayMotionService? {
        let samples = SampleDrive.load()
        return samples.isEmpty ? nil : ReplayMotionService(samples: samples, speed: speed)
    }

    func start() {
        stop()
        index = 0
        startedAt = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in self?.tick() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let elapsed = Date().timeIntervalSince(startedAt) * speed
        while index < recorded.count, recorded[index].time <= elapsed {
            subject.send(recorded[index])
            index += 1
        }
        if index >= recorded.count {
            stop()
            finishedSubject.send()
        }
    }
}
