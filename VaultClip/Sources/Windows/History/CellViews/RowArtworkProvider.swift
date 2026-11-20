//
// RowArtworkProvider — leading row art: thumbnails, color swatches, file icons, tinted symbols (U11).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

enum RowArtworkProvider {
    static let side: CGFloat = 28

    static func image(for item: HistoryItem, kind: ItemKind) -> NSImage? {
        switch kind {
        case .image:
            return thumbnail(for: item) ?? symbolTile("photo", tint: .systemTeal)
        case .color:
            return item.getColor().map(swatch) ?? symbolTile("paintpalette", tint: .systemPink)
        case .file:
            if let url = item.getFileUrl() {
                return NSWorkspace.shared.icon(forFile: url.path)
            }
            return symbolTile("doc", tint: .systemGray)
        case .pdf:
            return NSWorkspace.shared.icon(for: .pdf)
        case .link:
            return symbolTile("link", tint: .systemBlue)
        case .password:
            return symbolTile("key.fill", tint: .systemOrange)
        case .text, .richText:
            if let bundleId = item.sourceBundleId {
                return SourceAppIconProvider.icon(forBundleId: bundleId)
            }
            return symbolTile("text.alignleft", tint: .systemGray)
        }
    }

    private static func thumbnail(for item: HistoryItem) -> NSImage? {
        let key = "row:\(item.fsId.uuidString):\(Int(side))"
        if let cached = ThumbnailMemoryCache.shared.image(forKey: key) { return cached }
        guard let source = item.getImage(), source.size.width > 0, source.size.height > 0 else { return nil }
        let size = NSSize(width: side, height: side)
        let thumb = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            path.addClip()
            // Aspect-fill crop.
            let scale = max(rect.width / source.size.width, rect.height / source.size.height)
            let drawSize = NSSize(width: source.size.width * scale, height: source.size.height * scale)
            let origin = NSPoint(x: (rect.width - drawSize.width) / 2, y: (rect.height - drawSize.height) / 2)
            source.draw(in: NSRect(origin: origin, size: drawSize))
            return true
        }
        ThumbnailMemoryCache.shared.store(thumb, forKey: key, cost: Int(side * side * 16))
        return thumb
    }

    private static func swatch(_ color: NSColor) -> NSImage {
        NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            let circle = NSBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3))
            color.setFill()
            circle.fill()
            NSColor.separatorColor.setStroke()
            circle.lineWidth = 1
            circle.stroke()
            return true
        }
    }

    private static func symbolTile(_ name: String, tint: NSColor) -> NSImage {
        NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            let tile = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6)
            tint.withAlphaComponent(0.18).setFill()
            tile.fill()
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
                .applying(.init(paletteColors: [tint]))
            if let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                .withSymbolConfiguration(config) {
                let s = symbol.size
                symbol.draw(in: NSRect(
                    x: (rect.width - s.width) / 2,
                    y: (rect.height - s.height) / 2,
                    width: s.width,
                    height: s.height
                ))
            }
            return true
        }
    }
}
