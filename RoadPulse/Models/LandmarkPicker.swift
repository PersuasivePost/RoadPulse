import Foundation

// MARK: - Choosing landmark names from OCR text

enum LandmarkPicker {
    static let minimumConfidence = 0.3
    static let maximumCandidates = 4

    /// Readable lines from a signboard photo, biggest text first, without junk or repeats.
    static func candidates(from lines: [RecognizedLine]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        let usable = lines
            .filter { $0.confidence >= minimumConfidence }
            .sorted { $0.area > $1.area }
        for line in usable {
            let text = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard isReadable(text), seen.insert(text.lowercased()).inserted else { continue }
            result.append(text)
            if result.count == maximumCandidates { break }
        }
        return result
    }

    /// At least three characters and two letters, so "|", "4" and "--" are dropped.
    private static func isReadable(_ text: String) -> Bool {
        text.count >= 3 && text.filter(\.isLetter).count >= 2
    }
}
