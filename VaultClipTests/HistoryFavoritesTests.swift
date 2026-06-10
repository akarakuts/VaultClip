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
        history.setPassword(true, for: item, comment: "Work account")
        XCTAssertTrue(item.isPassword)
        XCTAssertEqual(item.passwordComment, "Work account")
        XCTAssertEqual(history.passwordItems.count, 1)
    }
    
    func testPasswordCommentClearsWhenRemoved() {
        let item = HistoryItem(
            unsavedData: [.string: "secret".data(using: .utf8)!],
            cache: cache,
            isPassword: true,
            passwordComment: "Note"
        )
        let history = History(historyFM: HistoryFileManagerMock(), cache: cache, items: [item], maxItems: 100)
        
        history.setPassword(false, for: item)
        
        XCTAssertFalse(item.isPassword)
        XCTAssertEqual(item.passwordComment, "")
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
