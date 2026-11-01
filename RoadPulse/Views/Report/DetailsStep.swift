import PhotosUI
import SwiftUI

// MARK: - Step 3: details

struct DetailsStep: View {
    private enum Field { case landmark, notes }

    // @EnvironmentObject: the flow's view model and the app-wide location manager
    @EnvironmentObject private var viewModel: ReportViewModel
    @EnvironmentObject private var locationManager: LocationManager
    // @FocusState: which text field has the keyboard; lets "Done" dismiss it
    @FocusState private var focused: Field?
    // @State: signboard picker and camera are local UI state
    @State private var signItem: PhotosPickerItem?
    @State private var showSignCamera = false

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                hazardCard
                locationCard
                landmarkCard
                notesCard
                Toggle("Already fixed", isOn: $viewModel.isAlreadyFixed)
                    .padding(16)
                    .cardStyle()
                PrimaryButton(title: "Review", systemImage: "arrow.right", action: viewModel.continueToConfirm)
                    .disabled(!viewModel.canReview)
                    .opacity(viewModel.canReview ? 1 : 0.5)
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.asphalt)
        .reportChrome(step: .details, title: "Details")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
        .task { await viewModel.resolvePlace() }
        .onChange(of: viewModel.location) { _, _ in
            Task { await viewModel.resolvePlace() }
        }
        .onChange(of: signItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    await viewModel.scanSign(image)
                } else {
                    viewModel.errorMessage = "That photo couldn't be opened. Try another one."
                }
                signItem = nil
            }
        }
        .fullScreenCover(isPresented: $showSignCamera) {
            CameraPicker(
                onImage: { image in
                    showSignCamera = false
                    Task { await viewModel.scanSign(image) }
                },
                onCancel: { showSignCamera = false }
            )
            .ignoresSafeArea()
        }
    }

    // MARK: Hazard

    private var hazardCard: some View {
        card("Hazard") {
            Picker("Type", selection: $viewModel.type) {
                ForEach(HazardType.allCases) { type in
                    Label(type.label, systemImage: type.symbol).tag(type)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Text("Severity")
                Spacer()
                SeverityBadge(severity: viewModel.severity)
            }
            Slider(value: severityBinding, in: 1 ... 5, step: 1)
                .tint(viewModel.severity.color)
                .accessibilityLabel("Severity")
                .accessibilityValue(viewModel.severity.label)
            Text(viewModel.isManualOverride
                 ? "You're reporting a photo the AI called normal, so set the severity yourself."
                 : "Pre-filled from the AI check. Adjust it if you disagree.")
                .font(.footnote)
                .foregroundStyle(Color.inkMuted)
        }
    }

    /// The Slider works in Doubles; the view model keeps a `Severity`.
    private var severityBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.severity.rawValue) },
            set: { viewModel.severity = Severity(clamping: Int($0.rounded())) }
        )
    }

    // MARK: Location

    private var locationCard: some View {
        card("Location") {
            if let place = viewModel.place {
                Label(place.address, systemImage: "mappin.and.ellipse")
                    .foregroundStyle(Color.ink)
                Text("Area: \(place.area), \(place.city)")
                    .font(.footnote)
                    .foregroundStyle(Color.inkMuted)
            } else if viewModel.isFindingPlace {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Finding the address…").foregroundStyle(Color.inkMuted)
                }
            } else if viewModel.location != nil {
                Label("Your position is saved. The address couldn't be found.", systemImage: "location.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.inkMuted)
            } else if locationManager.isDenied {
                LocationDeniedView(isRestricted: locationManager.authorizationStatus == .restricted)
            } else {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Waiting for your location…").foregroundStyle(Color.inkMuted)
                }
            }
        }
    }

    // MARK: Landmark and signboard OCR

    private var landmarkCard: some View {
        card("Landmark") {
            TextField("Nearby landmark (optional)", text: $viewModel.landmark)
                .focused($focused, equals: .landmark)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
            signboardMenu
            if viewModel.isScanningSign {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Reading the sign…").font(.footnote).foregroundStyle(Color.inkMuted)
                }
            }
            if viewModel.landmarkCandidates.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.landmarkCandidates, id: \.self) { candidate in
                            FilterChip(title: candidate, isSelected: viewModel.landmark == candidate) {
                                viewModel.landmark = candidate
                            }
                        }
                    }
                }
            }
        }
    }

    private var signboardMenu: some View {
        Menu {
            if CameraPicker.isAvailable {
                Button { showSignCamera = true } label: { Label("Take photo", systemImage: "camera") }
            }
            PhotosPicker(selection: $signItem, matching: .images) {
                Label("Choose photo", systemImage: "photo")
            }
            #if targetEnvironment(simulator)
            Button {
                if let image = SampleImages.signboard { Task { await viewModel.scanSign(image) } }
            } label: {
                Label("Use sample signboard", systemImage: "signpost.right")
            }
            #endif
        } label: {
            Label("Scan signboard", systemImage: "text.viewfinder")
                .font(.subheadline.weight(.semibold))
        }
    }

    // MARK: Notes

    private var notesCard: some View {
        card("Notes") {
            TextField("Anything else? (optional)", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3 ... 6)
                .focused($focused, equals: .notes)
        }
    }

    // MARK: Card helper

    private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DetailsStep()
    }
    .environmentObject(ReportViewModel(persistence: .preview))
    .environmentObject(LocationManager())
}
