import CoreLocation
import UIKit
import XCTest
@testable import RoadPulse

// MARK: - Test doubles

private final class MockClassifier: ImageClassifying {
    var outcome: Result<ClassificationResult, Error>
    private(set) var calls = 0

    init(_ outcome: Result<ClassificationResult, Error>) { self.outcome = outcome }

    func classify(_ image: UIImage) async throws -> ClassificationResult {
        calls += 1
        return try outcome.get()
    }
}

/// Takes a while to answer, like a real model on a slow device.
private final class SlowClassifier: ImageClassifying {
    let result: ClassificationResult
    let delay: UInt64

    init(result: ClassificationResult, delay: UInt64) {
        self.result = result
        self.delay = delay
    }

    func classify(_ image: UIImage) async throws -> ClassificationResult {
        try? await Task.sleep(nanoseconds: delay)
        return result
    }
}

private final class MockRecognizer: TextRecognizing {
    var lines: [RecognizedLine] = []
    var error: Error?

    func recognizeText(in image: UIImage) async throws -> [RecognizedLine] {
        if let error { throw error }
        return lines
    }
}

private final class MockReverseGeocoder: ReverseGeocodingProviding {
    var place: PlaceDetails? = PlaceDetails(address: "LBS Marg, Ghatkopar, Mumbai", area: "Ghatkopar", city: "Mumbai")
    var error: Error?
    private(set) var calls = 0

    func placeDetails(for location: CLLocation) async throws -> PlaceDetails? {
        calls += 1
        if let error { throw error }
        return place
    }
}

private struct Boom: Error {}

private let pothole = ClassificationResult(label: "pothole", confidence: 0.97)
private let normal = ClassificationResult(label: "normal", confidence: 0.92)
private let ghatkopar = CLLocation(latitude: 19.0864, longitude: 72.9079)

// MARK: - Tests

@MainActor
final class ReportViewModelTests: XCTestCase {
    private var classifier = MockClassifier(.success(pothole))
    private var recognizer = MockRecognizer()
    private var geocoder = MockReverseGeocoder()

