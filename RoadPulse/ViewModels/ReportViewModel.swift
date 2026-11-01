import CoreLocation
import SwiftUI

// MARK: - Report flow view model

/// All state for one report, from photo to saved hazard. Async methods are `@MainActor`, so
/// every `@Published` change after an `await` lands on the main thread; the heavy work
/// (Vision, geocoding, saving) runs in the services.
final class ReportViewModel: ObservableObject {
    // MARK: Navigation

    /// The flow's `NavigationPath`; Capture is the root, the rest are pushed.
    @Published var path = NavigationPath()

    // MARK: Photo and analysis

    @Published private(set) var image: UIImage?
    @Published private(set) var analysis: Analysis = .idle
    /// The user chose to report a photo the model called "normal".
    @Published private(set) var isManualOverride = false

    // MARK: Details the user edits

    @Published var type: HazardType = .pothole
    @Published var severity: Severity = .medium
    @Published var notes = ""
    @Published var isAlreadyFixed = false
    @Published var landmark = ""

    // MARK: Location, place and signboard

    @Published private(set) var location: CLLocation?
    @Published private(set) var place: PlaceDetails?
    @Published private(set) var isFindingPlace = false
    @Published private(set) var landmarkCandidates: [String] = []
    @Published private(set) var isScanningSign = false

    // MARK: Saving and errors

    @Published private(set) var saveState: SaveState = .idle
    /// A user-friendly message; the flow shows it in an alert and clears it.
    @Published var errorMessage: String?

    private let repository: HazardRepository
    private let makeClassifier: () throws -> ImageClassifying
    private let textRecognizer: TextRecognizing
    private let geocoder: ReverseGeocodingProviding
    private let minimumAnalysisTime: Duration
    private var classifier: ImageClassifying?
    private var placeLocation: CLLocation?

    // MARK: Init

    init(persistence: PersistenceController,
         makeClassifier: @escaping () throws -> ImageClassifying = { try ClassifierService() },
         textRecognizer: TextRecognizing = TextRecognitionService(),
         geocoder: ReverseGeocodingProviding = GeocodingService(),
         minimumAnalysisTime: Duration = .seconds(1.4)) {
        repository = HazardRepository(persistence: persistence)
        self.makeClassifier = makeClassifier
        self.textRecognizer = textRecognizer
        self.geocoder = geocoder
        self.minimumAnalysisTime = minimumAnalysisTime
    }

    // MARK: Derived

    var result: ClassificationResult? {
        if case .finished(let result) = analysis { return result }
        return nil
    }

    /// A report needs a position; without one the hazard can't be placed on the map.
    var canReview: Bool { location != nil }

    // MARK: Photo

    /// Straightens and shrinks the photo off the main thread, then starts the flow.
    @MainActor
    func load(_ rawImage: UIImage) async {
        let prepared = await Task.detached(priority: .userInitiated) {
            ImageProcessing.prepared(rawImage)
        }.value
        startReport(with: prepared)
    }

    @MainActor
    func load(data: Data) async {
        guard let image = UIImage(data: data) else {
            errorMessage = ClassifierError.unreadableImage.errorDescription
            return
        }
        await load(image)
    }

    private func startReport(with prepared: UIImage) {
        resetFields()
        image = prepared
        path.append(ReportStep.analyze)
    }

    // MARK: Analysis

    @MainActor
    func analyze() async {
        guard let image, analysis == .idle || isFailed else { return }
        analysis = .analyzing
        do {
            let classifier = try self.classifier ?? makeClassifier()
            self.classifier = classifier
            let started = ContinuousClock.now
            let result = try await classifier.classify(image)
            // Let the scan animation play even when the model answers instantly.
            let remaining = minimumAnalysisTime - (ContinuousClock.now - started)
            if remaining > .zero { try? await Task.sleep(for: remaining) }
            // The user may have gone back and picked another photo while this one was analysed.
            guard self.image === image else { return }
            apply(result)
        } catch {
            guard self.image === image else { return }
            analysis = .failed((error as? LocalizedError)?.errorDescription ?? "The photo couldn't be analysed.")
        }
    }

    private var isFailed: Bool {
        if case .failed = analysis { return true }
        return false
    }

    private func apply(_ result: ClassificationResult) {
        severity = result.suggestedSeverity
        type = .pothole
        analysis = .finished(result)
    }

    /// The model said "normal" but the user can see a hazard.
    func reportAnyway() {
        isManualOverride = true
        path.append(ReportStep.details)
    }

    func continueToDetails() {
        path.append(ReportStep.details)
    }

    func continueToConfirm() {
        guard canReview else { return }
        path.append(ReportStep.confirm)
    }

    /// Back from Analyze returns to a clean Capture (a new photo starts a new report);
    /// from any later step it goes back one step and keeps the edits.
    func goBack() {
        if path.count <= 1 {
            reset()
        } else {
            path.removeLast()
        }
    }

    // MARK: Location and place

    func updateLocation(_ newLocation: CLLocation?) {
        location = newLocation
    }

    /// Looks up the address once per position (skips if within 50 m of the last lookup).
    @MainActor
    func resolvePlace() async {
        guard let location else { return }
        if let placeLocation, placeLocation.distance(from: location) < 50, place != nil { return }
        isFindingPlace = true
        defer { isFindingPlace = false }
        do {
            place = try await geocoder.placeDetails(for: location)
            placeLocation = location
        } catch {
            place = nil // not fatal: the report can still be saved with coordinates only
        }
    }

    // MARK: Signboard OCR

    @MainActor
    func scanSign(_ rawImage: UIImage) async {
        isScanningSign = true
        defer { isScanningSign = false }
        do {
            let lines = try await textRecognizer.recognizeText(in: rawImage)
            let candidates = LandmarkPicker.candidates(from: lines)
            landmarkCandidates = candidates
            if let first = candidates.first {
                landmark = first
            } else {
                errorMessage = "No readable text found. Try a closer, straighter photo of the sign."
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "The sign couldn't be read. Please try again."
        }
    }

    // MARK: Saving (the draft itself is built in ReportViewModel+Draft.swift)

    @MainActor
    func save() async {
        guard saveState != .saving, let draft = makeDraft() else { return }
        saveState = .saving
        do {
            let objectID = try await repository.createInBackground(draft)
            guard let hazard = repository.hazard(objectID: objectID) else {
                throw PersistenceError.saveFailed("saved hazard not found")
            }
            saveState = .saved(hazard.id)
        } catch {
            saveState = .failed((error as? LocalizedError)?.errorDescription ?? "Your report couldn't be saved.")
            errorMessage = saveStateMessage
        }
    }

    private var saveStateMessage: String? {
        if case .failed(let message) = saveState { return message }
        return nil
    }

    // MARK: Reset

    /// Back to an empty Capture screen.
    func reset() {
        path = NavigationPath()
        resetFields()
    }

    private func resetFields() {
        image = nil
        analysis = .idle
        isManualOverride = false
        type = .pothole
        severity = .medium
        notes = ""
        isAlreadyFixed = false
        landmark = ""
        landmarkCandidates = []
        place = nil
        placeLocation = nil
        saveState = .idle
    }
}
