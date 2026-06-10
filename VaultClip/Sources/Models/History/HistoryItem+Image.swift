//
//  HistoryItem+Image.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit
import Foundation
import ImageIO

extension HistoryItem {
    
    /// Pasteboard types treated as in-memory raster images (priority order for decoding).
    static let rasterImagePasteboardTypes: [NSPasteboard.PasteboardType] = [
        .png,
        .tiff,
        NSPasteboard.PasteboardType("public.jpeg"),
        NSPasteboard.PasteboardType("public.jpg"),
        NSPasteboard.PasteboardType("public.heic"),
        NSPasteboard.PasteboardType("public.heif"),
        NSPasteboard.PasteboardType("com.compuserve.gif"),
        NSPasteboard.PasteboardType("public.gif"),
        NSPasteboard.PasteboardType("com.microsoft.bmp"),
        NSPasteboard.PasteboardType("public.bmp"),
        NSPasteboard.PasteboardType("org.webmproject.webp"),
        NSPasteboard.PasteboardType("public.webp"),
        NSPasteboard.PasteboardType("com.apple.icns"),
        NSPasteboard.PasteboardType("public.image"),
    ]
    
    /// Legacy macOS image types still emitted by Safari, Preview, Screenshot, etc.
    static let legacyRasterPasteboardTypes: [NSPasteboard.PasteboardType] = [
        NSPasteboard.PasteboardType("Apple PNG pasteboard type"),
        NSPasteboard.PasteboardType("NeXT TIFF v4.0 pasteboard type"),
        NSPasteboard.PasteboardType("com.apple.pict"),
    ]
    
    static var allRasterCaptureTypes: [NSPasteboard.PasteboardType] {
        rasterImagePasteboardTypes + legacyRasterPasteboardTypes
    }
    
    static func isRasterImageType(_ type: NSPasteboard.PasteboardType) -> Bool {
        allRasterCaptureTypes.contains(type)
    }
    
    /// Whether the item carries decodable raster image bytes (may coexist with a temp `file://` URL).
    func hasRasterImage() -> Bool {
        getImage() != nil
    }
    
    func getImage() -> NSImage? {
        for type in Self.allRasterCaptureTypes where types.contains(type) {
            guard let data = data(forType: type), !data.isEmpty else { continue }
            if let image = Self.decodeRasterImage(from: data) {
                return image
            }
        }
        for type in types where Self.isLikelyRasterPasteboardType(type) {
            guard let data = data(forType: type), !data.isEmpty else { continue }
            if let image = Self.decodeRasterImage(from: data) {
                return image
            }
        }
        return nil
    }
    
    /// Searchable / fallback label, e.g. "Image (JPEG)".
    func getRasterImageDisplayString() -> String? {
        guard hasRasterImage() else { return nil }
        if let type = Self.allRasterCaptureTypes.first(where: { types.contains($0) }) {
            return "Image (\(Self.displayName(for: type)))"
        }
        return "Image"
    }
    
    /// Reads raster bytes from a pasteboard item when generic type iteration misses them.
    static func extractRasterData(from item: NSPasteboardItem) -> [NSPasteboard.PasteboardType: Data]? {
        for type in allRasterCaptureTypes where item.types.contains(type) {
            if let data = item.data(forType: type), !data.isEmpty, decodeRasterImage(from: data) != nil {
                return [type: data]
            }
        }
        for type in item.types where isLikelyRasterPasteboardType(type) {
            if let data = item.data(forType: type), !data.isEmpty, decodeRasterImage(from: data) != nil {
                return [type: data]
            }
        }
        return nil
    }
    
    static func decodeRasterImage(from data: Data) -> NSImage? {
        if let image = NSImage(data: data) {
            if let normalized = normalizeDecodedImage(image) {
                return normalized
            }
        }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
    
    static func displayPixelSize(of image: NSImage) -> NSSize {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first(where: { $0.pixelsWide > 0 }) {
            return NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        }
        if image.size.width > 0 && image.size.height > 0 {
            return image.size
        }
        return NSSize(width: 1, height: 1)
    }
    
    static func displayName(for type: NSPasteboard.PasteboardType) -> String {
        switch type.rawValue {
        case NSPasteboard.PasteboardType.png.rawValue, "Apple PNG pasteboard type": return "PNG"
        case NSPasteboard.PasteboardType.tiff.rawValue, "NeXT TIFF v4.0 pasteboard type": return "TIFF"
        case "public.jpeg", "public.jpg": return "JPEG"
        case "public.heic": return "HEIC"
        case "public.heif": return "HEIF"
        case "com.compuserve.gif", "public.gif": return "GIF"
        case "com.microsoft.bmp", "public.bmp": return "BMP"
        case "org.webmproject.webp", "public.webp": return "WebP"
        case "com.apple.icns": return "ICNS"
        case "public.image", "com.apple.pict": return "Image"
        default:
            let raw = type.rawValue
            if let suffix = raw.split(separator: ".").last, suffix != raw {
                return String(suffix).uppercased()
            }
            return "Image"
        }
    }
    
    private static func normalizeDecodedImage(_ image: NSImage) -> NSImage? {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first(where: { $0.pixelsWide > 0 }) {
            let size = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            let normalized = NSImage(size: size)
            normalized.addRepresentation(rep)
            return normalized
        }
        if image.size.width > 0 && image.size.height > 0 {
            return image
        }
        return nil
    }
    
    private static func isLikelyRasterPasteboardType(_ type: NSPasteboard.PasteboardType) -> Bool {
        if isRasterImageType(type) {
            return true
        }
        let raw = type.rawValue.lowercased()
        let hints = ["png", "tiff", "jpeg", "jpg", "heic", "heif", "gif", "bmp", "webp", "image", "pict"]
        return hints.contains(where: { raw.contains($0) })
    }
}
