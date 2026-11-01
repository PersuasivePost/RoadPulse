import SwiftUI

// MARK: - Step 2: analyse

struct AnalyzeStep: View {
    // @EnvironmentObject: the flow's view model, injected by ReportFlow
    @EnvironmentObject private var viewModel: ReportViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                photo
                outcome
                    .frame(maxWidth: .infinity)
            }
            .padding(16)
            .animation(Motion.smooth, value: viewModel.analysis)
        }
        .background(Color.asphalt)
        .reportChrome(step: .analyze, title: "Analysing")
        // Runs when the step appears; returning from Details doesn't re-run a finished analysis.
        .task { await viewModel.analyze() }
        .onChange(of: viewModel.analysis) { _, state in
            if case .finished = state { Haptics.tap() }
        }
    }

    // MARK: Photo with scan line

    private var photo: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 260)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .accessibilityLabel("Your photo")
            }
            if viewModel.analysis == .analyzing {
                Color.shadowTint.opacity(0.15)
                ScanLine()
                    .transition(.opacity)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .cardStyle()
    }

    // MARK: Outcome

    @ViewBuilder
    private var outcome: some View {
        switch viewModel.analysis {
        case .idle, .analyzing:
            VStack(spacing: 12) {
                Text("Checking the road surface…")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.ink)
                LaneDivider()
                    .frame(width: 120)
            }
            .transition(.opacity)
        case .finished(let result):
            if result.isPothole {
                potholeOutcome(result)
            } else {
                normalOutcome(result)
            }
        case .failed(let message):
            failedOutcome(message)
        }
    }

    private func potholeOutcome(_ result: ClassificationResult) -> some View {
        VStack(spacing: 16) {
            ConfidenceRing(progress: result.confidence, color: result.suggestedSeverity.color)
            Text(result.headline)
                .font(.title2.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            HStack(spacing: 8) {
                Text("Suggested")
                    .font(.footnote)
                    .foregroundStyle(Color.inkMuted)
                SeverityBadge(severity: result.suggestedSeverity)
            }
            PrimaryButton(title: "Continue", systemImage: "arrow.right", action: viewModel.continueToDetails)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func normalOutcome(_ result: ClassificationResult) -> some View {
        VStack(spacing: 16) {
            ConfidenceRing(progress: result.confidence, color: Severity.minor.color)
            Text(result.headline)
                .font(.title2.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            Text("The model is \(result.percent)% sure this road looks fine. If you can see a hazard, you can still report it.")
                .font(.subheadline)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Report it anyway", systemImage: "exclamationmark.triangle", action: viewModel.reportAnyway)
            Button("Choose another photo", action: viewModel.reset)
                .font(.subheadline.weight(.semibold))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }

    private func failedOutcome(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Severity.high.color)
            Text(message)
                .font(.body)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Try again", systemImage: "arrow.clockwise") {
                Task { await viewModel.analyze() }
            }
            Button("Choose another photo", action: viewModel.reset)
                .font(.subheadline.weight(.semibold))
        }
        .transition(.opacity)
    }
}

// MARK: - Scan line

/// A glowing yellow line that sweeps down and up the photo while the model works.
/// Reduce Motion: the line stays centred and pulses in opacity.
private struct ScanLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // @State: local animation driver
    @State private var sweep = false

    var body: some View {
        GeometryReader { proxy in
            LinearGradient(colors: [.clear, Color.laneYellow, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 4)
                .shadow(color: Color.laneYellow.opacity(0.8), radius: 8)
                .offset(y: reduceMotion ? proxy.size.height / 2 : (sweep ? proxy.size.height - 4 : 0))
                .opacity(reduceMotion ? (sweep ? 1 : 0.3) : 1)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { sweep = true }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnalyzeStep()
    }
    .environmentObject(ReportViewModel(persistence: .preview))
}
