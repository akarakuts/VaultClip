//
//  HistoryItem+Password.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

extension HistoryItem {
    
    static let passwordMetadataFileName = "password"
    static let passwordCommentMetadataFileName = "passwordComment"
    static let passwordLoginMetadataFileName = "passwordLogin"
    static let passwordURLMetadataFileName = "passwordURL"
    
    static let passwordMarker = "1"
    
    /// URL for "Open in Browser" when the stored string is valid.
    var passwordOpenableURL: URL? {
        let trimmed = passwordURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }
    
    /// Trims and adds https:// when the user omits a scheme.
    static func normalizePasswordURL(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.contains("://") { return trimmed }
        return "https://\(trimmed)"
    }
}
