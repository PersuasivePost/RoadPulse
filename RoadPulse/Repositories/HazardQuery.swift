import CoreData

// MARK: - Hazard query

/// Filters that turn into one `NSPredicate`. Shared by the repository, `@FetchRequest`s and
/// filter chips, so every screen filters the same way.
struct HazardQuery: Equatable {
    enum Sort: Equatable {
        case newest, mostSevere
    }

    var severity: ClosedRange<Severity>?
    var status: HazardStatus?
    var type: HazardType?
    var areaName: String?
    var dateRange: ClosedRange<Date>?
    /// Matched against notes, address, landmark and area name (case/diacritic-insensitive).
    var text: String = ""
    var sort: Sort = .newest

    // MARK: Predicate

    /// `nil` when no filter is set, so a fetch returns everything.
    var predicate: NSPredicate? {
        var parts: [NSPredicate] = []
        if let severity {
            parts.append(NSPredicate(format: "severity >= %@ AND severity <= %@",
                                     NSNumber(value: severity.lowerBound.rawValue),
                                     NSNumber(value: severity.upperBound.rawValue)))
        }
        if let status {
            parts.append(NSPredicate(format: "status == %@", status.rawValue))
        }
        if let type {
            parts.append(NSPredicate(format: "type == %@", type.rawValue))
        }
        if let areaName, !areaName.isEmpty {
            parts.append(NSPredicate(format: "area.name ==[c] %@", areaName))
        }
        if let dateRange {
            parts.append(NSPredicate(format: "createdAt >= %@ AND createdAt <= %@",
                                     dateRange.lowerBound as NSDate, dateRange.upperBound as NSDate))
        }
        let search = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !search.isEmpty {
            parts.append(NSPredicate(
                format: "notes CONTAINS[cd] %@ OR address CONTAINS[cd] %@ OR landmark CONTAINS[cd] %@ OR area.name CONTAINS[cd] %@",
                search, search, search, search))
        }
        switch parts.count {
        case 0: return nil
        case 1: return parts[0]
        default: return NSCompoundPredicate(andPredicateWithSubpredicates: parts)
        }
    }

    // MARK: Sorting

    var sortDescriptors: [NSSortDescriptor] {
        switch sort {
        case .newest:
            return [NSSortDescriptor(key: "createdAt", ascending: false)]
        case .mostSevere:
            return [NSSortDescriptor(key: "severity", ascending: false),
                    NSSortDescriptor(key: "createdAt", ascending: false)]
        }
    }

    func fetchRequest() -> NSFetchRequest<Hazard> {
        let request = Hazard.makeFetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return request
    }
}
