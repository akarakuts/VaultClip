//
//  HistoryFileManager.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

/// Handles the interfacing with a `FileManager` object to save and retrieve history data.
class HistoryFileManager {
    
    var fileManager: FileManager
    var orderManager: ArrayFileManager
    var dataFileManager: DataFileManager
    var dispatchQueue: DispatchQueue
    var errorLogger: ErrorLogger
    var warningLogger: WarningLogger
    var alerter: Alerter
    
    static var `default` = HistoryFileManager()
    
    init(
        fileManager: FileManager = FileManager.default,
        orderManager: ArrayFileManager? = nil,
        dataFileManager: DataFileManager = DataFileManager(),
        dispatchQueue: DispatchQueue? = nil,
        errorLogger: ErrorLogger = .general,
        warningLogger: WarningLogger = .general,
        alerter: Alerter = .general
    ) {
        self.fileManager = fileManager
        self.dataFileManager = dataFileManager
        self.orderManager = orderManager ?? ArrayFileManager(url: Constants.urls.historyOrder, dataFileManager: dataFileManager)
        self.errorLogger = errorLogger
        self.warningLogger = warningLogger
        self.alerter = alerter
        
        // Create a SERIAL background dispatch queue with a background quality of service. Can't just use DispatchQueue.global(qos: .background) as it's a concurrent queue, which we don't want
        // See: https://www.raywenderlich.com/5370-grand-central-dispatch-tutorial-for-swift-4-part-1-2
        self.dispatchQueue = dispatchQueue ?? DispatchQueue(label: "HistoryFileManagerQueue", qos: .background)
    }
    
    private func callHander(_ handler: ((Bool) -> Void)?, withVal val: Bool) {
        if let handler = handler {
            handler(val)
        }
    }
    
    private func writeHistoryOrder(history: [HistoryItem]) -> Bool {
        do {
            try checkHistoryDirectory()
            try self.orderManager.write(history.map({$0.fsId.uuidString}) as NSArray)
            return true
        }
        catch {
            let historyError = ClipError(localizedDescription: "Failed to write history order due to error: \(error.localizedDescription)")
            historyError.log(with: self.errorLogger)
            historyError.show(with: self.alerter)
            return false
        }
    }
    
    func checkHistoryDirectory() throws {
        try SecureStorageHelper.validateStorageURL(
            Constants.urls.history,
            mustResideUnder: Constants.urls.appSupport
        )
        try SecureStorageHelper.ensureSecureDirectory(at: Constants.urls.history, fileManager: fileManager)
    }
    
    private func writeMetadata(_ string: String, to url: URL) throws {
        guard let data = string.data(using: .utf8) else { return }
        try dataFileManager.writeData(data, to: url, options: .atomic)
    }
    
