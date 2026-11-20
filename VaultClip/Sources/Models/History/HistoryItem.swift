//
//  HistoryItem.swift
//  VaultClip
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation
import Cocoa
import Quartz
import UniformTypeIdentifiers

/// Interface for an item that was on the pasteboard
class HistoryItem: NSObject {
    
    // MARK: - Private attributes
    
    /// Private variable for data that hasn't yet been saved to disk.
    private var _unsavedData: [NSPasteboard.PasteboardType: Data]?
    private let unsavedDataLock = NSLock()
    
    
    // MARK: - Public attributes
    
    /// The types of pasteboard data the item contains.
    let types: [NSPasteboard.PasteboardType]
    
    /// Data for the item that hasn't yet been saved to disk.
    ///
    /// This will be become `nil` when `startCaching()` is called to release it from memory.
    ///
    /// If you expect to need the items data after a call to `stopCaching(unsavedData:)` and the data is not saved to disk then you should should provide the data as an argument to `stopCaching(unsavedData:)`.
    var unsavedData: [NSPasteboard.PasteboardType: Data]? {
        unsavedDataLock.lock()
        defer { unsavedDataLock.unlock() }
        return _unsavedData
    }
    
    /// The cache to load data from when requesting data and using caching.
    var cache: HistoryCache
    
    /// File system id. Unique name of the folder contains the data for this item
    let fsId: UUID
    
    /// Bundle identifier of the app that was frontmost when this item was copied.
    let sourceBundleId: String?
    
    /// When this item was added to the history.
    let copiedAt: Date

    /// Last paste/copy/promote time; defaults to `copiedAt` when missing on disk (U12).
    var lastUsedAt: Date
    
    /// Pinned in the Favorites tab; exempt from automatic history pruning.
    var isFavorite: Bool
    
    /// Saved in the Passwords tab; exempt from automatic history pruning.
    var isPassword: Bool
    
    /// Comment shown on line 1 in the Passwords tab.
    var passwordComment: String
    
    /// Login shown on line 2 in the Passwords tab.
    var passwordLogin: String
    
    /// Site URL shown on the Passwords tab (optional).
    var passwordURL: String

    /// SHA-256 hex digest of sorted pasteboard payloads for O(1) dedup (T23).
    var contentDigest: String?
    
    /// Items kept when clearing history or trimming the list.
    var isPinnedFromPruning: Bool {
        isFavorite || isPassword
    }
    
    /// On-disk metadata filename (not a pasteboard type).
    static let sourceBundleIdMetadataFileName = "sourceBundleId"
    static let contentDigestMetadataFileName = "contentDigest"
    
    /// Whether the item is being cached.
    var isCached: Bool {
        return cache.isItemRegistered(fsId)
    }
    
    static let historyItemIdType = NSPasteboard.PasteboardType(rawValue: "com.karakuts.VaultClip.history-item-id")
    
    /// Whether this item writes RTF/HTML data to the pasteboard. Set from settings
    /// by the paste path before the item is written (was a global static before D5).
    var pastesRichText = true
    
    
    // MARK: - Constructors
    
    /// Creates a `HistoryItem` for an item that has not been saved to disk yet.
    ///
    /// It will be initialised with a unique id.
    ///
    /// - Parameter unsavedData: Pastebaord data that has not yet been saved to disk.
    /// - Parameter cache: `HistoryCache` to use for caching if this item starts using caching.
    init(
        unsavedData: [NSPasteboard.PasteboardType: Data],
        cache: HistoryCache,
        sourceBundleId: String? = nil,
        copiedAt: Date = Date(),
        lastUsedAt: Date? = nil,
        isFavorite: Bool = false,
        isPassword: Bool = false,
        passwordComment: String = "",
        passwordLogin: String = "",
        passwordURL: String = "",
        contentDigest: String? = nil
    ) {
        self._unsavedData = unsavedData
        self.types = unsavedData.keys.map({$0})
        self.cache = cache
        self.fsId = UUID()
        self.sourceBundleId = sourceBundleId
        self.copiedAt = copiedAt
        self.lastUsedAt = lastUsedAt ?? copiedAt
        self.isFavorite = isFavorite
        self.isPassword = isPassword
        self.passwordComment = passwordComment
        self.passwordLogin = passwordLogin
        self.passwordURL = passwordURL
        self.contentDigest = contentDigest ?? ContentDigest.compute(from: unsavedData)
    }
    
