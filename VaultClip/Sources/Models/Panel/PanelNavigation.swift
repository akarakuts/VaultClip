//
// PanelNavigation — quick-paste index, page size, open-panel policy (U20).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum PanelNavigation {
    /// ⌘1…⌘9 → visible items 1–9; ⌘0 → 10th. Returns nil if out of range.
    static func displayedIndex(forQuickPasteKey key: Int, visibleItemCount: Int) -> Int? {
        let index: Int
        if key == 0 {
            index = 9
        } else if (1...9).contains(key) {
            index = key - 1
        } else {
            return nil
        }
        guard index >= 0, index < visibleItemCount else { return nil }
        return index
    }

    /// Shortcut digit shown on row `itemOrdinal` (1-based among items, skipping headers).
    static func shortcutDigit(forItemOrdinal ordinal: Int) -> Int? {
        if (1...9).contains(ordinal) { return ordinal }
        if ordinal == 10 { return 0 }
        return nil
    }

    static func pageSize(visibleRowHeight: CGFloat, viewportHeight: CGFloat) -> Int {
        guard visibleRowHeight > 0 else { return 1 }
        return max(1, Int(floor(viewportHeight / visibleRowHeight)))
    }

    static func indexAfterPage(
        current: Int,
        direction: Int,
        pageSize: Int,
        count: Int
    ) -> Int {
        guard count > 0 else { return 0 }
        let next = current + direction * pageSize
        return min(max(0, next), count - 1)
    }

    /// Auto-scroll leaves one row of margin when possible.
    static func scrollTargetRow(
        selected: Int,
        firstVisible: Int,
        lastVisible: Int,
        count: Int
    ) -> Int? {
        guard count > 0 else { return nil }
        if selected <= firstVisible {
            return max(0, selected - 1)
        }
        if selected >= lastVisible {
            return min(count - 1, selected + 1)
        }
        return nil
    }
}

struct PanelOpenPolicy: Equatable {
    var resetSearchAndFiltersOnClose: Bool = true
    var reopenLastTab: Bool = false
    var selectSecondItem: Bool = false

    func initialTab(lastTab: HistoryListMode) -> HistoryListMode {
        reopenLastTab ? lastTab : .history
    }

    func initialSelectedIndex(itemCount: Int) -> Int? {
        guard itemCount > 0 else { return nil }
        if selectSecondItem, itemCount > 1 { return 1 }
        return 0
    }
}
