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

/// Interface for an item that was on the pasteboard
class HistoryItem: NSObject {
    
    // MARK: - Private attributes
    
    /// Private variable for data that hasn't yet been saved to disk.
    private var _unsavedData: [NSPasteboard.PasteboardType: Data]?
    
    
    // MARK: - Public attributes
    
    /// The types of pasteboard data the item contains.
    let types: [NSPasteboard.PasteboardType]
    
    /// Data for the item that hasn't yet been saved to disk.
    ///
    /// This will be become `nil` when `startCaching()` is called to release it from memory.
    ///
    /// If you expect to need the items data after a call to `stopCaching(unsavedData:)` and the data is not saved to disk then you should should provide the data as an argument to `stopCaching(unsavedData:)`.
    var unsavedData: [NSPasteboard.PasteboardType: Data]? {
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
    
    /// Pinned in the Favorites tab; exempt from automatic history pruning.
    var isFavorite: Bool
    
    /// Saved in the Passwords tab; exempt from automatic history pruning.
    var isPassword: Bool
    
    /// Optional note shown under the password value in the Passwords tab.
    var passwordComment: String
    
    /// Items kept when clearing history or trimming the list.
    var isPinnedFromPruning: Bool {
        isFavorite || isPassword
    }
    
    /// On-disk metadata filename (not a pasteboard type).
    static let sourceBundleIdMetadataFileName = "sourceBundleId"
    
    /// Whether the item is being cached.
    var isCached: Bool {
        return cache.isItemRegistered(fsId)
    }
    
    static let historyItemIdType = NSPasteboard.PasteboardType(rawValue: "VaultClip.historyItemId")
    
    /// Static definition of whether the history items should write RTF data to the pasteboard.
    ///
    /// This value is used when determining the writable types for an item.
    static var pastesRichText = true
    
    
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
        isFavorite: Bool = false,
        isPassword: Bool = false,
        passwordComment: String = ""
    ) {
        self._unsavedData = unsavedData
        self.types = unsavedData.keys.map({$0})
        self.cache = cache
        self.fsId = UUID()
        self.sourceBundleId = sourceBundleId
        self.copiedAt = copiedAt
        self.isFavorite = isFavorite
        self.isPassword = isPassword
        self.passwordComment = passwordComment
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
        isFavorite: Bool = false,
        isPassword: Bool = false,
        passwordComment: String = ""
    ) {
        self.fsId = fsId
        self._unsavedData = nil
        self.types = types
        self.cache = cache
        self.sourceBundleId = sourceBundleId
        self.copiedAt = copiedAt
        self.isFavorite = isFavorite
        self.isPassword = isPassword
        self.passwordComment = passwordComment
        self.cache.registerItem(withId: fsId)
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
        _unsavedData = nil
        guard !isPassword else { return }
        cache.registerItem(withId: fsId)
    }
    
    /// Stops caching the item.
    ///
    /// - Parameter unsavedData: If the item's data is writen to disk this parameter can be ignored. But if itsn't then the `unsavedData` should be provided so it isn't lost.
    func stopCaching(unsavedData: [NSPasteboard.PasteboardType: Data]? = nil) {
        self._unsavedData = unsavedData
        cache.unregisterItem(withId: fsId)
    }
    
