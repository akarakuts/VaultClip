//
// MaxItemSizeTests — oversize pasteboard payloads are skipped (T26).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class MaxItemSizeTests: XCTestCase {
    private var cache: HistoryCache!
    private var previousMax: Int!

    override func setUp() {
        super.setUp()
        cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 2_000_000)
        previousMax = Settings.main.maxItemSizeMB
    }

    override func tearDown() {
        SettingsPersistence.apply { $0.maxItemSizeMB = previousMax }
        super.tearDown()
    }

    func testOversizeItemIsSkipped() {
        SettingsPersistence.apply { $0.maxItemSizeMB = 1 }

        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 50)
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.maxsize.skip"))
        pb.clearContents()
        let big = Data(repeating: 0x41, count: 1_100_000)
        pb.setData(big, forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")

        XCTAssertTrue(history.items.isEmpty)
        XCTAssertNil(history.currentClipboardItemId)
    }

    func testUnlimitedAllowsLargeItem() {
        SettingsPersistence.apply { $0.maxItemSizeMB = 0 }

        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 50)
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.maxsize.unlimited"))
        pb.clearContents()
        let big = Data(repeating: 0x42, count: 1_100_000)
        pb.setData(big, forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")

        XCTAssertEqual(history.items.count, 1)
    }
}