    private func readMetadata(from url: URL) -> String? {
        guard let data = try? dataFileManager.loadData(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func ensureItemDirectory(for item: HistoryItem) throws -> URL {
        try checkHistoryDirectory()
        let directoryUrl = getUrl(forItemWithId: item.fsId)
        try SecureStorageHelper.validateStorageURL(directoryUrl, mustResideUnder: Constants.urls.history, fileManager: fileManager)
        try SecureStorageHelper.ensureSecureDirectory(at: directoryUrl, fileManager: fileManager)
        return directoryUrl
    }
    
    func saveHistoryOrder(history: [HistoryItem], completionHandler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            let res = self.writeHistoryOrder(history: history)
            if let c = completionHandler {
                c(res)
            }
        }
    }
    
    func loadHistoryOrder() -> [UUID]? {
        guard let order = orderManager.read() as? [String] else {
            ClipWarning(localizedDescription: "Failed to load the history order.").log(with: warningLogger)
            return nil
        }
        var uuidOrder = [UUID]()
        for str in order {
            if let id = UUID(uuidString: str) {
                uuidOrder.append(id)
            }
            else {
                ClipWarning(localizedDescription: "Found string '\(str)' in history order, which is not of the expected UUID format.").log(with: warningLogger)
            }
        }
        return uuidOrder
    }
    
    func loadData(forItemWithId id: UUID, andType type: NSPasteboard.PasteboardType) -> Data? {
        do {
            return try dataFileManager.loadData(contentsOf: getUrl(forItemWithId: id, andPasteboardType: type))
        }
        catch {
            ClipError(localizedDescription: "Error: Failed to retrieve data with type \(type.rawValue) for item with id \(id.uuidString) due to error: \(error.localizedDescription)").log(with: self.errorLogger)
            return nil
        }
    }
    
    func loadHistory(cache: HistoryCache) -> History {
        guard let order = loadHistoryOrder() else {
            ClipWarning(localizedDescription: "Failed to retrieve order. Creating new order...").log(with: warningLogger)
            saveHistoryOrder(history: [])
            return History(cache: cache, items: [])
        }
        var items = [UUID: HistoryItem]()
        var contents = [URL]()
        
        do {
            // Get all the items
            contents = try self.fileManager.contentsOfDirectory(at: Constants.urls.history, includingPropertiesForKeys: nil)
            // Remove the history order
            contents.removeAll(where: {$0 == Constants.urls.historyOrder})
            contents.removeAll(where: {$0.lastPathComponent == ".DS_Store"})
        }
        catch {
            let historyError = ClipError(code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Creating an empty history because we failed to load history due to error: \(error.localizedDescription)"
            ])
            historyError.log(with: self.errorLogger)
            historyError.show(with: self.alerter)
            saveHistoryOrder(history: [])
            return History(cache: cache, items: [])
        }
        
        for content in contents {
            // Get the id and build the item
            if let id = UUID(uuidString: content.lastPathComponent) {
                do {
                    // Get all the files
                    let dataUrls = try self.fileManager.contentsOfDirectory(at: content, includingPropertiesForKeys: nil)
                    let sourceBundleId = self.loadSourceBundleId(from: content)
                    let copiedAt = self.loadCopiedAt(from: content)
                    let isFavorite = self.loadFavorite(from: content)
                    let isPassword = self.loadPassword(from: content)
                    let passwordComment = self.loadPasswordComment(from: content)
                    let types = dataUrls
                        .map(\.lastPathComponent)
                        .filter { !HistoryItem.isMetadataFileName($0) }
                        .map { SecureStorageHelper.pasteboardType(fromStoredFileName: $0) }
                    items[id] = HistoryItem(
                        fsId: id,
                        types: types,
                        cache: cache,
                        sourceBundleId: sourceBundleId,
                        copiedAt: copiedAt,
                        isFavorite: isFavorite,
                        isPassword: isPassword,
                        passwordComment: passwordComment
                    )
                }
                catch {
                    let historyError = ClipError(code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to load clipboard data for history item with id '\(id.uuidString)' due to error: \(error.localizedDescription). Will continue anyway."
                    ])
                    historyError.log(with: self.errorLogger)
                    historyError.show(with: self.alerter)
                }
            }
            else {
                // Skip
                ClipWarning(localizedDescription: "Directory '\(content.lastPathComponent)' in history directory could not be interpreted as a history item.").log(with: self.warningLogger)
            }
        }
        
        var orderedItems = [HistoryItem]()
        var unfoundItems = [String]()
        for id in order {
            if let item = items.removeValue(forKey: id) {
                orderedItems.append(item)
            }
            else {
                unfoundItems.append(id.uuidString)
            }
        }
        if !unfoundItems.isEmpty {
            let unfound = unfoundItems.map({"'\($0)'"}).joined(separator: ", ")
            let historyError = ClipError(code: 0, userInfo: [
                NSLocalizedDescriptionKey: "We cannot find the saved clipboard items with ids: \(unfound). You may notice them missing from the history."
            ])
            historyError.log(with: self.errorLogger)
            historyError.show(with: self.alerter)
            for unfoundItem in unfoundItems {
                orderedItems.removeAll(where: {$0.fsId.uuidString == unfoundItem})
            }
            saveHistoryOrder(history: orderedItems)
        }
        
