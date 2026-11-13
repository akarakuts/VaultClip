//
//  HistoryEncryptionProbeTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class HistoryEncryptionProbeTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("HistoryEncryptionProbeTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func url(_ name: String, contents: Data) throws -> URL {
        let target = directory.appendingPathComponent(name)
        try contents.write(to: target)
        return target
    }

    func testEncryptedMagicPrefixDetected() throws {
        let target = try url("enc.bin", contents: Data("VC1".utf8 + [1, 2, 3]))
        XCTAssertTrue(HistoryEncryptionProbe.isEncryptedFile(at: target))
    }

    func testPlaintextNotDetected() throws {
        let target = try url("plain.plist", contents: Data("<plist/>".utf8))
        XCTAssertFalse(HistoryEncryptionProbe.isEncryptedFile(at: target))
    }

    func testShortAndEmptyFilesNotDetected() throws {
        let oneByte = try url("one.bin", contents: Data("V".utf8))
        XCTAssertFalse(HistoryEncryptionProbe.isEncryptedFile(at: oneByte))
        let empty = try url("empty.bin", contents: Data())
        XCTAssertFalse(HistoryEncryptionProbe.isEncryptedFile(at: empty))
    }

    func testMissingFileReturnsFalse() {
        XCTAssertFalse(HistoryEncryptionProbe.isEncryptedFile(at: directory.appendingPathComponent("gone.bin")))
    }

    func testBigEncryptedFileDetectedWithoutLoadingPayload() throws {
        // The probe must only read the 3-byte magic; a multi-MB file still classifies instantly.
        var contents = Data("VC1".utf8)
        contents.append(Data(repeating: 0x5A, count: 8_000_000))
        let target = try url("big.bin", contents: contents)

        let started = Date()
        XCTAssertTrue(HistoryEncryptionProbe.isEncryptedFile(at: target))
        XCTAssertLessThan(Date().timeIntervalSince(started), 0.5)
    }

    func testPrefixMatchIsCaseSensitive() throws {
        let target = try url("lower.bin", contents: Data("vc1rest".utf8))
        XCTAssertFalse(HistoryEncryptionProbe.isEncryptedFile(at: target))
    }
}
