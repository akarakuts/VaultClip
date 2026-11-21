//
// PanelStatusBarModel — footer counter, hints, banners, toast policy (U09).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import CoreGraphics
import Foundation

enum PanelHintContext: Equatable {
    case list
    case multiSelect(count: Int)
    case editor
}

struct PanelStatusBarInput: Equatable {
    var totalCount: Int
    var visibleCount: Int
    var isSearch: Bool
    var selectedCount: Int
    var isLoading: Bool
    var hintContext: PanelHintContext
    var availableWidth: CGFloat
    var showKeyHints: Bool
    var locale: Locale
    /// Active type/app filter label («Текст · Safari»), shown in the counter.
    var filterSummary: String? = nil
}

struct PanelStatusBarModel: Equatable {
    var counterText: String
    var hints: [String]
}

enum PanelStatusBarPresenter {
    static let footerHeight: CGFloat = 24
    static let toastNormalSeconds: TimeInterval = 4
    static let toastUndoSeconds: TimeInterval = 8

    static func present(_ input: PanelStatusBarInput) -> PanelStatusBarModel {
        PanelStatusBarModel(
            counterText: counter(for: input),
            hints: hints(for: input)
        )
    }

    static func counter(for input: PanelStatusBarInput) -> String {
        _ = input.locale
        let base: String
        if input.isLoading {
            base = L10n.statusLoading
        } else if input.selectedCount > 1 {
            base = L10n.statusSelected(input.selectedCount)
        } else if input.isSearch {
            base = L10n.statusFoundOf(visible: input.visibleCount, total: input.totalCount)
        } else {
            base = L10n.countItems(input.totalCount)
        }
        if let filter = input.filterSummary, !filter.isEmpty {
            return base + " · " + filter
        }
        return base
    }

    static func hints(for input: PanelStatusBarInput) -> [String] {
        guard input.showKeyHints else { return [] }
        _ = input.locale
        var all: [String]
        switch input.hintContext {
        case .list:
            // Click selects; ⏎ / 2× click paste. Clear filters is a footer button, not only text.
            if input.filterSummary != nil {
                all = [L10n.hintPaste, L10n.hintDoubleClickPaste, L10n.hintKeys]
            } else {
                all = [L10n.hintPaste, L10n.hintDoubleClickPaste, L10n.hintKeys]
            }
        case .multiSelect(let count):
            // Paste uses list order + separator from Settings → Paste.
            all = [L10n.hintPasteCount(count), L10n.hintMultiPasteOrder, L10n.hintClearSelection]
        case .editor:
            all = [L10n.hintPasteEdit, L10n.hintSaveEdit, L10n.hintCancel]
        }
        // Drop from the end when width is tight (~90pt per hint) so “⏎ Paste” stays.
        let maxHints = max(0, Int(input.availableWidth / 90))
        return Array(all.prefix(min(3, maxHints)))
    }
}
