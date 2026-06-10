//
//  HistoryItemTests.swift
//  VaultClipTests
//
//  Copyright (C) 2019 Matthew Davidson
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

class HistoryItemTests: XCTestCase {

    private static let minimalPdfData = Data("""
    %PDF-1.4
    1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
    2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
    3 0 obj<</Type/Page/MediaBox[0 0 200 200]/Parent 2 0 R>>endobj
    xref
    0 4
    0000000000 65535 f
    trailer<</Size 4/Root 1 0 R>>
    startxref
    0
    %%EOF
    """.utf8)

    var savedItem: HistoryItem!
    var unsavedItem: HistoryItem!
    
    var unsavedData: [NSPasteboard.PasteboardType: Data]!
    
    var cache: HistoryCacheMock!
    
    override func setUp() {
        
        unsavedData = [.string: "Test".data(using: .utf8)!]
        
        cache = HistoryCacheMock()
        
        savedItem = HistoryItem(
            fsId: UUID(),
            types: [.string],
            cache: cache
        )
        
        unsavedItem = HistoryItem(
            unsavedData: unsavedData,
            cache: cache
        )
    }
    
    // MARK: - data()
    func testDataForMissingType() {
        // 1. For an item without a type
        XCTAssertFalse(savedItem.types.contains(.color))
        
        // 2. Get the data for that type
        let res = savedItem.data(forType: .color)
        
        // 3. The data should be nil
        XCTAssertNil(res)
    }
    
    func testDataForTypeInUnsavedData() {
        // 1. For an item with a type
        XCTAssertTrue(savedItem.types.contains(.string))
        
        // 2. Get the data for that type
        let res = unsavedItem.data(forType: .string)
        
        // 3. Should be the unsaved data
        XCTAssertEqual(res, unsavedData[.string])
    }
    
    func testDataForNoUnsavedData() {
        // 1. Set up the mock
        let data = Data(repeating: 1, count: 1)
        cache.data = data
        
        // 2. Get the data for that type
        let res = savedItem.data(forType: .string)
        
        // 3. Should be the data from the cache
        XCTAssertEqual(res, data)
        XCTAssertEqual(cache.dataCallCount, 1)
    }
    
