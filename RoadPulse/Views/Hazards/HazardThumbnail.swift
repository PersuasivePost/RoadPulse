import SwiftUI

// MARK: - Hazard thumbnail (shared by the list, the gallery and the detail hero)

/// The photo, or a tinted type symbol when there is none. All three screens give it the same
/// matched-geometry id, so one thumbnail morphs between list row, grid cell and detail hero.
struct HazardThumbnail: View {
    @ObservedObject var hazard: Hazard
    let namespace: Namespace.ID
    /// False while the detail overlay shows this hazard's hero, so only one view is the source.
    var isSource = true
    var cornerRadius: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let image = ThumbnailCache.image(for: hazard) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    placeholder
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if hazard.isFixed {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.onFill, Color.fixedGrey)
                    .padding(4)
            }
        }
        .matchedGeometryEffect(id: hazard.id, in: namespace, isSource: isSource)
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        let tint = hazard.severityLevel.color(isFixed: hazard.isFixed)
        return ZStack {
            tint.opacity(0.14)
            Image(systemName: hazard.hazardType.symbol)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
        }
    }
}
