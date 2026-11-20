//
// CellHeightsCache — per-(cell, item, signature) heights keyed under layout context (T24).
//
// Copyright (C) 2019 Matthew Davidson
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

class CellHeightsCache {

    struct LayoutContext: Equatable {
        var cellWidth: CGFloat
        var isRichText: Bool
    }

    private struct EntryKey: Hashable {
        let cellIdentifier: String
        let itemId: UUID
        let displaySignature: String
    }

    private var layoutContext: LayoutContext?
    private var heights: [EntryKey: CGFloat] = [:]

    func cellHeight(
        forId id: UUID,
        withCellIdentifier cellIdentifier: String,
        cellWidth: CGFloat,
        isRichText: Bool,
        displaySignature: String
    ) -> CGFloat? {
        let layout = LayoutContext(cellWidth: cellWidth, isRichText: isRichText)
        guard layout == layoutContext else { return nil }
        return heights[EntryKey(cellIdentifier: cellIdentifier, itemId: id, displaySignature: displaySignature)]
    }

    func storeCellHeight(
        _ height: CGFloat,
        forId id: UUID,
        withCellIdentifier cellIdentifier: String,
        layout: LayoutContext,
        displaySignature: String
    ) {
        if layoutContext != layout {
            layoutContext = layout
            heights.removeAll()
        }
        heights[EntryKey(cellIdentifier: cellIdentifier, itemId: id, displaySignature: displaySignature)] = height
    }

    func removeCellHeight(forId id: UUID) {
        heights = heights.filter { $0.key.itemId != id }
    }

    func clearCache() {
        heights.removeAll()
        layoutContext = nil
    }
}
