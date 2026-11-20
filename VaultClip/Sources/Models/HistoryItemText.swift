//
//  HistoryItemText.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

struct HistoryItemText {
    
    static let passwordMask = "••••••••"

    /// VoiceOver label: localized type + preview text; passwords never include the secret (T36).
    static func accessibilityLabel(for item: HistoryItem, listMode: HistoryListMode) -> String {
        let typeName = accessibilityTypeName(for: item)
        let preview: String
        if item.isPassword {
            preview = passwordMask
        } else {
            preview = String(getString(forItem: item, listMode: listMode).prefix(200))
        }
        if preview.isEmpty { return typeName }
        return "\(typeName), \(preview)"
    }

    private static func accessibilityTypeName(for item: HistoryItem) -> String {
        if item.isPassword { return L10n.a11yTypePassword }
        if item.hasRasterImage() { return L10n.a11yTypeImage }
        if item.types.contains(.pdf) || item.types.contains(NSPasteboard.PasteboardType(rawValue: "com.adobe.pdf")) {
            return L10n.a11yTypePDF
        }
        if item.getColor() != nil { return L10n.a11yTypeColor }
        if item.getFileUrl() != nil { return L10n.a11yTypeFile }
        return L10n.a11yTypeText
    }
    
    static let itemStringAttributes: [NSAttributedString.Key: Any] = [
        .font: PanelChrome.Typography.body,
        .foregroundColor: NSColor.textColor,
        .paragraphStyle: PanelChrome.Typography.bodyParagraphStyle,
    ]
    
    static let copiedAtLabelAttributes: [NSAttributedString.Key: Any] = [
        .font: PanelChrome.Typography.body,
        .foregroundColor: PanelChrome.Colors.copiedAtLabel,
        .paragraphStyle: PanelChrome.Typography.bodyParagraphStyle,
    ]
    
    static let passwordCommentAttributes: [NSAttributedString.Key: Any] = [
        .font: PanelChrome.Typography.body,
        .foregroundColor: PanelChrome.Colors.passwordCommentLabel,
        .paragraphStyle: PanelChrome.Typography.bodyParagraphStyle,
    ]
    
    static let passwordLoginAttributes: [NSAttributedString.Key: Any] = [
        .font: PanelChrome.Typography.body,
        .foregroundColor: PanelChrome.Colors.passwordLoginLabel,
        .paragraphStyle: PanelChrome.Typography.bodyParagraphStyle,
    ]
    
    static func displayCacheSignature(for item: HistoryItem, listMode: HistoryListMode) -> String {
        "\(listMode.rawValue)|\(item.isFavorite)|\(item.isPassword)|\(item.passwordComment)|\(item.passwordLogin)|\(item.passwordURL)"
    }
    
    static func shouldMaskPassword(for item: HistoryItem, listMode: HistoryListMode, revealPassword: Bool) -> Bool {
        item.isPassword && !revealPassword && listMode != .passwords
    }
    
    static func getString(forItem item: HistoryItem, listMode: HistoryListMode = .history, revealPassword: Bool = false) -> String {
        if listMode == .passwords, item.isPassword {
            return passwordTabPlainString(for: item)
        }
        if shouldMaskPassword(for: item, listMode: listMode, revealPassword: revealPassword) {
            return passwordMask
        }
        if let plainStr = item.getPlainString() {
            return plainStr
        }
        else if let attrStr = item.getRtfAttributedString() {
            return attrStr.string
        }
        else if let htmlStr = item.getHtmlRawString() {
            return htmlStr
        }
        else if let url = item.getUrl() {
            return url.absoluteString
        }
        else if let pdfLabel = item.getPdfDisplayString() {
            return pdfLabel
        }
        else if let imageLabel = item.getRasterImageDisplayString() {
            return imageLabel
        }
        else if let url = item.getFileUrl() {
            return url.path
        }
        else {
            return item.getCopiedAtDisplayString()
        }
    }
    
    static func getAttributedString(
        forItem item: HistoryItem,
        usingItemRtf: Bool = true,
        listMode: HistoryListMode = .history,
        revealPassword: Bool = false
    ) -> NSAttributedString {
        if listMode == .passwords, item.isPassword {
            return passwordTabAttributedString(for: item)
        }
        if shouldMaskPassword(for: item, listMode: listMode, revealPassword: revealPassword) {
            return NSAttributedString(string: passwordMask, attributes: itemStringAttributes)
        }
        let base: NSAttributedString
        if usingItemRtf, let attrStr = item.getRtfAttributedString() {
            base = attrStr
        } else if let url = item.getUrl(),
                  item.getPlainString() == nil,
                  item.getRtfAttributedString() == nil,
                  item.getHtmlRawString() == nil {
            base = NSAttributedString(
                string: url.absoluteString,
                attributes: urlStringAttributes(for: url)
            )
        } else {
            let label = getString(forItem: item, listMode: listMode, revealPassword: revealPassword)
            if label == item.getCopiedAtDisplayString() {
                base = NSAttributedString(string: label, attributes: copiedAtLabelAttributes)
            } else {
                base = NSAttributedString(string: label, attributes: itemStringAttributes)
            }
        }
        return withLeftAlignedParagraphs(base)
    }
    
    static func passwordTabPlainString(for item: HistoryItem) -> String {
        passwordTabLines(for: item)
            .map(\.text)
            .joined(separator: "\n")
    }
    
