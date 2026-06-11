//
//  HistoryCache.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa

/// Cache for history.
class HistoryCache {
    
    private struct Usage {
        var id: UUID
        var type: NSPasteboard.PasteboardType
    }
    
    private var cachedData = [UUID: [NSPasteboard.PasteboardType: Data]]()
    private var usage = [Usage]()
    private var _currentCacheSize = 0
    
    /// Bytes currently held in the in-memory cache (for tests and diagnostics).
    var currentCacheSize: Int {
        var size = 0
        accessQueue.sync { size = self._currentCacheSize }
        return size
    }
    
    let maxCacheSize: Int
    var historyFM: HistoryFileManager
    var errorLogger: ErrorLogger
    var warningLogger: WarningLogger
    
    private let accessQueue = DispatchQueue(label: "SynchronizedCacheAccess", attributes: .concurrent)
    
    init(
        historyFM: HistoryFileManager = .default,
        maxCacheSize: Int = 100_000_000,
        errorLogger: ErrorLogger = .general,
        warningLogger: WarningLogger = .general
    ) {
        self.historyFM = historyFM
        self.maxCacheSize = maxCacheSize
        self.errorLogger = errorLogger
        self.warningLogger = warningLogger
    }
    
    func data(withId id: UUID, forType type: NSPasteboard.PasteboardType) -> Data? {
        var retData: Data?
        accessQueue.sync(flags: .barrier) {
            if let data = self.cachedData[id]?[type] {
                self.usedData(withId: id, andType: type)
                retData = data
                return
            }
            guard let data = self.historyFM.loadData(forItemWithId: id, andType: type) else {
                return
            }
            if !self.cachedData.keys.contains(id) {
                retData = data
                return
            }
            if data.count > self.maxCacheSize {
                retData = data
                return
            }
            while data.count + self._currentCacheSize > self.maxCacheSize {
                self.removeLRU()
            }
            if self.cachedData[id] == nil {
                self.cachedData[id] = [:]
            }
            self.cachedData[id]?[type] = data
            self.usedData(withId: id, andType: type)
            self._currentCacheSize += data.count
            retData = data
        }
        return retData
    }
    
    func registerItem(withId id: UUID) {
        accessQueue.async(flags: .barrier) {
            if self.cachedData[id] == nil {
                self.cachedData[id] = [:]
            }
        }
    }
    
    func unregisterItem(withId id: UUID) {
        accessQueue.async(flags: .barrier) {
            if let data = self.cachedData.removeValue(forKey: id) {
                for (_, bytes) in data {
                    var mutable = bytes
                    SecureStorageHelper.zeroize(&mutable)
                }
                self._currentCacheSize -= data.reduce(0, { $0 + $1.value.count })
                self.usage.removeAll(where: { $0.id == id })
            }
        }
    }
    
    func isItemRegistered(_ id: UUID) -> Bool {
        var registered = false
        accessQueue.sync {
            registered = self.cachedData.keys.contains(id)
        }
        return registered
    }
    
    private func usedData(withId id: UUID, andType type: NSPasteboard.PasteboardType) {
        if let i = usage.firstIndex(where: { $0.id == id && $0.type == type }) {
            let usage = self.usage.remove(at: i)
            self.usage.append(usage)
        } else {
            self.usage.append(Usage(id: id, type: type))
        }
    }
    
    private func removeLRU() {
        let removed = usage.removeFirst()
        guard var bucket = cachedData[removed.id],
              var bytes = bucket.removeValue(forKey: removed.type) else {
            ClipError(localizedDescription: "Error: Didn't find data with type \(removed.type.rawValue) for item with id \(removed.id.uuidString) to remove from the cache.")
                .log(with: errorLogger)
            return
        }
        SecureStorageHelper.zeroize(&bytes)
        cachedData[removed.id] = bucket.isEmpty ? nil : bucket
        if bucket.isEmpty {
            cachedData.removeValue(forKey: removed.id)
        }
        _currentCacheSize -= bytes.count
    }
}
