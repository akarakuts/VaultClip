//
// PanelKeyRouter — pure (zone, chord, context) → command / passThrough / type-to-search (U04).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum PanelKeyRoute: Equatable {
    case command(PanelCommandID)
    case passThrough
    case typeToSearch(String)
}

struct PanelKeyRouterContext: Equatable {
    var searchIsEmpty: Bool = true
    var searchFieldOwnsEditingShortcuts: Bool = false
    var hasTextSelectionInField: Bool = false
    var canUndoDelete: Bool = false
}

enum PanelKeyRouter {

    static func route(
        zone: FocusZone,
        chord: KeyChord,
        typed: String? = nil,
        context: PanelKeyRouterContext = PanelKeyRouterContext()
    ) -> PanelKeyRoute {
        // Search field keeps macOS editing chords when it has content.
        if zone == .search, context.searchFieldOwnsEditingShortcuts || !context.searchIsEmpty {
            if isSearchFieldEditingChord(chord) {
                return .passThrough
            }
        }

        // ⌘A: list always; search only when empty.
        if chord == .cmd("a") {
            if zone == .list { return .command(.selectAll) }
            if zone == .search {
                return context.searchIsEmpty ? .command(.selectAll) : .passThrough
            }
        }

        // ⌘⌫: delete when search empty / not in search; otherwise edit field.
        if chord == KeyChord(key: .delete, modifiers: .command) {
            if zone == .search, !context.searchIsEmpty {
                return .passThrough
            }
        }

        // Space in search goes to the field; list toggles preview via registry.
        if chord == KeyChord(key: .space, modifiers: []), zone == .search {
            return .passThrough
        }

        // Type-to-search from the list: printable character, no ⌘/⌃.
        if zone == .list,
           chord.modifiers.isDisjoint(with: [.command, .control]),
           let typed, !typed.isEmpty,
           typed.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.union(.punctuationCharacters).union(.symbols).contains($0) || $0 == " " }) {
            // Bare space is preview toggle, not type-to-search.
            if typed == " ", chord.modifiers.isEmpty {
                // fall through to registry
            } else if chord.modifiers.isEmpty || chord.modifiers == [.shift] {
                if case .letter = chord.key { return .typeToSearch(typed) }
                if case .digit = chord.key { return .typeToSearch(typed) }
                // Other printable via typed string without a registry hit:
                if PanelCommandRegistry.resolve(chord: chord, in: zone) == nil {
                    return .typeToSearch(typed)
                }
            }
        }

        if let id = PanelCommandRegistry.resolve(chord: chord, in: zone) {
            return .command(id)
        }

        // Unmodified printable in list with no registry match → type-to-search.
        if zone == .list,
           chord.modifiers.isEmpty || chord.modifiers == [.shift],
           let typed, !typed.isEmpty, typed != "\r", typed != "\u{1b}" {
            return .typeToSearch(typed)
        }

        return .passThrough
    }

    private static func isSearchFieldEditingChord(_ chord: KeyChord) -> Bool {
        switch chord.key {
        case .leftArrow, .rightArrow:
            return chord.modifiers.isEmpty || chord.modifiers == [.shift] || chord.modifiers == [.option]
                || chord.modifiers == [.command] || chord.modifiers == [.command, .shift]
        case .delete, .forwardDelete:
            return chord.modifiers.isEmpty || chord.modifiers == [.option]
        case .letter("a"), .letter("c"), .letter("v"), .letter("x"), .letter("z"):
            return chord.modifiers == .command || chord.modifiers == [.command, .shift]
        default:
            return false
        }
    }
}
