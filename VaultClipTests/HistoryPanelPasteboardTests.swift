//
// HistoryPanelPasteboardTests — concealed password clipboard writes.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class HistoryPanelPasteboardTests: XCTestCase {

    private var pasteboard: NSPasteboard!
    private var cache: HistoryCache!
    private var history: History!

    override func setUp() {
        super.setUp()
        pasteboard = NSPasteboard(name: NSPasteboard.Name("VaultClipTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        cache = HistoryCache()
        history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [])
        HistoryPanel.lastSelfWriteChangeCount = nil
    }

    override func tearDown() {
        pasteboard.releaseGlobally()
        pasteboard = nil
        HistoryPanel.lastSelfWriteChangeCount = nil
        super.tearDown()
    }

    func testCopyPasswordWritesConcealedMarker() {
        // Keep unsaved payload in RAM — passwords are never registered in HistoryCache.
        let item = makePasswordItem(value: "s3cret")
        let panel = HistoryPanel(history: history, items: [item], pasteboard: pasteboard)

        panel.copyPassword(item: item)

        XCTAssertEqual(pasteboard.string(forType: .string), "s3cret")
        XCTAssertNotNil(pasteboard.data(forType: PasteboardWriter.concealedType))
        let types = Set(pasteboard.types ?? [])
        XCTAssertTrue(HistoryPasteboardPolicy.usableTypes(from: types).isEmpty)
    }

    func testCopyLoginDoesNotConceal() {
        let item = makePasswordItem(value: "s3cret", login: "alice")
        let panel = HistoryPanel(history: history, items: [item], pasteboard: pasteboard)

        panel.copyLogin(item: item)

        XCTAssertEqual(pasteboard.string(forType: .string), "alice")
        XCTAssertNil(pasteboard.data(forType: PasteboardWriter.concealedType))
    }

    func testPasswordItemWriteOmitsHistoryIdType() {
        let item = makePasswordItem(value: "s3cret")
        _ = item.write(to: pasteboard)

        XCTAssertEqual(pasteboard.string(forType: .string), "s3cret")
        XCTAssertNotNil(pasteboard.data(forType: PasteboardWriter.concealedType))
        XCTAssertNil(pasteboard.string(forType: HistoryItem.historyItemIdType))
    }

    private func makePasswordItem(value: String, login: String = "") -> HistoryItem {
        let item = HistoryItem(
            unsavedData: [.string: Data(value.utf8)],
            cache: cache,
            isPassword: true,
            passwordLogin: login
        )
        return item
    }
}
