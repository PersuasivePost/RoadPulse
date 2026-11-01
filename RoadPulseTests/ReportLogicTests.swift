import ImageIO
import UIKit
import XCTest
@testable import RoadPulse

final class ReportLogicTests: XCTestCase {
    // MARK: Severity prefill (docs/ARCHITECTURE.md)

    func testPrefillBoundaries() {
        XCTAssertEqual(Severity.prefill(isPothole: true, confidence: 1.0), .severe)
        XCTAssertEqual(Severity.prefill(isPothole: true, confidence: 0.95), .severe)
        XCTAssertEqual(Severity.prefill(isPothole: true, confidence: 0.949), .high)
        XCTAssertEqual(Severity.prefill(isPothole: true, confidence: 0.85), .high)
        XCTAssertEqual(Severity.prefill(isPothole: true, confidence: 0.849), .medium)
        XCTAssertEqual(Severity.prefill(isPothole: true, confidence: 0.7), .medium)
        XCTAssertEqual(Severity.prefill(isPothole: true, confidence: 0.699), .low)
        XCTAssertEqual(Severity.prefill(isPothole: true, confidence: 0.5), .low)
    }

    func testNormalAlwaysPrefillsLowest() {
        XCTAssertEqual(Severity.prefill(isPothole: false, confidence: 0.99), .minor)
        XCTAssertEqual(Severity.prefill(isPothole: false, confidence: 0.2), .minor)
    }

    // MARK: Classification result

    func testPercentRoundsDownSoNearlyCertainIsNotAHundred() {
        XCTAssertEqual(ClassificationResult(label: "pothole", confidence: 0.996).percent, 99)
        XCTAssertEqual(ClassificationResult(label: "pothole", confidence: 1.0).percent, 100)
        XCTAssertEqual(ClassificationResult(label: "pothole", confidence: 1.4).percent, 100, "clamped")
    }

    func testHeadlines() {
        XCTAssertEqual(ClassificationResult(label: "pothole", confidence: 0.934).headline, "Pothole 93%")
        XCTAssertEqual(ClassificationResult(label: "normal", confidence: 0.9).headline, "No hazard detected")
    }

    func testPotholeProbabilityIsTheComplementForNormal() {
        XCTAssertEqual(ClassificationResult(label: "pothole", confidence: 0.9).potholeProbability, 0.9, accuracy: 0.0001)
        XCTAssertEqual(ClassificationResult(label: "normal", confidence: 0.9).potholeProbability, 0.1, accuracy: 0.0001)
    }

    func testSuggestedSeverityFollowsConfidence() {
        XCTAssertEqual(ClassificationResult(label: "pothole", confidence: 0.97).suggestedSeverity, .severe)
        XCTAssertEqual(ClassificationResult(label: "normal", confidence: 0.97).suggestedSeverity, .minor)
    }

    // MARK: Place details

    func testPlaceDetailsBuildsAddressAndArea() {
        let place = PlaceDetails.make(street: "12 LBS Marg", subLocality: "Ghatkopar West",
                                      locality: "Mumbai", administrativeArea: "Maharashtra")
        XCTAssertEqual(place?.address, "12 LBS Marg, Ghatkopar West, Mumbai")
        XCTAssertEqual(place?.area, "Ghatkopar West")
        XCTAssertEqual(place?.city, "Mumbai")
    }

    func testPlaceDetailsFallsBackToLocalityAndDropsRepeats() {
        let place = PlaceDetails.make(street: "  ", subLocality: nil, locality: "Thane", administrativeArea: "MH")
        XCTAssertEqual(place?.area, "Thane")
        XCTAssertEqual(place?.city, "Thane")
        XCTAssertEqual(place?.address, "Thane")

        let repeated = PlaceDetails.make(street: nil, subLocality: "Thane", locality: "Thane", administrativeArea: nil)
        XCTAssertEqual(repeated?.address, "Thane")
    }

    func testPlaceDetailsIsNilWithoutAnyNeighbourhood() {
        XCTAssertNil(PlaceDetails.make(street: "Some Road", subLocality: nil, locality: "", administrativeArea: "MH"))
    }

    // MARK: Landmark candidates

    func testLandmarkCandidatesPreferBigReadableText() {
        let lines = [
            RecognizedLine(text: "Road No. 4", confidence: 0.9, area: 0.02),
            RecognizedLine(text: "KALYAN STATION", confidence: 0.95, area: 0.2),
            RecognizedLine(text: "|", confidence: 0.9, area: 0.5),
            RecognizedLine(text: "42", confidence: 0.9, area: 0.4),
            RecognizedLine(text: "blurry", confidence: 0.1, area: 0.9),
        ]
        XCTAssertEqual(LandmarkPicker.candidates(from: lines), ["KALYAN STATION", "Road No. 4"])
    }

    func testLandmarkCandidatesAreDedupedAndCapped() {
        let repeated = (0 ..< 3).map { _ in RecognizedLine(text: "Thane Naka", confidence: 0.9, area: 0.1) }
        XCTAssertEqual(LandmarkPicker.candidates(from: repeated), ["Thane Naka"])

        let many = (0 ..< 10).map { RecognizedLine(text: "Sign \($0)", confidence: 0.9, area: Double($0) / 10) }
        XCTAssertEqual(LandmarkPicker.candidates(from: many).count, LandmarkPicker.maximumCandidates)
    }

    // MARK: Steps

    func testStepNumbersFollowTheFourDashProgress() {
        XCTAssertEqual([ReportStep.analyze, .details, .confirm].map(\.number), [2, 3, 4])
        XCTAssertEqual(ReportStep.total, 4)
    }

    // MARK: Image preparation

    func testLargeImagesAreScaledDownKeepingAspectRatio() {
        let source = makeImage(width: 3000, height: 1500)
        let prepared = ImageProcessing.prepared(source, maxDimension: 1024)
        XCTAssertEqual(prepared.size.width, 1024, accuracy: 1)
        XCTAssertEqual(prepared.size.height, 512, accuracy: 1)
        XCTAssertEqual(prepared.scale, 1)
    }

    func testSmallImagesAreNotUpscaled() {
        let prepared = ImageProcessing.prepared(makeImage(width: 400, height: 300), maxDimension: 1024)
        XCTAssertEqual(prepared.size.width, 400, accuracy: 1)
        XCTAssertEqual(prepared.size.height, 300, accuracy: 1)
    }

    func testRotatedPhotosComeOutUpright() throws {
        // A camera photo: pixels are 400×200 landscape, EXIF says "rotate right", so it displays 200×400.
        let cgImage = try XCTUnwrap(makeImage(width: 400, height: 200).cgImage)
        let rotated = UIImage(cgImage: cgImage, scale: 1, orientation: .right)
        XCTAssertEqual(rotated.size.width, 200)

        let prepared = ImageProcessing.prepared(rotated)

        XCTAssertEqual(prepared.imageOrientation, .up)
        XCTAssertEqual(prepared.size.width, 200, accuracy: 1)
        XCTAssertEqual(prepared.size.height, 400, accuracy: 1)
        XCTAssertEqual(CGImagePropertyOrientation(UIImage.Orientation.right), .right)
    }

    func testJPEGDataIsProduced() {
        XCTAssertNotNil(ImageProcessing.jpegData(makeImage(width: 64, height: 64)))
    }

    private func makeImage(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
