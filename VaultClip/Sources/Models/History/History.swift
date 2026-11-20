//
//  History.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa
import RxSwift
import RxRelay

/// In-memory clipboard history.
///
/// Invariant (T13): `_items` is mutated only on the main queue. `HistoryItem` instances are
/// reference types shared with the UI; persistence receives `[HistoryItem]` arrays of those
/// same references (not value copies). Disk I/O runs on `HistoryFileManager`'s queue and must
/// not call `startCaching`/`stopCaching` — those stay on main.
class History {

    private func assertMain() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
    }
    
    private var _items = [HistoryItem]()

    /// fsId of the history item that currently matches the system pasteboard contents.
    private(set) var currentClipboardItemId: UUID?
    
    private var _lastRecordedChangeCount = BehaviorRelay<Int>(value: -1)
    
    var observableLastRecordedChangeCount: Observable<Int> {
        return _lastRecordedChangeCount.asObservable()
    }
    
    var lastRecordedChangeCount: Int {
        return _lastRecordedChangeCount.value
    }
    
    private(set) var historyFM: HistoryFileManaging
    private(set) var cache: HistoryCache
    
    private var _maxItems: BehaviorRelay<Int>
    
    private final class Subscription {
        let handler: SubscribeHandler
        init(handler: @escaping SubscribeHandler) { self.handler = handler }
    }
    
    var items: [HistoryItem] {
        get { self._items }
    }
    
    var favoriteItems: [HistoryItem] {
        _items.filter(\.isFavorite)
    }
    
    var passwordItems: [HistoryItem] {
        _items.filter(\.isPassword)
    }
    
    var maxItems: Observable<Int> {
        _maxItems.asObservable()
    }
    
    enum Change {
        case initial
        case insert(index: Int)
        case delete(deletedItem: HistoryItem)
        case clear
        case move(from: Int, to: Int)
        case itemLimitDecreased(deletedItems: [HistoryItem])
        case favoriteChanged(item: HistoryItem, isFavorite: Bool)
        case passwordChanged(item: HistoryItem, isPassword: Bool)
        case pinnedLimitExceeded(current: Int, max: Int)
    }
    
    typealias SubscribeHandler = ([HistoryItem], Change) -> Void
    private var subscriptions = [Subscription]()
    
    private static let deduplicationLookback = 20
    /// Digest → fsId for O(1) duplicate promotion (T23).
    private var digestIndex: [String: UUID] = [:]
    
    init(historyFM: HistoryFileManaging = HistoryFileManager.default, cache: HistoryCache, items: [HistoryItem], maxItems: Int = Constants.system.maxHistoryItems) {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
        self.historyFM = historyFM
        self.cache = cache
        self._items = items
        self._maxItems = BehaviorRelay<Int>(value: maxItems)
        rebuildDigestIndex()
        scheduleMissingDigestBackfill()

        if items.count > maxItems {
            reduceHistory(to: maxItems)
        }
    }

    static func load(historyFM: HistoryFileManaging = HistoryFileManager.default, cache: HistoryCache) -> History {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(.main))
        #endif
        let items = historyFM.loadHistory(cache: cache)
        return History(historyFM: historyFM, cache: cache, items: items)
    }

    static func loadAsync(
        historyFM: HistoryFileManaging = HistoryFileManager.default,
        cache: HistoryCache,
        completion: @escaping ([HistoryItem]) -> Void
    ) {
        historyFM.loadHistoryAsync(cache: cache, completion: completion)
    }

    /// Swaps in the asynchronously loaded list (main thread) and notifies subscribers.
    /// During startup there are usually no subscribers yet; the notify keeps the contract honest.
    func replaceLoaded(with loaded: [HistoryItem]) {
        assertMain()
        _items.forEach { $0.stopCaching() }
        _items = loaded
        rebuildDigestIndex()
        scheduleMissingDigestBackfill()
        notify(Change.initial)
        pruneExcessItems()
        historyFM.captureHistoryOrder(_items)
    }

    @discardableResult
    func subscribe(onNext: @escaping SubscribeHandler) -> () -> Void {
        assertMain()
        let subscription = Subscription(handler: onNext)
        subscriptions.append(subscription)
        onNext(_items, Change.initial)
        return { [weak self, weak subscription] in
            guard let self, let subscription else { return }
            self.subscriptions.removeAll { $0 === subscription }
        }
    }

    private func notify(_ change: Change) {
        subscriptions.forEach { $0.handler(_items, change) }
    }

    func insertItem(_ item: HistoryItem, at i: Int) {
        assertMain()
        _items.insert(item, at: i)
        if let digest = item.contentDigest {
            digestIndex[digest] = item.fsId
        }
        if i == 0 {
            currentClipboardItemId = item.fsId
        }
        notify(Change.insert(index: i))
        historyFM.insertItem(item, historyOrder: _items)
        pruneExcessItems()
    }

    func noteClipboardItemId(_ id: UUID?) {
        assertMain()
        currentClipboardItemId = id
    }

    func clearCurrentClipboardItemId() {
        assertMain()
        currentClipboardItemId = nil
    }

    func deleteItem(at i: Int) {
        assertMain()
        guard _items.indices.contains(i) else { return }
        let removed = _items.remove(at: i)
        removeFromDigestIndex(removed)
        removed.stopCaching()
        notify(Change.delete(deletedItem: removed))
        historyFM.deleteItem(newHistory: _items, deleted: removed)
    }
    
    func deleteItem(withId id: UUID) {
        guard let index = index(ofId: id) else { return }
        deleteItem(at: index)
    }
    
    func index(of item: HistoryItem) -> Int? {
        index(ofId: item.fsId)
    }
    
    func index(ofId id: UUID) -> Int? {
        _items.firstIndex(where: { $0.fsId == id })
    }
    
    func clear(nonFavoritesOnly: Bool = false) {
        assertMain()
        if nonFavoritesOnly {
            // Ordinary "Clear History" keeps favorites and saved passwords; only "Clear All" removes them.
            let removed = _items.filter { !$0.isFavorite && !$0.isPassword }
            guard !removed.isEmpty else { return }
            _items = _items.filter { $0.isFavorite || $0.isPassword }
            removed.forEach {
                removeFromDigestIndex($0)
                $0.stopCaching()
            }
            historyFM.deleteItems(removed, historyOrder: _items)
            notify(Change.clear)
            return
        }
        _items.forEach({ $0.stopCaching() })
        _items = []
        digestIndex = [:]
        notify(Change.clear)
        historyFM.clearHistory()
    }

    func setFavorite(_ isFavorite: Bool, for item: HistoryItem) {
        assertMain()
        guard let index = index(of: item) else { return }
        guard _items[index].isFavorite != isFavorite else { return }
        _items[index].isFavorite = isFavorite
        historyFM.setFavorite(isFavorite, for: item)
        notify(Change.favoriteChanged(item: item, isFavorite: isFavorite))
    }
    
    @discardableResult
    func toggleFavorite(for item: HistoryItem) -> Bool {
        guard let index = index(of: item) else { return item.isFavorite }
        let newValue = !_items[index].isFavorite
        setFavorite(newValue, for: item)
        return newValue
    }
    
    func setPassword(
        _ isPassword: Bool,
        for item: HistoryItem,
        comment: String? = nil,
        login: String? = nil,
        url: String? = nil
    ) {
        assertMain()
        guard let index = index(of: item) else { return }
        let resolvedComment = (comment ?? (isPassword ? _items[index].passwordComment : ""))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedLogin = (login ?? (isPassword ? _items[index].passwordLogin : ""))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedURL = HistoryItem.normalizePasswordURL(
            url ?? (isPassword ? _items[index].passwordURL : "")
        )
        let passwordChanged = _items[index].isPassword != isPassword
        let commentChanged = _items[index].passwordComment != resolvedComment
        let loginChanged = _items[index].passwordLogin != resolvedLogin
        let urlChanged = _items[index].passwordURL != resolvedURL
        guard passwordChanged || commentChanged || loginChanged || urlChanged else { return }
        _items[index].isPassword = isPassword
        _items[index].passwordComment = isPassword ? resolvedComment : ""
        _items[index].passwordLogin = isPassword ? resolvedLogin : ""
        _items[index].passwordURL = isPassword ? resolvedURL : ""
        if isPassword {
            item.stopCaching()
        }
        historyFM.setPassword(
            isPassword,
            comment: _items[index].passwordComment,
            login: _items[index].passwordLogin,
            url: _items[index].passwordURL,
            for: item
        )
        notify(Change.passwordChanged(item: item, isPassword: isPassword))
    }
    
    func setPasswordMetadata(comment: String, login: String, url: String, for item: HistoryItem) {
        assertMain()
        guard let index = index(of: item), _items[index].isPassword else { return }
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = HistoryItem.normalizePasswordURL(url)
        guard _items[index].passwordComment != trimmedComment
            || _items[index].passwordLogin != trimmedLogin
            || _items[index].passwordURL != trimmedURL else { return }
        _items[index].passwordComment = trimmedComment
        _items[index].passwordLogin = trimmedLogin
        _items[index].passwordURL = trimmedURL
        historyFM.setPasswordMetadata(
            comment: trimmedComment,
            login: trimmedLogin,
            url: trimmedURL,
            for: item
        )
        notify(Change.passwordChanged(item: item, isPassword: true))
    }
    
    @discardableResult
    func togglePassword(for item: HistoryItem) -> Bool {
        guard let index = index(of: item) else { return item.isPassword }
        let newValue = !_items[index].isPassword
        setPassword(newValue, for: item)
        return newValue
    }
    
    func moveItem(at i: Int, to j: Int) {
        assertMain()
        guard _items.indices.contains(i), _items.indices.contains(j) else { return }
        guard i != j else { return }
        let item = _items.remove(at: i)
        _items.insert(item, at: j)
        if j == 0 {
            currentClipboardItemId = item.fsId
        }
        notify(Change.move(from: i, to: j))
        historyFM.moveItem(newHistory: _items, from: i, to: j)
    }
    
    func moveItem(_ item: HistoryItem, to destination: HistoryItem) {
        guard let from = index(of: item), let to = index(of: destination), from != to else { return }
        moveItem(at: from, to: to)
    }
    
    private func pruneExcessItems() {
        assertMain()
        var deleted: [HistoryItem] = []
        while _items.count > _maxItems.value {
            guard let index = _items.lastIndex(where: { !$0.isPinnedFromPruning }) else {
                notify(Change.pinnedLimitExceeded(current: _items.count, max: _maxItems.value))
                break
            }
            deleted.append(_items.remove(at: index))
        }
        guard !deleted.isEmpty else { return }
        deleted.forEach {
            removeFromDigestIndex($0)
            $0.stopCaching()
        }
        historyFM.deleteItems(deleted, historyOrder: _items)
        for item in deleted {
            notify(Change.delete(deletedItem: item))
        }
    }

    func recordPasteboardChange(withCount changeCount: Int) {
        assertMain()
        _lastRecordedChangeCount.accept(changeCount)
    }

    func setMaxItems(_ maxItems: Int) {
        assertMain()
        if maxItems < _maxItems.value {
            reduceHistory(to: maxItems)
        }
        _maxItems.accept(maxItems)
    }

    func purgeExpiredItems(now: Date = Date()) {
        assertMain()
        let ids = HistoryRetention.expiredIds(in: _items, retentionDays: Settings.main.retentionDays, now: now)
        for id in ids {
            deleteItem(withId: id)
        }
    }

    /// How many unpinned items would be deleted if the limit became `newMax` (T28).
    func itemsToPrune(forNewMax newMax: Int) -> Int {
        assertMain()
        guard newMax < _items.count else { return 0 }
        var remaining = _items
        var pruned = 0
        while remaining.count > newMax {
            guard let index = remaining.lastIndex(where: { !$0.isPinnedFromPruning }) else { break }
            remaining.remove(at: index)
            pruned += 1
        }
        return pruned
    }

    private func reduceHistory(to maxItems: Int) {
        assertMain()
        guard _items.count > maxItems else { return }
        var deletedItems: [HistoryItem] = []
        while _items.count > maxItems {
            guard let index = _items.lastIndex(where: { !$0.isPinnedFromPruning }) else {
                notify(Change.pinnedLimitExceeded(current: _items.count, max: maxItems))
                break
            }
            deletedItems.append(_items.remove(at: index))
        }
        guard !deletedItems.isEmpty else { return }
        deletedItems.forEach {
            removeFromDigestIndex($0)
            $0.stopCaching()
        }
        historyFM.deleteItems(deletedItems, historyOrder: _items)
        notify(Change.itemLimitDecreased(deletedItems: deletedItems))
    }
    
    private func rebuildDigestIndex() {
        digestIndex = [:]
        for item in _items {
            if let digest = item.contentDigest {
                digestIndex[digest] = item.fsId
            }
        }
    }

    private func removeFromDigestIndex(_ item: HistoryItem) {
        guard let digest = item.contentDigest else { return }
        if digestIndex[digest] == item.fsId {
            digestIndex.removeValue(forKey: digest)
        }
    }

    private func promoteDuplicate(_ item: HistoryItem, digest: String) {
        if item.contentDigest == nil {
            item.contentDigest = digest
            digestIndex[digest] = item.fsId
            historyFM.saveContentDigest(digest, for: item)
        }
        if let idx = index(ofId: item.fsId) {
            if idx != 0 {
                moveItem(at: idx, to: 0)
            } else {
                currentClipboardItemId = item.fsId
            }
        }
    }

    /// Digest hit, else byte-compare lookback for legacy items missing a digest.
    private func existingDuplicate(for payload: [NSPasteboard.PasteboardType: Data]) -> (item: HistoryItem, digest: String)? {
        let digest = ContentDigest.compute(from: payload)
        if let id = digestIndex[digest], let item = _items.first(where: { $0.fsId == id }) {
            return (item, digest)
        }
        for item in _items.prefix(Self.deduplicationLookback) {
            if item.contentDigest != nil { continue }
            var matches = true
            for (type, bytes) in payload {
                guard let previous = item.data(forType: type), previous == bytes else {
                    matches = false
                    break
                }
            }
            if matches {
                return (item, digest)
            }
        }
        return nil
    }

    private func scheduleMissingDigestBackfill() {
        let targets = Array(_items.prefix(Self.deduplicationLookback).filter { $0.contentDigest == nil })
        guard !targets.isEmpty else { return }
        let fm = historyFM
        DispatchQueue.global(qos: .utility).async { [weak self] in
            var computed: [(UUID, String)] = []
            for item in targets {
                var payload: [NSPasteboard.PasteboardType: Data] = [:]
                for type in item.types {
                    if let data = item.data(forType: type) {
                        payload[type] = data
                    }
                }
                guard !payload.isEmpty else { continue }
                computed.append((item.fsId, ContentDigest.compute(from: payload)))
            }
            DispatchQueue.main.async {
                guard let self else { return }
                for (id, digest) in computed {
                    guard let item = self._items.first(where: { $0.fsId == id }), item.contentDigest == nil else { continue }
                    item.contentDigest = digest
                    self.digestIndex[digest] = id
                    fm.saveContentDigest(digest, for: item)
                }
            }
        }
    }
    
    private static func extractPasteboardPayload(
        from item: NSPasteboardItem,
        filteredTypes: Set<NSPasteboard.PasteboardType>
    ) -> [NSPasteboard.PasteboardType: Data] {
        var data = [NSPasteboard.PasteboardType: Data]()
        for type in filteredTypes {
            guard let payload = item.data(forType: type) else {
                #if DEBUG
                print("Warning: new pasteboard data nil for type '\(type.rawValue)'")
                #endif
                continue
            }
            data[type] = payload
        }
        return data
    }
}

