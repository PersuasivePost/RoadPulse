import ImageIO
import UIKit

// MARK: - Thumbnail cache

/// Downsampled hazard photos for rows and grid cells. Decoding a 1024 px JPEG on every scroll
/// would stutter, so thumbnails are made once (ImageIO) and kept in an `NSCache`.
enum ThumbnailCache {
    private static let cache = NSCache<NSUUID, UIImage>()

    static func image(for hazard: Hazard, maxPixel: CGFloat = 400) -> UIImage? {
        let key = hazard.id as NSUUID
        if let cached = cache.object(forKey: key) { return cached }
        guard let data = hazard.photo, let image = downsample(data, maxPixel: maxPixel) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    static func downsample(_ data: Data, maxPixel: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Call after a photo changes or a hazard is deleted.
    static func remove(_ id: UUID) {
        cache.removeObject(forKey: id as NSUUID)
    }
}
