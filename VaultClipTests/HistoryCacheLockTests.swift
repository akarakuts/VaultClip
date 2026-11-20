//
// HistoryCacheLockTests — miss path does not hold the lock during I/O (T21).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

private final class BlockingLoader: HistoryDataLoading {
    let gate = DispatchSemaphore(value: 0)
    let entered = DispatchSemaphore(value: 0)
    var payloads: [UUID: [NSPasteboard.PasteboardType: Data]] = [:]

    func loadData(forItemWithId id: UUID, andType type: NSPasteboard.PasteboardType) -> Data? {
        entered.signal()
        gate.wait()
        return payloads[id]?[type]
    }
}

final class HistoryCacheLockTests: XCTestCase {

    func testMissDoesNotBlockParallelHit() {
        let loader = BlockingLoader()
        let slowId = UUID()
        let fastId = UUID()
        loader.payloads[slowId] = [.string: Data("slow".utf8)]
        loader.payloads[fastId] = [.string: Data("fast".utf8)]

        let cache = HistoryCache(historyFM: loader, maxCacheSize: 1_000_000)
        cache.registerItem(withId: slowId)
        cache.registerItem(withId: fastId)
        // Prime the fast id so the second call is a hit.
        loader.gate.signal()
        _ = cache.data(withId: fastId, forType: .string)
        // Reset: next slow load will block.
        // (fast is already cached)

        let slowDone = expectation(description: "slow")
        let fastDone = expectation(description: "fast hit during slow load")

        DispatchQueue.global().async {
            _ = cache.data(withId: slowId, forType: .string)
            slowDone.fulfill()
        }
        XCTAssertEqual(loader.entered.wait(timeout: .now() + 1), .success)

        DispatchQueue.global().async {
            let data = cache.data(withId: fastId, forType: .string)
            XCTAssertEqual(data, Data("fast".utf8))
            fastDone.fulfill()
        }
        wait(for: [fastDone], timeout: 1)
        loader.gate.signal()
        wait(for: [slowDone], timeout: 1)
    }

    func testOversizedPayloadReturnsWithoutCaching() {
        let mock = HistoryFileManagerMock()
        let cache = HistoryCache(historyFM: mock, maxCacheSize: 8)
        let id = UUID()
        cache.registerItem(withId: id)
        let big = Data(repeating: 1, count: 32)
        mock.data[id] = [.string: big]
        XCTAssertEqual(cache.data(withId: id, forType: .string), big)
        XCTAssertEqual(cache.currentCacheSize, 0)
    }
}
