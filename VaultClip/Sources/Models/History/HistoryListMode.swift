//
//  HistoryListMode.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum HistoryListMode: Int, CaseIterable {
    case history = 0
    case favorites = 1
    case passwords = 2
    
    static var tabDefinitions: [HistoryTabDefinition] {
        [
            HistoryTabDefinition(
                mode: .history,
                title: L10n.tabHistory,
                iconName: "clock.arrow.circlepath",
                fallbackGlyph: "⏱"
            ),
            HistoryTabDefinition(
                mode: .favorites,
                title: L10n.tabFavorites,
                iconName: "star.fill",
                fallbackGlyph: "★"
            ),
            HistoryTabDefinition(
                mode: .passwords,
                title: L10n.tabPasswords,
                iconName: "key.fill",
                fallbackGlyph: "🔑"
            ),
        ]
    }
    
    func next() -> HistoryListMode {
        let all = HistoryListMode.allCases
        guard let index = all.firstIndex(of: self) else { return self }
        return all[(index + 1) % all.count]
    }
    
    func previous() -> HistoryListMode {
        let all = HistoryListMode.allCases
        guard let index = all.firstIndex(of: self) else { return self }
        return all[(index + all.count - 1) % all.count]
    }
}
