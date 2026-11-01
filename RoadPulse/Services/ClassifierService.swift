import CoreML
import UIKit
import Vision

// MARK: - Classifier

protocol ImageClassifying {
    func classify(_ image: UIImage) async throws -> ClassificationResult
}

enum ClassifierError: LocalizedError, Equatable {
    case modelMissing
    case unreadableImage
    case noResult

    var errorDescription: String? {
        switch self {
        case .modelMissing:
            return "The hazard checker isn't available. Please reinstall RoadPulse."
        case .unreadableImage:
            return "That photo couldn't be read. Try another one."
        case .noResult:
            return "The photo couldn't be analysed. Try another one."
        }
    }
}

/// Runs `RoadClassifier.mlpackage` through Vision. The compiled model is loaded once; each
/// request runs on a background task, so the UI stays responsive (and the scan animation moves).
final class ClassifierService: ImageClassifying {
    private let model: VNCoreMLModel

    /// - Parameter computeUnits: `.all` on devices; tests use `.cpuOnly` for deterministic CI runs.
    init(bundle: Bundle = Bundle(for: ClassifierService.self), computeUnits: MLComputeUnits = .all) throws {
        guard let url = bundle.url(forResource: "RoadClassifier", withExtension: "mlmodelc") else {
            throw ClassifierError.modelMissing
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = computeUnits
        model = try VNCoreMLModel(for: MLModel(contentsOf: url, configuration: configuration))
    }

    func classify(_ image: UIImage) async throws -> ClassificationResult {
        guard let cgImage = image.cgImage else { throw ClassifierError.unreadableImage }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let model = model

        // Vision's `perform` blocks until the model finishes, so it runs off the main thread.
        return try await Task.detached(priority: .userInitiated) { () throws -> ClassificationResult in
            let request = VNCoreMLRequest(model: model)
            // Training squashed photos to 224×224 (no crop), so Vision must do the same.
            request.imageCropAndScaleOption = .scaleFill
            try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
            guard let top = (request.results as? [VNClassificationObservation])?.first else {
                throw ClassifierError.noResult
            }
            return ClassificationResult(label: top.identifier, confidence: Double(top.confidence))
        }.value
    }
}
