//
// QuickLookTempStoreTests — temp PDF write, per-id remove, removeAll, 0600 mode.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class QuickLookTempStoreTests: XCTestCase {
    private var directory: URL!
    private var store: QuickLookTempStore!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VaultClip-QL-test-\(UUID().uuidString)", isDirectory: true)
        store = QuickLookTempStore(directory: directory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        store = nil
        directory = nil
        super.tearDown()
    }

    func testUrlWritesFileWithOwnerReadWriteOnly() throws {
        let id = UUID()
        let data = Data("%PDF-1.4 test".utf8)
        let url = try store.url(for: id, data: data)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(try Data(contentsOf: url), data)
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let mode = attrs[.posixPermissions] as? NSNumber
        XCTAssertEqual(mode?.intValue, 0o600)
    }

    func testRemoveDeletesSingleFile() throws {
        let id = UUID()
        let url = try store.url(for: id, data: Data("a".utf8))
        store.remove(id: id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testRemoveAllClearsDirectory() throws {
        _ = try store.url(for: UUID(), data: Data("a".utf8))
        _ = try store.url(for: UUID(), data: Data("b".utf8))
        store.removeAll()
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }
}
