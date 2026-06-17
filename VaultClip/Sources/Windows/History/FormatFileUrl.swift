//
//  FormatFileUrl.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

func formatFileUrl(_ url: URL) -> NSAttributedString {
    let str = NSMutableAttributedString(string: url.path)
    
    let lastComponentAttributes: [NSAttributedString.Key: Any] = [
        .font: Constants.fonts.listFileNameText,
        .foregroundColor: NSColor.textColor,
        .paragraphStyle: HistoryListTheme.typography.bodyParagraphStyle,
    ]
    
    let pathAttributes: [NSAttributedString.Key: Any] = [
        .font: Constants.fonts.listFileNameText,
        .foregroundColor: NSColor.secondaryLabelColor,
        .paragraphStyle: HistoryListTheme.typography.bodyParagraphStyle,
    ]
    
    let deletedAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.systemRed
    ]
    
    let startOfLast = url.path.count - url.lastPathComponent.count
    
    str.addAttributes(pathAttributes, range: NSRange(location: 0, length: startOfLast))
    str.addAttributes(lastComponentAttributes, range: NSRange(location: startOfLast, length: url.lastPathComponent.count))
    
    if !FileManager.default.fileExists(atPath: url.path) {
        str.addAttributes(deletedAttributes, range: NSRange(location: 0, length: url.path.count))
    }
    
    return str
}
