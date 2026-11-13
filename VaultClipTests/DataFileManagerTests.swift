//
//  DataFileManagerTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

private final class PassthroughEncryptor: DataEncryptor {
    func encrypt(_ data: Data) throws -> Data { data }
    func decrypt(_ data: Data) throws -> Data { data }
}

final class DataFileManagerTests: XCTestCase {

    private var directory: URL!
    private var fileManager: DataFileManager!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DataFileManagerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileManager = DataFileManager(encryptor: PassthroughEncryptor())
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func url(_ name: String) -> URL { directory.appendingPathComponent(name) }

    func testWriteThenReadRoundTrip() throws {
        let target = url("payload.txt")
        let payload = Data("clipboard bytes".utf8)
        try fileManager.writeData(payload, to: target)
        XCTAssertEqual(try fileManager.loadData(contentsOf: target), payload)
    }

    func testWrittenFileHasOwnerOnlyPermissions() throws {
        let target = url("secret.txt")
        try Data("x".utf8).write(to: target) // pre-create with default mode first
        try fileManager.writeData(Data("y".utf8), to: target)

        let attributes = try FileManager.default.attributesOfItem(atPath: target.path)
        let mode = (attributes[.posixPermissions] as? NSNumber)?.int16Value
        XCTAssertEqual(mode, 0o600)
    }

    func testLegacyPlaintextFileIsStillReadable() throws {
        // Files written before the encryption upgrade lack the VC1 prefix and must load as-is.
        let target = url("legacy.txt")
        let legacy = Data("legacy plaintext".utf8)
        try legacy.write(to: target)
        XCTAssertEqual(try fileManager.loadData(contentsOf: target), legacy)
    }

    func testMigrateLegacyFileReencryptsInPlace() throws {
        let target = url("legacy2.txt")
        let legacy = Data("legacy plaintext".utf8)
        try legacy.write(to: target)

        fileManager.migrateLegacyFileIfNeeded(at: target)

        let raw = try Data(contentsOf: target)
        XCTAssertEqual(raw.prefix(3), Data("VC1".utf8))
        XCTAssertEqual(try fileManager.loadData(contentsOf: target), legacy)
    }
}
