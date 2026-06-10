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
    
    static let itemStringAttributes: [NSAttributedString.Key: Any] = [
        .font: HistoryListTheme.typography.body,
        .foregroundColor: NSColor.textColor,
        .paragraphStyle: HistoryListTheme.typography.bodyParagraphStyle,
    ]
    
    static let copiedAtLabelAttributes: [NSAttributedString.Key: Any] = [
        .font: HistoryListTheme.typography.body,
        .foregroundColor: HistoryListTheme.colors.copiedAtLabel,
        .paragraphStyle: HistoryListTheme.typography.bodyParagraphStyle,
    ]
    
    static let passwordCommentAttributes: [NSAttributedString.Key: Any] = [
        .font: HistoryListTheme.typography.body,
        .foregroundColor: HistoryListTheme.colors.passwordCommentLabel,
        .paragraphStyle: HistoryListTheme.typography.bodyParagraphStyle,
    ]
    
    static func displayCacheSignature(for item: HistoryItem, listMode: HistoryListMode) -> String {
        "\(listMode.rawValue)|\(item.isFavorite)|\(item.isPassword)|\(item.passwordComment)"
    }
    
    static func shouldMaskPassword(for item: HistoryItem, listMode: HistoryListMode, revealPassword: Bool) -> Bool {
        item.isPassword && !revealPassword && listMode != .passwords
    }
    
    static func getString(forItem item: HistoryItem, listMode: HistoryListMode = .history, revealPassword: Bool = false) -> String {
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
        if shouldMaskPassword(for: item, listMode: listMode, revealPassword: revealPassword) {
            let masked = NSAttributedString(string: passwordMask, attributes: itemStringAttributes)
            return appendPasswordCommentIfNeeded(to: masked, for: item, listMode: listMode)
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
        return appendPasswordCommentIfNeeded(to: base, for: item, listMode: listMode)
    }
    
    static func appendPasswordCommentIfNeeded(
        to base: NSAttributedString,
        for item: HistoryItem,
        listMode: HistoryListMode = .passwords
    ) -> NSAttributedString {
        guard listMode == .passwords, item.isPassword, !item.passwordComment.isEmpty else {
            return withLeftAlignedParagraphs(base)
        }
        let combined = NSMutableAttributedString(attributedString: withLeftAlignedParagraphs(base))
        combined.append(NSAttributedString(string: "\n" + item.passwordComment, attributes: passwordCommentAttributes))
        return combined
    }
    
    /// Normalizes pasted RTF/HTML styles so list rows stay left-aligned.
    static func withLeftAlignedParagraphs(_ string: NSAttributedString) -> NSAttributedString {
        guard string.length > 0 else { return string }
        let mutable = NSMutableAttributedString(attributedString: string)
        let fullRange = NSRange(location: 0, length: mutable.length)
        var hasParagraphStyle = false
        mutable.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
            hasParagraphStyle = true
            let style = ((value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle)
                ?? (HistoryListTheme.typography.bodyParagraphStyle.mutableCopy() as! NSMutableParagraphStyle)
            style.alignment = .left
            mutable.addAttribute(.paragraphStyle, value: style, range: range)
        }
        if !hasParagraphStyle {
            mutable.addAttribute(.paragraphStyle, value: HistoryListTheme.typography.bodyParagraphStyle, range: fullRange)
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
}
