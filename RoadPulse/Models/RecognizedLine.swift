import Foundation

// MARK: - One line of OCR output

struct RecognizedLine: Equatable {
    let text: String
    /// 0–1 recognition confidence.
    let confidence: Double
    /// Bounding-box area as a fraction of the image; big text is more likely the sign's name.
    let area: Double
}
