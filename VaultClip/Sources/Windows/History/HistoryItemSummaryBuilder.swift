//
// HistoryItemSummaryBuilder — HistoryItem → ItemSummary bridge with per-item content cache (U05/U11).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import AppKit

final class HistoryItemSummaryBuilder {
    static let shared = HistoryItemSummaryBuilder()

    /// Content-derived fields never change for a stored item, so decrypt once per fsId.
    private struct ContentFacts {
        var kind: ItemKind
        var title: String
        var charCount: Int
        var lineCount: Int
        var linkHost: String?
        var fileNames: [String]
        var imagePixelSize: CGSize?
        var imageFormat: String?
        var colorHex: String?
        var pdfPageCount: Int?
        var isRichText: Bool
    }

    private var facts: [UUID: ContentFacts] = [:]

    func summary(for item: HistoryItem) -> ItemSummary {
        let content = facts[item.fsId] ?? makeFacts(for: item)
        facts[item.fsId] = content
        return ItemSummary(
            title: content.title,
            charCount: content.charCount,
            lineCount: content.lineCount,
            linkHost: content.linkHost,
            fileNames: content.fileNames,
            imagePixelSize: content.imagePixelSize,
            imageFormat: content.imageFormat,
            colorHex: content.colorHex,
            sourceBundleId: item.sourceBundleId,
            copiedAt: item.copiedAt,
            lastUsedAt: item.lastUsedAt,
            kind: item.isPassword ? .password : content.kind,
            passwordComment: item.passwordComment,
            pdfPageCount: content.pdfPageCount,
            isRichText: content.isRichText,
            sourceAppName: item.sourceBundleId.map { SourceAppDisplayName.name(forBundleId: $0) }
        )
    }

    func kind(for item: HistoryItem) -> ItemKind {
        summary(for: item).kind
    }

    func invalidate(id: UUID) {
        facts[id] = nil
    }

    func removeAll() {
        facts.removeAll()
    }

    private func makeFacts(for item: HistoryItem) -> ContentFacts {
        let typeIds = item.types.map(\.rawValue)
        let plain = item.isPassword ? nil : item.getPlainString()
        let fileURL = item.isPassword ? nil : item.getFileUrl()
        let kind = ItemKindClassifier.classify(.init(
            isPassword: item.isPassword,
            typeIdentifiers: typeIds,
            plainText: plain,
            fileURLCount: fileURL == nil ? 0 : 1
        ))
        let text = plain ?? ""
        var facts = ContentFacts(
            kind: kind,
            title: text,
            charCount: text.count,
            lineCount: max(1, text.split(whereSeparator: \.isNewline).count),
            linkHost: nil,
            fileNames: [],
            imagePixelSize: nil,
            imageFormat: nil,
            colorHex: nil,
            pdfPageCount: nil,
            isRichText: kind == .richText
        )
        switch kind {
        case .link:
            let url = item.getUrl() ?? URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines))
            facts.linkHost = url?.host
            if facts.title.isEmpty { facts.title = url?.absoluteString ?? "" }
        case .file:
            if let fileURL { facts.fileNames = [fileURL.lastPathComponent] }
        case .image:
            facts.imageFormat = Self.imageFormat(from: typeIds)
            if let rep = item.getImage()?.representations.first, rep.pixelsWide > 0 {
                facts.imagePixelSize = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
            }
        case .color:
            facts.colorHex = item.getColor().flatMap(Self.hex(for:))
        case .pdf:
            facts.title = item.getPdfDisplayString() ?? ""
            facts.pdfPageCount = item.getPdf()?.pageCount
        default:
            break
        }
        return facts
    }

    static func imageFormat(from types: [String]) -> String {
        let lower = types.map { $0.lowercased() }
        if lower.contains(where: { $0.contains("png") }) { return "PNG" }
        if lower.contains(where: { $0.contains("jpeg") || $0.contains("jpg") }) { return "JPEG" }
        if lower.contains(where: { $0.contains("heic") }) { return "HEIC" }
        if lower.contains(where: { $0.contains("gif") }) { return "GIF" }
        if lower.contains(where: { $0.contains("tiff") }) { return "TIFF" }
        return "PNG"
    }

    static func hex(for color: NSColor) -> String? {
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        let r = Int((rgb.redComponent * 255).rounded())
        let g = Int((rgb.greenComponent * 255).rounded())
        let b = Int((rgb.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
