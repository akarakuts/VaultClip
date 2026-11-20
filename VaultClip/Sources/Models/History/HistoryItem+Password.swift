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
    
    /// http(s) URL for "Open in Browser"; other schemes stay plain text (T11).
    var passwordOpenableURL: URL? {
        Self.openableHTTPURL(from: passwordURL)
    }

    /// Trims and adds https:// when the user omits a scheme.
    static func normalizePasswordURL(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.contains("://") { return trimmed }
        return "https://\(trimmed)"
    }

    /// Only `http` / `https` (bare hosts get `https://`).
    static func openableHTTPURL(from raw: String) -> URL? {
        let normalized = normalizePasswordURL(raw)
        guard !normalized.isEmpty, let url = URL(string: normalized) else { return nil }
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }
        return url
    }
}
