//
// ThumbnailMemoryCache — in-memory NSCache for row thumbnails, 32 MB cap (U11).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import ImageIO

final class ThumbnailMemoryCache {
    static let shared = ThumbnailMemoryCache()

    private let cache = NSCache<NSString, NSImage>()
    private var pressureSource: DispatchSourceMemoryPressure?

    private init() {
        cache.totalCostLimit = 32 * 1024 * 1024
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        source.setEventHandler { [weak self] in
            self?.cache.removeAllObjects()
        }
        source.resume()
        pressureSource = source
    }

    func image(forKey key: String) -> NSImage? {
        cache.object(forKey: key as NSString)
    }

    func store(_ image: NSImage, forKey key: String, cost: Int) {
        cache.setObject(image, forKey: key as NSString, cost: max(cost, 1))
    }

    func clear() {
        cache.removeAllObjects()
    }

    /// Creates a thumbnail in memory only — never writes temp files.
    static func thumbnail(from data: Data, maxPixelSize: CGFloat) -> NSImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