    /// Creates a `HistoryItem` for an item that is saved to disk.
    ///
    /// - Parameter fsId: The unique id of the item.
    /// - Parameter types: The types of pasteboard data that this item contains.
    /// - Parameter cache: `HistoryCache` to use for caching.
    init(
        fsId: UUID,
        types: [NSPasteboard.PasteboardType],
        cache: HistoryCache,
        sourceBundleId: String? = nil,
        copiedAt: Date = Date(),
        lastUsedAt: Date? = nil,
        isFavorite: Bool = false,
        isPassword: Bool = false,
        passwordComment: String = "",
        passwordLogin: String = "",
        passwordURL: String = "",
        contentDigest: String? = nil
    ) {
        self.fsId = fsId
        self._unsavedData = nil
        self.types = types
        self.cache = cache
        self.sourceBundleId = sourceBundleId
        self.copiedAt = copiedAt
        self.lastUsedAt = lastUsedAt ?? copiedAt
        self.isFavorite = isFavorite
        self.isPassword = isPassword
        self.passwordComment = passwordComment
        self.passwordLogin = passwordLogin
        self.passwordURL = passwordURL
        self.contentDigest = contentDigest
        // Mirrors `startCaching()`: password payloads must never enter the plaintext RAM cache.
        if !isPassword {
            self.cache.registerItem(withId: fsId)
        }
    }
    
    /// Plain-text password payload stored with this history item.
    func getPasswordValue() -> String? {
        getPlainString()
    }
    
    
    // MARK: - Public methods
    
