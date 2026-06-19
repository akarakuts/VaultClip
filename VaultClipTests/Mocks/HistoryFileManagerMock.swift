//
//  HistoryFileManagerMock.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class HistoryFileManagerMock: HistoryFileManager {
    
    var dataCallCount = 0
    var data = [UUID: [NSPasteboard.PasteboardType: Data]]()
    var savedHistoryOrders = [[UUID]]()
    var insertedItems = [UUID]()
    var deletedItems = [UUID]()
    var didClearHistory = false
    var favoriteUpdates = [(id: UUID, isFavorite: Bool)]()
    var passwordUpdates = [(id: UUID, isPassword: Bool, comment: String, login: String, url: String)]()
    var passwordMetadataUpdates = [(id: UUID, comment: String, login: String, url: String)]()
    
    override func loadData(forItemWithId id: UUID, andType type: NSPasteboard.PasteboardType) -> Data? {
        dataCallCount += 1
        if let d = data[id]?[type] {
            return d
        }
        return nil
    }

    override func saveHistoryOrder(history: [HistoryItem], completionHandler: ((Bool) -> Void)? = nil) {
        savedHistoryOrders.append(history.map(\.fsId))
        completionHandler?(true)
    }

    override func insertItem(_ item: HistoryItem, historyOrder: [HistoryItem], completionHandler handler: ((Bool) -> Void)? = nil) {
        insertedItems.append(item.fsId)
        savedHistoryOrders.append(historyOrder.map(\.fsId))
        item.startCaching()
        handler?(true)
    }

    override func deleteItems(_ deletedItems: [HistoryItem], historyOrder: [HistoryItem], completionHandler handler: ((Bool) -> Void)? = nil) {
        self.deletedItems.append(contentsOf: deletedItems.map(\.fsId))
        savedHistoryOrders.append(historyOrder.map(\.fsId))
        deletedItems.forEach { $0.stopCaching() }
        handler?(true)
    }

    override func moveItem(newHistory: [HistoryItem], from: Int, to: Int, completionHandler: ((Bool) -> Void)? = nil) {
        savedHistoryOrders.append(newHistory.map(\.fsId))
        completionHandler?(true)
    }

    override func clearHistory(completionHandler handler: ((Bool) -> Void)? = nil) {
        didClearHistory = true
        handler?(true)
    }

    override func setFavorite(_ isFavorite: Bool, for item: HistoryItem, completionHandler handler: ((Bool) -> Void)? = nil) {
        favoriteUpdates.append((item.fsId, isFavorite))
        handler?(true)
    }

    override func setPassword(
        _ isPassword: Bool,
        comment: String,
        login: String,
        url: String,
        for item: HistoryItem,
        completionHandler handler: ((Bool) -> Void)? = nil
    ) {
        passwordUpdates.append((item.fsId, isPassword, comment, login, url))
        handler?(true)
    }

    override func setPasswordMetadata(
        comment: String,
        login: String,
        url: String,
        for item: HistoryItem,
        completionHandler handler: ((Bool) -> Void)? = nil
    ) {
        passwordMetadataUpdates.append((item.fsId, comment, login, url))
        handler?(true)
    }
}
