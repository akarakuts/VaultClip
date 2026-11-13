//
//  HistoryAsyncLoadTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

/// Covers the async-load swap-in (P6), the self-write pasteboard skip (P8.3),
/// the password cache invariant (P2) and color decoding (P8.2).
final class HistoryAsyncLoadTests: XCTestCase {

    private var cache: HistoryCache!

    override func setUp() {
        super.setUp()
        cache = HistoryCache()
    }

    override func tearDown() {
        HistoryPanel.lastSelfWriteChangeCount = nil
        super.tearDown()
    }

    // MARK: - replaceLoaded()

    func testReplaceLoadedSwapsItemsNotifiesOnceAndCapturesOrder() {
        let historyFM = HistoryFileManagerMock()
        let history = History(historyFM: historyFM, cache: cache, items: [], maxItems: 100)
        let placeholder = HistoryItem(unsavedData: [.string: Data("x".utf8)], cache: cache)
        history.insertItem(placeholder, at: 0)

        let first = HistoryItem(fsId: UUID(), types: [.string], cache: cache)
        let second = HistoryItem(fsId: UUID(), types: [.string], cache: cache)
        var initialNotifications = 0
        let cancel = history.subscribe { _, change in
            if case .initial = change { initialNotifications += 1 }
        }
        let notificationsBeforeSwap = initialNotifications

        history.replaceLoaded(with: [first, second])

        XCTAssertEqual(history.items.map(\.fsId), [first.fsId, second.fsId])
        XCTAssertEqual(initialNotifications, notificationsBeforeSwap + 1, "one .initial notify for the swap")
        XCTAssertFalse(cache.isItemRegistered(placeholder.fsId), "stale item must leave the RAM cache")
        XCTAssertEqual(historyFM.capturedOrders.last, [first.fsId, second.fsId])
        cancel()
    }

    func testReplaceLoadedPrunesExcessItems() {
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 2)
        let items = (0..<4).map { _ in HistoryItem(fsId: UUID(), types: [.string], cache: cache) }

        history.replaceLoaded(with: items)

        XCTAssertEqual(history.items.count, 2)
        XCTAssertEqual(history.items.map(\.fsId), [items[0].fsId, items[1].fsId])
    }

    // MARK: - Self-write skip (P8.3)

    func testSelfWriteChangeCountSkippedEvenFromDenylistedSource() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.selfwrite"))
        pasteboard.clearContents()
        pasteboard.setString("pasted from the panel", forType: .string)
        let count = pasteboard.changeCount

        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [], maxItems: 10)
        history.recordPasteboardChange(withCount: count - 1)
        HistoryPanel.lastSelfWriteChangeCount = count

        history.pasteboardDidChange(pasteboard, originBundleId: "com.agilebits.onepassword7")

        XCTAssertTrue(history.items.isEmpty, "own paste must not be re-recorded as a copy")
        XCTAssertEqual(history.lastRecordedChangeCount, count, "but the change count still advances")
    }

    // MARK: - Password cache invariant (P2)

    func testPasswordItemsStayOutOfMemoryCache() {
        let passwordItem = HistoryItem(fsId: UUID(), types: [.string], cache: cache, isPassword: true)
        XCTAssertFalse(cache.isItemRegistered(passwordItem.fsId))
        passwordItem.startCaching()
        XCTAssertFalse(cache.isItemRegistered(passwordItem.fsId), "startCaching must respect the password flag")

        let plainItem = HistoryItem(fsId: UUID(), types: [.string], cache: cache)
        XCTAssertTrue(cache.isItemRegistered(plainItem.fsId))
    }

    // MARK: - Color decoding (P8.2)

    func testGetColorDecodesKeyedArchiverPayload() throws {
        let color = NSColor(srgbRed: 0.25, green: 0.5, blue: 0.75, alpha: 1)
        let archived = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true)
        let item = HistoryItem(unsavedData: [NSPasteboard.PasteboardType.color: archived], cache: cache)

        let decoded = try XCTUnwrap(item.getColor())
        XCTAssertEqual(decoded.usingColorSpace(.sRGB), color)
    }

    func testGetColorFallsBackToPasteboardForLegacyPayload() throws {
        let writer = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.legacyColor"))
        writer.clearContents()
        XCTAssertTrue(writer.writeObjects([NSColor.systemTeal]))
        let legacyData = try XCTUnwrap(writer.data(forType: .color))

        let item = HistoryItem(unsavedData: [NSPasteboard.PasteboardType.color: legacyData], cache: cache)

        XCTAssertNotNil(item.getColor())
    }
}