    /// Returns the data for given type.
    ///
    /// If the data is available in `unsavedData` it will be returned.
    /// Otherwise if the item is not being cached, the data will be loaded from disk using the cache, but it will not be cached.
    /// Otherwise it will use the cache to get the data.
    ///
    /// - Parameter type: The type of pasteboard data to get.
    /// - Returns: The data if successful, otherwise `nil`.
    ///
    func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        if !types.contains(type) {
            return nil
        }
        if let data = unsavedData, data.keys.contains(type) {
            return data[type]
        }
        return cache.data(withId: fsId, forType: type)
    }
    
    /// Requests all the data for the item.
    ///
    /// - Returns: A dictionary of all the data by calling `data(forType:)`.
    func allData() -> [NSPasteboard.PasteboardType: Data?] {
        var data = [NSPasteboard.PasteboardType: Data?]()
        for type in types {
            data[type] = self.data(forType: type)
        }
        return data
    }
    
    /// Starts caching the item.
    ///
    /// Deallocates the `unsavedData`. Assumes that the data has been saved to disk.
    func startCaching() {
        unsavedDataLock.lock()
        _unsavedData = nil
        unsavedDataLock.unlock()
        guard !isPassword else { return }
        cache.registerItem(withId: fsId)
    }
    
    /// Stops caching the item.
    ///
    /// - Parameter unsavedData: If the item's data is writen to disk this parameter can be ignored. But if itsn't then the `unsavedData` should be provided so it isn't lost.
    func stopCaching(unsavedData: [NSPasteboard.PasteboardType: Data]? = nil) {
        unsavedDataLock.lock()
        self._unsavedData = unsavedData
        unsavedDataLock.unlock()
        cache.unregisterItem(withId: fsId)
    }
    
    /// True when at least one payload can be read (decrypts with the current key).
    func hasReadableStoredData() -> Bool {
        types.contains { data(forType: $0) != nil }
    }

    func getPlainString() -> String? {
        for type in Self.plainTextPasteboardTypes where types.contains(type) {
            if let string = decodedText(for: type) {
                return string
            }
        }
        for type in types {
            let raw = type.rawValue.lowercased()
            guard raw.contains("plain-text") || raw == "public.text" || raw.hasSuffix(".text") else {
                continue
            }
            if let string = decodedText(for: type) {
                return string
            }
        }
        return nil
    }

    private func decodedText(for type: NSPasteboard.PasteboardType) -> String? {
        guard let data = data(forType: type), !data.isEmpty else { return nil }
        let raw = type.rawValue.lowercased()
        if raw.contains("utf16") {
            if let text = String(data: data, encoding: .utf16) { return text.isEmpty ? nil : text }
            if let text = String(data: data, encoding: .utf16LittleEndian) { return text.isEmpty ? nil : text }
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }
        return nil
    }

    static let plainTextPasteboardTypes: [NSPasteboard.PasteboardType] = [
        .string,
        NSPasteboard.PasteboardType(rawValue: "NSStringPboardType"),
        NSPasteboard.PasteboardType(rawValue: "public.text"),
        NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text"),
        NSPasteboard.PasteboardType(rawValue: "public.utf16-plain-text"),
        NSPasteboard.PasteboardType(rawValue: "com.apple.traditional-mac-plain-text"),
        NSPasteboard.PasteboardType(rawValue: "com.trolltech.anymime.text--plain"),
    ]
    
    func getRtfAttributedString() -> NSAttributedString? {
        guard let data = data(forType: .rtf) else { return nil }
        return NSAttributedString(rtf: data, documentAttributes: nil)
    }
    
    func getHtmlRawString() -> String? {
        for type in Self.htmlPasteboardTypes where types.contains(type) {
            if let data = data(forType: type),
               let string = String(data: data, encoding: .utf8),
               !string.isEmpty {
                return string
            }
        }
        return nil
    }

    private static let htmlPasteboardTypes: [NSPasteboard.PasteboardType] = [
        .html,
        NSPasteboard.PasteboardType(rawValue: "public.html"),
        NSPasteboard.PasteboardType(rawValue: "Apple HTML pasteboard type"),
    ]
    
    func getHtmlAttributedString() -> NSAttributedString? {
        for type in Self.htmlPasteboardTypes where types.contains(type) {
            guard let data = data(forType: type) else { continue }
            if let attr = NSAttributedString(
                html: data,
                options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            ), attr.length > 0 {
                return attr
            }
        }
        return nil
    }
    
    /// Web/link URL from the pasteboard (not a `file://` path).
    func getUrl() -> URL? {
        for type in Self.webUrlPasteboardTypes where types.contains(type) {
            if let url = Self.parseUrl(from: data(forType: type)) {
                return url
            }
        }
        return nil
    }
    
    private static let webUrlPasteboardTypes: [NSPasteboard.PasteboardType] = [
        .URL,
        NSPasteboard.PasteboardType(rawValue: "Apple URL pasteboard type"),
    ]
    
    static func parseUrl(from data: Data?) -> URL? {
        guard let data = data, !data.isEmpty else { return nil }
        if let url = URL(dataRepresentation: data, relativeTo: nil) {
            return url
        }
        if let str = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !str.isEmpty,
           let url = URL(string: str) {
            return url
        }
        return nil
    }
    
    func getFileUrl() -> URL? {
        guard let data = data(forType: .fileURL) else { return nil }
        return URL(dataRepresentation: data, relativeTo: nil)
    }
    
    func pdfData() -> Data? {
        for type in Self.pdfPasteboardTypes where types.contains(type) {
            if let data = data(forType: type), !data.isEmpty {
                return data
            }
        }
        return nil
    }
    
    func getPdf() -> PDFDocument? {
        guard let data = pdfData() else { return nil }
        return PDFDocument(data: data)
    }
    
    /// Human-readable label for PDF clipboard data (not file paths).
    func getPdfDisplayString() -> String? {
        guard getFileUrl() == nil, let document = getPdf() else { return nil }
        let pages = document.pageCount
        let pageSuffix = pages == 1 ? L10n.pdfPageOne : L10n.pdfPageOther(pages)
        if let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String,
           !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return pages > 0 ? L10n.pdfTitled(title, pageSuffix) : title
        }
        return pages > 0 ? L10n.pdfTitled(L10n.pdfDocument, pageSuffix) : L10n.pdfDocument
    }
    
    func getPdfIcon() -> NSImage {
        NSWorkspace.shared.icon(for: .pdf)
    }
    
    /// True when Quick Look can show this item (file URL or PDF pasteboard data) — no temp write.
    var hasQuickLookPreview: Bool {
        getFileUrl() != nil || pdfData() != nil
    }

    /// File URL for Quick Look — existing files or a short-lived temp copy of PDF data.
    func makeQuickLookPreviewURL(store: QuickLookTempStore = .shared) -> URL? {
        if let fileUrl = getFileUrl() {
            return fileUrl
        }
        guard let data = pdfData() else { return nil }
        return try? store.url(for: fsId, data: data)
    }

    static func removeQuickLookCache(for id: UUID, store: QuickLookTempStore = .shared) {
        store.remove(id: id)
    }
    
    private static let pdfPasteboardTypes: [NSPasteboard.PasteboardType] = [
        .pdf,
        NSPasteboard.PasteboardType(rawValue: "com.adobe.pdf"),
    ]
    
    func getFileIcon() -> NSImage? {
        guard let url = getFileUrl() else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    func getColor() -> NSColor? {
        guard let data = data(forType: .color) else { return nil }
        // Modern items store an NSKeyedArchiver plist — decode it directly. The round-trip
        // through a named pasteboard was global state and could leak back stale colors (P8.2).
        if let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
            return color
        }
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: "VaultClip.ColorTest"))
        pasteboard.declareTypes([.color], owner: nil)
        pasteboard.setData(data, forType: .color)
        return NSColor(from: pasteboard)
    }
    
    private let richTextPasteboardTypes = [
        NSPasteboard.PasteboardType.rtf.rawValue,
        NSPasteboard.PasteboardType.html.rawValue,
        "public.utf16-external-plain-text",
        "org.chromium.web-custom-data",
    ]
}

