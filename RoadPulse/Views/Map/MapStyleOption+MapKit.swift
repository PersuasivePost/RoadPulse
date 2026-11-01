import MapKit
import SwiftUI // `MapStyle` comes from MapKit's SwiftUI overlay, which needs both imports

// MARK: - Settings value → MapKit style

extension MapStyleOption {
    var mapStyle: MapStyle {
        switch self {
        case .standard: return .standard(elevation: .realistic)
        case .hybrid: return .hybrid(elevation: .realistic)
        case .imagery: return .imagery(elevation: .realistic)
        }
    }

    /// Next style for the map's style button: standard → hybrid → satellite → standard.
    var next: MapStyleOption {
        let all = MapStyleOption.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }

    var toggleSymbol: String {
        switch self {
        case .standard: return "map"
        case .hybrid: return "square.2.layers.3d"
        case .imagery: return "globe.asia.australia.fill"
        }
    }
}
