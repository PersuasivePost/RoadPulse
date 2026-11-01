import CoreML
import UIKit
import XCTest
@testable import RoadPulse

/// Runs the real `RoadClassifier` model on the bundled held-out sample photos.
final class ClassifierServiceTests: XCTestCase {
    private func makeService() throws -> ClassifierService {
        // CPU only: deterministic, and the simulator has no Neural Engine anyway.
        try ClassifierService(computeUnits: .cpuOnly)
    }

    // MARK: Real photos

    func testPotholeSamplesAreClassifiedAsPotholeAtEightyPercentOrMore() async throws {
        let service = try makeService()
        let samples = SampleImages.all.filter(\.isPothole)
        XCTAssertGreaterThanOrEqual(samples.count, 3)

        for sample in samples {
            let image = try XCTUnwrap(SampleImages.image(for: sample), "\(sample.resource).jpg is missing")
            let result = try await service.classify(image)
            XCTAssertTrue(result.isPothole, "\(sample.resource) → \(result)")
            XCTAssertGreaterThanOrEqual(result.confidence, 0.8, "\(sample.resource) → \(result)")
            XCTAssertGreaterThanOrEqual(result.percent, 80)
        }
    }

    func testNormalSamplesAreClassifiedAsNormal() async throws {
        let service = try makeService()
        for sample in SampleImages.all where !sample.isPothole {
            let image = try XCTUnwrap(SampleImages.image(for: sample), "\(sample.resource).jpg is missing")
            let result = try await service.classify(image)
            XCTAssertFalse(result.isPothole, "\(sample.resource) → \(result)")
            XCTAssertEqual(result.headline, "No hazard detected")
        }
    }

    func testPhotoStillClassifiesAfterReportPreparation() async throws {
        // The app classifies the prepared (upright, <= 1024 px) image, not the original.
        let service = try makeService()
        let original = try XCTUnwrap(SampleImages.image(resource: "pothole_sample_2"))
        let prepared = ImageProcessing.prepared(original)

        let result = try await service.classify(prepared)

        XCTAssertTrue(result.isPothole)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
    }

    func testResultIsAProbabilityOverTheTwoClasses() async throws {
        let service = try makeService()
        let image = try XCTUnwrap(SampleImages.image(resource: "pothole_sample_1"))
        let result = try await service.classify(image)
        XCTAssertTrue(["pothole", "normal"].contains(result.label))
        XCTAssertGreaterThan(result.confidence, 0.5)
        XCTAssertLessThanOrEqual(result.confidence, 1)
    }

    // MARK: Errors

    func testMissingModelThrowsFriendlyError() throws {
        let emptyBundle = try XCTUnwrap(Bundle(path: NSTemporaryDirectory()))
        XCTAssertThrowsError(try ClassifierService(bundle: emptyBundle)) { error in
            XCTAssertEqual(error as? ClassifierError, .modelMissing)
            XCTAssertNotNil((error as? LocalizedError)?.errorDescription)
        }
    }

    func testImageWithoutPixelsThrowsUnreadable() async throws {
        let service = try makeService()
        do {
            _ = try await service.classify(UIImage())
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? ClassifierError, .unreadableImage)
        }
    }

    // MARK: Fixtures

    func testEverySampleResourceIsBundled() {
        for sample in SampleImages.all {
            XCTAssertNotNil(SampleImages.image(for: sample), "\(sample.resource).jpg missing from the app bundle")
        }
        XCTAssertNotNil(SampleImages.signboard)
    }
}
