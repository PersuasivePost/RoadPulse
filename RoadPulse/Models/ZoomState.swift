import CoreGraphics

// MARK: - Pinch-zoom state

/// Scale and pan for the detail photo. Pure value maths; `ZoomableImage` feeds it gesture values.
struct ZoomState: Equatable {
    static let scaleRange: ClosedRange<CGFloat> = 1 ... 4
    /// Scale a double-tap zooms to.
    static let doubleTapScale: CGFloat = 2.5

    var scale: CGFloat = 1
    var offset: CGSize = .zero

    var isZoomed: Bool { scale > 1.01 }

    static func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, scaleRange.lowerBound), scaleRange.upperBound)
    }

    /// Keeps the pan inside the zoomed image so no empty edge shows.
    static func clampedOffset(_ offset: CGSize, scale: CGFloat, in size: CGSize) -> CGSize {
        let limitX = max((scale - 1) * size.width / 2, 0)
        let limitY = max((scale - 1) * size.height / 2, 0)
        return CGSize(width: min(max(offset.width, -limitX), limitX),
                      height: min(max(offset.height, -limitY), limitY))
    }

    mutating func reset() {
        scale = 1
        offset = .zero
    }

    /// Double-tap: zoomed → back to fit; fit → zoomed in.
    mutating func toggle() {
        if isZoomed { reset() } else { scale = Self.doubleTapScale }
    }

    /// Commits a finished pinch and pan.
    mutating func commit(magnification: CGFloat, drag: CGSize, in size: CGSize) {
        scale = Self.clampedScale(scale * magnification)
        if isZoomed {
            offset = Self.clampedOffset(CGSize(width: offset.width + drag.width,
                                               height: offset.height + drag.height),
                                        scale: scale, in: size)
        } else {
            reset()
        }
    }
}
