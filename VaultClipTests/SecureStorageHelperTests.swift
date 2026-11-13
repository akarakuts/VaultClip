//
//  SecureStorageHelperTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class SecureStorageHelperTests: XCTestCase {

    private var root: URL!
    private var created: [URL] = []

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("SecureStorageHelperTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        for url in created where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        try? FileManager.default.removeItem(at: root)
    }

    // MARK: - Pasteboard file name encode/decode

    func testFileNameRoundTrip_forCommonTypes() {
        for type in [
            NSPasteboard.PasteboardType.string,
            .tiff,
            .png,
            NSPasteboard.PasteboardType("public.utf16-external-plain-text"),
            NSPasteboard.PasteboardType("org.chromium.web-custom-data"),
            NSPasteboard.PasteboardType("public.file-url")
        ] {
            let name = SecureStorageHelper.sanitizedPasteboardFileName(for: type)
            XCTAssertEqual(SecureStorageHelper.pasteboardType(fromStoredFileName: name), type, "round-trip broke for \(type.rawValue)")
        }
    }

    func testFileNameEncodesPercentAndSeparators() {
        let type = NSPasteboard.PasteboardType("a%b/c:d")
        let name = SecureStorageHelper.sanitizedPasteboardFileName(for: type)
        XCTAssertFalse(name.contains("/"))
        XCTAssertFalse(name.contains(":"))
        XCTAssertTrue(name.contains("%25"))
        XCTAssertTrue(name.contains("%2F"))
        XCTAssertTrue(name.contains("%3A"))
        XCTAssertEqual(SecureStorageHelper.pasteboardType(fromStoredFileName: name), type)
    }

    func testDecode_staysCompatibleWithLegacyStoredNames() {
        // Names written by the previous encoder keep decoding to the same types.
        XCTAssertEqual(
            SecureStorageHelper.pasteboardType(fromStoredFileName: "public.plist%3Avariant"),
            NSPasteboard.PasteboardType("public.plist:variant")
        )
        XCTAssertEqual(
            SecureStorageHelper.pasteboardType(fromStoredFileName: "com.apple.PasteboardType%2Fstuff"),
            NSPasteboard.PasteboardType("com.apple.PasteboardType/stuff")
        )
        XCTAssertEqual(
            SecureStorageHelper.pasteboardType(fromStoredFileName: "Apple%20type"),
            NSPasteboard.PasteboardType("Apple type")
        )
        // Encoded NUL is dropped — pasteboard types never legitimately contain it.
        XCTAssertEqual(
            SecureStorageHelper.pasteboardType(fromStoredFileName: "public.data%00"),
            NSPasteboard.PasteboardType("public.data")
        )
    }

    func testDecode_leavesInvalidPercentSequencesLiteral() {
        XCTAssertEqual(
            SecureStorageHelper.pasteboardType(fromStoredFileName: "100%real"),
            NSPasteboard.PasteboardType("100%real")
        )
        XCTAssertEqual(
            SecureStorageHelper.pasteboardType(fromStoredFileName: "trailing%"),
            NSPasteboard.PasteboardType("trailing%")
        )
    }

    func testAllDotNames_neverBecomePathComponents() {
        XCTAssertEqual(
            SecureStorageHelper.sanitizedPasteboardFileName(for: NSPasteboard.PasteboardType("..")),
            "%2E%2E"
        )
        XCTAssertEqual(
            SecureStorageHelper.sanitizedPasteboardFileName(for: NSPasteboard.PasteboardType(".")),
            "%2E"
        )
    }

    // MARK: - Directory hardening

    func testEnsureSecureDirectory_setsOwnerOnlyPermissions() throws {
        let url = root.appendingPathComponent("item-dir", isDirectory: true)
        created.append(url)
        try SecureStorageHelper.ensureSecureDirectory(at: url)
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let mode = (attributes[.posixPermissions] as? NSNumber)?.int16Value
        XCTAssertEqual(mode, SecureStorageHelper.directoryPermissions)
    }

    func testValidateStorageURL_rejectsSymlinkEscape() throws {
        let outside = FileManager.default.temporaryDirectory
            .appendingPathComponent("escape-target-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        let link = root.appendingPathComponent("linked", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        defer {
            try? FileManager.default.removeItem(at: link)
            try? FileManager.default.removeItem(at: outside)
        }
        XCTAssertThrowsError(try SecureStorageHelper.validateStorageURL(link, mustResideUnder: root))
    }

    func testValidateStorageURL_acceptsPlainSubdirectory() throws {
        let sub = root.appendingPathComponent("ok-dir", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        created.append(sub)
        XCTAssertNoThrow(try SecureStorageHelper.validateStorageURL(sub, mustResideUnder: root))
    }

    func testZeroize_clearsBytes() {
        var data = Data([1, 2, 3, 4])
        SecureStorageHelper.zeroize(&data)
        XCTAssertEqual(data, Data([0, 0, 0, 0]))
    }
}
