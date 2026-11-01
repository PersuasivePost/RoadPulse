import XCTest

/// F9 "done when": every syllabus row points to real code. Reads docs/SYLLABUS_MAP.md from the
/// source tree (like the GPX test) and checks each `File.swift` it names exists.
final class DocsAuditTests: XCTestCase {
    private let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent()

    private func swiftFileNames() -> Set<String> {
        let enumerator = FileManager.default.enumerator(at: root.appendingPathComponent("RoadPulse"),
                                                        includingPropertiesForKeys: nil)
        var names = Set<String>()
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            names.insert(url.lastPathComponent)
        }
        return names
    }

    private func tableRows() throws -> [[String]] {
        let text = try String(contentsOf: root.appendingPathComponent("docs/SYLLABUS_MAP.md"), encoding: .utf8)
        return text.split(separator: "\n")
            .filter { $0.hasPrefix("|") && !$0.hasPrefix("|---") && !$0.hasPrefix("| Module") }
            .map { $0.split(separator: "|", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty } }
    }

    func testEverySyllabusRowIsDoneAndHasAWhere() throws {
        let rows = try tableRows()
        XCTAssertGreaterThan(rows.count, 25)
        for row in rows {
            XCTAssertEqual(row.count, 4, "Malformed row: \(row)")
            XCTAssertEqual(row.last, "✅", "Not done: \(row.prefix(2))")
            XCTAssertFalse(row[2].isEmpty, "No code listed for: \(row[1])")
        }
    }

    func testEveryFileNamedInTheSyllabusMapExists() throws {
        let existing = swiftFileNames()
        let pattern = try NSRegularExpression(pattern: "[A-Za-z0-9+]+\\.swift")
        for row in try tableRows() {
            let range = NSRange(row[2].startIndex..., in: row[2])
            for match in pattern.matches(in: row[2], range: range) {
                let name = String(row[2][Range(match.range, in: row[2])!])
                // "Report/*Step.swift" is a wildcard written for readers, not a file name.
                if name.hasPrefix("Step") { continue }
                XCTAssertTrue(existing.contains(name), "\(name) (row: \(row[1])) is not in RoadPulse/")
            }
        }
    }

    func testAppIconIsPresent() {
        let icon = root.appendingPathComponent("RoadPulse/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: icon.path))
    }
}
