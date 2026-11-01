import SwiftUI

// MARK: - Report tab: Capture → Analyze → Details → Confirm

struct ReportFlow: View {
    // @StateObject: the flow owns its view model for as long as the tab lives
    @StateObject private var viewModel: ReportViewModel
    // @EnvironmentObject: shared app state and the one app-wide location manager
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    init(persistence: PersistenceController) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(persistence: persistence))
    }

    // MARK: Body

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            CaptureStep()
                .navigationDestination(for: ReportStep.self) { step in
                    switch step {
                    case .analyze: AnalyzeStep()
                    case .details: DetailsStep()
                    case .confirm: ConfirmStep(onFinished: finish)
                    }
                }
        }
        // Applied to the stack so every pushed step can read the same view model.
        .environmentObject(viewModel)
        .onAppear { viewModel.updateLocation(locationManager.location) }
        .onChange(of: locationManager.location) { _, newLocation in
            viewModel.updateLocation(newLocation)
        }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: Finishing

    /// Pops back to an empty Capture screen, then shows the new hazard on the map.
    private func finish(_ id: UUID) {
        viewModel.reset()
        appState.showOnMap(id)
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
    ReportFlow(persistence: .preview)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(AppState())
        .environmentObject(LocationManager())
}