        if !items.isEmpty {
            let orphans = items.values.sorted { $0.copiedAt > $1.copiedAt }
            let unfound = orphans.map({ $0.fsId.uuidString }).joined(separator: ", ")
            let historyError = ClipError(code: 0, userInfo: [
                NSLocalizedDescriptionKey: "We could not find the order for the saved clipboard items with ids: \(unfound). So they will be added to the most recent history."
            ])
            historyError.log(with: self.errorLogger)
            historyError.show(with: self.alerter)
            orderedItems = orphans + orderedItems
            saveHistoryOrder(history: orderedItems)
        }
        
        return History(cache: cache, items: orderedItems)
    }
    
    func insertItem(_ item: HistoryItem, historyOrder: [HistoryItem], completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            guard let unsavedData = item.unsavedData else {
                let historyError = ClipError(code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to save new item due to error: unsavedError is nil"
                ])
                historyError.log(with: self.errorLogger)
                historyError.show(with: self.alerter)
                self.callHander(handler, withVal: false)
                return
            }
            
            let directoryUrl: URL
            do {
                directoryUrl = try self.ensureItemDirectory(for: item)
            } catch {
                let historyError = ClipError(code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to save new item due to error: \(error.localizedDescription)"
                ])
                historyError.log(with: self.errorLogger)
                historyError.show(with: self.alerter)
                self.callHander(handler, withVal: false)
                return
            }
            
            if let sourceBundleId = item.sourceBundleId {
                let sourceUrl = directoryUrl.appendingPathComponent(HistoryItem.sourceBundleIdMetadataFileName)
                do {
                    try self.writeMetadata(sourceBundleId, to: sourceUrl)
                } catch {
                    ClipWarning(localizedDescription: "Failed to save source bundle id for item '\(item.fsId.uuidString)': \(error.localizedDescription)")
                        .log(with: self.warningLogger)
                }
            }
            
            let copiedAtUrl = directoryUrl.appendingPathComponent(HistoryItem.copiedAtMetadataFileName)
            do {
                try self.writeMetadata(HistoryItem.serializeCopiedAt(item.copiedAt), to: copiedAtUrl)
            } catch {
                ClipWarning(localizedDescription: "Failed to save copy time for item '\(item.fsId.uuidString)': \(error.localizedDescription)")
                    .log(with: self.warningLogger)
            }
            
            for (type, data) in unsavedData {
                let itemUrl = self.getUrl(forItemWithId: item.fsId, andPasteboardType: type)
                do {
                    try self.dataFileManager.writeData(data, to: itemUrl, options: [])
                } catch {
                    try? self.fileManager.removeItem(at: directoryUrl)
                    let historyError = ClipError(code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to save new pasteboard item due to error: \(error.localizedDescription) Attempted to save pasteboard item at '\(itemUrl)'."
                    ])
                    historyError.log(with: self.errorLogger)
                    historyError.show(with: self.alerter)
                    self.callHander(handler, withVal: false)
                    return
                }
            }
            
            DispatchQueue.main.async {
                item.startCaching()
            }
            self.saveHistoryOrder(history: historyOrder, completionHandler: handler)
        }
    }
    
    func deleteItem(newHistory: [HistoryItem], deleted: HistoryItem, completionHandler handler: ((Bool) -> Void)? = nil) {
        deleteItems([deleted], historyOrder: newHistory, completionHandler: handler)
    }
    
    func deleteItems(_ deletedItems: [HistoryItem], historyOrder: [HistoryItem], completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            for deleted in deletedItems {
                do {
                    try self.fileManager.removeItem(at: self.getUrl(forItemWithId: deleted.fsId))
                } catch {
                    let historyError = ClipError(code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to delete item due to error: \(error.localizedDescription)"
                    ])
                    historyError.log(with: self.errorLogger)
                    historyError.show(with: self.alerter)
                    self.callHander(handler, withVal: false)
                    return
                }
                HistoryItem.removeQuickLookCache(for: deleted.fsId)
                deleted.stopCaching()
            }
            self.saveHistoryOrder(history: historyOrder, completionHandler: handler)
        }
    }
    
    func reduce(oldHistory: [HistoryItem], toSize size: Int, completionHandler handler: ((Bool) -> Void)? = nil) {
        if oldHistory.count <= size {
            callHander(handler, withVal: true)
            return
        }
        
        dispatchQueue.async {
            let newHistory = Array(oldHistory.prefix(size))
            
            for item in oldHistory.suffix(from: size) {
                HistoryItem.removeQuickLookCache(for: item.fsId)
                do {
                    try self.fileManager.removeItem(at: self.getUrl(forItemWithId: item.fsId))
                }
                catch {
                    let historyError = ClipError(code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to delete item due to error: \(error.localizedDescription)"
                    ])
                    historyError.log(with: self.errorLogger)
                    historyError.show(with: self.alerter)
                    self.callHander(handler, withVal: false)
                }
                
                item.stopCaching()
            }
            
            // Update order
            self.saveHistoryOrder(history: newHistory, completionHandler: handler)
        }
    }
    
    func moveItem(newHistory: [HistoryItem], from: Int, to: Int, completionHandler: ((Bool) -> Void)? = nil) {
        saveHistoryOrder(history: newHistory, completionHandler: completionHandler)
    }
    
    func clearHistory(completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            // Delete the old history
            do {
                try self.fileManager.removeItem(at: Constants.urls.history)
            }
            catch {
                let historyError = ClipError(code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to delete old history due to error: \(error.localizedDescription)"
                ])
                historyError.log(with: self.errorLogger)
                historyError.show(with: self.alerter)
                self.callHander(handler, withVal: false)
                return
            }
            
            // Create a new empty history
            do {
                try self.fileManager.createDirectory(at: Constants.urls.history, withIntermediateDirectories: true)
            }
            catch {
                let historyError = ClipError(code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to create directory for new history due to error: \(error.localizedDescription)"
                ])
                historyError.log(with: self.errorLogger)
                historyError.show(with: self.alerter)
                self.callHander(handler, withVal: false)
                return
            }
            
            // Save the new order
            self.saveHistoryOrder(history: [], completionHandler: handler)
        }
    }
    
    private func loadSourceBundleId(from itemDirectory: URL) -> String? {
        let sourceUrl = itemDirectory.appendingPathComponent(HistoryItem.sourceBundleIdMetadataFileName)
        guard let raw = readMetadata(from: sourceUrl) ?? (try? String(contentsOf: sourceUrl, encoding: .utf8)) else { return nil }
        let bundleId = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return bundleId.isEmpty ? nil : bundleId
    }
    
    func setFavorite(_ isFavorite: Bool, for item: HistoryItem, completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            let directoryUrl = self.getUrl(forItemWithId: item.fsId)
            let favoriteUrl = directoryUrl.appendingPathComponent(HistoryItem.favoriteMetadataFileName)
            do {
                if isFavorite {
                    try self.writeMetadata(HistoryItem.favoriteMarker, to: favoriteUrl)
                } else if self.fileManager.fileExists(atPath: favoriteUrl.path) {
                    try self.fileManager.removeItem(at: favoriteUrl)
                }
                self.callHander(handler, withVal: true)
            } catch {
                ClipWarning(localizedDescription: "Failed to save favorite flag for item '\(item.fsId.uuidString)': \(error.localizedDescription)")
                    .log(with: self.warningLogger)
                self.callHander(handler, withVal: false)
            }
        }
    }
    
    private func loadFavorite(from itemDirectory: URL) -> Bool {
        let favoriteUrl = itemDirectory.appendingPathComponent(HistoryItem.favoriteMetadataFileName)
        guard let raw = readMetadata(from: favoriteUrl) ?? (try? String(contentsOf: favoriteUrl, encoding: .utf8)) else { return false }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines) == HistoryItem.favoriteMarker
    }
    
    func setPassword(_ isPassword: Bool, comment: String, for item: HistoryItem, completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            let directoryUrl = self.getUrl(forItemWithId: item.fsId)
            let passwordUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordMetadataFileName)
            let commentUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordCommentMetadataFileName)
            do {
                if isPassword {
                    try self.writeMetadata(HistoryItem.passwordMarker, to: passwordUrl)
                    if comment.isEmpty {
                        if self.fileManager.fileExists(atPath: commentUrl.path) {
                            try self.fileManager.removeItem(at: commentUrl)
                        }
                    } else {
                        try self.writeMetadata(comment, to: commentUrl)
                    }
                } else {
                    if self.fileManager.fileExists(atPath: passwordUrl.path) {
                        try self.fileManager.removeItem(at: passwordUrl)
                    }
                    if self.fileManager.fileExists(atPath: commentUrl.path) {
                        try self.fileManager.removeItem(at: commentUrl)
                    }
                }
                self.callHander(handler, withVal: true)
            } catch {
                ClipWarning(localizedDescription: "Failed to save password metadata for item '\(item.fsId.uuidString)': \(error.localizedDescription)")
                    .log(with: self.warningLogger)
                self.callHander(handler, withVal: false)
            }
        }
    }
    
    func setPasswordComment(_ comment: String, for item: HistoryItem, completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            let directoryUrl = self.getUrl(forItemWithId: item.fsId)
            let commentUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordCommentMetadataFileName)
            do {
                if comment.isEmpty {
                    if self.fileManager.fileExists(atPath: commentUrl.path) {
                        try self.fileManager.removeItem(at: commentUrl)
                    }
                } else {
                    try self.writeMetadata(comment, to: commentUrl)
                }
                self.callHander(handler, withVal: true)
            } catch {
                ClipWarning(localizedDescription: "Failed to save password comment for item '\(item.fsId.uuidString)': \(error.localizedDescription)")
                    .log(with: self.warningLogger)
                self.callHander(handler, withVal: false)
            }
        }
    }
    
    private func loadPassword(from itemDirectory: URL) -> Bool {
        let passwordUrl = itemDirectory.appendingPathComponent(HistoryItem.passwordMetadataFileName)
        guard let raw = readMetadata(from: passwordUrl) ?? (try? String(contentsOf: passwordUrl, encoding: .utf8)) else { return false }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines) == HistoryItem.passwordMarker
    }
    
    private func loadPasswordComment(from itemDirectory: URL) -> String {
        let commentUrl = itemDirectory.appendingPathComponent(HistoryItem.passwordCommentMetadataFileName)
        guard let raw = readMetadata(from: commentUrl) ?? (try? String(contentsOf: commentUrl, encoding: .utf8)) else { return "" }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func loadCopiedAt(from itemDirectory: URL) -> Date {
        let copiedAtUrl = itemDirectory.appendingPathComponent(HistoryItem.copiedAtMetadataFileName)
        if let raw = readMetadata(from: copiedAtUrl) ?? (try? String(contentsOf: copiedAtUrl, encoding: .utf8)) {
            let stamp = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if let date = HistoryItem.deserializeCopiedAt(stamp) {
                return date
            }
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: itemDirectory.path),
           let created = attrs[.creationDate] as? Date {
            return created
        }
        return Date()
    }
    
    func getUrl(forItemWithId id: UUID) -> URL {
        return Constants.urls.history.appendingPathComponent("\(id.uuidString)", isDirectory: true)
    }
    
    func getUrl(forItemWithId id: UUID, andPasteboardType type: NSPasteboard.PasteboardType) -> URL {
        let fileName = SecureStorageHelper.sanitizedPasteboardFileName(for: type)
        return getUrl(forItemWithId: id).appendingPathComponent(fileName, isDirectory: false)
    }
}