    static func appendPasswordCommentIfNeeded(
        to base: NSAttributedString,
        for item: HistoryItem,
        listMode: HistoryListMode = .passwords
    ) -> NSAttributedString {
        if listMode == .passwords, item.isPassword {
            return passwordTabAttributedString(for: item)
        }
        return withLeftAlignedParagraphs(base)
    }
    
    static func passwordTabAttributedString(for item: HistoryItem) -> NSAttributedString {
        let combined = NSMutableAttributedString()
        let lines = passwordTabLines(for: item)
        for (index, line) in lines.enumerated() {
            if index > 0 {
                combined.append(NSAttributedString(string: "\n", attributes: itemStringAttributes))
            }
            combined.append(NSAttributedString(string: line.text, attributes: line.attributes))
        }
        return withLeftAlignedParagraphs(combined)
    }
    
    private static func passwordTabLines(for item: HistoryItem) -> [(text: String, attributes: [NSAttributedString.Key: Any])] {
        var lines: [(String, [NSAttributedString.Key: Any])] = []
        let comment = item.passwordComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !comment.isEmpty {
            lines.append((comment, passwordCommentAttributes))
        }
        let login = item.passwordLogin.trimmingCharacters(in: .whitespacesAndNewlines)
        if !login.isEmpty {
            lines.append((login, passwordLoginAttributes))
        }
        let urlString = item.passwordURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.isEmpty {
            if let url = HistoryItem.openableHTTPURL(from: urlString) {
                lines.append((url.absoluteString, urlStringAttributes(for: url)))
            } else {
                lines.append((urlString, passwordLoginAttributes))
            }
        }
        lines.append((passwordMask, itemStringAttributes))
        return lines
    }
    
    /// Normalizes pasted RTF/HTML styles so list rows stay left-aligned.
    static func withLeftAlignedParagraphs(_ string: NSAttributedString) -> NSAttributedString {
        guard string.length > 0 else { return string }
        let mutable = NSMutableAttributedString(attributedString: string)
        let fullRange = NSRange(location: 0, length: mutable.length)
        var hasParagraphStyle = false
        mutable.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
            hasParagraphStyle = true
            let style: NSMutableParagraphStyle
            if let existing = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle {
                style = existing
            } else {
                let fallback = NSMutableParagraphStyle()
                fallback.setParagraphStyle(PanelChrome.Typography.bodyParagraphStyle)
                style = fallback
            }
            style.alignment = .left
            mutable.addAttribute(.paragraphStyle, value: style, range: range)
        }
        if !hasParagraphStyle {
            mutable.addAttribute(.paragraphStyle, value: PanelChrome.Typography.bodyParagraphStyle, range: fullRange)
        }
        return mutable
    }
    
    private static func urlStringAttributes(for url: URL) -> [NSAttributedString.Key: Any] {
        [
            .font: Constants.fonts.listPlainText,
            .foregroundColor: NSColor.linkColor,
            .link: url,
        ]
    }

    /// Shared HTML strip for search (regex only — safe off the main thread).
    static func stripHTMLTagsForSearch(_ html: String) -> String {
        stripHTMLTags(html)
    }

    /// Cheap searchable blob for SearchIndex (no HTML AppKit parse, no PDF/image decode).
    static func searchableText(for source: SearchSource, cache: HistoryCache) -> String {
        #if DEBUG
        dispatchPrecondition(condition: .notOnQueue(.main))
        #endif
        if source.isPassword {
            return [source.passwordComment, source.passwordLogin, source.passwordURL]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        }
        if let prefetched = source.prefetchedText, !prefetched.isEmpty {
            return prefetched
        }
        let types = Set(source.types)
        if let plain = firstDecodedString(id: source.fsId, types: HistoryItem.plainTextPasteboardTypes, in: types, cache: cache) {
            return String(plain.prefix(20_000))
        }
        if let rtf = cache.data(withId: source.fsId, forType: .rtf),
           let attr = NSAttributedString(rtf: rtf, documentAttributes: nil) {
            return String(attr.string.prefix(20_000))
        }
        if let html = cache.data(withId: source.fsId, forType: .html),
           let raw = String(data: html, encoding: .utf8) {
            return String(stripHTMLTags(raw).prefix(20_000))
        }
        if types.contains(.URL), let data = cache.data(withId: source.fsId, forType: .URL),
           let url = HistoryItem.parseUrl(from: data) {
            return url.absoluteString
        }
        if types.contains(.fileURL), let data = cache.data(withId: source.fsId, forType: .fileURL),
           let url = HistoryItem.parseUrl(from: data) {
            return url.path
        }
        if types.contains(.pdf) || types.contains(NSPasteboard.PasteboardType(rawValue: "com.adobe.pdf")) {
            return L10n.searchLabelPDF
        }
        if HistoryItem.rasterImagePasteboardTypes.contains(where: types.contains) {
            return L10n.searchLabelImage
        }
        return ""
    }

    private static func firstDecodedString(
        id: UUID,
        types: [NSPasteboard.PasteboardType],
        in available: Set<NSPasteboard.PasteboardType>,
        cache: HistoryCache
    ) -> String? {
        for type in types where available.contains(type) {
            guard let data = cache.data(withId: id, forType: type),
                  let string = String(data: data, encoding: .utf8),
                  !string.isEmpty else { continue }
            return string
        }
        return nil
    }

    private static func stripHTMLTags(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
