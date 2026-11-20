//
//  LogStorageTests.swift
//  VaultClipTests
//
//  Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class LogStorageTests: XCTestCase {

    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LogStorageTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func fileMode(of url: URL) throws -> Int16 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes[.posixPermissions] as? NSNumber)?.int16Value ?? 0
    }

    func testSecureAndPruneLogs_appliesOwnerOnlyPermissions() throws {
        let log = directory.appendingPathComponent("error-log.txt")
        try Data("payload".utf8).write(to: log)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o644))],
            ofItemAtPath: log.path
        )

        LogStorage.secureAndPruneLogs(at: [log])

        XCTAssertEqual(try fileMode(of: log), LogStorage.logFilePermissions)
    }

    func testSecureAndPruneLogs_leavesMissingFilesAlone() {
        let missing = directory.appendingPathComponent("nope.log")
        LogStorage.secureAndPruneLogs(at: [missing])
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing.path))
    }

    func testRotateIfNeeded_trimsToTailWhenOverThreshold() throws {
        let log = directory.appendingPathComponent("pasteboard-debug.log")
        let noise = Data(repeating: 0x41, count: LogStorage.rotationThresholdBytes + 1_024)
        try noise.write(to: log)

        LogStorage.rotateIfNeeded(at: log)

        let trimmed = try Data(contentsOf: log)
        XCTAssertEqual(trimmed.count, LogStorage.rotatedTailBytes)
    }

    func testRotateIfNeeded_keepsSmallFilesIntact() throws {
        let log = directory.appendingPathComponent("small.log")
        try Data("tiny".utf8).write(to: log)

        LogStorage.rotateIfNeeded(at: log)

        XCTAssertEqual(try Data(contentsOf: log), Data("tiny".utf8))
    }

    func testSecureAndPruneLogs_skipsRotationWhenPredicateDenies() throws {
        let log = directory.appendingPathComponent("debug.log")
        try Data(repeating: 0x42, count: LogStorage.rotationThresholdBytes + 1_024).write(to: log)

        LogStorage.secureAndPruneLogs(at: [log], shouldRotate: { _ in false })

        let size = try Data(contentsOf: log).count
        XCTAssertGreaterThan(size, LogStorage.rotatedTailBytes)
        XCTAssertEqual(try fileMode(of: log), LogStorage.logFilePermissions)
    }

    func testEnsureLogFileExistsCreatesOwnerOnlyFile() throws {
        let log = directory.appendingPathComponent("fresh.log")
        LogStorage.ensureLogFileExists(at: log)
        XCTAssertTrue(FileManager.default.fileExists(atPath: log.path))
        XCTAssertEqual(try fileMode(of: log), LogStorage.logFilePermissions)
    }

    func testSecureAtLaunchRotatesOversizedErrorLogUnderOverrideRoot() throws {
        let previous = StorageRoot.override
        StorageRoot.override = directory
        defer { StorageRoot.override = previous }

        try FileManager.default.createDirectory(at: Constants.urls.appSupport, withIntermediateDirectories: true)
        try Data(repeating: 0x43, count: LogStorage.rotationThresholdBytes + 2_048)
            .write(to: Constants.urls.errorLog)

        LogStorage.secureAtLaunch()

        let trimmed = try Data(contentsOf: Constants.urls.errorLog)
        XCTAssertEqual(trimmed.count, LogStorage.rotatedTailBytes)
        XCTAssertEqual(try fileMode(of: Constants.urls.errorLog), LogStorage.logFilePermissions)
    }
}
