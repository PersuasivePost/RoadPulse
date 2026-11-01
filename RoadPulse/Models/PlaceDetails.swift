import Foundation

// MARK: - Reverse-geocoded place

/// Where a hazard is: a readable address plus the Area (neighbourhood) and city it belongs to.
struct PlaceDetails: Equatable {
    let address: String
    let area: String
    let city: String

    /// Builds details from placemark fields. `nil` when there is no usable neighbourhood name.
    static func make(street: String?, subLocality: String?, locality: String?,
                     administrativeArea: String?) -> PlaceDetails? {
        let area = clean(subLocality) ?? clean(locality)
        guard let area else { return nil }
        let city = clean(locality) ?? clean(administrativeArea) ?? area

        var parts: [String] = []
        for part in [clean(street), clean(subLocality), clean(locality)].compactMap({ $0 })
        where parts.last != part {
            parts.append(part)
        }
        return PlaceDetails(address: parts.joined(separator: ", "), area: area, city: city)
    }

    private static func clean(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
