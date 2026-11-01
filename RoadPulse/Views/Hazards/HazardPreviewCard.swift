import SwiftUI

// MARK: - Long-press preview

/// Larger look at a report, shown above the context menu.
struct HazardPreviewCard: View {
    @ObservedObject var hazard: Hazard

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            photo
            Text(hazard.displayTitle)
                .font(.title3.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            if let address = hazard.address {
                Text(address)
                    .font(.footnote)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(2)
            }
            SeverityBadge(severity: hazard.severityLevel, isFixed: hazard.isFixed)
        }
        .padding(16)
        .frame(width: 300, alignment: .leading)
        .background(Color.surface)
    }

    @ViewBuilder
    private var photo: some View {
        if let data = hazard.photo, let image = ThumbnailCache.downsample(data, maxPixel: 900) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Image(systemName: hazard.hazardType.symbol)
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(hazard.severityLevel.color(isFixed: hazard.isFixed))
                .frame(height: 100)
                .frame(maxWidth: .infinity)
        }
    }
}
