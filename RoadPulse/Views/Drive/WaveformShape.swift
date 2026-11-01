import SwiftUI

// MARK: - Waveform

/// The last few seconds of vertical acceleration as a line. `range` is the g value at the top
/// and (negated) at the bottom of the frame; readings beyond it are clamped.
struct WaveformShape: Shape {
    var samples: [Double]
    var range: Double = 1

    /// Y for a reading in a frame `height` tall (0 at the top).
    static func y(for value: Double, range: Double, height: CGFloat) -> CGFloat {
        let clamped = min(max(value, -range), range)
        return height / 2 - CGFloat(clamped / range) * height / 2
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard samples.count > 1 else { return path }
        let step = rect.width / CGFloat(DriveViewModel.waveformLength - 1)
        // Newest sample on the right edge, so the line scrolls leftwards.
        let startX = rect.maxX - step * CGFloat(samples.count - 1)
        for (index, value) in samples.enumerated() {
            let point = CGPoint(x: startX + step * CGFloat(index),
                                y: rect.minY + Self.y(for: value, range: range, height: rect.height))
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

// MARK: - Waveform view

/// Waveform over a dashed lane-line baseline (the signature motif), with the threshold marked.
struct WaveformView: View {
    let samples: [Double]
    let thresholdG: Double
    let isHot: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Baseline()
                    .stroke(Color.laneYellow.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
                Baseline(offset: WaveformShape.y(for: thresholdG, range: 1, height: proxy.size.height) - proxy.size.height / 2)
                    .stroke(Severity.high.color.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                WaveformShape(samples: samples)
                    .stroke(isHot ? Severity.severe.color : Color.laneYellow,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true) // the numbers beside it carry the same information
    }

    private struct Baseline: Shape {
        var offset: CGFloat = 0
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY + offset))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + offset))
            return path
        }
    }
}

// MARK: - Preview

#Preview {
    WaveformView(samples: (0 ..< 150).map { sin(Double($0) / 5) * 0.6 }, thresholdG: 0.35, isHot: true)
        .padding()
        .background(Color.surface)
}
