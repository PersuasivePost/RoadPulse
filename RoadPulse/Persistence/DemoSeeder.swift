import CoreData

// MARK: - Demo data

/// 25 hazards across five Mumbai-region areas, for previews, the simulator and the viva demo.
/// Coordinates are approximate; dates are relative to `now` so the data always looks recent.
enum DemoSeeder {
    struct DemoArea {
        let name: String
        let city: String
        let ward: String?
        let latitude: Double
        let longitude: Double
    }

    struct DemoHazard {
        let area: Int
        let landmark: String
        let latitude: Double
        let longitude: Double
        let type: HazardType
        let severity: Int
        let fixed: Bool
        let daysAgo: Int
        let rainfallMM: Double?
        let notes: String
    }

    static let areas: [DemoArea] = [
        DemoArea(name: "Kalyan", city: "Kalyan-Dombivli", ward: nil, latitude: 19.2403, longitude: 73.1305),
        DemoArea(name: "Dombivli", city: "Kalyan-Dombivli", ward: nil, latitude: 19.2167, longitude: 73.0867),
        DemoArea(name: "Thane", city: "Thane", ward: nil, latitude: 19.1950, longitude: 72.9700),
        DemoArea(name: "Ghatkopar", city: "Mumbai", ward: "N", latitude: 19.0858, longitude: 72.9081),
        DemoArea(name: "Vidyavihar", city: "Mumbai", ward: "N", latitude: 19.0790, longitude: 72.8970),
    ]

    static let hazards: [DemoHazard] = [
        // Kalyan
        DemoHazard(area: 0, landmark: "Kalyan Station (W)", latitude: 19.2353, longitude: 73.1292, type: .pothole, severity: 5, fixed: false, daysAgo: 2, rainfallMM: 182.4, notes: "Deep pothole at the auto stand exit; fills with water."),
        DemoHazard(area: 0, landmark: "Shivaji Chowk", latitude: 19.2412, longitude: 73.1286, type: .pothole, severity: 4, fixed: false, daysAgo: 5, rainfallMM: 164.0, notes: "Two potholes across the left lane."),
        DemoHazard(area: 0, landmark: "Murbad Road", latitude: 19.2465, longitude: 73.1402, type: .crack, severity: 2, fixed: false, daysAgo: 9, rainfallMM: nil, notes: "Long crack along the divider."),
        DemoHazard(area: 0, landmark: "Khadakpada Circle", latitude: 19.2547, longitude: 73.1338, type: .waterlogging, severity: 3, fixed: false, daysAgo: 3, rainfallMM: 201.7, notes: "Water collects after 20 minutes of rain."),
        DemoHazard(area: 0, landmark: "Birla College Road", latitude: 19.2442, longitude: 73.1255, type: .pothole, severity: 3, fixed: true, daysAgo: 21, rainfallMM: 88.0, notes: "Patched by KDMC."),
        // Dombivli
        DemoHazard(area: 1, landmark: "Manpada Road", latitude: 19.2122, longitude: 73.0905, type: .pothole, severity: 5, fixed: false, daysAgo: 1, rainfallMM: 175.2, notes: "Bike skidded here last week."),
        DemoHazard(area: 1, landmark: "Phadke Road", latitude: 19.2178, longitude: 73.0870, type: .crack, severity: 1, fixed: false, daysAgo: 12, rainfallMM: nil, notes: "Hairline cracks, minor."),
        DemoHazard(area: 1, landmark: "Dombivli Station (E)", latitude: 19.2185, longitude: 73.0862, type: .pothole, severity: 4, fixed: false, daysAgo: 4, rainfallMM: 158.9, notes: "Pothole right at the bus stop."),
        DemoHazard(area: 1, landmark: "Tilak Nagar", latitude: 19.2201, longitude: 73.0951, type: .pothole, severity: 2, fixed: true, daysAgo: 30, rainfallMM: 62.5, notes: "Filled with paver blocks."),
        DemoHazard(area: 1, landmark: "MIDC Phase 1", latitude: 19.2090, longitude: 73.1003, type: .debris, severity: 3, fixed: false, daysAgo: 6, rainfallMM: nil, notes: "Construction debris on the carriageway."),
        // Thane
        DemoHazard(area: 2, landmark: "Teen Haath Naka", latitude: 19.1925, longitude: 72.9561, type: .pothole, severity: 4, fixed: false, daysAgo: 2, rainfallMM: 190.3, notes: "Cluster of potholes near the signal."),
        DemoHazard(area: 2, landmark: "Ghodbunder Road, Manpada", latitude: 19.2361, longitude: 72.9715, type: .pothole, severity: 5, fixed: false, daysAgo: 1, rainfallMM: 212.6, notes: "Crater-sized pothole; traffic slows to a crawl."),
        DemoHazard(area: 2, landmark: "Gokhale Road", latitude: 19.1930, longitude: 72.9735, type: .crack, severity: 2, fixed: false, daysAgo: 15, rainfallMM: nil, notes: "Surface cracking near the school."),
        DemoHazard(area: 2, landmark: "Kopri Bridge", latitude: 19.1847, longitude: 72.9810, type: .waterlogging, severity: 4, fixed: false, daysAgo: 3, rainfallMM: 205.0, notes: "Waterlogging under the bridge."),
        DemoHazard(area: 2, landmark: "Majiwada Junction", latitude: 19.2183, longitude: 72.9805, type: .pothole, severity: 3, fixed: true, daysAgo: 25, rainfallMM: 97.4, notes: "Resurfaced."),
        // Ghatkopar
        DemoHazard(area: 3, landmark: "LBS Marg", latitude: 19.0880, longitude: 72.9105, type: .pothole, severity: 4, fixed: false, daysAgo: 2, rainfallMM: 171.8, notes: "Pothole in the bus lane."),
        DemoHazard(area: 3, landmark: "Ghatkopar Station (W)", latitude: 19.0864, longitude: 72.9079, type: .pothole, severity: 3, fixed: false, daysAgo: 7, rainfallMM: 149.3, notes: "Uneven patch near the skywalk stairs."),
        DemoHazard(area: 3, landmark: "Pant Nagar", latitude: 19.0812, longitude: 72.9145, type: .crack, severity: 2, fixed: false, daysAgo: 10, rainfallMM: nil, notes: "Cracks around a manhole cover."),
        DemoHazard(area: 3, landmark: "Andheri–Ghatkopar Link Road", latitude: 19.0925, longitude: 72.9010, type: .pothole, severity: 5, fixed: false, daysAgo: 1, rainfallMM: 188.0, notes: "Deep pothole on the flyover approach."),
        DemoHazard(area: 3, landmark: "Eastern Express Highway", latitude: 19.0790, longitude: 72.9180, type: .debris, severity: 3, fixed: true, daysAgo: 18, rainfallMM: nil, notes: "Debris cleared."),
        // Vidyavihar
        DemoHazard(area: 4, landmark: "Vidyavihar Station (E)", latitude: 19.0791, longitude: 72.8975, type: .pothole, severity: 3, fixed: false, daysAgo: 3, rainfallMM: 166.1, notes: "Pothole outside the ticket window."),
        DemoHazard(area: 4, landmark: "Somaiya Campus Gate", latitude: 19.0728, longitude: 72.8998, type: .pothole, severity: 4, fixed: false, daysAgo: 2, rainfallMM: 172.5, notes: "Pothole next to the zebra crossing students use."),
        DemoHazard(area: 4, landmark: "Rajawadi Road", latitude: 19.0805, longitude: 72.9030, type: .waterlogging, severity: 3, fixed: false, daysAgo: 4, rainfallMM: 195.2, notes: "Ankle-deep water after heavy rain."),
        DemoHazard(area: 4, landmark: "Neelkanth Valley", latitude: 19.0760, longitude: 72.9050, type: .crack, severity: 1, fixed: true, daysAgo: 40, rainfallMM: nil, notes: "Minor cracks, repaired."),
        DemoHazard(area: 4, landmark: "Station Road (W)", latitude: 19.0802, longitude: 72.8940, type: .pothole, severity: 2, fixed: false, daysAgo: 8, rainfallMM: 120.0, notes: "Small pothole near the vegetable market."),
    ]

