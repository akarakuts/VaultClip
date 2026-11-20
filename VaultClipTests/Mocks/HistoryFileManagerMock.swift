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

    /// Concurrent HistoryItem reads under TSan hit this counter; protect it (test-only).
    private let dataCallCountLock = NSLock()
    private var _dataCallCount = 0
    var dataCallCount: Int {
        get {
            dataCallCountLock.lock()
            defer { dataCallCountLock.unlock() }
            return _dataCallCount
        }
        set {
            dataCallCountLock.lock()
            defer { dataCallCountLock.unlock() }
            _dataCallCount = newValue
        }
    }
    var data = [UUID: [NSPasteboard.PasteboardType: Data]]()
    var savedHistoryOrders = [[UUID]]()
    var capturedOrders = [[UUID]]()
    var insertedItems = [UUID]()
    var deletedItems = [UUID]()
    var didClearHistory = false
    var favoriteUpdates = [(id: UUID, isFavorite: Bool)]()
    var passwordUpdates = [(id: UUID, isPassword: Bool, comment: String, login: String, url: String)]()
    var passwordMetadataUpdates = [(id: UUID, comment: String, login: String, url: String)]()
    var contentDigestUpdates = [(id: UUID, digest: String)]()

    override func loadData(forItemWithId id: UUID, andType type: NSPasteboard.PasteboardType) -> Data? {
        dataCallCountLock.lock()
        _dataCallCount += 1
        dataCallCountLock.unlock()
        if let d = data[id]?[type] {
            return d
        }
        return nil
    }

    override func captureHistoryOrder(_ history: [HistoryItem]) {
        capturedOrders.append(history.map(\.fsId))
    }

    // Deterministic: skip the coalescing timer, record straight into the order log.
    override func scheduleHistoryOrderWrite(history: [HistoryItem], immediate: Bool, completionHandler handler: ((Bool) -> Void)?) {
        saveHistoryOrder(history: history, completionHandler: handler)
    }

    override func saveHistoryOrder(history: [HistoryItem], completionHandler: ((Bool) -> Void)? = nil) {
        savedHistoryOrders.append(history.map(\.fsId))
        completionHandler?(true)
    }

    override func insertItem(_ item: HistoryItem, historyOrder: [HistoryItem], completionHandler handler: ((Bool) -> Void)? = nil) {
        insertedItems.append(item.fsId)
        savedHistoryOrders.append(historyOrder.map(\.fsId))
        // Mirror production: startCaching happens on main after disk write.
        DispatchQueue.main.async {
            item.startCaching()
        }
        handler?(true)
    }

    override func deleteItems(_ deletedItems: [HistoryItem], historyOrder: [HistoryItem], completionHandler handler: ((Bool) -> Void)? = nil) {
        self.deletedItems.append(contentsOf: deletedItems.map(\.fsId))
        savedHistoryOrders.append(historyOrder.map(\.fsId))
        // stopCaching is owned by History on the main queue (T13).
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

    override func saveContentDigest(_ digest: String, for item: HistoryItem, completionHandler: ((Bool) -> Void)? = nil) {
        contentDigestUpdates.append((item.fsId, digest))
        completionHandler?(true)
    }
}
