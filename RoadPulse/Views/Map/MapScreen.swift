import MapKit
import SwiftUI

// MARK: - Map tab

struct MapScreen: View {
    // @StateObject: this screen owns its view model
    @StateObject private var viewModel: MapViewModel
    // @EnvironmentObject: filters and the selected hazard live in the shared AppState, and the
    // location manager is shared with the Report tab
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var location: LocationManager
    // @AppStorage: the map style is a persisted setting, also editable in Settings
    @AppStorage(SettingsKey.mapStyle) private var mapStyle: MapStyleOption = SettingsKey.Default.mapStyle
    // @State: the camera is local UI state; the map and search both move it
    @State private var position: MapCameraPosition = .region(MapCamera.mumbaiRegion)
    @State private var isDeniedBannerDismissed = false
    // @Environment: camera moves are skipped when Reduce Motion is on
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(persistence: PersistenceController) {
        _viewModel = StateObject(wrappedValue: MapViewModel(persistence: persistence))
    }

    // MARK: Body

    var body: some View {
        HazardMapView(query: appState.query,
                      position: $position,
                      selection: $appState.selectedHazardID,
                      style: mapStyle)
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .top, spacing: 0) { topBar }
            .safeAreaInset(edge: .bottom, spacing: 0) { deniedBanner }
            .overlay(alignment: .bottomTrailing) { styleButton }
            .sheet(isPresented: sheetBinding) { sheetContent }
            .onAppear { focusSelectedHazard(haptic: false) } // e.g. arriving from a saved report
            .onChange(of: viewModel.searchResult) { _, result in
                if let result { flyTo(MapCamera.region(showing: result)) }
            }
            .onChange(of: appState.selectedHazardID) { _, _ in focusSelectedHazard(haptic: true) }
            .alert("Something went wrong", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    // MARK: Overlays

    private var topBar: some View {
        VStack(spacing: 8) {
            SearchBar(text: $viewModel.searchText, state: viewModel.searchState, onSubmit: viewModel.submitSearch)
            FilterChips()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var deniedBanner: some View {
        if location.isDenied && !isDeniedBannerDismissed {
            LocationDeniedView(isRestricted: location.authorizationStatus == .restricted)
                .overlay(alignment: .topTrailing) {
                    Button {
                        isDeniedBannerDismissed = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.inkMuted)
                            .padding(8)
                    }
                    .accessibilityLabel("Dismiss")
                }
                .padding(16)
        }
    }

    private var styleButton: some View {
        Button {
            Haptics.tap()
            mapStyle = mapStyle.next
        } label: {
            Image(systemName: mapStyle.toggleSymbol)
                .font(.headline)
                .foregroundStyle(Color.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.surfaceRaised))
                .overlay(Circle().stroke(Color.inkMuted.opacity(0.12), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
        }
        .buttonStyle(PressScaleButtonStyle())
        .padding(16)
        .accessibilityLabel("Map style")
        .accessibilityValue(mapStyle.label)
        .accessibilityHint("Switches to \(mapStyle.next.label)")
    }

    // MARK: Sheet

    @ViewBuilder
    private var sheetContent: some View {
        if let id = appState.selectedHazardID, let hazard = viewModel.hazard(id: id) {
            HazardSheet(hazard: hazard,
                        onToggleFixed: { viewModel.toggleFixed(hazard) },
                        onDelete: { delete(hazard) })
        }
    }

    /// The sheet is open exactly while a hazard is selected; swiping it away clears the selection.
    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { appState.selectedHazardID != nil },
            set: { if !$0 { appState.selectedHazardID = nil } }
        )
    }

    private func delete(_ hazard: Hazard) {
        // Close the sheet first so nothing reads the hazard after it's gone.
        appState.selectedHazardID = nil
        DispatchQueue.main.async { viewModel.delete(hazard) }
    }

    // MARK: Helpers

    private func focusSelectedHazard(haptic: Bool) {
        guard let id = appState.selectedHazardID, let hazard = viewModel.hazard(id: id) else { return }
        if haptic { Haptics.tap() }
        flyTo(MapCamera.region(focusing: hazard.coordinate))
    }

    private func flyTo(_ region: MKCoordinateRegion) {
        withAnimation(reduceMotion ? nil : Motion.smooth) {
            position = .region(region)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

// MARK: - Preview

#Preview {
    MapScreen(persistence: .preview)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(AppState())
        .environmentObject(LocationManager())
}
