//
// LegacyHistoryMigrationTests — plaintext history files re-encrypt on load (T10).
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import XCTest
@testable import VaultClip

final class LegacyHistoryMigrationTests: XCTestCase {
    private var root: URL!
    private var previousOverride: URL?

    override func setUp() {
        super.setUp()
        previousOverride = StorageRoot.override
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VaultClip-legacy-mig-\(UUID().uuidString)", isDirectory: true)
        StorageRoot.override = root
        try? FileManager.default.createDirectory(at: Constants.urls.history, withIntermediateDirectories: true)
    }

    override func tearDown() {
        StorageRoot.override = previousOverride
        try? FileManager.default.removeItem(at: root)
        root = nil
        previousOverride = nil
        super.tearDown()
    }

    func testLoadReencryptsPlaintextItemFile() throws {
        let id = UUID()
        let itemDir = Constants.urls.history.appendingPathComponent(id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: itemDir, withIntermediateDirectories: true)
        let type = NSPasteboard.PasteboardType.string
        let fileURL = itemDir.appendingPathComponent(SecureStorageHelper.sanitizedPasteboardFileName(for: type))
        let plaintext = Data("hello-legacy".utf8)
        try plaintext.write(to: fileURL)

        let order = try PropertyListSerialization.data(fromPropertyList: [id.uuidString], format: .xml, options: 0)
        try order.write(to: Constants.urls.historyOrder)

        let cache = HistoryCache()
        _ = History(historyFM: HistoryFileManager(), cache: cache, items: HistoryFileManager().loadHistory(cache: cache))

        XCTAssertTrue(HistoryEncryptionProbe.isEncryptedFile(at: fileURL))
        let decrypted = try DataFileManager().loadData(contentsOf: fileURL)
        XCTAssertEqual(decrypted, plaintext)
    }
}
