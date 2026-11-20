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

    // MARK: - Coalesced order writes

    /// Latest snapshot awaiting a flush. Confined to `dispatchQueue`; a crash between copies may
    /// leave the on-disk order one flush behind — orphan recovery (see `makeHistory`) re-adds such
    /// items by `copiedAt`, so no item data is lost.
    private var pendingHistoryOrder: [HistoryItem]?
    private var pendingOrderHandlers: [((Bool) -> Void)?] = []
    private var orderFlushScheduled = false
    /// Internal for tests: 1 s collapses copy bursts; 0 flushes on the next queue tick.
    var orderCoalesceInterval: TimeInterval = 1.0
    
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
            let historyError = ClipError(.historyOrderWriteFailed, localizedDescription: "Failed to write history order due to error: \(error.localizedDescription)")
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

    // MARK: - History order persistence

    /// Snapshots the order from the main thread for later coalesced writes.
    func captureHistoryOrder(_ history: [HistoryItem]) {
        dispatchQueue.async { self.pendingHistoryOrder = history }
    }

    /// Queues an order write; coalesced bursts collapse to one disk hit unless `immediate`.
    func scheduleHistoryOrderWrite(
        history: [HistoryItem],
        immediate: Bool = false,
        completionHandler handler: ((Bool) -> Void)? = nil
    ) {
        dispatchQueue.async {
            self.pendingHistoryOrder = history
            if let handler { self.pendingOrderHandlers.append(handler) }
            if immediate {
                self.flushPendingOrder()
                return
            }
            guard !self.orderFlushScheduled else { return }
            self.orderFlushScheduled = true
            self.dispatchQueue.asyncAfter(deadline: .now() + self.orderCoalesceInterval) {
                self.orderFlushScheduled = false
                self.flushPendingOrder()
            }
        }
    }

    func flushHistoryOrder(completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            if let handler { self.pendingOrderHandlers.append(handler) }
            self.flushPendingOrder()
        }
    }

    /// Blocks (bounded) until queued work drains — for app termination.
    func flushHistoryOrderSync(timeout: TimeInterval) {
        let semaphore = DispatchSemaphore(value: 0)
        dispatchQueue.async {
            self.flushPendingOrder()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + timeout)
    }

    private func flushPendingOrder() {
        guard let snapshot = pendingHistoryOrder else {
            let handlers = pendingOrderHandlers
            pendingOrderHandlers = []
            handlers.forEach { callHander($0, withVal: true) }
            return
        }
        pendingHistoryOrder = nil
        let result = writeHistoryOrder(history: snapshot)
        let handlers = pendingOrderHandlers
        pendingOrderHandlers = []
        handlers.forEach { callHander($0, withVal: result) }
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
        scheduleHistoryOrderWrite(history: history, completionHandler: completionHandler)
    }
    
    func loadHistoryOrder() -> [UUID]? {
        let orderURL = Constants.urls.historyOrder
        guard fileManager.fileExists(atPath: orderURL.path) else {
            return []
        }

        guard let order = orderManager.read() as? [String] else {
            if HistoryEncryptionProbe.isEncryptedFile(at: orderURL, fileManager: fileManager) {
                let historyError = ClipError(.historyOrderDecryptFailed, localizedDescription: "Failed to decrypt the history order file.")
                historyError.log(with: errorLogger)
                historyError.show(with: alerter)
                return nil
            }
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
            ClipError(.historyItemDataLoadFailed, localizedDescription: "Error: Failed to retrieve data with type \(type.rawValue) for item with id \(id.uuidString) due to error: \(error.localizedDescription)").log(with: self.errorLogger)
            return nil
        }
    }
    
    func loadHistory(cache: HistoryCache) -> History {
        makeHistory(cache: cache)
    }

    /// Builds the history off the calling thread (heavy directory scan), then publishes on main.
    func loadHistoryAsync(cache: HistoryCache, completion: @escaping (History) -> Void) {
        dispatchQueue.async {
            let history = self.makeHistory(cache: cache)
            DispatchQueue.main.async {
                completion(history)
            }
        }
    }

    private func makeHistory(cache: HistoryCache) -> History {
        guard let order = loadHistoryOrder() else {
            if HistoryEncryptionProbe.hasEncryptedPayloads(fileManager: fileManager) {
                ClipWarning(localizedDescription: "Encrypted history is present but could not be loaded.").log(with: warningLogger)
                return History(cache: cache, items: [])
            }
            ClipWarning(localizedDescription: "Failed to retrieve order. Creating new order...").log(with: warningLogger)
            saveHistoryOrder(history: [])
            return History(cache: cache, items: [])
        }

        if order.isEmpty, !HistoryEncryptionProbe.hasEncryptedPayloads(fileManager: fileManager) {
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
            let historyError = ClipError(.historyDirectoryListFailed, localizedDescription: "Creating an empty history because we failed to load history due to error: \(error.localizedDescription)")
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
                    let passwordLogin = self.loadPasswordLogin(from: content)
                    let passwordURL = self.loadPasswordURL(from: content)
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
                        passwordComment: passwordComment,
                        passwordLogin: passwordLogin,
                        passwordURL: passwordURL
                    )
                }
                catch {
                    let historyError = ClipError(.historyItemLoadFailed, localizedDescription: "Failed to load clipboard data for history item with id '\(id.uuidString)' due to error: \(error.localizedDescription). Will continue anyway.")
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
            let historyError = ClipError(.historyOrderLoadFailed, localizedDescription: "We cannot find the saved clipboard items with ids: \(unfound). You may notice them missing from the history.")
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
            let historyError = ClipError(.historyOrderLoadFailed, localizedDescription: "We could not find the order for the saved clipboard items with ids: \(unfound). So they will be added to the most recent history.")
            historyError.log(with: self.errorLogger)
            historyError.show(with: self.alerter)
            orderedItems = orphans + orderedItems
            saveHistoryOrder(history: orderedItems)
        }

        var quarantined: [HistoryItem] = []
        var kept: [HistoryItem] = []
        for item in orderedItems {
            switch probeReadability(itemDirectory: getUrl(forItemWithId: item.fsId), types: item.types) {
            case .readable:
                kept.append(item)
            case .undecryptable:
                if quarantineItemDirectory(getUrl(forItemWithId: item.fsId), id: item.fsId) {
                    quarantined.append(item)
                } else {
                    kept.append(item)
                }
            case .ioError:
                ClipWarning(localizedDescription: "Clipboard item '\(item.fsId.uuidString)' could not be read (I/O); keeping it in history.")
                    .log(with: warningLogger)
                kept.append(item)
            }
        }
        if kept.count != orderedItems.count {
            orderedItems = kept
            saveHistoryOrder(history: orderedItems)
        }
        if !quarantined.isEmpty {
            let message = L10n.encryptionQuarantineBody(count: quarantined.count)
            ClipWarning(localizedDescription: message).log(with: warningLogger)
            // Skip modal alerts in the XCTest host — runModal blocks the test run loop.
            if !AppIdentity.isRunningUnitTests {
                ClipError(.historyItemLoadFailed, localizedDescription: message).show(with: alerter)
            }
        }
        
        return History(cache: cache, items: orderedItems)
    }

    enum ItemReadability {
        case readable
        case undecryptable
        case ioError
    }

    /// Probes the smallest data file in the item directory without going through HistoryCache.
    func probeReadability(itemDirectory: URL, types: [NSPasteboard.PasteboardType]) -> ItemReadability {
        let files: [URL]
        do {
            files = try fileManager.contentsOfDirectory(
                at: itemDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            return .ioError
        }
        let dataFiles = files
            .filter { !HistoryItem.isMetadataFileName($0.lastPathComponent) }
            .sorted { lhs, rhs in
                let ls = (try? lhs.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? Int.max
                let rs = (try? rhs.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? Int.max
                return ls < rs
            }
        guard let probe = dataFiles.first else {
            return .readable
        }
        do {
            _ = try dataFileManager.loadData(contentsOf: probe)
            return .readable
        } catch StoredDataError.authenticationFailed {
            return .undecryptable
        } catch {
            if DataFileManager.isAuthenticationFailure(error) {
                return .undecryptable
            }
            return .ioError
        }
    }

    @discardableResult
    private func quarantineItemDirectory(_ directory: URL, id: UUID) -> Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())
        let destinationRoot = Constants.urls.quarantine.appendingPathComponent(stamp, isDirectory: true)
        do {
            try SecureStorageHelper.ensureSecureDirectory(at: Constants.urls.quarantine, fileManager: fileManager)
            try SecureStorageHelper.ensureSecureDirectory(at: destinationRoot, fileManager: fileManager)
            let destination = destinationRoot.appendingPathComponent(id.uuidString, isDirectory: true)
            try fileManager.moveItem(at: directory, to: destination)
            return true
        } catch {
            ClipWarning(localizedDescription: "Failed to quarantine item '\(id.uuidString)': \(error.localizedDescription)")
                .log(with: warningLogger)
            return false
        }
    }
    
    func insertItem(_ item: HistoryItem, historyOrder: [HistoryItem], completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            guard let unsavedData = item.unsavedData else {
                let historyError = ClipError(.historyItemSaveFailed, localizedDescription: "Failed to save new item due to error: unsavedError is nil")
                historyError.log(with: self.errorLogger)
                historyError.show(with: self.alerter)
                self.callHander(handler, withVal: false)
                return
            }
            
            let directoryUrl: URL
            do {
                directoryUrl = try self.ensureItemDirectory(for: item)
            } catch {
                let historyError = ClipError(.historyItemSaveFailed, localizedDescription: "Failed to save new item due to error: \(error.localizedDescription)")
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
                    try self.dataFileManager.writeData(data, to: itemUrl, options: .atomic)
                } catch {
                    try? self.fileManager.removeItem(at: directoryUrl)
                    let historyError = ClipError(.historyItemSaveFailed, localizedDescription: "Failed to save new pasteboard item due to error: \(error.localizedDescription) Attempted to save pasteboard item at '\(itemUrl)'.")
                    historyError.log(with: self.errorLogger)
                    historyError.show(with: self.alerter)
                    self.callHander(handler, withVal: false)
                    return
                }
            }
            
            item.startCaching()
            self.scheduleHistoryOrderWrite(history: historyOrder, completionHandler: handler)
        }
    }
    
    func deleteItem(newHistory: [HistoryItem], deleted: HistoryItem, completionHandler handler: ((Bool) -> Void)? = nil) {
        deleteItems([deleted], historyOrder: newHistory, completionHandler: handler)
    }
    
    func deleteItems(_ deletedItems: [HistoryItem], historyOrder: [HistoryItem], completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            var allSucceeded = true
            for deleted in deletedItems {
                do {
                    try self.fileManager.removeItem(at: self.getUrl(forItemWithId: deleted.fsId))
                } catch {
                    // Keep going: a stuck directory must not block the order rewrite,
                    // otherwise the remaining "deleted" items resurrect as orphans on next load.
                    allSucceeded = false
                    let historyError = ClipError(.historyItemDeleteFailed, localizedDescription: "Failed to delete item due to error: \(error.localizedDescription)")
                    historyError.log(with: self.errorLogger)
                    historyError.show(with: self.alerter)
                }
                HistoryItem.removeQuickLookCache(for: deleted.fsId)
                deleted.stopCaching()
            }
            self.scheduleHistoryOrderWrite(history: historyOrder, immediate: true, completionHandler: { wroteOrder in
                self.callHander(handler, withVal: wroteOrder && allSucceeded)
            })
        }
    }
    
    func reduce(oldHistory: [HistoryItem], toSize size: Int, completionHandler handler: ((Bool) -> Void)? = nil) {
        if oldHistory.count <= size {
            callHander(handler, withVal: true)
            return
        }
        
        dispatchQueue.async {
            let newHistory = Array(oldHistory.prefix(size))

            var allSucceeded = true
            for item in oldHistory.suffix(from: size) {
                HistoryItem.removeQuickLookCache(for: item.fsId)
                do {
                    try self.fileManager.removeItem(at: self.getUrl(forItemWithId: item.fsId))
                }
                catch {
                    allSucceeded = false
                    let historyError = ClipError(.historyItemDeleteFailed, localizedDescription: "Failed to delete item due to error: \(error.localizedDescription)")
                    historyError.log(with: self.errorLogger)
                    historyError.show(with: self.alerter)
                }

                item.stopCaching()
            }

            // Update order
            self.scheduleHistoryOrderWrite(history: newHistory, immediate: true, completionHandler: { wroteOrder in
                self.callHander(handler, withVal: wroteOrder && allSucceeded)
            })
        }
    }
    
    func moveItem(newHistory: [HistoryItem], from: Int, to: Int, completionHandler: ((Bool) -> Void)? = nil) {
        saveHistoryOrder(history: newHistory, completionHandler: completionHandler)
    }
    
    func clearHistory(completionHandler handler: ((Bool) -> Void)? = nil) {
        dispatchQueue.async {
            // A stale pending snapshot would resurrect cleared items into the order file.
            self.flushPendingOrder()

            // Delete the old history
            do {
                try self.fileManager.removeItem(at: Constants.urls.history)
            }
            catch {
                let historyError = ClipError(.historyClearFailed, localizedDescription: "Failed to delete old history due to error: \(error.localizedDescription)")
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
                let historyError = ClipError(.historyClearFailed, localizedDescription: "Failed to create directory for new history due to error: \(error.localizedDescription)")
                historyError.log(with: self.errorLogger)
                historyError.show(with: self.alerter)
                self.callHander(handler, withVal: false)
                return
            }

            // Save the new order
            self.scheduleHistoryOrderWrite(history: [], immediate: true, completionHandler: handler)
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
    
    func setPassword(
        _ isPassword: Bool,
        comment: String,
        login: String,
        url: String,
        for item: HistoryItem,
        completionHandler handler: ((Bool) -> Void)? = nil
    ) {
        dispatchQueue.async {
            let directoryUrl = self.getUrl(forItemWithId: item.fsId)
            let passwordUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordMetadataFileName)
            let commentUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordCommentMetadataFileName)
            let loginUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordLoginMetadataFileName)
            let siteUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordURLMetadataFileName)
            do {
                if isPassword {
                    try self.writeMetadata(HistoryItem.passwordMarker, to: passwordUrl)
                    try self.writeOptionalMetadata(comment, to: commentUrl)
                    try self.writeOptionalMetadata(login, to: loginUrl)
                    try self.writeOptionalMetadata(url, to: siteUrl)
                } else {
                    for url in [passwordUrl, commentUrl, loginUrl, siteUrl] where self.fileManager.fileExists(atPath: url.path) {
                        try self.fileManager.removeItem(at: url)
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
    
    func setPasswordMetadata(
        comment: String,
        login: String,
        url: String,
        for item: HistoryItem,
        completionHandler handler: ((Bool) -> Void)? = nil
    ) {
        dispatchQueue.async {
            let directoryUrl = self.getUrl(forItemWithId: item.fsId)
            let commentUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordCommentMetadataFileName)
            let loginUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordLoginMetadataFileName)
            let siteUrl = directoryUrl.appendingPathComponent(HistoryItem.passwordURLMetadataFileName)
            do {
                try self.writeOptionalMetadata(comment, to: commentUrl)
                try self.writeOptionalMetadata(login, to: loginUrl)
                try self.writeOptionalMetadata(url, to: siteUrl)
                self.callHander(handler, withVal: true)
            } catch {
                ClipWarning(localizedDescription: "Failed to save password metadata for item '\(item.fsId.uuidString)': \(error.localizedDescription)")
                    .log(with: self.warningLogger)
                self.callHander(handler, withVal: false)
            }
        }
    }
    
    private func writeOptionalMetadata(_ value: String, to url: URL) throws {
        if value.isEmpty {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        } else {
            try writeMetadata(value, to: url)
        }
    }
    
    private func loadPassword(from itemDirectory: URL) -> Bool {
        let passwordUrl = itemDirectory.appendingPathComponent(HistoryItem.passwordMetadataFileName)
        guard let raw = readMetadata(from: passwordUrl) ?? (try? String(contentsOf: passwordUrl, encoding: .utf8)) else { return false }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines) == HistoryItem.passwordMarker
    }
    
    private func loadPasswordComment(from itemDirectory: URL) -> String {
        loadPasswordMetadataString(from: itemDirectory, fileName: HistoryItem.passwordCommentMetadataFileName)
    }
    
    private func loadPasswordLogin(from itemDirectory: URL) -> String {
        loadPasswordMetadataString(from: itemDirectory, fileName: HistoryItem.passwordLoginMetadataFileName)
    }
    
    private func loadPasswordURL(from itemDirectory: URL) -> String {
        loadPasswordMetadataString(from: itemDirectory, fileName: HistoryItem.passwordURLMetadataFileName)
    }
    
    private func loadPasswordMetadataString(from itemDirectory: URL, fileName: String) -> String {
        let url = itemDirectory.appendingPathComponent(fileName)
        guard let raw = readMetadata(from: url) ?? (try? String(contentsOf: url, encoding: .utf8)) else { return "" }
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
        if let attrs = try? fileManager.attributesOfItem(atPath: itemDirectory.path),
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