    func getPlainString() -> String? {
        guard let data = data(forType: .string) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func getRtfAttributedString() -> NSAttributedString? {
        guard let data = data(forType: .rtf) else { return nil }
        return NSAttributedString(rtf: data, documentAttributes: nil)
    }
    
    func getHtmlRawString() -> String? {
        guard let data = data(forType: .html) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func getHtmlAttributedString() -> NSAttributedString? {
        guard let data = data(forType: .html) else { return nil }
        return NSAttributedString(html: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
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
        let pageSuffix = pages == 1 ? "1 page" : "\(pages) pages"
        if let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String,
           !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return pages > 0 ? "\(title) (\(pageSuffix))" : title
        }
        return pages > 0 ? "PDF document (\(pageSuffix))" : "PDF document"
    }
    
    func getPdfIcon() -> NSImage {
        NSWorkspace.shared.icon(forFileType: "com.adobe.pdf")
    }
    
    /// File URL for Quick Look — existing files or a short-lived temp copy of PDF data.
    func quickLookPreviewURL() -> URL? {
        if let fileUrl = getFileUrl() {
            return fileUrl
        }
        guard let data = pdfData() else { return nil }
        let directory = Self.quickLookCacheDirectory
        try? SecureStorageHelper.ensureSecureDirectory(at: directory)
        let url = directory.appendingPathComponent("\(fsId.uuidString).pdf")
        if !FileManager.default.fileExists(atPath: url.path) {
            var options: Data.WritingOptions = .atomic
            if #available(macOS 11.0, *) {
                options.insert(.completeFileProtectionUntilFirstUserAuthentication)
            }
            try? data.write(to: url, options: options)
        }
        return url
    }
    
    static func removeQuickLookCache(for id: UUID) {
        let url = quickLookCacheDirectory.appendingPathComponent("\(id.uuidString).pdf")
        try? FileManager.default.removeItem(at: url)
    }
    
    private static let pdfPasteboardTypes: [NSPasteboard.PasteboardType] = [
        .pdf,
        NSPasteboard.PasteboardType(rawValue: "com.adobe.pdf"),
    ]
    
    private static var quickLookCacheDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("VaultClip-QL", isDirectory: true)
    }
    
    func getThumbnailImage() -> NSImage? {
        var image: NSImage?
        DispatchQueue.global(qos: .userInteractive).sync {
            guard let url = getFileUrl() else { return }
            let ref = QLThumbnailCreate(kCFAllocatorDefault, url as CFURL, CGSize(width: 300, height: 300), [kQLThumbnailOptionIconModeKey: true] as CFDictionary)
            
            guard let thumbnail = ref?.takeRetainedValue() else { return }
            let cgImageRef = QLThumbnailCopyImage(thumbnail)
            guard let cgImage = cgImageRef?.takeRetainedValue() else { return }
            image = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        }
        return image
        
        
    }
    
    func getFileIcon() -> NSImage? {
        guard let url = getFileUrl() else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
    
    func getColor() -> NSColor? {
        guard let data = data(forType: .color) else { return nil }
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: "VaultClip.ColorTest"))
        pasteboard.declareTypes([.color], owner: nil)
        pasteboard.setData(data, forType: .color)
        return NSColor(from: pasteboard)
    }
    
    private func isStringLink(string: String) -> Bool {
        let types: NSTextCheckingResult.CheckingType = [.link]
        guard let detector = try? NSDataDetector(types: types.rawValue), !string.isEmpty else { return false }
        return detector.numberOfMatches(
            in: string,
            options: NSRegularExpression.MatchingOptions(rawValue: 0),
            range: NSMakeRange(0, string.count)
        ) > 0
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
    
    /// Writes all supported representations onto `pasteboard`, including a plain-text
    /// fallback for link-only items so browsers and editors accept ⌘V.
    func write(to pasteboard: NSPasteboard) {
        var types = writableTypes(for: pasteboard)
        if getUrl() != nil && getPlainString() == nil && !types.contains(.string) {
            types.append(.string)
        }
        if isPassword {
            types.append(NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        }
        guard !types.isEmpty else { return }
        
        pasteboard.declareTypes(types, owner: nil)
        for type in types {
            if type == Self.historyItemIdType {
                pasteboard.setString(fsId.uuidString, forType: type)
            } else if type == .string {
                if let plain = getPlainString() {
                    pasteboard.setString(plain, forType: .string)
                } else if let url = getUrl() {
                    pasteboard.setString(url.absoluteString, forType: .string)
                }
            } else if let data = data(forType: type) {
                pasteboard.setData(data, forType: type)
            }
        }
    }
}

// MARK: - HistoryItem+NSPasteboardWriting
extension HistoryItem: NSPasteboardWriting {
    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        return types.filter{
            HistoryItem.pastesRichText || !richTextPasteboardTypes.contains($0.rawValue)
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