    private func makeViewModel(store: PersistenceController? = nil) -> ReportViewModel {
        let classifier = classifier
        return ReportViewModel(persistence: store ?? TestStore.make(),
                               makeClassifier: { classifier },
                               textRecognizer: recognizer,
                               geocoder: geocoder,
                               minimumAnalysisTime: .zero)
    }

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 64, height: 48), format: format).image { context in
            UIColor.darkGray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 48))
        }
    }

    /// A view model that has loaded a photo, analysed it and has a location.
    private func readyViewModel(store: PersistenceController? = nil) async -> ReportViewModel {
        let viewModel = makeViewModel(store: store)
        await viewModel.load(makeImage())
        await viewModel.analyze()
        viewModel.updateLocation(ghatkopar)
        await viewModel.resolvePlace()
        return viewModel
    }

    // MARK: Starting a report

    func testLoadingAPhotoStartsTheFlowAtAnalyze() async {
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())

        XCTAssertNotNil(viewModel.image)
        XCTAssertEqual(viewModel.path.count, 1)
        XCTAssertEqual(viewModel.analysis, .idle)
    }

    func testUnreadableDataShowsFriendlyError() async {
        let viewModel = makeViewModel()
        await viewModel.load(data: Data([0, 1, 2]))

        XCTAssertNil(viewModel.image)
        XCTAssertEqual(viewModel.path.count, 0)
        XCTAssertEqual(viewModel.errorMessage, ClassifierError.unreadableImage.errorDescription)
    }

    // MARK: Analysis

    func testPotholeResultPrefillsSeverityAndType() async {
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())

        await viewModel.analyze()

        XCTAssertEqual(viewModel.analysis, .finished(pothole))
        XCTAssertEqual(viewModel.severity, .severe, "0.97 confidence")
        XCTAssertEqual(viewModel.type, .pothole)
    }

    func testNormalResultCanBeOverriddenManually() async {
        classifier.outcome = .success(normal)
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())
        await viewModel.analyze()
        XCTAssertEqual(viewModel.severity, .minor)
        XCTAssertFalse(viewModel.isManualOverride)

        viewModel.reportAnyway()

        XCTAssertTrue(viewModel.isManualOverride)
        XCTAssertEqual(viewModel.path.count, 2, "Analyze + Details")
    }

    func testFinishedAnalysisIsNotRepeatedWhenReturningToTheStep() async {
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())
        await viewModel.analyze()
        await viewModel.analyze()
        XCTAssertEqual(classifier.calls, 1)
    }

    func testLateResultForAnAbandonedPhotoIsIgnored() async {
        let slow = SlowClassifier(result: pothole, delay: 200_000_000)
        let viewModel = ReportViewModel(persistence: TestStore.make(), makeClassifier: { slow },
                                        textRecognizer: recognizer, geocoder: geocoder, minimumAnalysisTime: .zero)
        await viewModel.load(makeImage())
        let firstAnalysis = Task { await viewModel.analyze() }
        try? await Task.sleep(nanoseconds: 20_000_000) // analysis is now in flight

        viewModel.goBack()                // user abandons the first photo…
        await viewModel.load(makeImage()) // …and picks another one
        await firstAnalysis.value         // the first model run finishes late

        XCTAssertEqual(viewModel.analysis, .idle, "the old result must not land on the new photo")
        XCTAssertEqual(viewModel.path.count, 1)
    }

    func testFailureIsFriendlyAndCanBeRetried() async {
        classifier.outcome = .failure(ClassifierError.noResult)
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())

        await viewModel.analyze()
        XCTAssertEqual(viewModel.analysis, .failed(ClassifierError.noResult.errorDescription ?? ""))

        classifier.outcome = .success(pothole)
        await viewModel.analyze()
        XCTAssertEqual(viewModel.analysis, .finished(pothole))
    }

    func testUnexpectedErrorGetsGenericMessage() async {
        classifier.outcome = .failure(Boom())
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())
        await viewModel.analyze()
        XCTAssertEqual(viewModel.analysis, .failed("The photo couldn't be analysed."))
    }

    // MARK: Place and signboard

    func testResolvePlaceFillsAddressAndSkipsNearbyRepeats() async {
        let viewModel = makeViewModel()
        viewModel.updateLocation(ghatkopar)

        await viewModel.resolvePlace()
        XCTAssertEqual(viewModel.place?.area, "Ghatkopar")
        await viewModel.resolvePlace()
        XCTAssertEqual(geocoder.calls, 1)

        viewModel.updateLocation(CLLocation(latitude: 19.2183, longitude: 72.9781)) // Thane, far away
        await viewModel.resolvePlace()
        XCTAssertEqual(geocoder.calls, 2)
    }

    func testGeocodingFailureIsNotFatal() async {
        geocoder.error = Boom()
        let viewModel = makeViewModel()
        viewModel.updateLocation(ghatkopar)

        await viewModel.resolvePlace()

        XCTAssertNil(viewModel.place)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.canReview, "coordinates alone are enough to report")
    }

    func testScanningASignFillsLandmarkAndOffersAlternatives() async {
        recognizer.lines = [RecognizedLine(text: "KALYAN STATION", confidence: 0.95, area: 0.2),
                            RecognizedLine(text: "Road No. 4", confidence: 0.9, area: 0.02)]
        let viewModel = makeViewModel()

        await viewModel.scanSign(makeImage())

        XCTAssertEqual(viewModel.landmark, "KALYAN STATION")
        XCTAssertEqual(viewModel.landmarkCandidates, ["KALYAN STATION", "Road No. 4"])
        XCTAssertFalse(viewModel.isScanningSign)
    }

    func testScanningASignWithNoTextExplainsWhy() async {
        let viewModel = makeViewModel()
        await viewModel.scanSign(makeImage())
        XCTAssertTrue(viewModel.landmark.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testScanningFailureShowsMessage() async {
        recognizer.error = Boom()
        let viewModel = makeViewModel()
        await viewModel.scanSign(makeImage())
        XCTAssertEqual(viewModel.errorMessage, "The sign couldn't be read. Please try again.")
    }

    // MARK: Navigation

    func testReviewNeedsALocation() async {
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())
        viewModel.continueToConfirm()
        XCTAssertEqual(viewModel.path.count, 1, "no location, so Confirm isn't reachable")

        viewModel.updateLocation(ghatkopar)
        viewModel.continueToConfirm()
        XCTAssertEqual(viewModel.path.count, 2)
    }

    func testBackFromAnalyzeClearsThePhotoButLaterStepsKeepEdits() async {
        let viewModel = await readyViewModel()
        viewModel.continueToDetails()
        viewModel.notes = "Deep one"
        XCTAssertEqual(viewModel.path.count, 2)

        viewModel.goBack()
        XCTAssertEqual(viewModel.path.count, 1)
        XCTAssertEqual(viewModel.notes, "Deep one")

        viewModel.goBack()
        XCTAssertEqual(viewModel.path.count, 0)
        XCTAssertNil(viewModel.image)
        XCTAssertEqual(viewModel.notes, "")
    }

    func testResetReturnsToAnEmptyCapture() async {
        let viewModel = await readyViewModel()
        viewModel.landmark = "Somewhere"
        viewModel.reset()

        XCTAssertEqual(viewModel.path.count, 0)
        XCTAssertNil(viewModel.image)
        XCTAssertEqual(viewModel.analysis, .idle)
        XCTAssertEqual(viewModel.landmark, "")
        XCTAssertEqual(viewModel.saveState, .idle)
    }

    // MARK: Draft

    func testDraftNeedsALocation() async {
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())
        XCTAssertNil(viewModel.makeDraft())
    }

    func testDraftReflectsEveryField() async throws {
        let viewModel = await readyViewModel()
        viewModel.type = .crack
        viewModel.severity = .high
        viewModel.notes = "  Near the bus stop \n"
        viewModel.landmark = "   "
        viewModel.isAlreadyFixed = true

        let draft = try XCTUnwrap(viewModel.makeDraft())

        XCTAssertEqual(draft.type, .crack)
        XCTAssertEqual(draft.severity, .high)
        XCTAssertEqual(draft.status, .fixed)
        XCTAssertEqual(draft.notes, "Near the bus stop")
        XCTAssertNil(draft.landmark, "blank landmark is not stored")
        XCTAssertEqual(draft.confidence, 0.97, accuracy: 0.0001)
        XCTAssertEqual(draft.latitude, 19.0864, accuracy: 0.00001)
        XCTAssertEqual(draft.longitude, 72.9079, accuracy: 0.00001)
        XCTAssertEqual(draft.address, "LBS Marg, Ghatkopar, Mumbai")
        XCTAssertEqual(draft.areaName, "Ghatkopar")
        XCTAssertEqual(draft.city, "Mumbai")
        XCTAssertNotNil(draft.photo)
    }

    func testDraftWithoutAddressStillGetsAnArea() async throws {
        geocoder.place = nil
        let viewModel = await readyViewModel()
        let draft = try XCTUnwrap(viewModel.makeDraft())
        XCTAssertNil(draft.address)
        XCTAssertEqual(draft.areaName, "Unknown area")
    }

    // MARK: Saving

    func testSavePersistsTheHazardAndItsArea() async throws {
        let store = TestStore.make()
        let viewModel = await readyViewModel(store: store)
        viewModel.severity = .high
        viewModel.landmark = "Ghatkopar Station"

        await viewModel.save()

        guard case .saved(let id) = viewModel.saveState else {
            return XCTFail("Expected .saved, got \(viewModel.saveState)")
        }
        let repo = HazardRepository(persistence: store)
        let hazard = try XCTUnwrap(repo.hazard(id: id))
        XCTAssertEqual(hazard.severityLevel, .high)
        XCTAssertEqual(hazard.landmark, "Ghatkopar Station")
        XCTAssertEqual(hazard.area?.name, "Ghatkopar")
        XCTAssertEqual(hazard.area?.city, "Mumbai")
        XCTAssertNotNil(hazard.photo)
        XCTAssertEqual(hazard.coordinate.latitude, 19.0864, accuracy: 0.00001)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSecondReportInTheSameAreaReusesIt() async throws {
        let store = TestStore.make()
        for _ in 0 ..< 2 {
            let viewModel = await readyViewModel(store: store)
            await viewModel.save()
        }
        let repo = HazardRepository(persistence: store)
        XCTAssertEqual(try repo.count(), 2)
        XCTAssertEqual(try repo.areas().count, 1)
    }

    func testSaveDoesNothingWithoutALocation() async {
        let viewModel = makeViewModel()
        await viewModel.load(makeImage())
        await viewModel.save()
        XCTAssertEqual(viewModel.saveState, .idle)
    }
}
