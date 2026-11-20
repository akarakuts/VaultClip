//
// HistoryItemConcurrencyTests — stress concurrent data(forType:) vs start/stopCaching.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class HistoryItemConcurrencyTests: XCTestCase {

    func testConcurrentDataAccessAndCachingDoesNotCrash() {
        let cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
        let payload = Data("concurrent-payload".utf8)
        let item = HistoryItem(unsavedData: [.string: payload], cache: cache)

        let group = DispatchGroup()
        let iterations = 200
        for _ in 0..<iterations {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                _ = item.data(forType: .string)
                group.leave()
            }
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                item.startCaching()
                item.stopCaching(unsavedData: [.string: payload])
                group.leave()
            }
        }
        XCTAssertEqual(group.wait(timeout: .now() + 5), .success)
        XCTAssertEqual(item.data(forType: .string), payload)
    }
}
