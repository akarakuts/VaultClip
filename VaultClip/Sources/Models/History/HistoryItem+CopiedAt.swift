//
//  HistoryItem+CopiedAt.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

extension HistoryItem {
    
    static let copiedAtMetadataFileName = "copiedAt"
    
    static let metadataFileNames: Set<String> = [
        sourceBundleIdMetadataFileName,
        copiedAtMetadataFileName,
        favoriteMetadataFileName,
        passwordMetadataFileName,
        passwordCommentMetadataFileName,
    ]
    
    static func isMetadataFileName(_ name: String) -> Bool {
        metadataFileNames.contains(name) || name.hasPrefix(".")
    }
    
    /// Localized date/time shown when the item has no other displayable label.
    func getCopiedAtDisplayString() -> String {
        Self.copiedAtFormatter.string(from: copiedAt)
    }
    
    private static let copiedAtFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = false
        return formatter
    }()
    
    static func serializeCopiedAt(_ date: Date) -> String {
        String(date.timeIntervalSince1970)
    }
    
    static func deserializeCopiedAt(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let interval = TimeInterval(trimmed) else { return nil }
        return Date(timeIntervalSince1970: interval)
    }
}
