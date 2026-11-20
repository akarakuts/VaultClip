//
// HistoryFileManaging — persistence contract for History (testable boundary).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

protocol HistoryFileManaging: AnyObject {
    func loadHistory(cache: HistoryCache) -> [HistoryItem]
    func loadHistoryAsync(cache: HistoryCache, completion: @escaping ([HistoryItem]) -> Void)
    func captureHistoryOrder(_ history: [HistoryItem])
    func scheduleHistoryOrderWrite(history: [HistoryItem], immediate: Bool, completionHandler: ((Bool) -> Void)?)
    func saveHistoryOrder(history: [HistoryItem], completionHandler: ((Bool) -> Void)?)
    func insertItem(_ item: HistoryItem, historyOrder: [HistoryItem], completionHandler: ((Bool) -> Void)?)
    func deleteItem(newHistory: [HistoryItem], deleted: HistoryItem, completionHandler: ((Bool) -> Void)?)
    func deleteItems(_ deletedItems: [HistoryItem], historyOrder: [HistoryItem], completionHandler: ((Bool) -> Void)?)
    func reduce(oldHistory: [HistoryItem], toSize size: Int, completionHandler: ((Bool) -> Void)?)
    func moveItem(newHistory: [HistoryItem], from: Int, to: Int, completionHandler: ((Bool) -> Void)?)
    func clearHistory(completionHandler: ((Bool) -> Void)?)
    func setFavorite(_ isFavorite: Bool, for item: HistoryItem, completionHandler: ((Bool) -> Void)?)
    func setPassword(
        _ isPassword: Bool,
        comment: String,
        login: String,
        url: String,
        for item: HistoryItem,
        completionHandler: ((Bool) -> Void)?
    )
    func setPasswordMetadata(
        comment: String,
        login: String,
        url: String,
        for item: HistoryItem,
        completionHandler: ((Bool) -> Void)?
    )
    func saveContentDigest(_ digest: String, for item: HistoryItem, completionHandler: ((Bool) -> Void)?)
}

extension HistoryFileManaging {

    /// Non-blocking managers only need the synchronous loader; wrap it for the async API.
    func loadHistoryAsync(cache: HistoryCache, completion: @escaping ([HistoryItem]) -> Void) {
        completion(loadHistory(cache: cache))
    }

    func captureHistoryOrder(_ history: [HistoryItem]) {}

    func scheduleHistoryOrderWrite(history: [HistoryItem], immediate: Bool, completionHandler: ((Bool) -> Void)?) {
        saveHistoryOrder(history: history, completionHandler: completionHandler)
    }

    func saveHistoryOrder(history: [HistoryItem]) {
        saveHistoryOrder(history: history, completionHandler: nil)
    }

    func insertItem(_ item: HistoryItem, historyOrder: [HistoryItem]) {
        insertItem(item, historyOrder: historyOrder, completionHandler: nil)
    }

    func deleteItem(newHistory: [HistoryItem], deleted: HistoryItem) {
        deleteItem(newHistory: newHistory, deleted: deleted, completionHandler: nil)
    }

    func deleteItems(_ deletedItems: [HistoryItem], historyOrder: [HistoryItem]) {
        deleteItems(deletedItems, historyOrder: historyOrder, completionHandler: nil)
    }

    func clearHistory() {
        clearHistory(completionHandler: nil)
    }

    func setFavorite(_ isFavorite: Bool, for item: HistoryItem) {
        setFavorite(isFavorite, for: item, completionHandler: nil)
    }

    func setPassword(
        _ isPassword: Bool,
        comment: String,
        login: String,
        url: String,
        for item: HistoryItem
    ) {
        setPassword(isPassword, comment: comment, login: login, url: url, for: item, completionHandler: nil)
    }

    func setPasswordMetadata(comment: String, login: String, url: String, for item: HistoryItem) {
        setPasswordMetadata(comment: comment, login: login, url: url, for: item, completionHandler: nil)
    }

    func moveItem(newHistory: [HistoryItem], from: Int, to: Int) {
        moveItem(newHistory: newHistory, from: from, to: to, completionHandler: nil)
    }

    func saveContentDigest(_ digest: String, for item: HistoryItem) {
        saveContentDigest(digest, for: item, completionHandler: nil)
    }

    func saveContentDigest(_ digest: String, for item: HistoryItem, completionHandler: ((Bool) -> Void)?) {
        completionHandler?(true)
    }
}

extension HistoryFileManager: HistoryFileManaging {}
