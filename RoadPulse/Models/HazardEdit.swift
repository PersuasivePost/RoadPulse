import Foundation

// MARK: - Editable fields of a hazard

/// A copy of the fields the detail screen lets the user change, so edits stay local until
/// "Update" is tapped.
struct HazardEdit: Equatable {
    var type: HazardType
    var severity: Severity
    var notes: String

    init(_ hazard: Hazard) {
        type = hazard.hazardType
        severity = hazard.severityLevel
        notes = hazard.notes ?? ""
    }

    /// Notes with surrounding whitespace removed; empty means "no notes".
    var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whitespace-only differences in the notes don't count as a change.
    func differs(from other: HazardEdit) -> Bool {
        type != other.type || severity != other.severity || trimmedNotes != other.trimmedNotes
    }

    func apply(to hazard: Hazard) {
        hazard.hazardType = type
        hazard.severityLevel = severity
        hazard.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
    }
}
