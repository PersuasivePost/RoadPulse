import Foundation

// MARK: - Classifier output

/// The top label from `RoadClassifier` ("pothole" or "normal") and how sure the model is.
struct ClassificationResult: Equatable {
    static let potholeLabel = "pothole"
    static let normalLabel = "normal"

    let label: String
    /// 0–1 confidence in `label`.
    let confidence: Double

    var isPothole: Bool { label == Self.potholeLabel }

    /// The model has two classes, so the other class gets the remainder.
    var potholeProbability: Double { isPothole ? confidence : 1 - confidence }

    /// Whole percent, rounded down so a 99.6% result never reads as a perfect 100%.
    var percent: Int { Int((min(max(confidence, 0), 1) * 100).rounded(.down)) }

    var suggestedSeverity: Severity {
        Severity.prefill(isPothole: isPothole, confidence: confidence)
    }

    var headline: String {
        isPothole ? "Pothole \(percent)%" : "No hazard detected"
    }
}
