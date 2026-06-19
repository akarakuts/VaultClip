//
//  HistoryFavoritesTests.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class HistoryFavoritesTests: XCTestCase {
    
    var cache: HistoryCache!
    
    override func setUp() {
        super.setUp()
        cache = HistoryCache(historyFM: HistoryFileManagerMock(), maxCacheSize: 1_000_000)
    }
    
    func testToggleFavoriteUpdatesItem() {
        let item = HistoryItem(unsavedData: [.string: "pinned".data(using: .utf8)!], cache: cache)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [item], maxItems: 100)
        
        XCTAssertFalse(item.isFavorite)
        XCTAssertTrue(history.toggleFavorite(for: item))
        XCTAssertTrue(item.isFavorite)
        XCTAssertEqual(history.favoriteItems.count, 1)
    }
    
    func testFavoriteItemsPreserveHistoryOrder() {
        let first = HistoryItem(unsavedData: [.string: "a".data(using: .utf8)!], cache: cache, isFavorite: true)
        let second = HistoryItem(unsavedData: [.string: "b".data(using: .utf8)!], cache: cache)
        let third = HistoryItem(unsavedData: [.string: "c".data(using: .utf8)!], cache: cache, isFavorite: true)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [first, second, third], maxItems: 100)
        
        XCTAssertEqual(history.favoriteItems.map(\.fsId), [first.fsId, third.fsId])
    }

    func testInvalidIndexOperationsAreIgnored() {
        let first = HistoryItem(unsavedData: [.string: "a".data(using: .utf8)!], cache: cache)
        let second = HistoryItem(unsavedData: [.string: "b".data(using: .utf8)!], cache: cache)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [first, second], maxItems: 100)

        history.deleteItem(at: 10)
        history.moveItem(at: -1, to: 0)
        history.moveItem(at: 0, to: 2)

        XCTAssertEqual(history.items.map(\.fsId), [first.fsId, second.fsId])
    }
    
    func testClearNonFavoritesOnlyKeepsPinnedItems() {
        let keep = HistoryItem(unsavedData: [.string: "keep".data(using: .utf8)!], cache: cache, isFavorite: true)
        let drop = HistoryItem(unsavedData: [.string: "drop".data(using: .utf8)!], cache: cache)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [keep, drop], maxItems: 100)
        
        history.clear(nonFavoritesOnly: true)
        
        XCTAssertEqual(history.items.count, 1)
        XCTAssertEqual(history.items.first?.fsId, keep.fsId)
    }
    
    func testTogglePasswordUpdatesItem() {
        let item = HistoryItem(unsavedData: [.string: "secret".data(using: .utf8)!], cache: cache)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [item], maxItems: 100)
        
        XCTAssertFalse(item.isPassword)
        history.setPassword(true, for: item, comment: "Work account", login: "user@example.com")
        XCTAssertTrue(item.isPassword)
        XCTAssertEqual(item.passwordComment, "Work account")
        XCTAssertEqual(item.passwordLogin, "user@example.com")
        XCTAssertEqual(history.passwordItems.count, 1)
    }
    
    func testPasswordMetadataClearsWhenRemoved() {
        let item = HistoryItem(
            unsavedData: [.string: "secret".data(using: .utf8)!],
            cache: cache,
            isPassword: true,
            passwordComment: "Note",
            passwordLogin: "alice"
        )
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [item], maxItems: 100)
        
        history.setPassword(false, for: item)
        
        XCTAssertFalse(item.isPassword)
        XCTAssertEqual(item.passwordComment, "")
        XCTAssertEqual(item.passwordLogin, "")
        XCTAssertEqual(item.passwordURL, "")
    }
    
    func testPasswordURLNormalizationOnSave() {
        let item = HistoryItem(unsavedData: [.string: "secret".data(using: .utf8)!], cache: cache)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [item], maxItems: 100)
        
        history.setPassword(true, for: item, comment: "Site", login: "user", url: "example.com/login")
        
        XCTAssertEqual(item.passwordURL, "https://example.com/login")
    }
    
    func testPasswordMetadataUpdateIncludesURL() {
        let item = HistoryItem(
            unsavedData: [.string: "secret".data(using: .utf8)!],
            cache: cache,
            isPassword: true,
            passwordComment: "Old",
            passwordLogin: "old-login",
            passwordURL: "https://old.example"
        )
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [item], maxItems: 100)
        
        history.setPasswordMetadata(comment: "New", login: "new-login", url: "new.example", for: item)
        
        XCTAssertEqual(item.passwordComment, "New")
        XCTAssertEqual(item.passwordLogin, "new-login")
        XCTAssertEqual(item.passwordURL, "https://new.example")
    }
    
    func testNormalizePasswordURLHelper() {
        XCTAssertEqual(HistoryItem.normalizePasswordURL(""), "")
        XCTAssertEqual(HistoryItem.normalizePasswordURL("  "), "")
        XCTAssertEqual(HistoryItem.normalizePasswordURL("https://vaultclip.app"), "https://vaultclip.app")
        XCTAssertEqual(HistoryItem.normalizePasswordURL("vaultclip.app"), "https://vaultclip.app")
    }
    
    func testPasswordMetadataUpdate() {
        let item = HistoryItem(
            unsavedData: [.string: "secret".data(using: .utf8)!],
            cache: cache,
            isPassword: true,
            passwordComment: "Old",
            passwordLogin: "old-login"
        )
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [item], maxItems: 100)
        
        history.setPasswordMetadata(comment: "New", login: "new-login", url: "", for: item)
        
        XCTAssertEqual(item.passwordComment, "New")
        XCTAssertEqual(item.passwordLogin, "new-login")
    }
    
    func testClearNonFavoritesOnlyKeepsPasswordItems() {
        let keep = HistoryItem(unsavedData: [.string: "keep".data(using: .utf8)!], cache: cache, isPassword: true)
        let drop = HistoryItem(unsavedData: [.string: "drop".data(using: .utf8)!], cache: cache)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [keep, drop], maxItems: 100)
        
        history.clear(nonFavoritesOnly: true)
        
        XCTAssertEqual(history.items.count, 1)
        XCTAssertEqual(history.items.first?.fsId, keep.fsId)
    }
    
    func testPrunePreservesPasswordItems() {
        let pinned = HistoryItem(unsavedData: [.string: "pin".data(using: .utf8)!], cache: cache, isPassword: true)
        let extra = HistoryItem(unsavedData: [.string: "x".data(using: .utf8)!], cache: cache)
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [extra, pinned], maxItems: 1)
        
        XCTAssertEqual(history.items.count, 1)
        XCTAssertEqual(history.items.first?.fsId, pinned.fsId)
    }
}
