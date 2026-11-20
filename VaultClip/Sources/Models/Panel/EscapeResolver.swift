//
// EscapeResolver — ordered Esc stack for the history panel (U04).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum EscapeLayer: Int, CaseIterable, Comparable {
    case overlay // palette, cheat sheet, popover
    case editorDirtyConfirm
    case editor
    case revealedPassword
    case multiSelect
    case searchText
    case filters
    case panel

    static func < (lhs: EscapeLayer, rhs: EscapeLayer) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum EscapeAction: Equatable {
    case dismissOverlay
    case warnEditorDiscard
    case leaveEditor
    case hidePassword
    case collapseMultiSelect
    case clearSearch
    case clearFilters
    case closePanel
}

struct EscapeStackState: Equatable {
    var overlayVisible: Bool = false
    var editorActive: Bool = false
    var editorHasChanges: Bool = false
    var editorDiscardArmed: Bool = false
    var passwordRevealed: Bool = false
    var multiSelectActive: Bool = false
    var searchIsEmpty: Bool = true
    var filtersActive: Bool = false
}

enum EscapeResolver {
    /// Topmost active layer → action for a single Esc press.
    static func resolve(_ state: EscapeStackState) -> EscapeAction {
        if state.overlayVisible { return .dismissOverlay }
        if state.editorActive {
            if state.editorHasChanges, !state.editorDiscardArmed {
                return .warnEditorDiscard
            }
            return .leaveEditor
        }
        if state.passwordRevealed { return .hidePassword }
        if state.multiSelectActive { return .collapseMultiSelect }
        if !state.searchIsEmpty { return .clearSearch }
        if state.filtersActive { return .clearFilters }
        return .closePanel
    }

    static func activeLayers(_ state: EscapeStackState) -> [EscapeLayer] {
        var layers: [EscapeLayer] = []
        if state.overlayVisible { layers.append(.overlay) }
        if state.editorActive {
            if state.editorHasChanges, !state.editorDiscardArmed {
                layers.append(.editorDirtyConfirm)
            }
            layers.append(.editor)
        }
        if state.passwordRevealed { layers.append(.revealedPassword) }
        if state.multiSelectActive { layers.append(.multiSelect) }
        if !state.searchIsEmpty { layers.append(.searchText) }
        if state.filtersActive { layers.append(.filters) }
        layers.append(.panel)
        return layers
    }
}
