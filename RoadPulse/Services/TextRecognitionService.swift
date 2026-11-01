import UIKit
import Vision

// MARK: - Text recognition (OCR)

protocol TextRecognizing {
    func recognizeText(in image: UIImage) async throws -> [RecognizedLine]
}

/// Reads text from a signboard photo with `VNRecognizeTextRequest`, off the main thread.
final class TextRecognitionService: TextRecognizing {
    func recognizeText(in image: UIImage) async throws -> [RecognizedLine] {
        guard let cgImage = image.cgImage else { throw ClassifierError.unreadableImage }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return try await Task.detached(priority: .userInitiated) { () throws -> [RecognizedLine] in
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])
            return (request.results ?? []).compactMap { observation -> RecognizedLine? in
                guard let best = observation.topCandidates(1).first else { return nil }
                return RecognizedLine(
                    text: best.string,
                    confidence: Double(best.confidence),
                    area: Double(observation.boundingBox.width * observation.boundingBox.height)
                )
            }
        }.value
    }
}
