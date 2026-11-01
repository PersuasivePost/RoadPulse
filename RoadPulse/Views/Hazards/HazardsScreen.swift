import SwiftUI

// MARK: - Hazards tab

struct HazardsScreen: View {
    // @StateObject: this screen owns its view model
    @StateObject private var viewModel: HazardsViewModel
    // @EnvironmentObject: the severity/status filters are shared with the map through AppState
    @EnvironmentObject private var appState: AppState
    // @AppStorage: list or gallery is remembered between launches
    @AppStorage(SettingsKey.hazardsLayout) private var layout: HazardsLayout = .list
    // @State: the open report and the report awaiting delete confirmation
    @State private var detailID: UUID?
    @State private var pendingDeleteID: UUID?
    // @Namespace: shared by the list, grid and detail so the photo morphs between them
    @Namespace private var heroNamespace
    // @Environment: the morph becomes a quick fade under Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(persistence: PersistenceController) {
        _viewModel = StateObject(wrappedValue: HazardsViewModel(persistence: persistence))
    }

    private var morph: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : Motion.smooth
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            HazardsContent(query: viewModel.query(filters: appState.query),
                           viewModel: viewModel,
                           layout: layout,
                           namespace: heroNamespace,
                           detailID: detailID,
                           pendingDeleteID: $pendingDeleteID,
                           onSelect: open,
                           onReport: { appState.requestedTab = .report },
                           onClearFilters: clearFilters)
                .navigationTitle("Hazards")
                .searchable(text: $viewModel.searchText, prompt: "Address, notes or area")
                .toolbar { toolbar }
                .safeAreaInset(edge: .top, spacing: 0) {
                    FilterChips()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
        }
        .overlay { detailOverlay }
        .confirmationDialog("Delete this report?", isPresented: deleteDialogBinding, titleVisibility: .visible) {
            Button("Delete report", role: .destructive, action: confirmDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Sort", selection: $viewModel.sort) {
                    Text("Newest first").tag(HazardQuery.Sort.newest)
                    Text("Most severe first").tag(HazardQuery.Sort.mostSevere)
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Sort")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Picker("Layout", selection: layoutBinding) {
                ForEach(HazardsLayout.allCases) { Image(systemName: $0.symbol).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 110)
        }
    }

    /// Switching layout animates, so the thumbnails morph through `matchedGeometryEffect`.
    private var layoutBinding: Binding<HazardsLayout> {
        Binding(get: { layout }, set: { newValue in withAnimation(morph) { layout = newValue } })
    }

    // MARK: Detail

    @ViewBuilder
    private var detailOverlay: some View {
        if let id = detailID, let hazard = viewModel.hazard(id: id) {
            HazardDetail(hazard: hazard,
                         namespace: heroNamespace,
                         onClose: close,
                         onSave: { edit in
                             if viewModel.update(hazard, with: edit) {
                                 ThumbnailCache.remove(id)
                                 Haptics.success()
                             }
                         },
                         onToggleFixed: { viewModel.toggleFixed(hazard) },
                         onDelete: { pendingDeleteID = id })
                .transition(.opacity)
        }
    }

    private func open(_ id: UUID) {
        withAnimation(morph) { detailID = id }
    }

    private func close() {
        withAnimation(morph) { detailID = nil }
    }

    // MARK: Delete

    private var deleteDialogBinding: Binding<Bool> {
        Binding(get: { pendingDeleteID != nil }, set: { if !$0 { pendingDeleteID = nil } })
    }

    private func confirmDelete() {
        guard let id = pendingDeleteID else { return }
        pendingDeleteID = nil
        if detailID == id { close() }
        // Close the detail first so nothing reads the hazard after it's gone.
        DispatchQueue.main.async {
            ThumbnailCache.remove(id)
            viewModel.delete(id: id)
        }
    }

    // MARK: Helpers

    private func clearFilters() {
        appState.clearFilters()
        viewModel.searchText = ""
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

// MARK: - Preview

#Preview {
    HazardsScreen(persistence: .preview)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(AppState())
}
