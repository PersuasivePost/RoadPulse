import SwiftUI

// MARK: - Colour tokens (docs/DESIGN.md)

/// Names of the colour sets in `Assets.xcassets`. Each has light + dark variants.
enum ColorToken: String, CaseIterable {
    case asphalt, surface, surfaceRaised, ink, inkMuted, laneYellow
    case sev1, sev2, sev3, sev4, sev5
    case fixedGrey
}

extension Color {
    // MARK: Surfaces & text

    static let asphalt = Color(ColorToken.asphalt)
    static let surface = Color(ColorToken.surface)
    static let surfaceRaised = Color(ColorToken.surfaceRaised)
    static let ink = Color(ColorToken.ink)
    static let inkMuted = Color(ColorToken.inkMuted)

    // MARK: Accent

    static let laneYellow = Color(ColorToken.laneYellow)

    // MARK: Severity scale (use `Severity.color` in views, never these directly)

    static let sev1 = Color(ColorToken.sev1)
    static let sev2 = Color(ColorToken.sev2)
    static let sev3 = Color(ColorToken.sev3)
    static let sev4 = Color(ColorToken.sev4)
    static let sev5 = Color(ColorToken.sev5)

    // MARK: Status

    static let fixedGrey = Color(ColorToken.fixedGrey)

    private init(_ token: ColorToken) {
        self.init(token.rawValue)
    }
}
