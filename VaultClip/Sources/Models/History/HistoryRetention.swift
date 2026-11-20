//
// HistoryRetention — delete unpinned items older than Settings.retentionDays (T34).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum HistoryRetention {
    /// Returns ids that should be removed for the given policy.
    static func expiredIds(
        in items: [HistoryItem],
        retentionDays: Int,
        now: Date = Date()
    ) -> [UUID] {
        guard retentionDays > 0 else { return [] }
        let cutoff = now.addingTimeInterval(-TimeInterval(retentionDays) * 86_400)
        return items
            .filter { !$0.isPinnedFromPruning && $0.lastUsedAt < cutoff }
            .map(\.fsId)
    }
}
