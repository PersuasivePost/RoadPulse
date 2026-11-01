import MapKit
import SwiftUI

// MARK: - The map and its hazard pins

/// Rebuilt by `MapScreen` whenever the filters change, which gives its `@FetchRequest` a new
/// predicate; Core Data then does the filtering.
struct HazardMapView: View {
    // @FetchRequest: live, filtered hazards straight from Core Data
    @FetchRequest private var hazards: FetchedResults<Hazard>
    // @Binding: the screen owns the camera and the selection; the map reads and writes them
    @Binding var position: MapCameraPosition
    @Binding var selection: UUID?
    let style: MapStyleOption

    init(query: HazardQuery,
         position: Binding<MapCameraPosition>,
         selection: Binding<UUID?>,
         style: MapStyleOption) {
        _hazards = FetchRequest(fetchRequest: query.fetchRequest(), animation: .default)
        _position = position
        _selection = selection
        self.style = style
    }

    var body: some View {
        Map(position: $position, selection: $selection) {
            UserAnnotation()
            ForEach(hazards) { hazard in
                Annotation(hazard.landmark ?? hazard.hazardType.label,
                           coordinate: hazard.coordinate,
                           anchor: .center) {
                    HazardPin(severity: hazard.severityLevel,
                              type: hazard.hazardType,
                              isFixed: hazard.isFixed,
                              isSelected: selection == hazard.id)
                }
                .annotationTitles(.hidden) // a MapContent modifier: the pin shows no label under it
                .tag(hazard.id)
            }
        }
        .mapStyle(style.mapStyle)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }
}
