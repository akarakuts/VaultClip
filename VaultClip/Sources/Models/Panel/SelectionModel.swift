//
// SelectionModel — ordered multi-select with anchor (U16).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

struct SelectionModel: Equatable {
    /// Selection order (list order for paste, not click order).
    private(set) var orderedIds: [UUID] = []
    private(set) var anchorId: UUID?

    var count: Int { orderedIds.count }
    var ids: Set<UUID> { Set(orderedIds) }
    var isMulti: Bool { orderedIds.count > 1 }

    mutating func selectSingle(_ id: UUID) {
        orderedIds = [id]
        anchorId = id
    }

    mutating func clear() {
        orderedIds = []
        anchorId = nil
    }

    /// ⌘-click toggle.
    mutating func toggle(_ id: UUID, visibleOrder: [UUID]) {
        if let index = orderedIds.firstIndex(of: id) {
            orderedIds.remove(at: index)
            if anchorId == id {
                anchorId = orderedIds.last
            }
        } else {
            orderedIds.append(id)
            orderedIds = Self.sorted(orderedIds, by: visibleOrder)
            anchorId = id
        }
    }

    /// ⇧-click / ⇧↑↓ range from anchor through target.
    mutating func selectRange(to id: UUID, visibleOrder: [UUID]) {
        guard let anchorId, let start = visibleOrder.firstIndex(of: anchorId),
              let end = visibleOrder.firstIndex(of: id) else {
            selectSingle(id)
            return
        }
        let lo = min(start, end)
        let hi = max(start, end)
        orderedIds = Array(visibleOrder[lo...hi])
    }

    mutating func selectAll(visibleOrder: [UUID]) {
        orderedIds = visibleOrder
        anchorId = visibleOrder.first
    }

    /// Keep only ids still present after filter change.
    mutating func retainVisible(_ visible: Set<UUID>, visibleOrder: [UUID]) {
        orderedIds = orderedIds.filter { visible.contains($0) }
        orderedIds = Self.sorted(orderedIds, by: visibleOrder)
        if let anchorId, !visible.contains(anchorId) {
            self.anchorId = orderedIds.first
        }
    }

    private static func sorted(_ ids: [UUID], by order: [UUID]) -> [UUID] {
        let rank = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
        return ids.sorted { (rank[$0] ?? .max) < (rank[$1] ?? .max) }
    }
}
