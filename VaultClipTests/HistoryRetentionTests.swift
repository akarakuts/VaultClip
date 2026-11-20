//
// HistoryRetentionTests — age-based purge keeps pinned items (T34).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class HistoryRetentionTests: XCTestCase {
    private var previousDays: Int!

    override func setUp() {
        super.setUp()
        previousDays = Settings.main.retentionDays
    }

    override func tearDown() {
        SettingsPersistence.apply { $0.retentionDays = previousDays }
        super.tearDown()
    }

    func testPurgeRemovesOldUnpinnedKeepsFavorite() {
        SettingsPersistence.apply { $0.retentionDays = 7 }
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let now = Date()
        let old = HistoryItem(
            unsavedData: [.string: Data("old".utf8)],
            cache: cache,
            copiedAt: now.addingTimeInterval(-10 * 86_400)
        )
        let pinned = HistoryItem(
            unsavedData: [.string: Data("pin".utf8)],
            cache: cache,
            copiedAt: now.addingTimeInterval(-10 * 86_400),
            isFavorite: true
        )
        let fresh = HistoryItem(
            unsavedData: [.string: Data("new".utf8)],
            cache: cache,
            copiedAt: now
        )
        let history = History(
            historyFM: HistoryFileManagerMock(),
            cache: cache,
            items: [fresh, pinned, old],
            maxItems: 100
        )
        history.purgeExpiredItems(now: now)
        XCTAssertEqual(Set(history.items.map(\.fsId)), Set([fresh.fsId, pinned.fsId]))
    }
}