    // MARK: Seeding

    /// Inserts all demo areas and hazards into `context` and saves.
    static func seed(in context: NSManagedObjectContext, now: Date = Date()) throws {
        let areaObjects = try areas.map {
            try Area.findOrCreate(name: $0.name, city: $0.city, ward: $0.ward,
                                  latitude: $0.latitude, longitude: $0.longitude, in: context)
        }
        for demo in hazards {
            let area = areas[demo.area]
            var draft = HazardDraft()
            draft.type = demo.type
            draft.severity = Severity(clamping: demo.severity)
            draft.confidence = 0.7 + Double(demo.severity) * 0.05
            draft.status = demo.fixed ? .fixed : .open
            draft.notes = demo.notes
            draft.landmark = demo.landmark
            draft.latitude = demo.latitude
            draft.longitude = demo.longitude
            draft.address = "\(demo.landmark), \(area.name), \(area.city)"
            draft.rainfallMM = demo.rainfallMM
            draft.createdAt = now.addingTimeInterval(-Double(demo.daysAgo) * 86_400)
            let hazard = try HazardRepository.insert(draft, into: context)
            hazard.area = areaObjects[demo.area]
        }
        try context.saveIfNeeded()
    }

    /// Seeds only when the store has no hazards. Returns whether it seeded.
    @discardableResult
    static func seedIfEmpty(in context: NSManagedObjectContext, now: Date = Date()) throws -> Bool {
        guard try context.count(for: Hazard.makeFetchRequest()) == 0 else { return false }
        try seed(in: context, now: now)
        return true
    }
}
