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
    private var previousRequiresAuth: Bool!

    override func setUp() {
        super.setUp()
        previousRequiresAuth = Settings.main.requiresPasswordAuthentication
        SettingsPersistence.apply { $0.requiresPasswordAuthentication = false }
        pasteboard = NSPasteboard(name: NSPasteboard.Name("VaultClipTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        cache = HistoryCache()
        history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [])
        HistoryPanel.lastSelfWriteChangeCount = nil
    }

    override func tearDown() {
        SettingsPersistence.apply { $0.requiresPasswordAuthentication = previousRequiresAuth }
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

    func testDeleteFavoriteRowDoesNotClearUnrelatedClipboard() {
        let favorite = HistoryItem(unsavedData: [.string: Data("fav".utf8)], cache: cache, isFavorite: true)
        let other = HistoryItem(unsavedData: [.string: Data("other".utf8)], cache: cache)
        history.insertItem(other, at: 0)
        history.insertItem(favorite, at: 0)
        history.noteClipboardItemId(other.fsId)
        history.recordPasteboardChange(withCount: pasteboard.changeCount)
        pasteboard.setString("other", forType: .string)
        history.recordPasteboardChange(withCount: pasteboard.changeCount)
        history.noteClipboardItemId(other.fsId)

        let panel = HistoryPanel(history: history, items: [favorite], pasteboard: pasteboard)
        _ = panel.delete(item: favorite)

        XCTAssertEqual(pasteboard.string(forType: .string), "other")
        XCTAssertEqual(history.currentClipboardItemId, other.fsId)
    }

    func testDeleteCurrentClipboardItemClearsPasteboard() {
        let item = HistoryItem(unsavedData: [.string: Data("top".utf8)], cache: cache)
        history.insertItem(item, at: 0)
        pasteboard.setString("top", forType: .string)
        history.noteClipboardItemId(item.fsId)
        history.recordPasteboardChange(withCount: pasteboard.changeCount)

        let panel = HistoryPanel(history: history, items: [item], pasteboard: pasteboard)
        _ = panel.delete(item: item)

        XCTAssertNil(pasteboard.string(forType: .string))
        XCTAssertNil(history.currentClipboardItemId)
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
