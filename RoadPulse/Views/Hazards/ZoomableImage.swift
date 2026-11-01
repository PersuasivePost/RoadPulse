import SwiftUI

// MARK: - Pinch-zoom photo

/// Pinch to zoom (1x–4x), drag to pan while zoomed, double-tap to zoom in or reset.
/// The maths lives in `ZoomState`; this view only feeds it gesture values.
struct ZoomableImage: View {
    let image: UIImage

    // @State: the committed zoom; gestures update a copy while they are in flight
    @State private var zoom = ZoomState()
    // @GestureState: live pinch/drag values that snap back to identity when the gesture ends
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var drag: CGSize = .zero
    // @Environment: the double-tap reset skips its animation under Reduce Motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let scale = ZoomState.clampedScale(zoom.scale * pinch)
            let offset = ZoomState.clampedOffset(
                CGSize(width: zoom.offset.width + drag.width, height: zoom.offset.height + drag.height),
                scale: scale, in: proxy.size)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .contentShape(Rectangle())
                .gesture(pinchGesture(size: proxy.size))
                // Panning only while zoomed, so an unzoomed photo never steals the scroll.
                .gesture(panGesture(size: proxy.size), including: zoom.isZoomed ? .all : .none)
                .onTapGesture(count: 2) {
                    withAnimation(reduceMotion ? nil : Motion.smooth) { zoom.toggle() }
                }
        }
        .accessibilityLabel("Photo of the hazard")
        .accessibilityHint("Double tap to zoom")
        .accessibilityAddTraits(.isImage)
    }

    // MARK: Gestures

    private func pinchGesture(size: CGSize) -> some Gesture {
        MagnifyGesture()
            .updating($pinch) { value, state, _ in state = value.magnification }
            .onEnded { value in
                withAnimation(reduceMotion ? nil : Motion.snappy) {
                    zoom.commit(magnification: value.magnification, drag: .zero, in: size)
                }
            }
    }

    private func panGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .updating($drag) { value, state, _ in state = value.translation }
            .onEnded { value in
                zoom.commit(magnification: 1, drag: value.translation, in: size)
            }
    }
}
