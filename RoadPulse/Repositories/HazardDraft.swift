import Foundation

// MARK: - Hazard draft

/// Plain values for a new hazard. A struct (not a managed object) so the report flow can build it
/// on the main thread and hand it safely to a background context for saving.
struct HazardDraft {
    var type: HazardType = .pothole
    var severity: Severity = .medium
    var confidence: Double = 0
    var status: HazardStatus = .open
    var notes: String?
    var landmark: String?
    var photo: Data?
    var latitude: Double = 0
    var longitude: Double = 0
    var address: String?
    var rainfallMM: Double?
    var createdAt = Date()

    // MARK: Area (found or created by name + city)

    var areaName: String?
    var city: String = "Mumbai"
    var ward: String?
}
