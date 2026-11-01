import SwiftUI

// MARK: - Hazard detail (opens over the list with a hero transition)

struct HazardDetail: View {
    // @ObservedObject: Core Data objects publish changes, so the screen follows status edits
    @ObservedObject var hazard: Hazard
    let namespace: Namespace.ID
    let onClose: () -> Void
    let onSave: (HazardEdit) -> Void
    let onToggleFixed: () -> Void
    let onDelete: () -> Void

    // @State: the edit form works on a copy until "Update" is tapped
    @State private var edit: HazardEdit
    // @FocusState: dismisses the keyboard when the user taps Update
    @FocusState private var notesFocused: Bool
    // @StateObject: this view owns the rainfall request (Combine) for its hazard
    @StateObject private var rainfall = RainfallViewModel()
    // @AppStorage: rainfall is shown in the user's chosen units
    @AppStorage(SettingsKey.units) private var units: UnitSystem = SettingsKey.Default.units

    init(hazard: Hazard,
         namespace: Namespace.ID,
         onClose: @escaping () -> Void,
         onSave: @escaping (HazardEdit) -> Void,
         onToggleFixed: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.hazard = hazard
        self.namespace = namespace
        self.onClose = onClose
        self.onSave = onSave
        self.onToggleFixed = onToggleFixed
        self.onDelete = onDelete
        _edit = State(initialValue: HazardEdit(hazard))
    }

    private var hasChanges: Bool { edit.differs(from: HazardEdit(hazard)) }

    // MARK: Body

    var body: some View {
        Group {
            if hazard.isDeleted || hazard.managedObjectContext == nil {
                Color.asphalt // deleted just now; the overlay is on its way out
            } else {
                content
            }
        }
        .background(Color.asphalt.ignoresSafeArea())
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                hero
                header
                badges
                RainfallRow(state: rainfall.state, units: units) { rainfall.retry(for: hazard) }
                LaneDivider()
                editForm
                LaneDivider()
                resolveSection
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .task(id: hazard.id) { rainfall.load(for: hazard) }
        .onDisappear { rainfall.cancel() } // drop an in-flight request
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            Button {
                Haptics.tap()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.surfaceRaised))
            }
            .accessibilityLabel("Close")
            Spacer()
            shareButton
        }
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }

    @ViewBuilder
    private var shareButton: some View {
        Group {
            if let data = hazard.photo, let image = UIImage(data: data) {
                ShareLink(item: Image(uiImage: image),
                          subject: Text(hazard.displayTitle),
                          message: Text(hazard.shareSummary),
                          preview: SharePreview(hazard.displayTitle, image: Image(uiImage: image)))
            } else {
                ShareLink(item: hazard.shareSummary, subject: Text(hazard.displayTitle))
            }
        }
        .labelStyle(.iconOnly)
        .font(.headline)
        .frame(width: 44, height: 44)
        .background(Circle().fill(Color.surfaceRaised))
    }

    // MARK: Sections

    @ViewBuilder
    private var hero: some View {
        Group {
            if let data = hazard.photo, let image = UIImage(data: data) {
                ZoomableImage(image: image)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(hazard.severityLevel.color(isFixed: hazard.isFixed).opacity(0.14))
                    .overlay(
                        Image(systemName: hazard.hazardType.symbol)
                            .font(.system(.largeTitle))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(hazard.severityLevel.color(isFixed: hazard.isFixed))
                    )
            }
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .matchedGeometryEffect(id: hazard.id, in: namespace, isSource: true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(hazard.displayTitle)
                .font(.title2.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            if let area = hazard.area {
                Text("\(area.name), \(area.city)")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkMuted)
            }
            if let address = hazard.address {
                Label(address, systemImage: "mappin.and.ellipse")
                    .font(.footnote)
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    private var badges: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { badgeViews }
            VStack(alignment: .leading, spacing: 8) { badgeViews }
        }
    }

    @ViewBuilder
    private var badgeViews: some View {
        SeverityBadge(severity: hazard.severityLevel, isFixed: hazard.isFixed)
        RiskBadge(risk: hazard.monsoonRisk)
    }

    // MARK: Edit form

    private var editForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit report")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            Picker("Type", selection: $edit.type) {
                ForEach(HazardType.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.menu)
            .tint(Color.laneYellow)
            VStack(alignment: .leading, spacing: 4) {
                Text("Severity: \(edit.severity.label) (\(edit.severity.rawValue)/5)")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkMuted)
                Slider(value: severityValue, in: 1 ... 5, step: 1)
                    .tint(edit.severity.color)
                    .accessibilityLabel("Severity")
                    .accessibilityValue("\(edit.severity.label), \(edit.severity.rawValue) of 5")
            }
            TextField("Notes", text: $edit.notes, axis: .vertical)
                .lineLimit(3 ... 6)
                .focused($notesFocused)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.surfaceRaised))
            PrimaryButton(title: "Update report", systemImage: "square.and.arrow.down") {
                notesFocused = false
                onSave(edit)
            }
            .disabled(!hasChanges)
            .opacity(hasChanges ? 1 : 0.4)
        }
        .padding(16)
        .cardStyle()
    }

    private var severityValue: Binding<Double> {
        Binding(
            get: { Double(edit.severity.rawValue) },
            set: { edit.severity = Severity(clamping: Int($0.rounded())) }
        )
    }

    // MARK: Resolve + delete

    private var resolveSection: some View {
        VStack(spacing: 12) {
            if hazard.isFixed {
                SheetActionButton(title: "Reopen", systemImage: "arrow.uturn.backward.circle", action: onToggleFixed)
            } else {
                ResolveSlider(title: "Slide to mark fixed", onResolve: onToggleFixed)
            }
            SheetActionButton(title: "Delete report", systemImage: "trash", isDestructive: true, action: onDelete)
        }
    }
}
