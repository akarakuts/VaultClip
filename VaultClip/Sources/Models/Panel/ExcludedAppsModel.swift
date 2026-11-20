//
// ExcludedAppsModel — excluded bundle ids without duplicates/self (U32).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum ExcludedAppsModel {
    static func add(_ bundleId: String, to existing: [String], selfBundleId: String) -> [String] {
        let trimmed = bundleId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != selfBundleId else { return existing }
        if existing.contains(trimmed) { return existing }
        return existing + [trimmed]
    }

    static func remove(_ bundleId: String, from existing: [String]) -> [String] {
        existing.filter { $0 != bundleId }
    }

    static func filterRunning(
        bundleIds: [String],
        alreadyExcluded: [String],
        selfBundleId: String
    ) -> [String] {
        bundleIds.filter { id in
            id != selfBundleId && !alreadyExcluded.contains(id)
        }
    }
}
