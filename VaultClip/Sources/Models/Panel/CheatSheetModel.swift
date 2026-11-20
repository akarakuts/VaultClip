//
// CheatSheetModel — all registry commands grouped for ⌘/ (U26).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct CheatSheetEntry: Equatable, Identifiable {
    var id: PanelCommandID
    var title: String
    var shortcut: String
    var group: PanelCommandGroup
}

enum CheatSheetModel {
    static func entries(filter query: String = "") -> [CheatSheetEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return PanelCommandRegistry.all.compactMap { command in
            let shortcut = command.bindings.first.map { $0.chord.displayString } ?? ""
            let entry = CheatSheetEntry(
                id: command.id,
                title: command.title,
                shortcut: shortcut,
                group: command.group
            )
            if q.isEmpty { return entry }
            let hay = (command.title + " " + command.keywords.joined(separator: " ")).lowercased()
            return hay.contains(q) || CommandPaletteRanker.isSubsequence(q, of: hay) ? entry : nil
        }
    }

    static func containsAllRegistryCommands(_ entries: [CheatSheetEntry]) -> Bool {
        Set(entries.map(\.id)) == Set(PanelCommandRegistry.all.map(\.id))
    }
}