// MARK: - Pasteboard output
extension HistoryItem {
    
    /// Writes supported representations onto `pasteboard` via `PasteboardWriter`.
    /// The in-app drag type (`historyItemIdType`) is omitted from the system clipboard.
    @discardableResult
    func write(to pasteboard: NSPasteboard) -> Int {
        var outputTypes = types.filter {
            pastesRichText || !richTextPasteboardTypes.contains($0.rawValue)
        }
        if getUrl() != nil && getPlainString() == nil && !outputTypes.contains(.string) {
            outputTypes.append(.string)
        }
        guard !outputTypes.isEmpty else { return pasteboard.changeCount }

        let item = NSPasteboardItem()
        for type in outputTypes {
            if type == .string {
                if let plain = getPlainString() {
                    item.setString(plain, forType: .string)
                } else if let url = getUrl() {
                    item.setString(url.absoluteString, forType: .string)
                }
            } else if let data = data(forType: type) {
                item.setData(data, forType: type)
            }
        }
        return PasteboardWriter.write(item, to: pasteboard, concealed: isPassword)
    }
}

// MARK: - HistoryItem+NSPasteboardWriting
extension HistoryItem: NSPasteboardWriting {
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return types.filter{
            pastesRichText || !richTextPasteboardTypes.contains($0.rawValue)
        } + [Self.historyItemIdType]
    }
    
    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        if type == Self.historyItemIdType {
            return fsId.uuidString
        }
        return data(forType: type)
    }
    
    func writingOptions(forType type: NSPasteboard.PasteboardType, pasteboard: NSPasteboard) -> NSPasteboard.WritingOptions {
        // Synchronous delivery — required for reliable paste into other apps.
        return []
    }
}
