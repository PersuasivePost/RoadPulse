import CoreLocation
import UIKit

// MARK: - Building the hazard to save

extension ReportViewModel {
    /// Everything the repository needs, built from the current state. `nil` until there's a location.
    func makeDraft() -> HazardDraft? {
        guard let location else { return nil }
        var draft = HazardDraft()
        draft.type = type
        draft.severity = severity
        draft.confidence = result?.potholeProbability ?? 0
        draft.status = isAlreadyFixed ? .fixed : .open
        draft.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        draft.landmark = landmark.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        draft.photo = image.flatMap { ImageProcessing.jpegData($0) }
        draft.latitude = location.coordinate.latitude
        draft.longitude = location.coordinate.longitude
        draft.address = place?.address
        draft.areaName = place?.area ?? "Unknown area"
        draft.city = place?.city ?? "Unknown"
        return draft
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
