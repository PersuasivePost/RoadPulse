import PhotosUI
import SwiftUI

// MARK: - Step 1: capture

struct CaptureStep: View {
    // @EnvironmentObject: the flow's view model, injected by ReportFlow
    @EnvironmentObject private var viewModel: ReportViewModel
    // @State: the picker selection and camera cover are local UI state
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    // @Environment: the secondary button follows the real appearance
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                RoadIllustration()
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .cardStyle()
                VStack(spacing: 8) {
                    Text("Photograph the hazard")
                        .font(.title.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.ink)
                    Text("Get close and keep the road in frame. An AI model on your phone checks it; the photo never leaves your device.")
                        .font(.body)
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                }
                buttons
            }
            .padding(16)
        }
        .background(Color.asphalt)
        .navigationTitle("New report")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            StepProgress(step: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.asphalt)
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.load(data: data)
                } else {
                    viewModel.errorMessage = "That photo couldn't be opened. Try another one."
                }
                pickerItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(
                onImage: { image in
                    showCamera = false
                    Task { await viewModel.load(image) }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
    }

    // MARK: Buttons

    private var buttons: some View {
        VStack(spacing: 12) {
            if CameraPicker.isAvailable {
                PrimaryButton(title: "Take photo", systemImage: "camera.fill") { showCamera = true }
                libraryPicker(isPrimary: false)
            } else {
                // No camera (simulator, some iPads): the library is the main action.
                libraryPicker(isPrimary: true)
            }
            #if targetEnvironment(simulator)
            sampleMenu
            #endif
        }
    }

    private func libraryPicker(isPrimary: Bool) -> some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            Label("Choose from library", systemImage: "photo.on.rectangle")
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
                // Same trick as PrimaryButton: dark ink on yellow in both appearances.
                .environment(\.colorScheme, isPrimary ? .light : colorScheme)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Capsule().fill(isPrimary ? Color.laneYellow : Color.surfaceRaised))
                .overlay(Capsule().stroke(Color.inkMuted.opacity(isPrimary ? 0 : 0.12), lineWidth: 1))
        }
    }

    /// Simulator only: its photo library is empty, so offer the bundled held-out samples.
    private var sampleMenu: some View {
        Menu {
            ForEach(SampleImages.all) { sample in
                Button(sample.title) {
                    if let image = SampleImages.image(for: sample) {
                        Task { await viewModel.load(image) }
                    }
                }
            }
        } label: {
            Label("Try a sample photo", systemImage: "wand.and.stars")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.inkMuted)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CaptureStep()
    }
    .environmentObject(ReportViewModel(persistence: .preview))
}
