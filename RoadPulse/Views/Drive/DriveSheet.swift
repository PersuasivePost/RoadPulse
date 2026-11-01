import SwiftUI

// MARK: - Drive Mode sheet

struct DriveSheet: View {
    // @ObservedObject: the Map tab owns the view model, so a drive survives closing the sheet
    @ObservedObject var drive: DriveViewModel
    // @AppStorage: spike threshold (g) from Settings
    @AppStorage(SettingsKey.driveThresholdG) private var threshold = SettingsKey.Default.driveThresholdG
    @AppStorage(SettingsKey.units) private var units: UnitSystem = SettingsKey.Default.units
    // @Environment: animations are skipped when Reduce Motion is on
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                WaveformView(samples: drive.waveform, thresholdG: threshold, isHot: drive.rms > threshold)
                stats
                LaneDivider()
                controls
                if let message = drive.errorMessage {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(Severity.severe.color)
                }
            }
            .padding(16)
        }
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.visible)
        // No background interaction: a pin tap would try to open a second sheet, which SwiftUI refuses.
        .presentationBackground(Color.surface)
        .presentationCornerRadius(20)
    }

    // MARK: Parts

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Drive Mode")
                .font(.title2.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.inkMuted)
        }
    }

    private var subtitle: String {
        switch drive.phase {
        case .idle: return "Put your phone in a holder and drive. Rough stretches appear on the map."
        case .running(let isReplay): return isReplay ? "Replaying a sample drive…" : "Recording. Rough stretches are marked in colour."
        case .finished: return "Drive finished."
        }
    }

    private var stats: some View {
        HStack(spacing: 12) {
            statTile("Vibration", String(format: "%.2f g", drive.rms), "waveform.path")
            statTile("Rough spots", "\(drive.roughSpots)", "exclamationmark.triangle")
            statTile("Distance", units.distance(meters: drive.distanceMeters), "point.topleft.down.to.point.bottomright.curvepath")
        }
    }

    private func statTile(_ title: String, _ value: String, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.laneYellow)
            Text(value)
                .font(.headline)
                .fontDesign(.rounded)
                .monospacedDigit()
                .foregroundStyle(Color.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color.inkMuted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.surfaceRaised))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var controls: some View {
        switch drive.phase {
        case .idle:
            VStack(spacing: 16) {
                if drive.isLiveAvailable {
                    HoldToStartButton { drive.start(replay: false, thresholdG: threshold) }
                }
                SheetActionButton(title: "Replay sample drive", systemImage: "play.circle") {
                    drive.start(replay: true, thresholdG: threshold)
                }
            }
            .frame(maxWidth: .infinity)
        case .running:
            PrimaryButton(title: "Stop drive", systemImage: "stop.fill") { drive.stop() }
        case .finished(let summary):
            VStack(spacing: 12) {
                Label("\(summary.roughSpots) rough spots over \(units.distance(meters: summary.distanceMeters))",
                      systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.ink)
                    .symbolEffect(.bounce, value: reduceMotion ? nil : summary)
                PrimaryButton(title: "Done") { drive.dismissSummary() }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DriveSheet(drive: DriveViewModel(persistence: .preview))
}
