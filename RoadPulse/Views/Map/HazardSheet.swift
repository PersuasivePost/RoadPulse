import SwiftUI

// MARK: - Hazard detail sheet (opened by selecting a pin)

struct HazardSheet: View {
    // @ObservedObject: Core Data objects publish changes, so the sheet updates when status changes
    @ObservedObject var hazard: Hazard
    let onToggleFixed: () -> Void
    let onDelete: () -> Void

    // @AppStorage: rainfall is shown in the user's chosen units
    @AppStorage(SettingsKey.units) private var units: UnitSystem = SettingsKey.Default.units
    // @State: whether the destructive confirmation is showing
    @State private var confirmingDelete = false

    // MARK: Body

    var body: some View {
        Group {
            if hazard.isDeleted || hazard.managedObjectContext == nil {
                Color.clear // the hazard was just deleted; the sheet is on its way out
            } else {
                content
            }
        }
        .presentationDetents([.fraction(0.4), .large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
        .presentationBackground(Color.surface)
        .presentationCornerRadius(20)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photo
                header
                badges
                if let address = hazard.address {
                    Label(address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(Color.inkMuted)
                }
                if let notes = hazard.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(Color.ink)
                }
                LaneDivider()
                actions
            }
            .padding(16)
        }
        .confirmationDialog("Delete this report?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete report", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: Sections

    @ViewBuilder
    private var photo: some View {
        if let data = hazard.photo, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel("Photo of the hazard")
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(hazard.severityLevel.color(isFixed: hazard.isFixed).opacity(0.12))
                .frame(height: 96)
                .overlay(
                    Image(systemName: hazard.hazardType.symbol)
                        .font(.system(size: 32))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(hazard.severityLevel.color(isFixed: hazard.isFixed))
                )
                .accessibilityHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(hazard.landmark ?? hazard.hazardType.label)
                .font(.title2.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            if let area = hazard.area {
                Text("\(area.name), \(area.city)")
                    .font(.subheadline)
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    /// Wraps onto two lines at large Dynamic Type sizes.
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
        if hazard.isFixed {
            Label("Fixed", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.fixedGrey)
        }
        if let rain = hazard.rainfall {
            Label("\(units.rainfall(mm: rain)) in 7 days", systemImage: "drop")
                .font(.caption)
                .foregroundStyle(Color.inkMuted)
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill") {
                DirectionsLauncher.openInMaps(to: hazard.coordinate,
                                              name: hazard.landmark ?? hazard.hazardType.label)
            }
            HStack(spacing: 12) {
                SheetActionButton(title: hazard.isFixed ? "Reopen" : "Mark fixed",
                                  systemImage: hazard.isFixed ? "arrow.uturn.backward.circle" : "checkmark.circle") {
                    onToggleFixed()
                    if !hazard.isFixed { Haptics.success() }
                }
                SheetActionButton(title: "Delete", systemImage: "trash", isDestructive: true) {
                    confirmingDelete = true
                }
            }
        }
    }
}

// MARK: - Secondary action button

private struct SheetActionButton: View {
    let title: String
    let systemImage: String
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(isDestructive ? Severity.severe.color : Color.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.surfaceRaised))
                .overlay(Capsule().stroke(Color.inkMuted.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.viewContext
    let hazard = (try? context.fetch(HazardQuery(sort: .mostSevere).fetchRequest()))?.first
    Group {
        if let hazard {
            HazardSheet(hazard: hazard, onToggleFixed: {}, onDelete: {})
        }
    }
}
