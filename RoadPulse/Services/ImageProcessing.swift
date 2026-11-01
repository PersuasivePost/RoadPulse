import ImageIO
import UIKit

// MARK: - Image preparation

enum ImageProcessing {
    /// Redraws the image upright (camera photos carry an EXIF rotation) and scales it so its
    /// longest side is at most `maxDimension` pixels. Smaller images are only straightened.
    static func prepared(_ image: UIImage, maxDimension: CGFloat = 1024) -> UIImage {
        let pixelSize = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let longest = max(pixelSize.width, pixelSize.height)
        guard longest > 0 else { return image }
        let ratio = min(1, maxDimension / longest)
        let target = CGSize(width: (pixelSize.width * ratio).rounded(), height: (pixelSize.height * ratio).rounded())

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // target is in pixels
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target)) // draw(in:) applies the orientation
        }
    }

    /// JPEG for storage in Core Data's external binary storage.
    static func jpegData(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
}

// MARK: - Orientation for Vision

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
