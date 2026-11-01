import UIKit
import XCTest
@testable import RoadPulse

/// Runs the real Vision OCR on a bundled signboard image ("KALYAN STATION / Road No. 4").
final class TextRecognitionServiceTests: XCTestCase {
    func testReadsTheSignboardAndPicksTheBigTextAsLandmark() async throws {
        let image = try XCTUnwrap(SampleImages.signboard, "signboard_sample.jpg missing from the app bundle")

        let lines = try await TextRecognitionService().recognizeText(in: image)

        let joined = lines.map(\.text).joined(separator: " ").lowercased()
        XCTAssertTrue(joined.contains("kalyan"), "OCR output was: \(joined)")
        let candidates = LandmarkPicker.candidates(from: lines)
        XCTAssertEqual(candidates.first?.lowercased().contains("kalyan"), true,
                       "the biggest text should come first; got \(candidates)")
    }

    func testImageWithoutPixelsThrows() async {
        do {
            _ = try await TextRecognitionService().recognizeText(in: UIImage())
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? ClassifierError, .unreadableImage)
        }
    }
}
