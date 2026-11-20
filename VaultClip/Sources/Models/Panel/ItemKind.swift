//
// ItemKind — clipboard item classification without decrypting secrets (U05).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum ItemKind: Equatable, Hashable {
    case text
    case richText
    case link
    case image
    case file(Int)
    case pdf
    case color
    case password
}

struct ItemKindClassifierInput: Equatable {
    var isPassword: Bool
    var typeIdentifiers: [String]
    /// Trimmed plain text when available without decrypting password payloads.
    var plainText: String?
    var fileURLCount: Int
}

enum ItemKindClassifier {
    private static let linkSchemes: Set<String> = ["http", "https", "mailto", "ftp"]

    static func classify(_ input: ItemKindClassifierInput) -> ItemKind {
        if input.isPassword { return .password }

        let types = Set(input.typeIdentifiers.map { $0.lowercased() })
        if typesContainsColor(types) { return .color }
        if typesContainsImage(types) { return .image }
        if typesContainsPDF(types) { return .pdf }
        if input.fileURLCount > 0 || typesContainsFileURL(types) {
            return .file(max(1, input.fileURLCount))
        }
        if typesContainsURL(types) || isStandaloneURL(input.plainText) {
            return .link
        }
        if typesContainsRichText(types) { return .richText }
        return .text
    }

    static func isStandaloneURL(_ text: String?) -> Bool {
        guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return false
        }
        // Prefer URL initializer for full-string match.
        if let url = URL(string: raw), let scheme = url.scheme?.lowercased(), linkSchemes.contains(scheme) {
            return true
        }
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        let ns = raw as NSString
        let full = NSRange(location: 0, length: ns.length)
        guard let match = detector.firstMatch(in: raw, options: [], range: full),
              match.range == full,
              let url = match.url,
              let scheme = url.scheme?.lowercased() else { return false }
        return linkSchemes.contains(scheme)
    }

    private static func typesContainsColor(_ types: Set<String>) -> Bool {
        types.contains("com.apple.cocoa.pasteboard.color")
            || types.contains { $0.contains("color") && $0.contains("pasteboard") }
    }

    private static func typesContainsImage(_ types: Set<String>) -> Bool {
        let hints = ["public.png", "public.jpeg", "public.tiff", "public.heic", "public.gif", "public.bmp", "public.webp", "image"]
        return types.contains { t in hints.contains(where: { t.contains($0) }) || t.hasPrefix("public.image") }
    }

    private static func typesContainsPDF(_ types: Set<String>) -> Bool {
        types.contains("com.adobe.pdf") || types.contains("public.pdf")
    }

    private static func typesContainsFileURL(_ types: Set<String>) -> Bool {
        types.contains("public.file-url") || types.contains("nsfilenamespboardtype")
    }

    private static func typesContainsURL(_ types: Set<String>) -> Bool {
        types.contains("public.url") || types.contains("public.url-name")
    }

    private static func typesContainsRichText(_ types: Set<String>) -> Bool {
        types.contains("public.rtf") || types.contains("public.html")
            || types.contains("neXT rich text format v1.0 pasteboard type")
    }
}

/// Cached kind keyed by fsId; invalidate when flags/digest change.
final class ItemKindCache {
    private struct Key: Hashable {
        let fsId: UUID
        let isPassword: Bool
        let digest: String?
    }

    private var values: [Key: ItemKind] = [:]
    private let lock = NSLock()

    func kind(for input: ItemKindClassifierInput, fsId: UUID, digest: String?) -> ItemKind {
        let key = Key(fsId: fsId, isPassword: input.isPassword, digest: digest)
        lock.lock()
        if let cached = values[key] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        let kind = ItemKindClassifier.classify(input)
        lock.lock()
        values[key] = kind
        lock.unlock()
        return kind
    }

    func remove(fsId: UUID) {
        lock.lock()
        values = values.filter { $0.key.fsId != fsId }
        lock.unlock()
    }

    func clear() {
        lock.lock()
        values.removeAll()
        lock.unlock()
    }
}