extension History: PasteboardMonitorDelegate {

    /// Re-reads the live pasteboard on launch even when `changeCount` matches persisted settings.
    func syncWithPasteboardOnLaunch(_ pasteboard: NSPasteboard) {
        assertMain()
        processPasteboardChange(
            pasteboard,
            originBundleId: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            ignoreChangeCount: true
        )
    }

    func pasteboardDidChange(_ pasteboard: NSPasteboard, originBundleId: String?) {
        assertMain()
        processPasteboardChange(pasteboard, originBundleId: originBundleId, ignoreChangeCount: false)
    }

    private func processPasteboardChange(
        _ pasteboard: NSPasteboard,
        originBundleId: String?,
        ignoreChangeCount: Bool
    ) {
        assertMain()
        if !ignoreChangeCount, pasteboard.changeCount == lastRecordedChangeCount {
            return
        }
        // Our own paste (panel action) is never re-recorded, whatever app turns out to be frontmost (P8.3).
        if !ignoreChangeCount, pasteboard.changeCount == HistoryPanel.lastSelfWriteChangeCount {
            // Own write — currentClipboardItemId is set by the panel path that wrote.
            recordPasteboardChange(withCount: pasteboard.changeCount)
            return
        }

        if Settings.main.isCapturePaused || StorageRoot.suppressesCapture {
            PasteboardDiagnostics.log("skipped capture paused")
            currentClipboardItemId = nil
            recordPasteboardChange(withCount: pasteboard.changeCount)
            return
        }

        let liveBundleId = Self.clipboardSourceBundleId(originBundleId: originBundleId)
        if HistoryPasteboardPolicy.shouldIgnoreSource(bundleId: liveBundleId) {
            PasteboardDiagnostics.log("skipped bundle denylist: \(liveBundleId ?? "nil")")
            currentClipboardItemId = nil
            recordPasteboardChange(withCount: pasteboard.changeCount)
            return
        }

        let pasteboardItems = Self.pasteboardItems(from: pasteboard)
        guard !pasteboardItems.isEmpty else {
            PasteboardDiagnostics.log("no pasteboard items (changeCount=\(pasteboard.changeCount))")
            currentClipboardItemId = nil
            recordPasteboardChange(withCount: pasteboard.changeCount)
            return
        }

        var inserted = 0
        for item in pasteboardItems.reversed() {
            let filteredTypes = HistoryPasteboardPolicy.usableTypes(from: Set(item.types))
            guard !filteredTypes.isEmpty else { continue }

            var data = Self.extractPasteboardPayload(
                from: item,
                filteredTypes: filteredTypes
            )
            if data.isEmpty, let raster = HistoryItem.extractRasterData(from: item) {
                data = raster
            }
            guard !data.isEmpty else {
                PasteboardDiagnostics.log("empty payload for types: \(filteredTypes.map(\.rawValue))")
                continue
            }
            let payloadBytes = data.values.reduce(0) { $0 + $1.count }
            let maxMB = Settings.main.maxItemSizeMB
            if maxMB > 0, payloadBytes > maxMB * 1_048_576 {
                PasteboardDiagnostics.log("skipped oversize item (\(payloadBytes) bytes)")
                currentClipboardItemId = nil
                continue
            }
            if let duplicate = existingDuplicate(for: data) {
                PasteboardDiagnostics.log("duplicate payload promote (\(data.count) types)")
                promoteDuplicate(duplicate.item, digest: duplicate.digest)
                inserted += 1 // counts as handled clipboard binding (not a new row)
                continue
            }
            let historyItem = HistoryItem(unsavedData: data, cache: cache, sourceBundleId: liveBundleId)
            insertItem(historyItem, at: 0)
            inserted += 1
        }

        if inserted == 0 {
            currentClipboardItemId = nil
        }
        PasteboardDiagnostics.log(
            "processed changeCount=\(pasteboard.changeCount) inserted=\(inserted) historyCount=\(_items.count) launchSync=\(ignoreChangeCount)"
        )
        recordPasteboardChange(withCount: pasteboard.changeCount)
    }

    private static func clipboardSourceBundleId(originBundleId: String?) -> String? {
        ClipboardSource.resolve(
            frontmost: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            tracked: originBundleId
        )
    }

    /// `pasteboardItems` can be nil while legacy `data(forType:)` still works on some macOS builds.
    private static func pasteboardItems(from pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        if let items = pasteboard.pasteboardItems, !items.isEmpty {
            return items
        }
        guard let types = pasteboard.types, !types.isEmpty else { return [] }
        let item = NSPasteboardItem()
        var wroteAny = false
        for type in types {
            if let data = pasteboard.data(forType: type) {
                item.setData(data, forType: type)
                wroteAny = true
            } else if let string = pasteboard.string(forType: type),
                      let data = string.data(using: .utf8) {
                item.setData(data, forType: type)
                wroteAny = true
            }
        }
        return wroteAny ? [item] : []
    }
}