    // MARK: - startCaching()
    func testStartCaching() {
        // 1. Start not caching with unsaved data
        XCTAssertFalse(unsavedItem.isCached)
        XCTAssertNotNil(unsavedItem.unsavedData)
        
        // 2. Start caching
        unsavedItem.startCaching()
        
        // 3. Unsaved data should be nil and should be caching
        self.expectation(for: NSPredicate(block: { (_, _) -> Bool in
            return self.unsavedItem.isCached && self.unsavedItem.unsavedData == nil
        }), evaluatedWith: nil, handler: nil)
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    // MARK: - stopCaching()
    func testStopCaching() {
        // 1. Need to make sure caching has started.
        self.expectation(for: NSPredicate(block: { (_, _) -> Bool in
            return self.savedItem.isCached
        }), evaluatedWith: nil, handler: { () -> Bool in
            // 2. Start caching
            self.savedItem.stopCaching()
            return true
        })
        
        // 3. Unsaved data should be nil and should not be caching
        self.expectation(for: NSPredicate(block: { (_, _) -> Bool in
            return !self.savedItem.isCached && self.savedItem.unsavedData == nil
        }), evaluatedWith: nil, handler: nil)
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    // MARK: - URLs
    func testGetUrlFromUtf8Data() {
        let urlString = "https://example.com/path?q=1"
        let item = HistoryItem(
            unsavedData: [.URL: urlString.data(using: .utf8)!],
            cache: cache
        )
        XCTAssertEqual(item.getUrl()?.absoluteString, urlString)
        XCTAssertEqual(HistoryItemText.getString(forItem: item), urlString)
    }
    
    func testGetUrlFromLegacyAppleUrlType() {
        let urlString = "https://mattdavo.com"
        let legacy = NSPasteboard.PasteboardType(rawValue: "Apple URL pasteboard type")
        let item = HistoryItem(
            unsavedData: [legacy: urlString.data(using: .utf8)!],
            cache: cache
        )
        XCTAssertEqual(item.getUrl()?.absoluteString, urlString)
    }
    
    func testUnknownFormatFallbackShowsCopiedAtDateAndTime() {
        let copiedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let item = HistoryItem(
            unsavedData: [NSPasteboard.PasteboardType("com.example.opaque"): Data([0x01, 0x02])],
            cache: cache,
            copiedAt: copiedAt
        )
        let display = HistoryItemText.getString(forItem: item)
        XCTAssertEqual(display, item.getCopiedAtDisplayString())
        XCTAssertNotEqual(display, "Unknown format")
        XCTAssertTrue(display.contains(":"), "Label should include time")
        XCTAssertTrue(display.range(of: #"\d"#, options: .regularExpression) != nil, "Label should include date")
    }
    
    func testSourceBundleIdIsStored() {
        let item = HistoryItem(
            unsavedData: [.string: "copied".data(using: .utf8)!],
            cache: cache,
            sourceBundleId: "com.apple.Safari"
        )
        XCTAssertEqual(item.sourceBundleId, "com.apple.Safari")
        XCTAssertNotNil(SourceAppIconProvider.icon(forBundleId: item.sourceBundleId))
    }
    
    func testRasterImagePreferredOverTemporaryFileUrl() throws {
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")!
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("vaultclip-test.png")
        try pngData.write(to: tempUrl)
        defer { try? FileManager.default.removeItem(at: tempUrl) }
        
        let item = HistoryItem(
            unsavedData: [
                .png: pngData,
                .fileURL: tempUrl.dataRepresentation,
            ],
            cache: cache
        )
        XCTAssertNotNil(item.getImage())
        XCTAssertTrue(item.getTableViewItemType() == HistoryTiffCellView.self)
    }
    
    func testRasterImageFormatsUseImageCell() {
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")!
        
        let pngItem = HistoryItem(unsavedData: [.png: pngData], cache: cache)
        XCTAssertTrue(pngItem.hasRasterImage())
        XCTAssertNotNil(pngItem.getImage())
        XCTAssertEqual(pngItem.getRasterImageDisplayString(), "Image (PNG)")
        XCTAssertTrue(pngItem.getTableViewItemType() == HistoryTiffCellView.self)
        
        let jpegType = NSPasteboard.PasteboardType("public.jpeg")
        let jpegItem = HistoryItem(unsavedData: [jpegType: pngData], cache: cache)
        XCTAssertTrue(jpegItem.hasRasterImage())
        XCTAssertNotNil(jpegItem.getImage())
        XCTAssertEqual(jpegItem.getRasterImageDisplayString(), "Image (JPEG)")
        
        let gifType = NSPasteboard.PasteboardType("com.compuserve.gif")
        let gifItem = HistoryItem(unsavedData: [gifType: pngData], cache: cache)
        XCTAssertTrue(gifItem.hasRasterImage())
        XCTAssertEqual(gifItem.getRasterImageDisplayString(), "Image (GIF)")
    }
    
    func testGetPdfDisplayString() {
        let pdfData = Self.minimalPdfData
        let item = HistoryItem(
            unsavedData: [.pdf: pdfData],
            cache: cache
        )
        XCTAssertNotNil(item.getPdf())
        XCTAssertEqual(item.getPdfDisplayString(), "PDF document (1 page)")
        XCTAssertEqual(HistoryItemText.getString(forItem: item), "PDF document (1 page)")
        XCTAssertTrue(item.getTableViewItemType() == HistoryPdfCellView.self)
    }
    
    func testQuickLookPreviewURLWritesTempPdf() {
        let item = HistoryItem(
            unsavedData: [.pdf: Self.minimalPdfData],
            cache: cache
        )
        let previewURL = item.quickLookPreviewURL()
        XCTAssertNotNil(previewURL)
        XCTAssertEqual(previewURL?.pathExtension, "pdf")
        XCTAssertTrue(FileManager.default.fileExists(atPath: previewURL!.path))
    }
    
    func testWriteUrlAddsPlainTextFallback() {
        let urlString = "https://example.com"
        let item = HistoryItem(
            unsavedData: [.URL: urlString.data(using: .utf8)!],
            cache: cache
        )
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("VaultClipTests.URLWrite"))
        pasteboard.clearContents()
        item.write(to: pasteboard)
        
        XCTAssertEqual(pasteboard.string(forType: .string), urlString)
        XCTAssertNotNil(pasteboard.data(forType: .URL))
        XCTAssertEqual(
            HistoryItem.parseUrl(from: pasteboard.data(forType: .URL))?.absoluteString,
            urlString
        )
    }
}
