import SwiftUI

// MARK: - Step 4: confirm and save

struct ConfirmStep: View {
    // @EnvironmentObject: the flow's view model, injected by ReportFlow
    @EnvironmentObject private var viewModel: ReportViewModel
    /// Called with the new hazard's id once the success animation has played.
    let onFinished: (UUID) -> Void

    private var isSaved: Bool {
        if case .saved = viewModel.saveState { return true }
        return false
    }

    var body: some View {
        ZStack {
            Color.asphalt.ignoresSafeArea()
            if isSaved {
                success
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                summary
                    .transition(.opacity)
            }
        }
        .animation(Motion.smooth, value: isSaved)
        .reportChrome(step: .confirm, title: "Confirm")
        .onChange(of: viewModel.saveState) { _, state in
            guard case .saved(let id) = state else { return }
            Haptics.success()
            Task {
                try? await Task.sleep(for: .seconds(1.4)) // let the checkmark finish drawing
                onFinished(id)
            }
        }
    }

    // MARK: Summary

    private var summary: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityLabel("Your photo")
                    }
                    HStack {
                        Label(viewModel.type.label, systemImage: viewModel.type.symbol)
                            .font(.title3.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.ink)
                        Spacer()
                        SeverityBadge(severity: viewModel.severity, isFixed: viewModel.isAlreadyFixed)
                    }
                    LaneDivider()
                    row("mappin.and.ellipse", viewModel.place?.address ?? "Saved position only")
                    if let area = viewModel.place?.area {
                        row("building.2", area)
                    }
                    if !viewModel.landmark.isEmpty {
                        row("signpost.right", viewModel.landmark)
                    }
                    if !viewModel.notes.isEmpty {
                        row("note.text", viewModel.notes)
                    }
                    if viewModel.isAlreadyFixed {
                        row("checkmark.circle", "Marked as already fixed")
                    }
                }
                .padding(16)
                .cardStyle()

                PrimaryButton(title: viewModel.saveState == .saving ? "Saving…" : "Save report",
                              systemImage: "tray.and.arrow.down.fill") {
                    Task { await viewModel.save() }
                }
                .disabled(viewModel.saveState == .saving)
                .opacity(viewModel.saveState == .saving ? 0.6 : 1)
            }
            .padding(16)
        }
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(Color.ink)
            .labelStyle(.titleAndIcon)
    }

    // MARK: Success

    private var success: some View {
        VStack(spacing: 24) {
            AnimatedCheckmark()
            Text("Report saved")
                .font(.title.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            Text("Opening it on the map…")
                .font(.body)
                .foregroundStyle(Color.inkMuted)
        }
        .padding(24)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConfirmStep(onFinished: { _ in })
    }
    .environmentObject(ReportViewModel(persistence: .preview))
}
