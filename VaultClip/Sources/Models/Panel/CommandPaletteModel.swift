//
// CommandPaletteModel — fuzzy ranking and sections for ⌘K (U25).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum CommandPaletteSection: String, Equatable {
    case forSelection
    case view
    case filters
    case app
}

struct CommandPaletteRow: Equatable, Identifiable {
    var id: PanelCommandID
    var title: String
    var symbolName: String
    var shortcut: String?
    var availability: PanelCommandAvailability
    var section: CommandPaletteSection
    var score: Int
}

enum CommandPaletteRanker {
    /// Higher is better: prefix > word-start > subsequence.
    static func score(query: String, title: String, keywords: [String]) -> Int? {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return 0 }
        let candidates = ([title] + keywords).map { $0.lowercased() }
        var best: Int?
        for text in candidates {
            if text.hasPrefix(q) {
                best = max(best ?? 0, 300 - text.count)
            } else if text.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).contains(where: { $0.hasPrefix(q) }) {
                best = max(best ?? 0, 200 - text.count)
            } else if isSubsequence(q, of: text) {
                best = max(best ?? 0, 100 - text.count)
            }
        }
        return best
    }

    static func isSubsequence(_ query: String, of text: String) -> Bool {
        var ti = text.startIndex
        for ch in query {
            guard let found = text[ti...].firstIndex(of: ch) else { return false }
            ti = text.index(after: found)
        }
        return true
    }
}

enum CommandPaletteBuilder {
    static func section(for group: PanelCommandGroup) -> CommandPaletteSection {
        switch group {
        case .item: return .forSelection
        case .view: return .view
        case .filter: return .filters
        case .app, .window: return .app
        }
    }

    static func rows(
        context: PanelCommandContext,
        query: String,
        recent: [PanelCommandID] = []
    ) -> [CommandPaletteRow] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var rows: [CommandPaletteRow] = []
        for command in PanelCommandRegistry.all where command.showsInPalette {
            let availability = command.availability(context)
            if case .hidden = availability { continue }
            let score: Int
            if q.isEmpty {
                if let idx = recent.firstIndex(of: command.id) {
                    score = 1000 - idx
                } else {
                    score = 0
                }
            } else if let s = CommandPaletteRanker.score(query: q, title: command.title, keywords: command.keywords) {
                score = s
            } else {
                continue
            }
            rows.append(CommandPaletteRow(
                id: command.id,
                title: command.title,
                symbolName: command.symbolName,
                shortcut: command.bindings.first.map { $0.chord.displayString },
                availability: availability,
                section: section(for: command.group),
                score: score
            ))
        }
        return rows.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }
}
