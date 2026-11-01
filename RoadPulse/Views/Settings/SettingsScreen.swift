import SwiftUI

// MARK: - Settings

struct SettingsScreen: View {
    // @StateObject: this screen owns its view model's lifecycle
    @StateObject private var viewModel: SettingsViewModel

    // @AppStorage: each setting is persisted in UserDefaults and survives relaunch
    @AppStorage(SettingsKey.mapStyle) private var mapStyle: MapStyleOption = SettingsKey.Default.mapStyle
    @AppStorage(SettingsKey.defaultMinSeverity) private var defaultMinSeverity: Int = SettingsKey.Default.minSeverity
    @AppStorage(SettingsKey.hapticsEnabled) private var hapticsEnabled: Bool = SettingsKey.Default.haptics
    @AppStorage(SettingsKey.driveThresholdG) private var driveThresholdG: Double = SettingsKey.Default.driveThresholdG
    @AppStorage(SettingsKey.units) private var units: UnitSystem = SettingsKey.Default.units
    // Same key RootTabView reads: setting it to false shows the intro again
    @AppStorage(SettingsKey.hasCompletedOnboarding) private var hasCompletedOnboarding = true

    // @FetchRequest: live count straight from Core Data, no view-model plumbing needed
    @FetchRequest(fetchRequest: HazardQuery().fetchRequest()) private var hazards: FetchedResults<Hazard>

    // @State: whether the destructive confirmation is showing
    @State private var confirmingDelete = false

    init(persistence: PersistenceController) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(persistence: persistence))
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                mapSection
                reportsSection
                driveSection
                feedbackSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Color.asphalt)
            .navigationTitle("Settings")
            .confirmationDialog("Delete all reports?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete \(hazards.count) report\(hazards.count == 1 ? "" : "s")", role: .destructive) {
                    viewModel.deleteAll()
                    Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Photos and notes will be removed from this device. This can't be undone.")
            }
            .alert("Something went wrong", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: Sections

    private var mapSection: some View {
        Section("Map") {
            // @AppStorage binds straight into Picker, Stepper, Toggle and Slider via `$`
            Picker("Map style", selection: $mapStyle) {
                ForEach(MapStyleOption.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Units", selection: $units) {
                ForEach(UnitSystem.allCases) { Text($0.label).tag($0) }
            }
        }
        .listRowBackground(Color.surface)
    }

    private var reportsSection: some View {
        Section {
            Stepper(value: $defaultMinSeverity, in: 1 ... 5) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Severity(clamping: defaultMinSeverity).color)
                        .frame(width: 12, height: 12)
                    Text("Show severity \(defaultMinSeverity)+")
                }
            }
            .accessibilityValue(Severity(clamping: defaultMinSeverity).label)
        } header: {
            Text("Hazards")
        } footer: {
            Text("The map starts with hazards at or above this severity.")
        }
        .listRowBackground(Color.surface)
    }

    private var driveSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Spike threshold")
                    Spacer()
                    Text(String(format: "%.2f g", driveThresholdG))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(Color.inkMuted)
                }
                Slider(value: $driveThresholdG, in: SettingsKey.driveThresholdRange, step: 0.05) {
                    Text("Spike threshold")
                } minimumValueLabel: {
                    Text("Sensitive").font(.caption)
                } maximumValueLabel: {
                    Text("Strict").font(.caption)
                }
            }
        } header: {
            Text("Drive Mode")
        } footer: {
            Text("A rough patch is logged when vibration passes this level. Lower values catch smaller bumps.")
        }
        .listRowBackground(Color.surface)
    }

    private var feedbackSection: some View {
        Section("Feedback") {
            Toggle("Haptic feedback", isOn: $hapticsEnabled)
        }
        .listRowBackground(Color.surface)
    }

    private var dataSection: some View {
        Section {
            LabeledContent("Reports on this device", value: "\(hazards.count)")
            Button {
                viewModel.loadDemoData()
            } label: {
                Label("Load demo data", systemImage: "square.and.arrow.down")
            }
            Button {
                hasCompletedOnboarding = false
            } label: {
                Label("Show intro again", systemImage: "arrow.counterclockwise")
            }
            Button(role: .destructive) {
                confirmingDelete = true
            } label: {
                Label("Delete all reports", systemImage: "trash")
            }
            .disabled(hazards.isEmpty)
        } header: {
            Text("Data")
        } footer: {
            Text(viewModel.statusMessage ?? "Everything stays on this device.")
        }
        .listRowBackground(Color.surface)
    }

    private var aboutSection: some View {
        Section {
            LaneDivider()
                .listRowBackground(Color.clear)
            Text("RoadPulse 1.0 · photos are classified on your device")
                .font(.footnote)
                .foregroundStyle(Color.inkMuted)
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
        }
    }

    // MARK: Helpers

    /// The alert shows whenever the view model has an error and clears it on dismiss.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

// MARK: - Preview

#Preview {
    SettingsScreen(persistence: .preview)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
