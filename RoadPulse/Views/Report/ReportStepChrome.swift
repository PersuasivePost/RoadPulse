import SwiftUI

// MARK: - Custom navigation chrome for report steps

/// Replaces the system back button with our own, adds Cancel, and pins the four-dash progress.
/// Back and Cancel are disabled once saving starts.
struct ReportStepChrome: ViewModifier {
    let step: ReportStep
    let title: String

    // @EnvironmentObject: the flow's view model, injected by ReportFlow
    @EnvironmentObject private var viewModel: ReportViewModel
    // @State: whether the discard confirmation is showing
    @State private var confirmingCancel = false

    private var isLocked: Bool {
        switch viewModel.saveState {
        case .saving, .saved: return true
        case .idle, .failed: return false
        }
    }

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: viewModel.goBack) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                    }
                    .disabled(isLocked)
                    .accessibilityLabel("Back")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { confirmingCancel = true }
                        .disabled(isLocked)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                StepProgress(step: step.number)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.asphalt)
            }
            .confirmationDialog("Discard this report?", isPresented: $confirmingCancel, titleVisibility: .visible) {
                Button("Discard report", role: .destructive, action: viewModel.reset)
                Button("Keep editing", role: .cancel) {}
            } message: {
                Text("Your photo and details will be lost.")
            }
    }
}

extension View {
    func reportChrome(step: ReportStep, title: String) -> some View {
        modifier(ReportStepChrome(step: step, title: title))
    }
}
