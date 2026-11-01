import SwiftUI

// MARK: - List row

struct HazardRow: View {
    // @ScaledMetric: the thumbnail grows with Dynamic Type, like the text beside it
    @ScaledMetric(relativeTo: .body) private var thumbnailSize: CGFloat = 64
    @ObservedObject var hazard: Hazard
    let namespace: Namespace.ID
    let isHeroSource: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            onSelect()
        } label: {
            HStack(spacing: 12) {
                HazardThumbnail(hazard: hazard, namespace: namespace, isSource: isHeroSource)
                    .frame(width: thumbnailSize, height: thumbnailSize)
                VStack(alignment: .leading, spacing: 4) {
                    Text(hazard.displayTitle)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(hazard.isFixed ? Color.inkMuted : Color.ink)
                        .lineLimit(1)
                        .layoutPriority(1) // when space runs out the address truncates, not the title
                    Text(hazard.address ?? hazard.hazardType.label)
                        .font(.caption)
                        .foregroundStyle(Color.inkMuted)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        SeverityBadge(severity: hazard.severityLevel, isFixed: hazard.isFixed)
                        Text(hazard.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(Color.inkMuted)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.inkMuted)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the report")
    }
}

// MARK: - Gallery cell

struct HazardGridCell: View {
    @ObservedObject var hazard: Hazard
    let namespace: Namespace.ID
    let isHeroSource: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HazardThumbnail(hazard: hazard, namespace: namespace, isSource: isHeroSource)
                    .aspectRatio(1, contentMode: .fit)
                Text(hazard.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(hazard.isFixed ? Color.inkMuted : Color.ink)
                    .lineLimit(1)
                SeverityBadge(severity: hazard.severityLevel, isFixed: hazard.isFixed)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the report")
    }
}
