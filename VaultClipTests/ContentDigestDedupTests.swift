//
// ContentDigestDedupTests — promote-on-duplicate without new rows (T23).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class ContentDigestDedupTests: XCTestCase {
    private var cache: HistoryCache!

    override func setUp() {
        super.setUp()
        cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
    }

    func testRepeatedCopyPromotesExistingItem() {
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 50)
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.digest.promote"))
        pb.clearContents()
        pb.setString("same payload", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")
        XCTAssertEqual(history.items.count, 1)
        let firstId = history.items[0].fsId

        pb.clearContents()
        pb.setString("other", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")
        XCTAssertEqual(history.items.count, 2)

        pb.clearContents()
        pb.setString("same payload", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")

        XCTAssertEqual(history.items.count, 2, "duplicate must not create a third row")
        XCTAssertEqual(history.items[0].fsId, firstId)
        XCTAssertEqual(history.currentClipboardItemId, firstId)
    }

    func testPromoteKeepsFavoriteFlag() {
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 50)
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.digest.favorite"))
        pb.clearContents()
        pb.setString("fav-payload", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")
        let item = history.items[0]
        history.setFavorite(true, for: item)

        pb.clearContents()
        pb.setString("noise", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")

        pb.clearContents()
        pb.setString("fav-payload", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")

        XCTAssertEqual(history.items[0].fsId, item.fsId)
        XCTAssertTrue(history.items[0].isFavorite)
    }

    func testDifferentPayloadCreatesNewItem() {
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 50)
        let pb = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.digest.diff"))
        pb.clearContents()
        pb.setString("alpha", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")
        pb.clearContents()
        pb.setString("beta", forType: .string)
        history.pasteboardDidChange(pb, originBundleId: "com.example.a")
        XCTAssertEqual(history.items.count, 2)
        XCTAssertNotEqual(history.items[0].fsId, history.items[1].fsId)
    }
}
